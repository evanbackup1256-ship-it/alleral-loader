# Alleral Hub

One script. Detects your game and runs it.

**Games:** Kick a Lucky Block · Speed Keyboard Escape · Slime RNG · Build A Ring Farm · Survive a Zombie Arena

## Load

Paste in Volt and execute:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/evanbackup1256-ship-it/kick/main/loader.luau?t=" .. tick()))()
```

You should see:

```
=== Alleral 7.0.0 active ===
```

If you see an old version, delete saved Alleral scripts in Volt and run the line above again.

Reload: `getgenv().Alleral_Reload()`

Clear cached files: `getgenv().Alleral_PurgeCache()`

Scan for old loaders: `getgenv().Alleral_ScanLegacy()`
