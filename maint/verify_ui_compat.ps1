$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$failed = @()

function Fail($msg) { $script:failed += $msg; Write-Host "FAIL: $msg" -ForegroundColor Red }
function Pass($msg) { Write-Host "OK: $msg" -ForegroundColor Green }

$alleralUi = Get-Content (Join-Path $root "hub/alleral_ui.luau") -Raw
$coreUi = Get-Content (Join-Path $root "hub/core_ui.luau") -Raw
$library = Get-Content (Join-Path $root "hub/ui/Library.luau") -Raw

if ($coreUi -match 'function Core\.resolveUiWindow') {
    Pass "core_ui exposes resolveUiWindow"
} else {
    Fail "core_ui missing Core.resolveUiWindow"
}

if ($coreUi -match 'function Core\.buildUiSection[\s\S]*?_rawWindow = window\._rawWindow') {
    Pass "buildUiSection forwards _rawWindow"
} else {
    Fail "buildUiSection must expose _rawWindow for tab boot"
}

if ($alleralUi -match 'Alleral UI layer') {
    Pass "alleral_ui declares UI layer marker"
} else {
    Fail "alleral_ui missing Alleral UI layer marker"
}

if ($alleralUi -match 'function Core\.buildUiWindow') {
    Pass "alleral_ui overrides buildUiWindow"
} else {
    Fail "alleral_ui missing buildUiWindow override"
}

if ($alleralUi -match 'function Core\.createWindUiGroupbox') {
    Pass "alleral_ui exposes createWindUiGroupbox adapter"
} else {
    Fail "alleral_ui missing createWindUiGroupbox adapter"
}

if ($coreUi -match 'function Core\.createStubUiGroup[\s\S]*?stub\.CreateDivider\s*=') {
    Pass "createStubUiGroup exposes CreateDivider"
} else {
    Fail "createStubUiGroup missing CreateDivider noop"
}

if ($coreUi -match 'function group:CreateDivider\(\)[\s\S]*?groupbox\.CreateDivider') {
    Pass "wrapUiGroup guards CreateDivider"
} else {
    Fail "wrapUiGroup must guard groupbox CreateDivider"
}

if ($library -match 'LibRef') {
    Pass "hub/ui/Library.luau defines LibRef"
} else {
    Fail "hub/ui/Library.luau missing LibRef marker"
}

if ($library -match 'EnsureGuiRoot') {
    Pass "hub/ui/Library.luau exposes EnsureGuiRoot"
} else {
    Fail "hub/ui/Library.luau missing EnsureGuiRoot"
}

if ($library -match 'ALLERAL_UI_VERSION') {
    Pass "hub/ui/Library.luau version pinned"
} else {
    Fail "hub/ui/Library.luau missing ALLERAL_UI_VERSION"
}

if ($library -match 'CreateWindow') {
    Pass "hub/ui/Library.luau exposes CreateWindow"
} else {
    Fail "hub/ui/Library.luau missing CreateWindow"
}

if ($alleralUi -match 'invalid Alleral library:') {
    Pass "alleral_ui validates library factory output"
} else {
    Fail "alleral_ui must validate Alleral library load"
}

$uiModules = @(
    "Maid.luau", "Spring.luau", "Utils.luau", "Icons.luau", "Theme.luau",
    "Motion.luau", "Config.luau", "Tooltip.luau", "Notification.luau", "Modal.luau",
    "CommandPalette.luau", "Components.luau", "Section.luau", "Page.luau",
    "Navigation.luau", "Window.luau", "Library.luau", "ModuleLoader.luau", "Vendor.luau"
)
$missing = @()
foreach ($name in $uiModules) {
    if (-not (Test-Path (Join-Path $root "hub/ui/$name"))) {
        $missing += $name
    }
}
if ($missing.Count -eq 0) {
    Pass "hub/ui ships all $($uiModules.Count) load modules"
} else {
    Fail "hub/ui missing modules: $($missing -join ', ')"
}

if ($alleralUi -match 'SectionFactory and SectionFactory\(fullDeps\)') {
    Pass "alleral_ui instantiates Section/Page/Navigation factories"
} else {
    Fail "alleral_ui must call Section/Page/Navigation factories with deps"
}

if ($alleralUi -match 'Alleral UI modules incomplete') {
    Pass "alleral_ui validates complete module graph"
} else {
    Fail "alleral_ui missing incomplete-module guard"
}

if ($alleralUi -match 'type\(result\) ~= "function"' -and $alleralUi -match 'LIBRARY_FILE') {
    Pass "alleral_ui accepts Library factory function"
} else {
    Fail "alleral_ui must accept Library.luau factory return type"
}

$continueHits = Select-String -Path (Join-Path $root "hub/ui/*.luau") -Pattern '\bcontinue\b' -ErrorAction SilentlyContinue
if (-not $continueHits) {
    Pass "hub/ui avoids continue keyword"
} else {
    Fail "hub/ui uses continue (executor compat risk)"
}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "UI compatibility checks failed ($($failed.Count))." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All UI compatibility checks passed." -ForegroundColor Green
exit 0
