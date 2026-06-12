# Syde UI (vendored)

Upstream: [essencejs/syde](https://github.com/essencejs/syde) (GPL-3.0)

- `source.luau` — full Syde library loaded by `hub/alleral_ui.luau`
- Docs: https://essencejs.github.io/syde/

Alleral patches in `source.luau`:
- Synced from [essencejs/syde `main`](https://github.com/essencejs/syde) (asset `rbxassetid://123800669522471`)
- UI template compat: `Title`/`title`, `Buttons`/`buttons`, `selected`/`Selected`, modal + slider row lookups, tab `indicator`/`Indicator`, pages `clipframe`, optional `minihome`
- `InitTab` accepts string or `{ Title = ... }`
- `initelement:Select()` for tab switching
- `Init({ Keybind = ... })` sets UI toggle key
- `Toggle()`, `GetState()`, `SetState()` on window root
- `initelement:Button()` returns `{ Set = ... }` for dynamic label updates
