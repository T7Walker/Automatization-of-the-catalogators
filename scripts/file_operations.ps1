# file_operations.ps1 - FILE OPERATIONS WITH LOGGING

function Write-OperationLog {
    param(
        [string]$Operation,
        [string]$Details,
        [string]$Status,
        [string]$LogPath = "C:\logs\catalogador\operations.log"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Status] $Operation - $Details"
    $logDir = Split-Path $LogPath -Parent
    if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    try {
        Add-Content -Path $LogPath -Value $logEntry
        switch ($Status) {
            "COMPLETED" { Write-Host $logEntry -ForegroundColor Green }
            "FAILED" { Write-Host $logEntry -ForegroundColor Red }
            "STARTED" { Write-Host $logEntry -ForegroundColor Cyan }
            default { Write-Host $logEntry -ForegroundColor White }
        }
        return $true
    }
    catch { return $false }
}

function Copy-DevToTest {
    param([string]$Source, [string]$Destination, [string]$LogPath = "C:\logs\catalogador\operations.log")
    Write-OperationLog -Operation "Copy-DevToTest" -Details "Starting copy: $Source -> $Destination" -Status "STARTED"
    try {
        if (!(Test-Path $Source)) {
            Write-OperationLog -Operation "Copy-DevToTest" -Details "Source not found: $Source" -Status "FAILED"
            return $false
        }
        $destDir = Split-Path $Destination -Parent
        if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Copy-Item -Path $Source -Destination $Destination -Recurse -Force
        if (Test-Path $Destination) {
            $fileCount = (Get-ChildItem $Destination -Recurse | Where-Object { !$_.PSIsContainer }).Count
            Write-OperationLog -Operation "Copy-DevToTest" -Details "Copy successful. Files: $fileCount" -Status "COMPLETED"
            return $true
        } else {
            Write-OperationLog -Operation "Copy-DevToTest" -Details "Copy failed - destination not found" -Status "FAILED"
            return $false
        }
    }
    catch {
        Write-OperationLog -Operation "Copy-DevToTest" -Details "Error: $($_.Exception.Message)" -Status "FAILED"
        return $false
    }
}

function Validate-FileStructure {
    param([string]$Path, [string[]]$ExpectedFiles)
    Write-OperationLog -Operation "Validate-FileStructure" -Details "Validating: $Path" -Status "STARTED"
    try {
        $missingFiles = @(); $existingFiles = @()
        foreach ($file in $ExpectedFiles) {
            $fullPath = Join-Path $Path $file
            if (Test-Path $fullPath) { $existingFiles += $file }
            else { $missingFiles += $file }
        }
        if ($missingFiles.Count -eq 0) {
            Write-OperationLog -Operation "Validate-FileStructure" -Details "All files present: $($existingFiles.Count)" -Status "COMPLETED"
            return $true, $existingFiles
        } else {
            Write-OperationLog -Operation "Validate-FileStructure" -Details "Missing: $($missingFiles -join ', ')" -Status "FAILED"
            return $false, $missingFiles
        }
    }
    catch { return $false, @() }
}

function Create-Backup {
    param([string]$SourcePath, [string]$BackupRoot = "C:\backups\catalogador\")
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = "$BackupRoot\$timestamp"
    Write-OperationLog -Operation "Create-Backup" -Details "Creating backup: $SourcePath -> $backupDir" -Status "STARTED"
    try {
        if (!(Test-Path $BackupRoot)) { New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null }
        Copy-Item -Path $SourcePath -Destination $backupDir -Recurse -Force
        if (Test-Path $backupDir) {
            $backupSize = (Get-ChildItem $backupDir -Recurse | Measure-Object -Property Length -Sum).Sum
            Write-OperationLog -Operation "Create-Backup" -Details "Backup created: $backupDir ($([math]::Round($backupSize/1MB, 2)) MB)" -Status "COMPLETED"
            return $backupDir
        } else { return $null }
    }
    catch { return $null }
}

Export-ModuleMember -Function Write-OperationLog, Copy-DevToTest, Validate-FileStructure, Create-Backup