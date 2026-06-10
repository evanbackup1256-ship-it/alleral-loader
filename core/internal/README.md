# Internal sources (readable)

Edit these files, then regenerate protected distribution copies:

```bash
python tools/obfuscate_critical.py
```

For Starlight UI, edit `vendor/starlight/lib/` then:

```bash
python vendor/starlight/bundle.py
```

| Readable source | Protected output (loaded by loader / executors) |
|-----------------|--------------------------------------------------|
| `core/internal/telemetry.luau` | `core/telemetry.luau` |
| `core/internal/analytics.luau` | `core/analytics.luau` |
| `vendor/starlight/Source.plain.lua` | `vendor/starlight/Source.lua` |

Do **not** edit the protected outputs directly — changes will be overwritten on the next obfuscation run.
