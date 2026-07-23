# status_tracker.ps1 - STATUS TRACKING SYSTEM

function New-StatusTracker {
    param([string]$ProcessId, [string]$StatusPath = "C:\logs\catalogador\status\")
    if (!(Test-Path $StatusPath)) { New-Item -ItemType Directory -Path $StatusPath -Force | Out-Null }
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
            try { $statusUpdate | ConvertTo-Json | Out-File $statusFile -Encoding UTF8 -Force; return $true }
            catch { return $false }
        }
        GetStatus = {
            try { if (Test-Path $statusFile) { return Get-Content $statusFile -Raw | ConvertFrom-Json }; return $null }
            catch { return $null }
        }
        GetStatusHistory = {
            $history = @()
            $statusFiles = Get-ChildItem $StatusPath -Filter "*.status" | Sort-Object LastWriteTime
            foreach ($file in $statusFiles) {
                try { $history += Get-Content $file.FullName -Raw | ConvertFrom-Json } catch {}
            }
            return $history
        }
        CleanupOldStatus = {
            param([int]$DaysToKeep = 7)
            $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)
            $oldFiles = Get-ChildItem $StatusPath -Filter "*.status" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
            $deletedCount = 0
            foreach ($file in $oldFiles) { try { Remove-Item $file.FullName -Force; $deletedCount++ } catch {} }
            Write-Host "🧹 Cleaned up: $deletedCount old status files" -ForegroundColor Green
            return $deletedCount
        }
    }
}

function Get-GlobalStatus {
    param([string]$StatusPath = "C:\logs\catalogador\status\")
    if (!(Test-Path $StatusPath)) { return @{ ActiveProcesses = 0; RecentStatus = @() } }
    $statusFiles = Get-ChildItem $StatusPath -Filter "*.status" | Sort-Object LastWriteTime -Descending
    $activeProcesses = 0; $recentStatus = @()
    foreach ($file in $statusFiles | Select-Object -First 10) {
        try {
            $status = Get-Content $file.FullName -Raw | ConvertFrom-Json
            $recentStatus += $status
            if ($status.Status -notin @("COMPLETED", "FAILED")) { $activeProcesses++ }
        } catch {}
    }
    return @{ ActiveProcesses = $activeProcesses; RecentStatus = $recentStatus; TotalTracked = $statusFiles.Count }
}

Export-ModuleMember -Function New-StatusTracker, Get-GlobalStatus