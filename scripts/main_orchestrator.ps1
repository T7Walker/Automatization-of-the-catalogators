# main_orchestrator.ps1 - MAIN ORCHESTRATOR

# Load required modules
. ".\system_severity.ps1"
. ".\system_notifications.ps1"
. ".\threshold_config.ps1"
. ".\source_logic.ps1"
. ".\environment_preconditions.ps1"
. ".\link_verification.ps1"
. ".\auxiliary_functions.ps1"

# --- INITIAL CONFIGURATION ---
$global:ExecutionLog = @()
$LogDirectory = "C:\logs\catalogador\"
$ExecutionId = "CATALOG_" + (Get-Date -Format "yyyyMMdd_HHmmss")
$Global:ProcessVariables = @{}

function Initialize-Logging {
    $directories = @(
        $LogDirectory,
        "$LogDirectory\Screenshots",
        "$LogDirectory\Errors",
        "$LogDirectory\Status",
        "$LogDirectory\Audit",
        "$LogDirectory\Reports"
    )
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    Write-Host "✅ Log directories initialized" -ForegroundColor Green
}

function Add-ExecutionStep {
    param(
        [string]$Step,
        [string]$Message,
        [string]$Status = "INFO",
        [bool]$TakeScreenshot = $false
    )
    $logEntry = @{
        Timestamp = Get-Date
        Step = $Step
        Message = $Message
        Status = $Status
        ExecutionId = $ExecutionId
    }
    $global:ExecutionLog += $logEntry

    $logFile = "$LogDirectory\execution_$(Get-Date -Format 'yyyyMMdd').log"
    $logLine = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Status] $Step - $Message"
    try { Add-Content -Path $logFile -Value $logLine -Encoding UTF8 } catch {}

    switch ($Status) {
        "STARTED" { Write-Host "🟡 [$Status] $Step - $Message" -ForegroundColor Yellow }
        "COMPLETED" { Write-Host "✅ [$Status] $Step - $Message" -ForegroundColor Green }
        "FAILED" { Write-Host "❌ [$Status] $Step - $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "⚠️ [$Status] $Step - $Message" -ForegroundColor Magenta }
        default { Write-Host "ℹ️ [$Status] $Step - $Message" -ForegroundColor Cyan }
    }
    if ($TakeScreenshot) {
        . ".\record_handler.ps1"
        Take_Screenshot -Context "STEP_$Step" -ScreenshotPath "$LogDirectory\Screenshots\"
    }
}

function Start-CatalogProcess {
    param(
        [string]$ProcessType,
        [string]$WorkItemId,
        [string]$SourcePath,
        [string]$DestinationPath,
        [hashtable]$StepControl
    )
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Add-ExecutionStep -Step "INIT" -Message "Starting $ProcessType - ID: $ExecutionId" -Status "STARTED" -TakeScreenshot $true

        Add-ExecutionStep -Step "CRITICAL_VALIDATION" -Message "Validating critical conditions" -Status "STARTED"
        $criticalErrors = Test-CriticalError -ProcessType $ProcessType -FilePath $SourcePath -StepControl $StepControl -TargetEnvironment $DestinationPath -WorkItemId $WorkItemId
        if ($criticalErrors.Count -gt 0) {
            Add-ExecutionStep -Step "CRITICAL_VALIDATION" -Message "Critical errors detected" -Status "FAILED"
            Invoke-PowerAutomateNotification -Severity "CRITICAL" -Errors $criticalErrors -ProcessType $ProcessType -WorkItemId $WorkItemId
            return $false
        }
        Add-ExecutionStep -Step "CRITICAL_VALIDATION" -Message "Critical validation passed" -Status "COMPLETED"

        Add-ExecutionStep -Step "HIGH_VALIDATION" -Message "Validating high conditions" -Status "STARTED"
        $highErrors = Test-HighError -DevelopmentPath $SourcePath -WorkItemId $WorkItemId -ProcessVariables $Global:ProcessVariables -HasSonarQCaptures $true
        if ($highErrors.Count -gt 0) {
            Add-ExecutionStep -Step "HIGH_VALIDATION" -Message "High errors detected" -Status "FAILED"
            Invoke-PowerAutomateNotification -Severity "HIGH" -Errors $highErrors -ProcessType $ProcessType -WorkItemId $WorkItemId
        } else {
            Add-ExecutionStep -Step "HIGH_VALIDATION" -Message "High validation passed" -Status "COMPLETED"
        }

        Add-ExecutionStep -Step "MAIN_PROCESS" -Message "Executing $ProcessType" -Status "STARTED" -TakeScreenshot $true
        Add-ExecutionStep -Step "MAIN_PROCESS" -Message "Main process completed" -Status "COMPLETED"

        $mediumErrors = Test-MediumError -AzureData (Get-AzureData -WorkItemId $WorkItemId) -RepositoryData (Get-RepositoryData -Path $SourcePath)
        $lowErrors = Test-LowError -AzureSolution (Get-AzureSolution -WorkItemId $WorkItemId) -RepositorySolution (Get-RepositorySolution -Path $SourcePath) -AssignedDeveloper (Get-AssignedDeveloper -WorkItemId $WorkItemId)

        if ($mediumErrors.Count -gt 0) {
            Add-AzureDevOpsTag -WorkItemId $WorkItemId -Tags @("LeadDeveloper", "Developer") -Comment "Medium errors detected: $($mediumErrors -join '; ')"
        }
        if ($lowErrors.Count -gt 0) {
            Add-AzureDevOpsTag -WorkItemId $WorkItemId -Tags @("LeadDeveloper", "Developer") -Comment "Low errors detected: $($lowErrors -join '; ')"
        }

        $timer.Stop()
        $timeMinutes = [math]::Round($timer.Elapsed.TotalMinutes, 2)
        $threshold = $TimeThresholds[$ProcessType]
        if ($timeMinutes -gt $threshold) {
            Invoke-PowerAutomateNotification -Severity "HIGH" -Errors @("TIME_EXCEEDED: $ProcessType took $timeMinutes min (threshold: $threshold min)") -ProcessType $ProcessType -WorkItemId $WorkItemId
        }

        Add-ExecutionStep -Step "COMPLETION" -Message "$ProcessType completed in $timeMinutes minutes" -Status "COMPLETED" -TakeScreenshot $true
        Generate-ExecutionReport
        return $true
    }
    catch {
        $timer.Stop()
        Add-ExecutionStep -Step "GENERAL_ERROR" -Message "Unhandled error: $($_.Exception.Message)" -Status "FAILED" -TakeScreenshot $true
        . ".\record_handler.ps1"
        Take_ErrorScreenshot -ErrorMessage $_.Exception.Message -StackTrace $_.ScriptStackTrace -Step "MAIN_PROCESS"
        Invoke-PowerAutomateNotification -Severity "HIGH" -Errors @($_.Exception.Message) -ProcessType $ProcessType -WorkItemId $WorkItemId
        Generate-ErrorReport -ErrorObject $_
        return $false
    }
}

function Generate-ExecutionReport {
    $reportFile = "$LogDirectory\Reports\execution_report_$ExecutionId.txt"
    $reportDir = Split-Path $reportFile -Parent
    if (!(Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir -Force | Out-Null }
    $report = @"
=== CATALOG EXECUTION - FINAL REPORT ===
ID: $ExecutionId
Date: $(Get-Date)
Total Steps: $($global:ExecutionLog.Count)
Status: COMPLETED

--- STEP SUMMARY ---
$($global:ExecutionLog | ForEach-Object { "  $($_.Timestamp.ToString('HH:mm:ss')) [$($_.Status)] $($_.Step) - $($_.Message)" } | Out-String)

--- STATISTICS ---
Start: $($global:ExecutionLog[0].Timestamp)
End: $(Get-Date)
Duration: $((Get-Date) - $global:ExecutionLog[0].Timestamp)
Successful: $(($global:ExecutionLog | Where-Object { $_.Status -eq 'COMPLETED' }).Count)
Failed: $(($global:ExecutionLog | Where-Object { $_.Status -eq 'FAILED' }).Count)
Warnings: $(($global:ExecutionLog | Where-Object { $_.Status -eq 'WARNING' }).Count)

=== END OF REPORT ===
"@
    $report | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Host "📊 Report generated: $reportFile" -ForegroundColor Green
}

function Generate-ErrorReport {
    param($ErrorObject)
    $reportFile = "$LogDirectory\Reports\error_report_$ExecutionId.txt"
    $report = @"
=== ERROR REPORT - CATALOGADOR ===
ID: $ExecutionId
Date: $(Get-Date)
Error: $($ErrorObject.Exception.Message)

--- TECHNICAL DETAILS ---
Type: $($ErrorObject.Exception.GetType().FullName)
Stack Trace: $($ErrorObject.ScriptStackTrace)

--- LAST STEPS ---
$($global:ExecutionLog | Select-Object -Last 5 | ForEach-Object { "  $($_.Timestamp.ToString('HH:mm:ss')) [$($_.Status)] $($_.Step)" } | Out-String)

--- RECOMMENDATIONS ---
1. Check logs at: $LogDirectory
2. Verify file permissions
3. Validate Azure DevOps connection
4. Check disk space

=== END OF ERROR REPORT ===
"@
    $report | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Host "📄 Error report generated: $reportFile" -ForegroundColor Red
}

# Initialize system
Initialize-Logging

if ($MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq '') {
    Write-Host "🚀 Starting Catalog Automator..." -ForegroundColor Cyan
    $result = Start-CatalogProcess -ProcessType "PROMOTION" -WorkItemId "12345" -SourcePath "C:\dev\source" -DestinationPath "C:\test\destination" -StepControl @{}
    if ($result) { Write-Host "🎉 Process completed successfully!" -ForegroundColor Green; exit 0 }
    else { Write-Host "💥 Process failed. Check logs." -ForegroundColor Red; exit 1 }
}

Export-ModuleMember -Function Start-CatalogProcess, Add-ExecutionStep, Initialize-Logging