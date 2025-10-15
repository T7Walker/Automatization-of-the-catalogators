# screenshot_handler.ps1 - Versión sin .NET
function Take_Screenshot {
    param(
        [string]$ScreenshotPath = "C:\logs\catalogador\screenshots\",
        [string]$Context = "unknown"
    )
    
    # Crear directorio si no existe
    if (!(Test-Path $ScreenshotPath)) {
        New-Item -ItemType Directory -Path $ScreenshotPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $screenshotFile = "$ScreenshotPath\$($Context)_$timestamp.txt"
    
    # Capturar estado completo del sistema
    $systemInfo = @"
=== SCREENSHOT LOG - $Context - $timestamp ===
USUARIO: $env:USERNAME
EQUIPO: $env:COMPUTERNAME
DOMINIO: $env:USERDOMAIN
DIRECTORIO ACTUAL: $(Get-Location)
FECHA/HORA: $(Get-Date)

--- PROCESOS ACTIVOS ---
$((Get-Process | Where-Object {$_.MainWindowTitle -ne ""} | Select-Object Name, Id, CPU, WorkingSet | Format-Table -AutoSize | Out-String).Trim())

--- VENTANAS ABIERTAS ---
$((Get-Process | Where-Object {$_.MainWindowTitle -ne ""} | Select-Object MainWindowTitle | Format-Table -AutoSize | Out-String).Trim())

--- INFORMACIÓN DE MEMORIA ---
Memoria del proceso actual: $([System.Math]::Round((Get-Process -Id $PID).WorkingSet / 1MB, 2)) MB
Memoria total utilizada: $([System.Math]::Round((Get-Process | Measure-Object WorkingSet -Sum).Sum / 1MB, 2)) MB

--- VARIABLES DE ENTORNO RELEVANTES ---
Path: $env:PATH
Temp: $env:TEMP
UserProfile: $env:USERPROFILE

--- EJECUCIÓN ACTUAL ---
Script en ejecución: $($MyInvocation.MyCommand.Path)
Línea de comando: $($MyInvocation.Line)

=== FIN SCREENSHOT LOG ===
"@
    
    try {
        $systemInfo | Out-File -FilePath $screenshotFile -Encoding UTF8
        Write-Host "📸 Screenshot log creado: $screenshotFile" -ForegroundColor Yellow
        return $screenshotFile
    }
    catch {
        Write-Host "❌ Error creando screenshot log: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Take_ErrorScreenshot {
    param(
        [string]$ErrorMessage,
        [string]$StackTrac3,
        [string]$Step
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $errorFile = "C:\logs\catalogador\errors\error_$($Step)_$timestamp.txt"
    
    # Crear directorio de errores si no existe
    $errorDir = Split-Path $errorFile -Parent
    if (!(Test-Path $errorDir)) {
        New-Item -ItemType Directory -Path $errorDir -Force | Out-Null
    }
    
    $errorInfo = @"
=== ERROR SCREENSHOT - $Step - $timestamp ===
MENSAJE DE ERROR: $ErrorMessage
STEP: $Step
TIMESTAMP: $(Get-Date)

--- STACK TRACE ---
$StackTrace

--- ESTADO DEL SISTEMA ---
Usuario: $env:USERNAME
Equipo: $env:COMPUTERNAME
Directorio: $(Get-Location)

--- VARIABLES DE POWERSHELL ---
ErrorActionPreference: $ErrorActionPreference
LastExitCode: $LASTEXITCODE

=== FIN ERROR SCREENSHOT ===
"@
    
    try {
        $errorInfo | Out-File -FilePath $errorFile -Encoding UTF8
        Write-Host "📄 Log de error creado: $errorFile" -ForegroundColor Red
        return $errorFile
    }
    catch {
        Write-Host "❌ Error creando log de error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Export-ModuleMember -Function Take-Screenshot, Take-ErrorScreenshot