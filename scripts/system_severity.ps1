param(
    [string]$ProcessType,
    [string]$WorkItemId,
    [string]$StepControlJson
)

try {
    $StepControl = $StepControlJson | ConvertFrom-Json
    . ".\source_logic.ps1"
    . ".\environment_preconditions.ps1"
    . ".\link_verification.ps1"

    $result = @{
        success = $true
        errors = @()
        warnings = @()
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

    if ($StepControl.file_server.objects -like "*.class*") {
        $classFiles = $StepControl.file_server.objects | Where-Object { $_ -like "*.class" }
        foreach ($file in $classFiles) {
            $hasSources = Test-SourceRequest -ClassFile $file -WorkItemId $WorkItemId
            if (!$hasSources) {
                $result.success = $false
                $result.errors += "CLASS_FILE_WITHOUT_SOURCES: $file"
            }
        }
    }

    $preconditionValid = Test-EnvironmentPrecondition -StepControl $StepControl -TargetEnvironment "Testing"
    if (!$preconditionValid) {
        $result.success = $false
        $result.errors += "ENVIRONMENT_PRECONDITION_INVALID"
    }

    $linksValid = Test-HULinked -WorkItemId $WorkItemId
    if (!$linksValid) {
        $result.errors += "INVALID_TESTING_URL_LINKS"
    }

    return $result | ConvertTo-Json
}
catch {
    $errorResult = @{
        success = $false
        errors = @("PowerShell validation error: $($_.Exception.Message)")
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    return $errorResult | ConvertTo-Json
}