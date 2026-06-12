# Syde UI (vendored)

Upstream: [essencejs/syde](https://github.com/essencejs/syde) (GPL-3.0)

- `source.luau` — full Syde library loaded by `hub/alleral_ui.luau`
- Docs: https://essencejs.github.io/syde/

Alleral patches in `source.luau`:
- `InitTab` accepts string or `{ Title = ... }`
- `initelement:Select()` for tab switching
- `Init({ Keybind = ... })` sets UI toggle key
- `Toggle()`, `GetState()`, `SetState()` on window root
