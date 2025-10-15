# file_operations.ps1 - Versión con logging completo
function Write-OperationLog {
    param(
        [string]$Operation,
        [string]$Details,
        [string]$Status,
        [string]$LogPath = "C:\logs\catalogador\operations.log"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Status] $Operation - $Details"
    
    # Crear directorio si no existe
    $logDir = Split-Path $LogPath -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    try {
        Add-Content -Path $LogPath -Value $logEntry
        # También escribir en consola con colores según estado
        switch ($Status) {
            "COMPLETED" { Write-Host $logEntry -ForegroundColor Green }
            "FAILED" { Write-Host $logEntry -ForegroundColor Red }
            "STARTED" { Write-Host $logEntry -ForegroundColor Cyan }
            default { Write-Host $logEntry -ForegroundColor White }
        }
        return $true
    }
    catch {
        Write-Host "❌ Error escribiendo log: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Copy-DevToTest {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$LogPath = "C:\logs\catalogador\operations.log"
    )
    
    Write-OperationLog -Operation "Copy-DevToTest" -Details "Iniciando copia: $Source -> $Destination" -Status "STARTED"
    
    try {
        # Verificar si source existe
        if (!(Test-Path $Source)) {
            Write-OperationLog -Operation "Copy-DevToTest" -Details "Source no existe: $Source" -Status "FAILED"
            return $false
        }
        
        # Crear destino si no existe
        $destDir = Split-Path $Destination -Parent
        if (!(Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            Write-OperationLog -Operation "Copy-DevToTest" -Details "Directorio creado: $destDir" -Status "INFO"
        }
        
        # Realizar copia
        Copy-Item -Path $Source -Destination $Destination -Recurse -Force
        
        # Verificar copia
        if (Test-Path $Destination) {
            $fileCount = (Get-ChildItem $Destination -Recurse | Where-Object { !$_.PSIsContainer }).Count
            Write-OperationLog -Operation "Copy-DevToTest" -Details "Copia exitosa. Archivos: $fileCount" -Status "COMPLETED"
            return $true
        } else {
            Write-OperationLog -Operation "Copy-DevToTest" -Details "Copia falló - destino no encontrado" -Status "FAILED"
            return $false
        }
    }
    catch {
        Write-OperationLog -Operation "Copy-DevToTest" -Details "Error: $($_.Exception.Message)" -Status "FAILED"
        return $false
    }
}

function Validate_FileStructure {
    param(
        [string]$Path,
        [string[]]$ExpectedFiles
    )
    
    Write-OperationLog -Operation "Validate-FileStructure" -Details "Validando: $Path" -Status "STARTED"
    
    try {
        $missingFiles = @()
        $existingFiles = @()
        
        foreach ($file in $ExpectedFiles) {
            $fullPath = Join-Path $Path $file
            if (Test-Path $fullPath) {
                $existingFiles += $file
            } else {
                $missingFiles += $file
            }
        }
        
        if ($missingFiles.Count -eq 0) {
            Write-OperationLog -Operation "Validate-FileStructure" -Details "Todos los archivos presentes: $($existingFiles.Count)" -Status "COMPLETED"
            return $true, $existingFiles
        } else {
            Write-OperationLog -Operation "Validate-FileStructure" -Details "Archivos faltantes: $($missingFiles -join ', ')" -Status "FAILED"
            return $false, $missingFiles
        }
    }
    catch {
        Write-OperationLog -Operation "Validate-FileStructure" -Details "Error: $($_.Exception.Message)" -Status "FAILED"
        return $false, @()
    }
}

function Create_Backup {
    param(
        [string]$SourcePath,
        [string]$BackupRoot = "C:\backups\catalogador\"
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = "$BackupRoot\$timestamp"
    
    Write-OperationLog -Operation "Create-Backup" -Details "Creando backup: $SourcePath -> $backupDir" -Status "STARTED"
    
    try {
        if (!(Test-Path $BackupRoot)) {
            New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
        }
        
        Copy-Item -Path $SourcePath -Destination $backupDir -Recurse -Force
        
        if (Test-Path $backupDir) {
            $backupSize = (Get-ChildItem $backupDir -Recurse | Measure-Object -Property Length -Sum).Sum
            Write-OperationLog -Operation "Create-Backup" -Details "Backup creado: $backupDir ($([math]::Round($backupSize/1MB, 2)) MB)" -Status "COMPLETED"
            return $backupDir
        } else {
            Write-OperationLog -Operation "Create-Backup" -Details "Backup falló" -Status "FAILED"
            return $null
        }
    }
    catch {
        Write-OperationLog -Operation "Create-Backup" -Details "Error: $($_.Exception.Message)" -Status "FAILED"
        return $null
    }
}

Export-ModuleMember -Function Write-OperationLog, Copy-DevToTest, Validate-FileStructure, Create-Backup