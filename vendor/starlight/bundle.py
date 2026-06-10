#!/usr/bin/env python3
"""Bundle modular Starlight sources into a single Source.lua for executor loadstring."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LIB = ROOT / "lib"
OUTPUT = ROOT / "Source.lua"

MODULE_ORDER = [
    "util.luau",
    "theme.luau",
    "tween.luau",
    "filesystem.luau",
    "notification.luau",
    "elements.luau",
    "window.luau",
]

HEADER = """--[[
    Starlight Interface Suite — Alleral Rewrite
    Bundled programmatic UI library. Edit files under vendor/starlight/lib/ then run:
    python vendor/starlight/bundle.py
]]

"""


def strip_requires(source: str) -> str:
    lines = []
    for line in source.splitlines():
        if re.match(r"^\s*local\s+\w+\s*=\s*require\(script\.Parent", line):
            continue
        if re.match(r"^\s*return\s+\w+\s*$", line):
            continue
        lines.append(line)
    return "\n".join(lines)


def module_name(filename: str) -> str:
    return Path(filename).stem


def bundle() -> str:
    chunks = [HEADER, "local modules = {}\nlocal function requireModule(name)\n\treturn modules[name]\nend\n"]

    for filename in MODULE_ORDER:
        path = LIB / filename
        name = module_name(filename)
        body = strip_requires(path.read_text(encoding="utf-8"))
        chunks.append(f"modules['{name}'] = (function()\n{body}\nend)()\n")

    chunks.append(
        """
local FileSystem = requireModule('filesystem')
local Theme = requireModule('theme')
local Notification = requireModule('notification')
local WindowBuilder = requireModule('window')
local Util = requireModule('util')

local Starlight = {
\tInterfaceBuild = "Alleral-1",
\tWindowKeybind = "K",
\tMinimized = false,
\tMaximized = false,
\tNotificationsOpen = false,
\tDialogOpen = false,
\tWindow = nil,
\tNotifications = nil,
\tInstance = nil,
\tOnDestroy = nil,
\tFileSystem = FileSystem,
\tThemes = Theme.Palettes,
\tCurrentTheme = Theme.current(),
}

function Starlight:Notification(data)
\treturn Notification.show(data)
end

function Starlight:CreateWindow(windowSettings)
\tlocal window = WindowBuilder.create(self, windowSettings)
\tself.Window = window
\tself.CurrentTheme = Theme.current()
\treturn window
end

function Starlight:SetTheme(themeName)
\tTheme.setTheme(themeName)
\tself.CurrentTheme = Theme.current()
\tif self.Window and self.Window.Instance then
\t\tWindowBuilder.refreshTheme(self.Window.Instance)
\tend
end

function Starlight:SetAccent(color)
\tTheme.applyAccent(color)
\tself.CurrentTheme = Theme.current()
end

function Starlight:GetVisualSettings()
\treturn Util.deepCopy(Theme.Visual)
end

function Starlight:SetVisualSettings(settings)
\tfor key, value in pairs(settings or {}) do
\t\tif Theme.Visual[key] ~= nil then
\t\t\tTheme.Visual[key] = value
\t\tend
\tend
\tself.CurrentTheme = Theme.current()
end

return Starlight
"""
    )
    return "\n".join(chunks)


def main() -> None:
    bundled = bundle()
    # Fix cross-module references inside bundled modules
    bundled = bundled.replace("require(script.Parent.util)", "requireModule('util')")
    bundled = bundled.replace("require(script.Parent.theme)", "requireModule('theme')")
    bundled = bundled.replace("require(script.Parent.tween)", "requireModule('tween')")
    OUTPUT.write_text(bundled, encoding="utf-8")
    print(f"Wrote {OUTPUT} ({len(bundled.splitlines())} lines)")


if __name__ == "__main__":
    main()
