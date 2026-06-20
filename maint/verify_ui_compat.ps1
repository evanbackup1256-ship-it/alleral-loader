$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$failures = 0

function Pass($msg) { Write-Host "OK: $msg" -ForegroundColor Green }
function Fail($msg) { Write-Host "FAIL: $msg" -ForegroundColor Red; $script:failures++ }

$alleralUi = Get-Content (Join-Path $root "hub/alleral_ui.luau") -Raw
if ($alleralUi -match 'Core\.loadUi') { Pass "alleral_ui defines loadUi" } else { Fail "alleral_ui missing loadUi" }
if ($alleralUi -match 'Core\.createUiGroupbox') { Pass "alleral_ui defines createUiGroupbox" } else { Fail "alleral_ui missing createUiGroupbox" }
if ($alleralUi -match 'Core\.UI_LIBRARY\s*=\s*"Linoria"') { Pass "alleral_ui declares Linoria as active UI library" } else { Fail "alleral_ui missing Linoria UI_LIBRARY" }
if ($alleralUi -match 'function Core\.buildUiWindow') { Pass "alleral_ui defines buildUiWindow" } else { Fail "alleral_ui missing buildUiWindow" }
if ($alleralUi -match 'function Core\.buildUiTab') { Pass "alleral_ui defines buildUiTab" } else { Fail "alleral_ui missing buildUiTab" }
if ($alleralUi -match 'function Core\.buildUiGroup') { Pass "alleral_ui defines buildUiGroup" } else { Fail "alleral_ui missing buildUiGroup" }
if ($alleralUi -match 'Core\.wrapUiGroup\s*=') { Pass "alleral_ui defines wrapUiGroup" } else { Fail "alleral_ui missing wrapUiGroup" }
if ($alleralUi -match 'function Core\.buildUiSection') { Pass "alleral_ui defines buildUiSection" } else { Fail "alleral_ui missing buildUiSection" }
$unclosedInlineFunctions = Select-String -Path (Join-Path $root "hub/alleral_ui.luau") -Pattern 'function .*return ' | Where-Object { $_.Line -notmatch '\bend\s*$' }
if ($unclosedInlineFunctions) {
    foreach ($match in $unclosedInlineFunctions) {
        Fail "alleral_ui inline function missing end at line $($match.LineNumber)"
    }
} else {
    Pass "alleral_ui inline return functions close with end"
}

# Linoria boot validation
if ($alleralUi -match 'loadLinoriaSource') { Pass "alleral_ui has Linoria boot function" } else { Fail "alleral_ui missing Linoria boot" }
if ($alleralUi -match 'violin-suzutsuki/LinoriaLib') { Pass "alleral_ui fetches Linoria from GitHub" } else { Fail "alleral_ui missing Linoria CDN URL" }

$loader = Get-Content (Join-Path $root "loader.luau") -Raw
if ($loader -notmatch '[Rr]ayfield') { Pass "loader has no Rayfield references" } else { Fail "loader still contains Rayfield references" }
if ($loader -match 'Linoria') { Pass "loader references Linoria" } else { Fail "loader missing Linoria reference" }

$release = Get-Content (Join-Path $root "cfg/release.json") -Raw | ConvertFrom-Json
if ($release.ui -eq "Linoria") { Pass "release.json ui is Linoria" } else { Fail "release.json ui is not Linoria" }

if ($failures -gt 0) {
    Write-Host "`n$failures UI compatibility check(s) failed." -ForegroundColor Red
    exit 1
}

Write-Host "`nAll UI compatibility checks passed." -ForegroundColor Green
