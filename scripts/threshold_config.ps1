# threshold_config.ps1

$TimeThresholds = @{
    "PROMOTION"   = 15
    "APPLICATION" = 5
    "UPDATE"      = 10
}

$NotificationRules = @{
    "CRITICAL" = @{ Action = "CLOSE_CYCLE"; PowerAutomate = $true }
    "HIGH"     = @{ Action = "NOTIFY_CATALOGERS"; PowerAutomate = $true }
    "MEDIUM"   = @{ Action = "TAG_LEAD_DEVELOPER"; PowerAutomate = $false; AzureDevOps = $true }
    "LOW"      = @{ Action = "TAG_LEAD_DEVELOPER"; PowerAutomate = $false; AzureDevOps = $true }
}

Export-ModuleMember -Variable TimeThresholds, NotificationRules