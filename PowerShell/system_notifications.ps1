param(
    [string]$Severidad,
    [string]$MensajesJson,
    [string]$TipoProceso,
    [string]$WorkItemId
)

try {
    # Convertir mensajes JSON
    $Mensajes = $MensajesJson | ConvertFrom-Json
    
    # Lógica de notificación existente
    $config = @{
        "CRITICA" = @{ PowerAutomate = $true; Destinatarios = @("catalogadores@bancolombia.com") }
        "ALTA" = @{ PowerAutomate = $true; Destinatarios = @("catalogadores@bancolombia.com") }
        "COMPLETADO" = @{ PowerAutomate = $false; AzureDevOps = $true }
    }
    
    $configActual = $config[$Severidad]
    
    if ($configActual.PowerAutomate) {
        # Lógica Power Automate existente
        Invoke-PowerAutomateNotification -Severidad $Severidad -Mensajes $Mensajes
    }
    
    if ($configActual.AzureDevOps) {
        # Lógica Azure DevOps existente
        Add-AzureDevOpsComment -WorkItemId $WorkItemId -Mensajes $Mensajes
    }
    
    $resultado = @{
        exitoso = $true
        mensaje = "Notificación $Severidad enviada"
    }
    
    return $resultado | ConvertTo-Json
    
} catch {
    $errorResult = @{
        exitoso = $false
        error = "Error en notificación: $($_.Exception.Message)"
    }
    return $errorResult | ConvertTo-Json
}