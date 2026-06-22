$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$failures = 0

function Pass($msg) { Write-Host "OK: $msg" -ForegroundColor Green }
function Fail($msg) { Write-Host "FAIL: $msg" -ForegroundColor Red; $script:failures++ }

$release = Get-Content (Join-Path $root "cfg/release.json") -Raw | ConvertFrom-Json
$uiVersion = if ($release.uiVersion) { $release.uiVersion } else { "11.5.3" }

$alleralUi = Get-Content (Join-Path $root "hub/alleral_ui.luau") -Raw
if ($alleralUi -match 'Core\.loadUi') { Pass "alleral_ui defines loadUi" } else { Fail "alleral_ui missing loadUi" }
if ($alleralUi -match 'Core\.createUiGroupbox') { Pass "alleral_ui defines createUiGroupbox" } else { Fail "alleral_ui missing createUiGroupbox" }
if ($alleralUi -match 'Core\.UI_LIBRARY\s*=\s*"WindUI"') { Pass "alleral_ui declares WindUI as active UI library" } else { Fail "alleral_ui missing WindUI UI_LIBRARY" }
if ($alleralUi -match 'function Core\.buildUiWindow') { Pass "alleral_ui defines buildUiWindow" } else { Fail "alleral_ui missing buildUiWindow" }
if ($alleralUi -match 'function Core\.buildUiTab') { Pass "alleral_ui defines buildUiTab" } else { Fail "alleral_ui missing buildUiTab" }
if ($alleralUi -match 'function Core\.buildUiGroup') { Pass "alleral_ui defines buildUiGroup" } else { Fail "alleral_ui missing buildUiGroup" }
if ($alleralUi -match '(function\s+Core\.wrapUiGroup|Core\.wrapUiGroup\s*=)') { Pass "alleral_ui defines wrapUiGroup" } else { Fail "alleral_ui missing wrapUiGroup" }
if ($alleralUi -match 'function Core\.buildUiSection') { Pass "alleral_ui defines buildUiSection" } else { Fail "alleral_ui missing buildUiSection" }
$unclosedInlineFunctions = Select-String -Path (Join-Path $root "hub/alleral_ui.luau") -Pattern 'function .*return ' | Where-Object { $_.Line -notmatch '\bend\s*$' }
if ($unclosedInlineFunctions) {
    foreach ($match in $unclosedInlineFunctions) {
        Fail "alleral_ui inline function missing end at line $($match.LineNumber)"
    }
} else {
    Pass "alleral_ui inline return functions close with end"
}

if ($alleralUi -match 'ALLERAL_UI_VERSION = "' + [regex]::Escape($uiVersion) + '"') {
    Pass "alleral_ui version $uiVersion"
} else {
    Fail "alleral_ui ALLERAL_UI_VERSION != release uiVersion ($uiVersion)"
}

$bootstrapUi = Get-Content (Join-Path $root "hub/ui/windui/Bootstrap.luau") -Raw
if ($bootstrapUi -match 'Bootstrap\.VERSION = "' + [regex]::Escape($uiVersion) + '"') {
    Pass "windui Bootstrap.VERSION $uiVersion"
} else {
    Fail "hub/ui/windui/Bootstrap.luau VERSION != release uiVersion ($uiVersion)"
}

$controlsUi = Get-Content (Join-Path $root "hub/ui/windui/Controls.luau") -Raw
if ($controlsUi -match 'attachRipple') { Pass "windui Controls has ripple press" } else { Fail "windui Controls missing ripple" }

$motionUi = Get-Content (Join-Path $root "hub/ui/windui/Motion.luau") -Raw
if ($motionUi -match 'animateWindowShow') { Pass "windui Motion has window animations" } else { Fail "windui Motion missing animateWindowShow" }
if ($motionUi -match 'logPerformance') { Pass "windui Motion exposes logPerformance" } else { Fail "windui Motion missing logPerformance" }

$initUi = Get-Content (Join-Path $root "hub/ui/windui/Init.luau") -Raw
if ($initUi -match 'loadModule\("Motion"\)') { Pass "windui Init wires Motion module" } else { Fail "windui Init missing Motion" }
if ($initUi -match 'loadModule\("Controls"\)') { Pass "windui Init wires Controls module" } else { Fail "windui Init missing Controls" }

if ($bootstrapUi -match 'Footagesus/WindUI') { Pass "windui Bootstrap fetches WindUI from GitHub" } else { Fail "windui Bootstrap missing WindUI CDN URL" }

$loader = Get-Content (Join-Path $root "loader.luau") -Raw
if ($loader -notmatch '[Rr]ayfield') { Pass "loader has no Rayfield references" } else { Fail "loader still contains Rayfield references" }
if ($loader -match 'WindUI') { Pass "loader references WindUI" } else { Fail "loader missing WindUI reference" }

if ($release.ui -eq "WindUI") { Pass "release.json ui is WindUI" } else { Fail "release.json ui is not WindUI" }

if ($failures -gt 0) {
    Write-Host "`n$failures UI compatibility check(s) failed." -ForegroundColor Red
    exit 1
}

Write-Host "`nAll UI compatibility checks passed." -ForegroundColor Green