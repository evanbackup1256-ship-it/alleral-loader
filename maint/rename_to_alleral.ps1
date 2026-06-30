# Close Cursor/terminals using this folder, then run:
#   pwsh -File maint\rename_to_alleral.ps1
$ErrorActionPreference = "Stop"
$desktop = [Environment]::GetFolderPath("Desktop")
$kick = Join-Path $desktop "kick"
$alleral = Join-Path $desktop "Alleral"

if (-not (Test-Path $kick)) {
    if (Test-Path $alleral) {
        Write-Host "Already renamed: $alleral"
        exit 0
    }
    throw "Neither kick nor Alleral found on Desktop"
}

if (Test-Path $alleral) {
    Write-Host "Removing old Alleral folder..."
    cmd /c "rmdir /s /q `"$alleral`"" | Out-Null
    if (Test-Path $alleral) {
        Remove-Item -LiteralPath $alleral -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Renaming kick -> Alleral..."
Rename-Item -LiteralPath $kick -NewName "Alleral"
Write-Host "Done. Reopen workspace: $alleral"