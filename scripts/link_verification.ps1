# link_verification.ps1

function Test-HULinked {
    param([string]$WorkItemId)
    try {
        Write-OperationLog -Operation "LINK_VERIFICATION" -Details "Checking links for WorkItem: $WorkItemId" -Status "STARTED"
        $workItem = Get-AzureDevOpsWorkItem -WorkItemId $WorkItemId
        if ($null -eq $workItem) {
            Write-OperationLog -Operation "LINK_VERIFICATION" -Details "Could not get WorkItem" -Status "FAILED"
            return $false
        }
        $links = Get-AzureDevOpsLinks -WorkItemId $WorkItemId
        if ($links.Count -eq 0) {
            Write-OperationLog -Operation "LINK_VERIFICATION" -Details "No links found for WorkItem" -Status "WARNING"
            return $false
        }
        Write-OperationLog -Operation "LINK_VERIFICATION" -Details "Links found: $($links.Count)" -Status "COMPLETED"
        return $true
    }
    catch {
        Write-OperationLog -Operation "LINK_VERIFICATION" -Details "Error: $($_.Exception.Message)" -Status "FAILED"
        return $false
    }
}

Export-ModuleMember -Function Test-HULinked