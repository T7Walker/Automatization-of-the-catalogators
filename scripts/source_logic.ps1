# source_logic.ps1

function Test-SourceRequest {
    param(
        [string]$ClassFile,
        [string]$WorkItemId
    )
    try {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($ClassFile)
        Write-OperationLog -Operation "SOURCE_VERIFICATION" -Details "Searching request for: $baseName" -Status "INFO"

        $requests = Get-SourceRequestsLinked -WorkItemId $WorkItemId -ObjectName $baseName
        if ($requests.Count -eq 0) {
            Write-OperationLog -Operation "SOURCE_VERIFICATION" -Details "No linked requests for: $baseName" -Status "WARNING"
            Invoke-PowerAutomateNotification -Type "NO_SOURCE_REQUEST" -ObjectName $baseName -WorkItemId $WorkItemId
            return $false
        }
        foreach ($req in $requests) {
            Write-OperationLog -Operation "SOURCE_VERIFICATION" -Details "Request found: $($req.Id) - Status: $($req.Status)" -Status "INFO"
            if ($req.Status -eq "delivered") {
                Write-OperationLog -Operation "SOURCE_VERIFICATION" -Details "Request DELIVERED: $($req.Id)" -Status "COMPLETED"
                return $true
            } else {
                Write-OperationLog -Operation "SOURCE_VERIFICATION" -Details "Request NOT DELIVERED: $($req.Status)" -Status "WARNING"
                Invoke-PowerAutomateNotification -Type "REQUEST_NOT_DELIVERED" -ObjectName $baseName -WorkItemId $WorkItemId -Status $req.Status
                return $false
            }
        }
        return $false
    }
    catch {
        Write-OperationLog -Operation "SOURCE_VERIFICATION" -Details "Error verifying sources: $($_.Exception.Message)" -Status "FAILED"
        return $false
    }
}

function Get-SourceRequestsLinked {
    param([string]$WorkItemId, [string]$ObjectName)
    $linkedItems = Get-AzureDevOpsLinkedItems -WorkItemId $WorkItemId
    $sourceRequests = @()
    foreach ($item in $linkedItems) {
        if ($item.Fields.'System.WorkItemType' -eq "Source Request" -and $item.Fields.'System.Title' -like "*$ObjectName*") {
            $sourceRequests += @{
                Id = $item.Id
                Title = $item.Fields.'System.Title'
                Status = $item.Fields.'Custom.RequestStatus'
                Url = $item.Url
            }
        }
    }
    return $sourceRequests
}

function Invoke-PowerAutomateNotification {
    param(
        [string]$Type,
        [string]$ObjectName = "",
        [string]$WorkItemId,
        [string]$Status = "",
        [string]$Environment = "",
        [string]$Support = ""
    )
    try {
        Write-OperationLog -Operation "POWER_AUTOMATE" -Details "Notification $Type for WorkItem $WorkItemId" -Status "INFO"
        return $true
    }
    catch {
        Write-OperationLog -Operation "POWER_AUTOMATE" -Details "Notification error: $($_.Exception.Message)" -Status "FAILED"
        return $false
    }
}

Export-ModuleMember -Function Test-SourceRequest, Get-SourceRequestsLinked, Invoke-PowerAutomateNotification