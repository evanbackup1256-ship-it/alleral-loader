const fs = require('fs');
const path = require('path');
const luaparse = require(process.cwd() + '/node_modules/luaparse/luaparse.js');

const files = [
    'hub/alleral_ui.luau',
    'hub/core_ui.luau',
    'hub/core_hub_ui.luau',
    'hub/core_base.luau',
    'hub/ui/noblev10/Init.luau',
    'hub/ui/noblev10/Theme.luau',
    'hub/ui/noblev10/State.luau',
    'hub/ui/noblev10/Layout.luau',
    'hub/ui/noblev10/Motion.luau',
    'hub/ui/noblev10/ZIndex.luau',
    'hub/ui/noblev10/Components/Controls.luau',
    'hub/ui/noblev10/Components/Card.luau',
    'hub/ui/noblev10/Components/ScrollContainer.luau',
    'hub/ui/noblev10/Components/init.luau',
    'hub/ui/noblev10/Vendor/Spr.luau',
    'hub/ui/noblev10/Vendor/Janitor.luau',
    'hub/ui/noblev10/Vendor/Signal.luau',
    'hub/ui/noblev10/Vendor/Fusion.luau',
    'hub/ui/noblev10/Systems/WindowManager.luau',
    'hub/ui/noblev10/Systems/SearchManager.luau',
    'hub/ui/noblev10/Systems/NotificationManager.luau',
    'hub/ui/noblev10/Systems/DropdownManager.luau',
    'hub/ui/noblev10/Systems/InputManager.luau',
    'hub/ui/noblev10/Systems/AnimationManager.luau',
    'hub/ui/noblev10/Systems/ConfigManager.luau',
    'hub/ui/noblev10/Systems/Validation.luau',
];

function getLineCol(src, pos) {
    const before = src.substring(0, pos);
    const line = (before.match(/\n/g) || []).length + 1;
    const lastNL = before.lastIndexOf('\n');
    return { line, col: pos - lastNL };
}

let ok = true;
for (const relPath of files) {
    const filepath = path.resolve(process.cwd(), relPath);
    try {
        const src = fs.readFileSync(filepath, 'utf8');
        try {
            luaparse.parse(src, { luaVersion: '5.1', comments: false, scope: false });
            console.log('[PASS] ' + relPath);
        } catch (err) {
            ok = false;
            const loc = getLineCol(src, err.index || 0);
            const lines = src.split('\n');
            const l = loc.line - 1;
            console.log('[FAIL] ' + relPath + ' line ' + loc.line + ': ' + err.message);
            for (let j = Math.max(0, l-2); j <= Math.min(lines.length-1, l+2); j++) {
                const marker = j === l ? '>>>' : '   ';
                let text = lines[j];
                if (text.length > 150) text = text.substring(0, 150) + '...';
                console.log('  ' + marker + ' ' + (j+1) + ': ' + text);
            }
        }
    } catch (e) {
        console.log('[SKIP] ' + relPath + ' - ' + e.message);
    }
}
console.log(ok ? '\nAll files pass' : '\nFAILED');