$Repo = "C:\Users\evanm\OneDrive\Desktop\kick"
$Branch = "main"
$CooldownSeconds = 5

Set-Location $Repo

git config credential.helper manager
git config pull.rebase true

$script:LastRun = Get-Date "2000-01-01"

function Sync-GitHub {
    $now = Get-Date

    if (($now - $script:LastRun).TotalSeconds -lt $CooldownSeconds) {
        return
    }

    $script:LastRun = $now

    Start-Sleep -Seconds 2

    $changes = git status --porcelain
    if (-not $changes) {
        return
    }

    git add -A

    $commitMessage = "Auto sync: 2026-06-08 12:41:57"
    git commit -m "$commitMessage"

    git pull --rebase origin $Branch

    if ($LASTEXITCODE -ne 0) {
        git rebase --abort 2>$null
        return
    }

    git push origin $Branch
}

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $Repo
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.Filter = "*.*"

$action = {
    $path = $Event.SourceEventArgs.FullPath

    if ($path -match "\\\.git\\") { return }
    if ($path -match "\\node_modules\\") { return }
    if ($path -match "\\__pycache__\\") { return }

    Sync-GitHub
}

Register-ObjectEvent $watcher Changed -Action $action | Out-Null
Register-ObjectEvent $watcher Created -Action $action | Out-Null
Register-ObjectEvent $watcher Deleted -Action $action | Out-Null
Register-ObjectEvent $watcher Renamed -Action $action | Out-Null

Sync-GitHub

while ($true) {
    Start-Sleep -Seconds 1
}
