param(
    [string]$TipoProceso,
    [string]$WorkItemId,
    [string]$ControlPasosJson
)

try {
    # Convertir JSON a objeto PowerShell
    $ControlPasos = $ControlPasosJson | ConvertFrom-Json
    
    # Cargar módulos
    . ".\logica_fuentes.ps1"
    . ".\validacion_precondicion.ps1"
    . ".\verificacion_links.ps1"
    
    $resultado = @{
        exitoso = $true
        errores = @()
        advertencias = @()
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    # VALIDACIONES CRÍTICAS (sin IA)
    
    # 1. Verificar archivos .CLASS con BMM
    if ($ControlPasos.file_server.objetos -like "*.class*") {
        $archivosClassBmm = $ControlPasos.file_server.objetos | Where-Object { $_ -like "*bmm*" }
        
        foreach ($archivo in $archivosClassBmm) {
            $tieneFuentes = Test-SolicitudFuentes -ArchivoClass $archivo -WorkItemId $WorkItemId
            
            if (!$tieneFuentes) {
                $resultado.exitoso = $false
                $resultado.errores += "ARCHIVO_CLASS_BMM_SIN_FUENTES: $archivo"
            }
        }
    }
    
    # 2. Verificar precondición
    $precondicionValida = Test-PrecondicionAmbiente -ControlPasos $ControlPasos -AmbienteDestino "Pruebas"
    if (!$precondicionValida) {
        $resultado.exitoso = $false
        $resultado.errores += "PRECONDICION_AMBIENTE_INVALIDA"
    }
    
    # 3. Verificar links
    $linksValidos = Test-HULinked -WorkItemId $WorkItemId
    if (!$linksValidos) {
        $resultado.errores += "LINKS_URLPRUEBAS_INVALIDOS"
    }
    
    # Devolver resultado como JSON para Python
    return $resultado | ConvertTo-Json
    
} catch {
    $errorResult = @{
        exitoso = $false
        errores = @("Error en validación PowerShell: $($_.Exception.Message)")
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    return $errorResult | ConvertTo-Json
}