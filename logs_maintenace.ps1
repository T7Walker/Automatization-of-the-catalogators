# log_maintenance.ps1 - CORREGIDO (sin warnings)

function Start-LogMaintenance {
    param(
        [string]$LogsPath = "C:\Automatizacion_catalogador_pruebas\logs",
        [int]$RetentionDays = 30,
        [int]$MaxLogSizeMB = 100
    )
    
    Write-Host "🧹 INICIANDO MANTENIMIENTO DE LOGS BMM..." -ForegroundColor Cyan
    
    $maintenanceReport = @{
        StartTime = Get-Date
        LogsPath = $LogsPath
        FilesProcessed = 0
        FilesDeleted = 0
        FilesCompressed = 0
        Errors = @()
    }
    
    try {
        # 1. LIMPIAR LOGS ANTIGUOS
        Write-Host "`n📅 Limpiando logs antiguos (> $RetentionDays días)..." -ForegroundColor Yellow
        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        
        $oldLogs = Get-ChildItem $LogsPath -Recurse -File -Include "*.log", "*.txt" | 
                   Where-Object { $_.LastWriteTime -lt $cutoffDate }
        
        foreach ($logFile in $oldLogs) {
            try {
                Remove-Item $logFile.FullName -Force
                Write-Host "   🗑️  Eliminado: $($logFile.Name)" -ForegroundColor Gray
                $maintenanceReport.FilesDeleted++
            }
            catch {
                $maintenanceReport.Errors += "Error eliminando $($logFile.Name): $($_.Exception.Message)"
            }
            $maintenanceReport.FilesProcessed++
        }
        
        # 2. ROTAR LOGS GRANDES
        Write-Host "`n📦 Rotando logs grandes (> $MaxLogSizeMB MB)..." -ForegroundColor Yellow
        $largeLogs = Get-ChildItem $LogsPath -Recurse -File -Include "*.log" | 
                     Where-Object { ($_.Length / 1MB) -gt $MaxLogSizeMB }
        
        foreach ($logFile in $largeLogs) {
            try {
                $backupPath = $logFile.FullName + ".backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                Move-Item $logFile.FullName $backupPath -Force
                
                # Crear nuevo log vacío
                "=== LOG ROTADO EL $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===`n" | Out-File -FilePath $logFile.FullName -Encoding UTF8
                
                Write-Host "   🔄 Rotado: $($logFile.Name) -> $(Split-Path $backupPath -Leaf)" -ForegroundColor Gray
                $maintenanceReport.FilesCompressed++
            }
            catch {
                $maintenanceReport.Errors += "Error rotando $($logFile.Name): $($_.Exception.Message)"
            }
            $maintenanceReport.FilesProcessed++
        }
        
        # 3. CREAR REPORTE DE MANTENIMIENTO
        $maintenanceReport.EndTime = Get-Date
        $maintenanceReport.Duration = $maintenanceReport.EndTime - $maintenanceReport.StartTime
        
        # Guardar reporte
        $reportPath = "$LogsPath\reports\maintenance"
        if (!(Test-Path $reportPath)) {
            New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
        }
        
        $reportFile = "$reportPath\maintenance_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $maintenanceReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportFile -Encoding UTF8
        
        Write-Host "`n✅ MANTENIMIENTO COMPLETADO:" -ForegroundColor Green
        Write-Host "   Archivos procesados: $($maintenanceReport.FilesProcessed)" -ForegroundColor White
        Write-Host "   Archivos eliminados: $($maintenanceReport.FilesDeleted)" -ForegroundColor White
        Write-Host "   Archivos rotados: $($maintenanceReport.FilesCompressed)" -ForegroundColor White
        Write-Host "   Duración: $($maintenanceReport.Duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
        
        if ($maintenanceReport.Errors.Count -gt 0) {
            Write-Host "   Errores: $($maintenanceReport.Errors.Count)" -ForegroundColor Yellow
            foreach ($err0r in $maintenanceReport.Errors) {
                Write-Host "     - $error" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "❌ ERROR EN MANTENIMIENTO: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-LogStatistics {
    param([string]$LogsPath = "C:\Automatizacion_catalogador_pruebas\logs")
    
    Write-Host "📈 ESTADÍSTICAS DE LOGS BMM:" -ForegroundColor Cyan
    
    if (!(Test-Path $LogsPath)) {
        Write-Host "   ❌ Directorio de logs no encontrado" -ForegroundColor Red
        return
    }
    
    $logFiles = Get-ChildItem $LogsPath -Recurse -File -Include "*.log", "*.txt" -ErrorAction SilentlyContinue
    
    if ($logFiles.Count -eq 0) {
        Write-Host "   ℹ️  No se encontraron archivos de log" -ForegroundColor Yellow
        return
    }
    
    $stats = @{
        TotalFiles = $logFiles.Count
        TotalSizeMB = [math]::Round(($logFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
        ByType = @{}
        OldestFile = $null
        NewestFile = $null
    }
    
    foreach ($file in $logFiles) {
        $extension = $file.Extension.ToLower()
        if (!$stats.ByType.ContainsKey($extension)) {
            $stats.ByType[$extension] = @{ Count = 0; SizeMB = 0 }
        }
        $stats.ByType[$extension].Count++
        $stats.ByType[$extension].SizeMB += [math]::Round($file.Length / 1MB, 2)
        
        # ✅ CORREGIDO: $null a la izquierda
        if ($null -eq $stats.OldestFile -or $file.LastWriteTime -lt $stats.OldestFile.LastWriteTime) {
            $stats.OldestFile = $file
        }
        
        # ✅ CORREGIDO: $null a la izquierda
        if ($null -eq $stats.NewestFile -or $file.LastWriteTime -gt $stats.NewestFile.LastWriteTime) {
            $stats.NewestFile = $file
        }
    }
    
    Write-Host "   Archivos totales: $($stats.TotalFiles)" -ForegroundColor White
    Write-Host "   Tamaño total: $($stats.TotalSizeMB) MB" -ForegroundColor White
    
    foreach ($type in $stats.ByType.Keys) {
        Write-Host "   $type : $($stats.ByType[$type].Count) archivos, $($stats.ByType[$type].SizeMB) MB" -ForegroundColor Gray
    }
    
    if ($stats.OldestFile) {
        Write-Host "   Archivo más antiguo: $($stats.OldestFile.Name) ($($stats.OldestFile.LastWriteTime))" -ForegroundColor Gray
    }
    if ($stats.NewestFile) {
        Write-Host "   Archivo más nuevo: $($stats.NewestFile.Name) ($($stats.NewestFile.LastWriteTime))" -ForegroundColor Gray
    }
}

# Ejecutar si se llama directamente
if ($MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq '') {
    Write-Host "🔧 HERRAMIENTAS DE MANTENIMIENTO DE LOGS - BMM" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    # Mostrar estadísticas primero
    Get-LogStatistics
    
    # Preguntar si ejecutar mantenimiento
    $choice = Read-Host "`n¿Ejecutar mantenimiento de logs? (S/N)"
    if ($choice -eq 'S' -or $choice -eq 's') {
        Start-LogMaintenance
    } else {
        Write-Host "Mantenimiento cancelado" -ForegroundColor Yellow
    }
}