const fs = require('fs');
const path = require('path');
const luaparse = require(process.cwd() + '/node_modules/luaparse/luaparse.js');

const files = [
    'hub/alleral_ui.luau',
    'hub/core_ui.luau',
    'hub/core_hub_ui.luau',
    'hub/core_base.luau',
    'hub/log.luau',
    'hub/ui/windui/Init.luau',
    'hub/ui/windui/Bootstrap.luau',
    'hub/ui/windui/Window.luau',
    'hub/ui/windui/Tabs.luau',
    'hub/ui/windui/Controls.luau',
    'hub/ui/windui/Configs.luau',
    'hub/ui/windui/Notifications.luau',
    'hub/ui/windui/Text.luau',
    'hub/ui/windui/Theme.luau',
    'hub/ui/windui/Motion.luau',
    'hub/ui/windui/Guards.luau',
    'hub/ui/windui/Validate.luau',
    'hub/ui/windui/GameRegistry.luau',
    'hub/ui/windui/Cache.luau',
    'hub/ui/windui/TooltipManager.luau',
    'hub/ui/windui/Patch.luau',
    'hub/ui/windui/Drag.luau',
    'hub/ui/windui/SearchGlow.luau',
    'hub/ui/windui/VisualPolish.luau',
    'hub/ui/windui/ElementPolish.luau',
    'hub/ui/windui/Runtime.luau',
    'hub/ui/windui/EventBus.luau',
    'hub/ui/windui/ConnectionTracker.luau',
    'hub/ui/windui/GameTabSchemas.luau',
    'hub/ui/windui/managers/AnimationManager.luau',
    'hub/ui/windui/managers/DragManager.luau',
    'hub/ui/windui/managers/ResizeManager.luau',
    'hub/ui/windui/managers/LayoutManager.luau',
    'hub/ui/windui/managers/PerformanceManager.luau',
    'hub/ui/windui/managers/WindowManager.luau',
    'hub/ui/windui/managers/TabManager.luau',
    'hub/ui/windui/managers/ThemeManager.luau',
    'hub/ui/windui/managers/NotificationManager.luau',
    'hub/ui/windui/managers/ValidationManager.luau',
    'hub/ui/windui/managers/GameUIBuilder.luau',
    'hub/ui/windui/managers/ConfigUIBuilder.luau',
    'hub/ui/windui/managers/DashboardBuilder.luau',
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