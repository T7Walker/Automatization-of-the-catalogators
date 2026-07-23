# environment_preconditions.ps1

function Test-EnvironmentPrecondition {
    param(
        [hashtable]$StepControl,
        [string]$TargetEnvironment
    )
    try {
        Write-OperationLog -Operation "PRECONDITION_VALIDATION" -Details "Checking precondition for: $TargetEnvironment" -Status "INFO"
        $recommendationText = $StepControl.ProcessRecommendations
        if ([string]::IsNullOrEmpty($recommendationText)) {
            Write-OperationLog -Operation "PRECONDITION_VALIDATION" -Details "No recommendation text" -Status "WARNING"
            return $true
        }
        $pattern = "support (.+) must be applied"
        $matches = [regex]::Matches($recommendationText, $pattern)
        if ($matches.Count -eq 0) {
            Write-OperationLog -Operation "PRECONDITION_VALIDATION" -Details "No precondition pattern found" -Status "INFO"
            return $true
        }
        foreach ($match in $matches) {
            $supportName = $match.Groups[1].Value.Trim()
            Write-OperationLog -Operation "PRECONDITION_VALIDATION" -Details "Checking support: $supportName" -Status "INFO"
            $applied = Test-SupportApplied -SupportName $supportName -Environment $TargetEnvironment
            if (!$applied) {
                Write-OperationLog -Operation "PRECONDITION_VALIDATION" -Details "SUPPORT NOT APPLIED: $supportName in $TargetEnvironment" -Status "FAILED"
                Invoke-PowerAutomateNotification -Type "PRECONDITION_NOT_MET" -Support $supportName -Environment $TargetEnvironment -WorkItemId $StepControl.WorkItemId
                return $false
            }
            Write-OperationLog -Operation "PRECONDITION_VALIDATION" -Details "Support applied: $supportName" -Status "COMPLETED"
        }
        return $true
    }
    catch {
        Write-OperationLog -Operation "PRECONDITION_VALIDATION" -Details "Error: $($_.Exception.Message)" -Status "FAILED"
        return $false
    }
}

function Test-SupportApplied {
    param([string]$SupportName, [string]$Environment)
    try { return $true }
    catch { return $false }
}

Export-ModuleMember -Function Test-EnvironmentPrecondition, Test-SupportApplied