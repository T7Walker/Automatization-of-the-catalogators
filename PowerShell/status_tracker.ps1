# status_tracker.ps1 - Sistema de seguimiento de estado
function New-StatusTracker {
    param(
        [string]$ProcessId,
        [string]$StatusPath = "C:\logs\catalogador\status\"
    )
    
    # Crear directorio de status si no existe
    if (!(Test-Path $StatusPath)) {
        New-Item -ItemType Directory -Path $StatusPath -Force | Out-Null
    }
    
    $statusFile = "$StatusPath\$ProcessId.status"
    
    return @{
        UpdateStatus = {
            param($Step, $Status, $Details, $Progress = 0)
            
            $statusUpdate = @{
                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                Step = $Step
                Status = $Status
                Details = $Details
                Progress = $Progress
                ProcessId = $ProcessId
                Machine = $env:COMPUTERNAME
                User = $env:USERNAME
            }
            
            try {
                $statusUpdate | ConvertTo-Json | Out-File $statusFile -Encoding UTF8 -Force
                Write-Host "📝 Status actualizado: $Step - $Status ($Progress%)" -ForegroundColor Blue
                return $true
            }
            catch {
                Write-Host "❌ Error actualizando status: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
        }
        
        GetStatus = {
            try {
                if (Test-Path $statusFile) {
                    $content = Get-Content $statusFile -Raw | ConvertFrom-Json
                    return $content
                }
                return $null
            }
            catch {
                Write-Host "❌ Error leyendo status: $($_.Exception.Message)" -ForegroundColor Red
                return $null
            }
        }
        
        GetStatusHistory = {
            $history = @()
            $statusFiles = Get-ChildItem $StatusPath -Filter "*.status" | Sort-Object LastWriteTime
            
            foreach ($file in $statusFiles) {
                try {
                    $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
                    $history += $content
                }
                catch {
                    # Continuar con el siguiente archivo
                }
            }
            
            return $history
        }
        
        CleanupOldStatus = {
            param([int]$DaysToKeep = 7)
            
            $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)
            $oldFiles = Get-ChildItem $StatusPath -Filter "*.status" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
            
            $deletedCount = 0
            foreach ($file in $oldFiles) {
                try {
                    Remove-Item $file.FullName -Force
                    $deletedCount++
                }
                catch {
                    Write-Host "⚠️ No se pudo eliminar: $($file.Name)" -ForegroundColor Yellow
                }
            }
            
            Write-Host "🧹 Status files limpiados: $deletedCount archivos antiguos removidos" -ForegroundColor Green
            return $deletedCount
        }
    }
}

function Get-GlobalStatus {
    param([string]$StatusPath = "C:\logs\catalogador\status\")
    
    if (!(Test-Path $StatusPath)) {
        return @{ ActiveProcesses = 0; RecentStatus = @() }
    }
    
    $statusFiles = Get-ChildItem $StatusPath -Filter "*.status" | Sort-Object LastWriteTime -Descending
    
    $activeProcesses = 0
    $recentStatus = @()
    
    foreach ($file in $statusFiles | Select-Object -First 10) {
        try {
            $status = Get-Content $file.FullName -Raw | ConvertFrom-Json
            $recentStatus += $status
            
            if ($status.Status -notin @("COMPLETED", "FAILED")) {
                $activeProcesses++
            }
        }
        catch {
            # Continuar con el siguiente archivo
        }
    }
    
    return @{
        ActiveProcesses = $activeProcesses
        RecentStatus = $recentStatus
        TotalTracked = $statusFiles.Count
    }
}

Export-ModuleMember -Function New-StatusTracker, Get-GlobalStatus