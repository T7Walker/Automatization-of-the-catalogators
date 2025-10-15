# main_orchestrator.ps1 - ORQUESTADOR PRINCIPAL ACTUALIZADO

# Cargar módulos necesarios
. ".\sistema_severidad_actualizado.ps1"
. ".\sistema_notificaciones.ps1"
. ".\config_umbrales.ps1"
. ".\logica_fuentes.ps1"
. ".\validacion_precondicion.ps1"
. ".\verificacion_links.ps1"
. ".\funciones_auxiliares_completas.ps1"

# --- CONFIGURACIÓN INICIAL ---
$global:ExecutionLog = @()
$LogDirectory = "C:\Bancolombia\CatalogadorAuto\Logs\"
$ExecutionId = "CATALOG_" + (Get-Date -Format "yyyyMMdd_HHmmss")
$Global:VariablesProceso = @{}

# Inicializar directorios de log
function Initialize_Logging {
    $directories = @(
        $LogDirectory,
        "$LogDirectory\Screenshots",
        "$LogDirectory\Errores", 
        "$LogDirectory\Estados",
        "$LogDirectory\Auditoria",
        "$LogDirectory\Reportes"
    )
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    Write-Host "✅ Directorios de log inicializados" -ForegroundColor Green
}

# Función de logging mejorada
function Add_ExecutionStep {
    param(
        [string]$Step,
        [string]$Message, 
        [string]$Status = "INFO",
        [bool]$TakeScreenshot = $false
    )
    
    $logEntry = @{
        Timestamp = Get-Date
        Step = $Step
        Message = $Message
        Status = $Status
        ExecutionId = $ExecutionId
    }
    
    $global:ExecutionLog += $logEntry
    
    # Escribir a archivo de log principal
    $logFile = "$LogDirectory\execution_$(Get-Date -Format 'yyyyMMdd').log"
    $logLine = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Status] $Step - $Message"
    
    try {
        Add-Content -Path $logFile -Value $logLine -Encoding UTF8
    }
    catch {
        Write-Host "❌ Error escribiendo log: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Mostrar en consola con colores
    switch ($Status) {
        "STARTED" { Write-Host "🟡 [$Status] $Step - $Message" -ForegroundColor Yellow }
        "COMPLETED" { Write-Host "✅ [$Status] $Step - $Message" -ForegroundColor Green }
        "FAILED" { Write-Host "❌ [$Status] $Step - $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "⚠️ [$Status] $Step - $Message" -ForegroundColor Magenta }
        default { Write-Host "ℹ️ [$Status] $Step - $Message" -ForegroundColor Cyan }
    }
    
    # Tomar screenshot si se solicita
    if ($TakeScreenshot) {
        . ".\screenshot_handler.ps1"
        Take_Screenshot -Context "STEP_$Step" -ScreenshotPath "$LogDirectory\Screenshots\"
    }
}

function Start_CatalogadorProcess {
    param(
        [string]$TipoProceso,  # "PROMOCION", "APLICACION", "ACTUALIZACION"
        [string]$WorkItemId,
        [string]$SourcePath,
        [string]$DestinationPath,
        [hashtable]$ControlPasos
    )
    
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        Add_ExecutionStep -Step "INIT" -Message "Iniciando proceso de $TipoProceso - ID: $ExecutionId" -Status "STARTED" -TakeScreenshot $true
        
        # 1. VALIDAR ERRORES CRÍTICOS
        Add_ExecutionStep -Step "VALIDACION_CRITICA" -Message "Validando condiciones críticas" -Status "STARTED"
        
        $erroresCriticos = Test-ErrorCritico -TipoProceso $TipoProceso -RutaArchivos $SourcePath -ControlPasos $ControlPasos -AmbienteDestino $DestinationPath -WorkItemId $WorkItemId
        
        if ($erroresCriticos.Count -gt 0) {
            Add_ExecutionStep -Step "VALIDACION_CRITICA" -Message "Errores críticos detectados" -Status "FAILED"
            
            # CERRAR CICLO Y NOTIFICAR
            Invoke-NotificacionPowerAutomate -Severidad "CRITICA" -Errores $erroresCriticos -TipoProceso $TipoProceso -WorkItemId $WorkItemId
            return $false
        }
        
        Add_ExecutionStep -Step "VALIDACION_CRITICA" -Message "Validación crítica exitosa" -Status "COMPLETED"
        
        # 2. VALIDAR ERRORES ALTOS
        Add_ExecutionStep -Step "VALIDACION_ALTOS" -Message "Validando condiciones altas" -Status "STARTED"
        
        $erroresAltos = Test-ErrorAlto -RutaDesarrollo $SourcePath -WorkItemId $WorkItemId -VariablesProceso $Global:VariablesProceso -TieneCapturasSonarQ $true
        
        if ($erroresAltos.Count -gt 0) {
            Add_ExecutionStep -Step "VALIDACION_ALTOS" -Message "Errores altos detectados" -Status "FAILED"
            
            # NOTIFICAR PERO CONTINUAR
            Invoke-NotificacionPowerAutomate -Severidad "ALTA" -Errores $erroresAltos -TipoProceso $TipoProceso -WorkItemId $WorkItemId
            # NO retornar false - continuar proceso
        } else {
            Add_ExecutionStep -Step "VALIDACION_ALTOS" -Message "Validación alta exitosa" -Status "COMPLETED"
        }
        
        # 3. EJECUTAR PROCESO PRINCIPAL
        Add_ExecutionStep -Step "PROCESO_PRINCIPAL" -Message "Ejecutando proceso de $TipoProceso" -Status "STARTED" -TakeScreenshot $true
        
        # ... (tu lógica principal de catalogación aquí)
        
        Add_ExecutionStep -Step "PROCESO_PRINCIPAL" -Message "Proceso principal completado" -Status "COMPLETED"
        
        # 4. VALIDAR ERRORES MEDIOS/BAJOS AL FINAL
        $erroresMedios = Test-ErrorMedio -DatosAzure (Get-DatosAzure -WorkItemId $WorkItemId) -DatosRepositorio (Get-DatosRepositorio -Ruta $SourcePath)
        $erroresBajos = Test-ErrorBajo -SolucionAzure (Get-SolucionAzure -WorkItemId $WorkItemId) -SolucionRepositorio (Get-SolucionRepositorio -Ruta $SourcePath) -DesarrolladorAsignado (Get-DesarrolladorAsignado -WorkItemId $WorkItemId)
        
        # MANEJAR ERRORES MEDIOS/BAJOS
        if ($erroresMedios.Count -gt 0) {
            $comentario = "Errores medios detectados: $($erroresMedios -join '; ')"
            Add-EtiquetaAzureDevOps -WorkItemId $WorkItemId -Etiquetas @("LiderDesarrollo", "Desarrollador") -Comentario $comentario
        }
        
        if ($erroresBajos.Count -gt 0) {
            $comentario = "Errores bajos detectados: $($erroresBajos -join '; ')" 
            Add-EtiquetaAzureDevOps -WorkItemId $WorkItemId -Etiquetas @("LiderDesarrollo", "Desarrollador") -Comentario $comentario
        }
        
        # 5. VERIFICAR TIEMPO DE EJECUCIÓN
        $timer.Stop()
        $tiempoMinutos = [math]::Round($timer.Elapsed.TotalMinutes, 2)
        $umbral = $UmbralesTiempo[$TipoProceso]
        
        if ($tiempoMinutos -gt $umbral) {
            $errorTiempo = "TIEMPO_EXCEDIDO: Proceso $TipoProceso tomó $tiempoMinutos minutos (umbral: $umbral minutos)"
            Invoke-NotificacionPowerAutomate -Severidad "ALTA" -Errores @($errorTiempo) -TipoProceso $TipoProceso -WorkItemId $WorkItemId
        }
        
        Add_ExecutionStep -Step "FINALIZACION" -Message "Proceso $TipoProceso completado en $tiempoMinutos minutos" -Status "COMPLETED" -TakeScreenshot $true
        
        # Generar reporte final
        Generate_ExecutionReport
        
        return $true
    }
    catch {
        $timer.Stop()
        Add_ExecutionStep -Step "ERROR_GENERAL" -Message "Error no controlado: $($_.Exception.Message)" -Status "FAILED" -TakeScreenshot $true
        
        # Tomar screenshot de error detallado
        . ".\screenshot_handler.ps1"
        Take_ErrorScreenshot -ErrorMessage $_.Exception.Message -StackTrac3 $_.ScriptStackTrace -Step "MAIN_PROCESS"
        
        # NOTIFICAR ERROR NO CONTROLADO COMO ALTO
        Invoke-NotificacionPowerAutomate -Severidad "ALTA" -Errores @($_.Exception.Message) -TipoProceso $TipoProceso -WorkItemId $WorkItemId
        
        # Generar reporte de error
        Generate_ErrorReport -Error $_
        
        return $false
    }
}

function Generate_ExecutionReport {
    $reportFile = "$LogDirectory\Reportes\execution_report_$ExecutionId.txt"
    $reportDir = Split-Path $reportFile -Parent
    
    if (!(Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $report = @"
=== EJECUCIÓN CATALOGADOR - REPORTE FINAL ===
ID: $ExecutionId
Fecha: $(Get-Date)
Total Pasos: $($global:ExecutionLog.Count)
Estado: COMPLETADO

--- RESUMEN DE PASOS ---
$($global:ExecutionLog | ForEach-Object { 
    "  $($_.Timestamp.ToString('HH:mm:ss')) [$($_.Status)] $($_.Step) - $($_.Message)" 
} | Out-String)

--- ESTADÍSTICAS ---
Inicio: $($global:ExecutionLog[0].Timestamp)
Fin: $(Get-Date)
Duración: $((Get-Date) - $global:ExecutionLog[0].Timestamp)

Pasos Exitosos: $(($global:ExecutionLog | Where-Object { $_.Status -eq 'COMPLETED' }).Count)
Pasos Fallidos: $(($global:ExecutionLog | Where-Object { $_.Status -eq 'FAILED' }).Count)
Advertencias: $(($global:ExecutionLog | Where-Object { $_.Status -eq 'WARNING' }).Count)

=== FIN DEL REPORTE ===
"@
    
    $report | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Host "📊 Reporte generado: $reportFile" -ForegroundColor Green
}

function Generate_ErrorReport {
    param($Err0r)
    
    $reportFile = "$LogDirectory\Reportes\error_report_$ExecutionId.txt"
    
    $report = @"
=== REPORTE DE ERROR - CATALOGADOR ===
ID: $ExecutionId
Fecha: $(Get-Date)
Error: $($Err0r.Exception.Message)

--- DETALLES TÉCNICOS ---
Tipo: $($Err0r.Exception.GetType().FullName)
Stack Trace: $($Err0r.ScriptStackTrace)

--- ÚLTIMOS PASOS EJECUTADOS ---
$($global:ExecutionLog | Select-Object -Last 5 | ForEach-Object { 
    "  $($_.Timestamp.ToString('HH:mm:ss')) [$($_.Status)] $($_.Step)" 
} | Out-String)

--- RECOMENDACIONES ---
1. Revisar los logs en: $LogDirectory
2. Verificar permisos de archivos
3. Validar conexión a Azure DevOps
4. Revisar espacio en disco

=== FIN REPORTE DE ERROR ===
"@
    
    $report | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Host "📄 Reporte de error generado: $reportFile" -ForegroundColor Red
}

# Inicializar sistema
Initialize_Logging

# Ejecutar el proceso cuando se llame directamente
if ($MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq '') {
    Write-Host "🚀 Iniciando Catalogador Automático..." -ForegroundColor Cyan
    
    # Ejemplo de uso - reemplazar con parámetros reales
    $result = Start_CatalogadorProcess -TipoProceso "PROMOCION" -WorkItemId "12345" -SourcePath "C:\dev\source" -DestinationPath "C:\test\destination" -ControlPasos @{}
    
    if ($result) {
        Write-Host "🎉 Proceso completado exitosamente!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "💥 Proceso falló. Revisar logs." -ForegroundColor Red
        exit 1
    }
}

Export-ModuleMember -Function Start_CatalogadorProcess, Add_ExecutionStep, Initialize_Logging