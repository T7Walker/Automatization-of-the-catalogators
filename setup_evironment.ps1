# setup_environment.ps1 - CORREGIDO (sin warnings)

function Initialize-ProjectEnvironment {
    param(
        [string]$BasePath = "C:\Automatizacion_catalogador_pruebas\logs"
    )
    
    Write-Host "🏗️ INICIANDO CONFIGURACIÓN DEL PROYECTO BMM..." -ForegroundColor Cyan
    Write-Host "Ruta base: $BasePath" -ForegroundColor Yellow
    
    # DEFINIR TODOS LOS DIRECTORIOS NECESARIOS
    $directories = @(
        # 🐍 ESTRUCTURA PYTHON
        "$BasePath\Python",
        "$BasePath\Python\modelos",
        "$BasePath\Python\datos",
        "$BasePath\Python\utilidades",
        
        # 🔧 ESTRUCTURA POWERSHELL  
        "$BasePath\PowerShell",
        "$BasePath\PowerShell\modules",
        "$BasePath\PowerShell\scripts",
        
        # 📊 ESTRUCTURA LOGS COMPLETA
        "$BasePath\Logs",
        "$BasePath\Logs\execution",
        "$BasePath\Logs\errors", 
        "$BasePath\Logs\screenshots",
        "$BasePath\Logs\audit",
        "$BasePath\Logs\reports",
        "$BasePath\Logs\performance",
        "$BasePath\Logs\ia_analysis",
        
        # 💾 ESTRUCTURA BACKUPS
        "$BasePath\Backups",
        "$BasePath\Backups\daily",
        "$BasePath\Backups\weekly",
        "$BasePath\Backups\monthly",
        "$BasePath\Backups\emergency",
        
        # 🗑️ ESTRUCTURA TEMPORAL
        "$BasePath\Temp",
        "$BasePath\Temp\uploads",
        "$BasePath\Temp\downloads",
        "$BasePath\Temp\processing",
        "$BasePath\Temp\cache",
        
        # 🔄 ESTRUCTURA CACHE
        "$BasePath\Cache",
        "$BasePath\Cache\azure_data",
        "$BasePath\Cache\ia_models",
        "$BasePath\Cache\file_analysis",
        "$BasePath\Cache\powerautomate",
        
        # 📁 ESTRUCTURA CONFIGURACIÓN
        "$BasePath\Config",
        "$BasePath\Config\environments",
        "$BasePath\Config\secrets"
    )
    
    # CREAR DIRECTORIOS
    $createdCount = 0
    $existingCount = 0
    $errorCount = 0
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            try {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-Host "✅ CREADO: $dir" -ForegroundColor Green
                $createdCount++
            }
            catch {
                Write-Host "❌ ERROR creando $dir : $($_.Exception.Message)" -ForegroundColor Red
                $errorCount++
            }
        } else {
            Write-Host "📁 EXISTE: $dir" -ForegroundColor Blue
            $existingCount++
        }
    }
    
    # CREAR ARCHIVOS DE CONFIGURACIÓN INICIALES
    Write-Host "`n📝 CREANDO ARCHIVOS DE CONFIGURACIÓN BMM..." -ForegroundColor Cyan
    
    $configFiles = @(
        @{
            Path = "$BasePath\Config\environment.json"
            Content = @"
{
    "empresa": "Banco Mundo Mujer (BMM)",
    "proyecto": "CatalogadorAutomatico",
    "version": "1.0.0",
    "ambiente": "desarrollo",
    "ruta_base": "$BasePath",
    "fecha_creacion": "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
"@
        },
        @{
            Path = "$BasePath\Config\rutas.json"
            Content = @"
{
    "scripts_python": "$BasePath\\Python",
    "scripts_powershell": "$BasePath\\PowerShell", 
    "directorio_logs": "$BasePath\\Logs",
    "directorio_backups": "$BasePath\\Backups",
    "directorio_temporal": "$BasePath\\Temp",
    "directorio_cache": "$BasePath\\Cache"
}
"@
        },
        @{
            Path = "$BasePath\Config\config_logs.json"
            Content = @"
{
    "niveles_log": {
        "DEBUG": 10,
        "INFO": 20,
        "ADVERTENCIA": 30,
        "ERROR": 40,
        "CRITICO": 50
    },
    "retencion_dias": 30,
    "tamaño_maximo_mb": 100,
    "habilitar_auditoria": true,
    "habilitar_rendimiento": true
}
"@
        }
    )
    
    foreach ($file in $configFiles) {
        try {
            # Asegurar que el directorio existe
            $dir = Split-Path $file.Path -Parent
            if (!(Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            
            $file.Content | Out-File -FilePath $file.Path -Encoding UTF8 -Force
            Write-Host "   ✅ Config: $(Split-Path $file.Path -Leaf)" -ForegroundColor Green
        }
        catch {
            Write-Host "   ❌ Error creando $(Split-Path $file.Path -Leaf): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # CREAR ARCHIVOS DE LOG INICIALES
    Write-Host "`n📊 INICIALIZANDO ARCHIVOS DE LOG BMM..." -ForegroundColor Cyan
    
    $logFiles = @(
        "$BasePath\Logs\execution\execution.log",
        "$BasePath\Logs\errors\errors.log", 
        "$BasePath\Logs\audit\audit.log",
        "$BasePath\Logs\performance\performance.log",
        "$BasePath\Logs\ia_analysis\ia_analysis.log"
    )
    
    foreach ($logFile in $logFiles) {
        try {
            # Asegurar que el directorio existe
            $dir = Split-Path $logFile -Parent
            if (!(Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            
            $logEntry = @"
=== LOG INICIALIZADO - BANCO MUNDO MUJER ===
Proyecto: Catalogador Automatico BMM
Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Ubicación: $logFile
=== INICIO LOG ===

"@
            $logEntry | Out-File -FilePath $logFile -Encoding UTF8 -Force
            Write-Host "   ✅ Log: $(Split-Path $logFile -Leaf)" -ForegroundColor Green
        }
        catch {
            Write-Host "   ❌ Error creando log $(Split-Path $logFile -Leaf): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # MOSTRAR RESUMEN
    Write-Host "`n📊 RESUMEN DE CONFIGURACIÓN BMM:" -ForegroundColor Cyan
    Write-Host "   Directorios creados: $createdCount" -ForegroundColor Green
    Write-Host "   Directorios existentes: $existingCount" -ForegroundColor Blue
    Write-Host "   Errores: $errorCount" -ForegroundColor $(if($errorCount -eq 0){"Green"}else{"Red"})
    Write-Host "   Total directorios: $(($createdCount + $existingCount))" -ForegroundColor White
    
    if ($errorCount -eq 0) {
        Write-Host "`n🎯 CONFIGURACIÓN BMM COMPLETADA EXITOSAMENTE!" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  CONFIGURACIÓN COMPLETADA CON ERRORES" -ForegroundColor Yellow
    }
}

function Test-EnvironmentAccess {
    param([string]$BasePath = "C:\Automatizacion_catalogador_pruebas\logs")
    
    Write-Host "`n🔍 VERIFICANDO ACCESO AL ENTORNO BMM..." -ForegroundColor Cyan
    
    $testPaths = @(
        "$BasePath\Python",
        "$BasePath\PowerShell", 
        "$BasePath\Logs",
        "$BasePath\Backups",
        "$BasePath\Temp",
        "$BasePath\Cache"
    )
    
    $accessResults = @()
    
    foreach ($path in $testPaths) {
        $canRead = $false
        $canWrite = $false
        
        # Probar lectura
        try {
            Get-ChildItem $path -ErrorAction Stop | Out-Null
            $canRead = $true
        } catch { $canRead = $false }
        
        # Probar escritura
        try {
            $testFile = Join-Path $path "test_access_$(Get-Date -Format 'yyyyMMddHHmmss').txt"
            "test" | Out-File -FilePath $testFile -ErrorAction Stop
            Remove-Item $testFile -Force -ErrorAction Stop
            $canWrite = $true
        } catch { $canWrite = $false }
        
        $accessResults += [PSCustomObject]@{
            Ruta = $path
            Lectura = $canRead
            Escritura = $canWrite
            Estado = if ($canRead -and $canWrite) {"✅ OK"} elseif ($canRead) {"⚠️ SOLO LECTURA"} else {"❌ SIN ACCESO"}
        }
    }
    
    # Mostrar resultados
    $accessResults | Format-Table -AutoSize
    
    $totalOK = ($accessResults | Where-Object { $_.Estado -eq "✅ OK" }).Count
    $totalSoloLectura = ($accessResults | Where-Object { $_.Estado -eq "⚠️ SOLO LECTURA" }).Count
    $totalSinAcceso = ($accessResults | Where-Object { $_.Estado -eq "❌ SIN ACCESO" }).Count
    
    Write-Host "`n📊 RESUMEN DE ACCESO BMM:" -ForegroundColor Cyan
    Write-Host "   ✅ Acceso completo: $totalOK" -ForegroundColor Green
    Write-Host "   ⚠️  Solo lectura: $totalSoloLectura" -ForegroundColor Yellow  
    Write-Host "   ❌ Sin acceso: $totalSinAcceso" -ForegroundColor Red
    
    return ($totalSinAcceso -eq 0)
}

function Get-EnvironmentStatus {
    param([string]$BasePath = "C:\Automatizacion_catalogador_pruebas\logs")
    
    Write-Host "`n📈 ESTADO DEL ENTORNO BMM:" -ForegroundColor Cyan
    
    $paths = @(
        @{Nombre = "Python"; Ruta = "$BasePath\Python"},
        @{Nombre = "PowerShell"; Ruta = "$BasePath\PowerShell"},
        @{Nombre = "Logs"; Ruta = "$BasePath\Logs"},
        @{Nombre = "Backups"; Ruta = "$BasePath\Backups"},
        @{Nombre = "Temp"; Ruta = "$BasePath\Temp"},
        @{Nombre = "Cache"; Ruta = "$BasePath\Cache"}
    )
    
    foreach ($item in $paths) {
        if (Test-Path $item.Ruta) {
            $tamaño = Get-FolderSize -Path $item.Ruta
            $cantidadArchivos = (Get-ChildItem $item.Ruta -Recurse -File -ErrorAction SilentlyContinue).Count
            Write-Host "   📁 $($item.Nombre): $tamaño | $cantidadArchivos archivos" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $($item.Nombre): NO EXISTE" -ForegroundColor Red
        }
    }
    
    # Espacio en disco
    $infoDisco = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $espacioLibreGB = [math]::Round($infoDisco.FreeSpace / 1GB, 2)
    $espacioTotalGB = [math]::Round($infoDisco.Size / 1GB, 2)
    
    Write-Host "`n💾 ESPACIO EN DISCO (C:):" -ForegroundColor Cyan
    Write-Host "   Libre: $espacioLibreGB GB / $espacioTotalGB GB" -ForegroundColor $(if($espacioLibreGB -gt 10){"Green"}else{"Yellow"})
}

function Get-FolderSize {
    param([string]$Path)
    
    if (!(Test-Path $Path)) { return "0 MB" }
    
    try {
        $tamaño = (Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum
        
        # ✅ CORREGIDO: $null a la izquierda
        if ($null -eq $tamaño) { return "0 MB" }
        
        if ($tamaño -gt 1GB) {
            return "$([math]::Round($tamaño/1GB, 2)) GB"
        } elseif ($tamaño -gt 1MB) {
            return "$([math]::Round($tamaño/1MB, 2)) MB"
        } else {
            return "$([math]::Round($tamaño/1KB, 2)) KB"
        }
    }
    catch {
        return "Error"
    }
}

# EJECUTAR CONFIGURACIÓN SI SE LLAMA DIRECTAMENTE
if ($MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq '') {
    Write-Host "🚀 CONFIGURADOR DE ENTORNO - BANCO MUNDO MUJER (BMM)" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
    
    # 1. Crear estructura
    Initialize-ProjectEnvironment
    
    # 2. Verificar acceso
    $accessOK = Test-EnvironmentAccess
    
    # 3. Mostrar estado
    Get-EnvironmentStatus
    
    if ($accessOK) {
        Write-Host "`n🎯 ENTORNO BMM LISTO PARA USAR!" -ForegroundColor Green
        Write-Host "   Puedes comenzar a copiar los scripts Python y PowerShell" -ForegroundColor Yellow
    } else {
        Write-Host "`n⚠️  REVISAR PERMISOS DE ACCESO" -ForegroundColor Red
    }
}