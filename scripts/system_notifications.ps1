param(
    [string]$Severity,
    [string]$MessagesJson,
    [string]$ProcessType,
    [string]$WorkItemId
)

try {
    $Messages = $MessagesJson | ConvertFrom-Json

    $config = @{
        "CRITICAL"   = @{ PowerAutomate = $true; AzureDevOps = $true }
        "HIGH"       = @{ PowerAutomate = $true; AzureDevOps = $true }
        "MEDIUM"     = @{ PowerAutomate = $false; AzureDevOps = $true }
        "LOW"        = @{ PowerAutomate = $false; AzureDevOps = $true }
        "COMPLETED"  = @{ PowerAutomate = $false; AzureDevOps = $true }
    }

    $currentConfig = $config[$Severity]
    if ($null -eq $currentConfig) {
        throw "Invalid severity: $Severity"
    }

    if ($currentConfig.PowerAutomate) {
        Invoke-PowerAutomateNotification -Severity $Severity -Messages $Messages
    }
    if ($currentConfig.AzureDevOps) {
        Add-AzureDevOpsComment -WorkItemId $WorkItemId -Messages $Messages
    }

    $result = @{ success = $true; message = "Notification $Severity sent" }
    return $result | ConvertTo-Json
}
catch {
    $errorResult = @{ success = $false; error = "Notification error: $($_.Exception.Message)" }
    return $errorResult | ConvertTo-Json
}