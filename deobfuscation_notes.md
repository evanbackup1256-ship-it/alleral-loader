# Deobfuscation Notes

Generated from `pasted-text.txt` on 2026-06-06.

## Files

- `original_obfuscated.lua` keeps the pasted code unchanged.
- `deobfuscated.lua` is the readable working copy.
- `decoded_strings.txt` lists every unique decoded string constant for auditing.
- `new_ui_library.lua` contains the pasted replacement UI library.
- `updated_obfuscated_version.lua` contains the latest pasted LuaObfuscator VM-wrapped source.
- `updated_vm_strings.txt` lists the strings recovered from the latest VM payload.

## What Changed

- Decoded 1,228 XOR-wrapped string constants.
- Collapsed 1,373 simple numeric-obfuscation expressions while preserving function-call parentheses.
- Renamed the most important top-level aliases such as `state`, `HttpService`, `Workspace`, `RunService`, `ReplicatedStorage`, and `LocalPlayer`.
- Fixed a nil crash when the remote UI library fails to load before `GetCustomIcon` is patched.
- Fixed undefined `OwnerWebhookURL` and `GlobalWebhookURL` checks by making them optional global strings and disabling those webhook branches when unset or left as template placeholders.
- Corrected misleading service names where `Workspace` and `RunService` were crossed.
- Added explicit defaults for previously uninitialized state keys: `Freecam`, `FastRun`, `Fly`, and `VolcanoTweenSpeed`.
- Verified that every referenced `state.*` key now has an assignment/default in the cleaned file.
- Renamed the remaining obfuscated `v###` code identifiers. Version strings such as `v3.6` may still appear inside UI text, but executable code no longer uses `v###` identifiers.
- Replaced several obfuscated state-machine helpers with direct Lua: settings save/load, remote module loading, selection normalization, filter matching, plot lookup, mutation lookup, cost helpers, CPS calculation, and unload cleanup.
- Removed the decoded-string helper and anti-analysis hooks that were no longer useful in the readable source.
- Centralized defaults in `defaultState`, fixed the duplicate `MaxUpLevel` default, and added status-webhook settings to persistence.
- Removed obvious unused locals/helpers/remotes and consolidated repeated dropdown selection logic through `selectedKeysFromMap`.
- Integrated the new UI as a local editable library. `deobfuscated.lua` now tries `new_ui_library.lua` first, then the GitHub raw library at `https://raw.githubusercontent.com/evanbackup1256-ship-it/luxyhubv6/refs/heads/main/code`, and only then the older fallback UI.
- Added UI compatibility shims for legacy notification fields (`Content`, `Text`, `Duration`) and the older `SetRTXMode` / `SetPotatoMode` call shapes.
- Fixed the new UI dropdown compatibility wrapper so `UpdateOptions` updates the dropdown instance consistently.
- Modernized `new_ui_library.lua` with a graphite/teal BuilderSans theme, global search by default, left-side notifications, resizable sidebar defaults, accent buttons/labels, editable `SetTheme` / `ApplyTheme`, hardened notification aliases, and real `SetPotatoMode` / `SetRTXMode` visual handlers.
- Updated `deobfuscated.lua` to request the modern window options explicitly when creating the main UI.
- Added gentler startup fallbacks for missing UI and game-data modules.
- Reverted the auto-kick wave movement path back to its original behavior after the detected anti-wave/godmode approach was removed.
- Centralized HTTP request selection for executor compatibility, including Delta/Volt-style `request` globals, and removed direct unsafe `fluxus.request` lookups.
- Tightened webhook validation/sending so Discord webhook URLs are checked, proxied consistently through Hyra where appropriate, and test/status sends report real failures instead of unconditional success.
- Removed an optional global-webhook early return that could stop the rest of the script when no global webhook was configured.
- Added explicit runtime defaults for upgrade-base cache, weight list, and favorite-scan callback state.
- Parsed the latest LuaObfuscator VM payload, recovered 806 unique string constants from 251 VM prototypes, and compared them against the readable script.
- Restored the updated direct `rev_ToggleFav` remote path while keeping the existing Network-module fallback.
- Restored the updated `SpeedData:GetCostForLevel` affordability guard for auto-buy speed upgrades, with fallback behavior when that API is unavailable.

## Review Notes

- This was deobfuscated statically. I did not execute the script or any remote `loadstring` payloads.
- The script still contains Roblox executor hooks, remote HTTP loaders, webhook/request code, and automated gameplay actions. Review those sections before running or modifying anything.
- Some short-lived locals now use generic names such as `temp###`, `arg###`, and `item###` where the static pass could not infer a safe domain-specific name.
