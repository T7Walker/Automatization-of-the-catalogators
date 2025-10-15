# logica_fuentes.ps1

function Test-SolicitudFuentes {
    param(
        [string]$ArchivoClass,
        [string]$WorkItemId
    )
    
    try {
        # Extraer nombre base (ej: "hjtbmm123" de "hjtbmm123.class")
        $nombreBase = [System.IO.Path]::GetFileNameWithoutExtension($ArchivoClass)
        
        Write_OperationLog -Operation "VERIFICACION_FUENTES" -Details "Buscando solicitud para: $nombreBase" -Status "INFO"
        
        # 1. BUSCAR SOLICITUDES DE FUENTES LINKEADAS A LA HU
        $solicitudes = Get-SolicitudesFuentesLinked -WorkItemId $WorkItemId -NombreObjeto $nombreBase
        
        if ($solicitudes.Count -eq 0) {
            Write_OperationLog -Operation "VERIFICACION_FUENTES" -Details "NO hay solicitudes linkeadas para: $nombreBase" -Status "WARNING"
            
            # ACTIVAR POWER AUTOMATE PARA NOTIFICAR A DESARROLLADORES
            Invoke-PowerAutomateNotificacion -Tipo "SIN_SOLICITUD_FUENTES" -Objeto $nombreBase -WorkItemId $WorkItemId -Destinatarios @("desarrolladores@bancolombia.com")
            return $false
        }
        
        # 2. VERIFICAR ESTADO DE CADA SOLICITUD
        foreach ($solicitud in $solicitudes) {
            Write_OperationLog -Operation "VERIFICACION_FUENTES" -Details "Solicitud encontrada: $($solicitud.Id) - Estado: $($solicitud.Estado)" -Status "INFO"
            
            if ($solicitud.Estado -eq "entregado") {
                Write_OperationLog -Operation "VERIFICACION_FUENTES" -Details "Solicitud EN ESTADO ENTREGADO: $($solicitud.Id)" -Status "COMPLETED"
                return $true
            }
            else {
                Write_OperationLog -Operation "VERIFICACION_FUENTES" -Details "Solicitud en estado NO ENTREGADO: $($solicitud.Estado)" -Status "WARNING"
                
                # NOTIFICAR INMEDIATAMENTE A CATALOGADORES
                Invoke-PowerAutomateNotificacion -Tipo "SOLICITUD_NO_ENTREGADA" -Objeto $nombreBase -WorkItemId $WorkItemId -Estado $solicitud.Estado -Destinatarios @("catalogadores@bancolombia.com")
                return $false
            }
        }
        
        # Si llegamos aquí, ninguna solicitud está en estado "entregado"
        return $false
    }
    catch {
        Write_OperationLog -Operation "VERIFICACION_FUENTES" -Details "Error verificando fuentes: $($_.Exception.Message)" -Status "FAILED"
        return $false
    }
}

function Get-SolicitudesFuentesLinked {
    param(
        [string]$WorkItemId,
        [string]$NombreObjeto
    )
    
    # OBTENER TODOS LOS WORK ITEMS LINKEADOS A LA HU
    $linkedItems = Get-AzureDevOpsLinkedItems -WorkItemId $WorkItemId
    
    $solicitudesFuentes = @()
    
    foreach ($item in $linkedItems) {
        # FILTRAR SOLO SOLICITUDES DE FUENTES QUE COINCIDAN CON EL NOMBRE DEL OBJETO
        if ($item.Fields.'System.WorkItemType' -eq "Solicitud de fuentes" -and 
            $item.Fields.'System.Title' -like "*$NombreObjeto*") {
            
            $solicitudesFuentes += @{
                Id = $item.Id
                Title = $item.Fields.'System.Title'
                Estado = $item.Fields.'Custom.EstadoSolicitud'  # Ajustar según tu campo personalizado
                Url = $item.Url
            }
        }
    }
    
    return $solicitudesFuentes
}

Export-ModuleMember -Function Test-SolicitudFuentes, Get-SolicitudesFuentesLinked