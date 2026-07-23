# record_handler.ps1 - SYSTEM SCREENSHOT AND ERROR HANDLING

function Take_Screenshot {
    param(
        [string]$ScreenshotPath = "C:\logs\catalogador\screenshots\",
        [string]$Context = "unknown"
    )
    if (!(Test-Path $ScreenshotPath)) {
        New-Item -ItemType Directory -Path $ScreenshotPath -Force | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $screenshotFile = "$ScreenshotPath\$($Context)_$timestamp.txt"
    $systemInfo = @"
=== SCREENSHOT LOG - $Context - $timestamp ===
USER: $env:USERNAME
COMPUTER: $env:COMPUTERNAME
DOMAIN: $env:USERDOMAIN
DIRECTORY: $(Get-Location)
DATE/TIME: $(Get-Date)

--- ACTIVE PROCESSES ---
$((Get-Process | Where-Object {$_.MainWindowTitle -ne ""} | Select-Object Name, Id, CPU, WorkingSet | Format-Table -AutoSize | Out-String).Trim())

--- MEMORY INFO ---
Process memory: $([System.Math]::Round((Get-Process -Id $PID).WorkingSet / 1MB, 2)) MB
Total memory: $([System.Math]::Round((Get-Process | Measure-Object WorkingSet -Sum).Sum / 1MB, 2)) MB

--- CURRENT EXECUTION ---
Script: $($MyInvocation.MyCommand.Path)

=== END SCREENSHOT LOG ===
"@
    try {
        $systemInfo | Out-File -FilePath $screenshotFile -Encoding UTF8
        Write-Host "📸 Screenshot log created: $screenshotFile" -ForegroundColor Yellow
        return $screenshotFile
    }
    catch {
        Write-Host "❌ Error creating screenshot: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Take_ErrorScreenshot {
    param([string]$ErrorMessage, [string]$StackTrace, [string]$Step)
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $errorFile = "C:\logs\catalogador\errors\error_$($Step)_$timestamp.txt"
    $errorDir = Split-Path $errorFile -Parent
    if (!(Test-Path $errorDir)) { New-Item -ItemType Directory -Path $errorDir -Force | Out-Null }
    $errorInfo = @"
=== ERROR SCREENSHOT - $Step - $timestamp ===
ERROR MESSAGE: $ErrorMessage
STEP: $Step
TIMESTAMP: $(Get-Date)

--- STACK TRACE ---
$StackTrace

--- SYSTEM STATE ---
User: $env:USERNAME
Computer: $env:COMPUTERNAME
Directory: $(Get-Location)

=== END ERROR SCREENSHOT ===
"@
    try {
        $errorInfo | Out-File -FilePath $errorFile -Encoding UTF8
        Write-Host "📄 Error log created: $errorFile" -ForegroundColor Red
        return $errorFile
    }
    catch {
        Write-Host "❌ Error creating error log: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Export-ModuleMember -Function Take_Screenshot, Take_ErrorScreenshot