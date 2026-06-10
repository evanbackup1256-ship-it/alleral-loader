# Luxy reference scripts

Read-only reference material used while porting game logic into Alleral.

| File | Description |
|------|-------------|
| `script.obfuscated.lua` | Original obfuscated Luxy Hub script |
| `script.deobfuscated.lua` | Strings decrypted + formatted for reading |
| `analytics.obfuscated.lua` | Obfuscated Luxy analytics module (LuaObfuscator VM) |
| `analytics.deobfuscated.lua` | Reconstructed Tracker API reference |

These are **not** loaded by the loader. Do not execute them in-game.

Upstream Luxy repos by [Omnie7](https://github.com/Omnie7):

- [Luxy-Core](https://github.com/Omnie7/Luxy-Core) — `Data/KickBlox.luau`, analytics module
- [Luxy-Hub](https://github.com/Omnie7/Luxy-Hub) — UI library and place-id router
- [Luxy-Scripts](https://github.com/Omnie7/Luxy-Scripts) — per-game script payloads

Alleral uses Starlight (not LuxyHub UI) but follows the same `game:HttpGet` + `?nocache=` fetch pattern and vendors KickBlox data from Luxy-Core.
