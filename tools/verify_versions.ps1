# Verify loader, core, manifest, and game script versions stay in sync.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$failed = @()

function Fail($msg) { $script:failed += $msg; Write-Host "FAIL: $msg" -ForegroundColor Red }
function Pass($msg) { Write-Host "OK: $msg" -ForegroundColor Green }

$release = Get-Content (Join-Path $root "config/release.json") -Raw | ConvertFrom-Json
$manifest = Get-Content (Join-Path $root "config/scripts_manifest.json") -Raw | ConvertFrom-Json
$loader = Get-Content (Join-Path $root "loader.luau") -Raw

if ($loader -match 'LOADER_VERSION = "([^"]+)"') {
    $loaderVer = $Matches[1]
    if ($loaderVer -ne $release.loader) {
        Fail "loader.luau ($loaderVer) != release.json ($($release.loader))"
    } else {
        Pass "loader $loaderVer"
    }
} else {
    Fail "loader.luau missing LOADER_VERSION"
}

$corePath = Join-Path $root "core/alleral_core.luau"
$core = Get-Content $corePath -Raw
if ($core -match 'Core\.VERSION = "([^"]+)"') {
    $coreVer = $Matches[1]
    if ($coreVer -ne $release.core) {
        Fail "core ($coreVer) != release.json ($($release.core))"
    } else {
        Pass "core $coreVer"
    }
} else {
    Fail "core missing Core.VERSION"
}

$gameFiles = @{
    kick_a_lucky_block      = "games/kick_a_lucky_block.luau"
    speed_keyboard_escape   = "games/speed_keyboard_escape.luau"
    slime_rng               = "games/slime_rng.luau"
    build_a_ring_farm       = "games/build_a_ring_farm.luau"
    survive_a_zombie_arena  = "games/survive_a_zombie_arena.luau"
}

foreach ($id in $gameFiles.Keys) {
    $path = Join-Path $root $gameFiles[$id]
    $src = Get-Content $path -Raw
    $manifestVer = $manifest.scripts.$id.version
    if ($src -match 'local VERSION = "([^"]+)"') {
        $gameVer = $Matches[1]
        if ($gameVer -ne $manifestVer) {
            Fail "$id game ($gameVer) != manifest ($manifestVer)"
        } else {
            Pass "$id v$gameVer"
        }
        if ($loader -notmatch ('id = "' + [regex]::Escape($id) + '"[\s\S]*?version = "' + [regex]::Escape($gameVer) + '"')) {
            Fail "$id version missing or mismatched in loader.luau GAMES table"
        }
    } else {
        Fail "$id missing local VERSION"
    }
}

if (Test-Path (Join-Path $root "load.luau")) {
    Fail "load.luau should not exist (removed in v5.x)"
}

if ($loader -match "EMBEDDED_CORE = \[=") {
    Fail "loader.luau contains embedded core (breaks Volt)"
}

if ($failed.Count -gt 0) {
    Write-Host "`n$($failed.Count) version check(s) failed." -ForegroundColor Red
    exit 1
}

Write-Host "`nAll version checks passed." -ForegroundColor Green
