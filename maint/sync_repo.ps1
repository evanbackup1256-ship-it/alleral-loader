$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

& (Join-Path $PSScriptRoot "bump_release.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& (Join-Path $PSScriptRoot "verify_versions.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& (Join-Path $PSScriptRoot "verify_ui_compat.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$status = git status --porcelain
if ($status) {
    git add -A
    git commit -m "chore: sync release commit and site build"
    git push origin main
    Write-Host "Pushed to origin/main"
} else {
    Write-Host "Repo clean — nothing to push"
}