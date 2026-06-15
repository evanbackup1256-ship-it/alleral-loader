#!/usr/bin/env python3
"""Apply compat + dropdown fixes to ui/syde/source.luau without full upstream rebuild."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "maint"))

from build_syde_source import add_dropdown_handle  # noqa: E402

COMPAT = ROOT / "ui" / "syde" / "compat.luau"
SOURCE = ROOT / "ui" / "syde" / "source.luau"
PATCH = ROOT / "ui" / "syde" / "patches" / "settings_dropdown.luau"


def replace_between(text: str, start: str, end: str, new_body: str) -> str:
    i = text.index(start)
    j = text.index(end, i)
    return text[:i] + new_body + text[j:]


def adapt_dropdown_patch(
    patch_text: str,
    *,
    page_expr: str,
    return_name: str,
    parent_expr: str,
    searchable: bool = False,
) -> str:
    block = patch_text.replace("function telement:Dropdown", f"function {return_name}:Dropdown")
    block = block.replace("window.settings.pages.page", page_expr)
    block = block.replace("dropdown.Parent = Page", f"dropdown.Parent = {parent_expr}")
    block = block.replace("return telement", f"return {return_name}")
    if searchable:
        block = block.replace(
            "sydeSetDropSelectedText(drop, data.PlaceHolder)\n",
            'sydeSetDropSelectedText(drop, data.PlaceHolder)\n\t\t\t\tdropdown:SetAttribute("Searchable", true)\n',
            1,
        )
    return block


def main() -> None:
    compat = COMPAT.read_text(encoding="utf-8")
    source = SOURCE.read_text(encoding="utf-8")
    patch = PATCH.read_text(encoding="utf-8")

    marker = "-- Alleral compatibility layer for upstream Syde"
    start = source.find(marker)
    if start == -1:
        raise SystemExit("compat marker missing in source.luau")
    func_anchor = "local function sydeClonePageTemplate(pageContainer, templateName)"
    func_start = source.find(func_anchor, start)
    end_anchor = "\n\nlocal resizing"
    end_idx = source.find(end_anchor, func_start)
    if end_idx == -1:
        raise SystemExit("compat block end missing in source.luau")

    source = source[:start] + compat.rstrip() + "\n\n" + source[end_idx + 2:]
    source = source.replace(
        "drop.down.MouseButton1Click:Connect(function()",
        "sydeConnectDropdownToggle(drop, function()",
    )
    source = source.replace("task.delay(1.2, function()", "task.delay(0.35, function()")

    settings_dd = add_dropdown_handle(
        adapt_dropdown_patch(
            patch,
            page_expr="window.settings.pages.page",
            return_name="telement",
            parent_expr="Page",
        )
    )
    page_dd = add_dropdown_handle(
        adapt_dropdown_patch(
            patch,
            page_expr="pages.page",
            return_name="initelement",
            parent_expr="defaultParent",
            searchable=True,
        )
    )
    source = replace_between(
        source,
        "function telement:Dropdown(Dropdown)",
        "\n\t\t\tfunction telement:Slider",
        settings_dd,
    )
    source = replace_between(
        source,
        "function initelement:Dropdown(Dropdown)",
        "\n\t\t--@@Colorpicker",
        page_dd,
    )

    SOURCE.write_text(source, encoding="utf-8")
    print(f"Updated {SOURCE} ({len(source)} bytes)")
    print(f"ALLERAL_SYDE_PATCH count: {source.count('ALLERAL_SYDE_PATCH =')}")
    print(f"sydeConnectDropdownToggle(drop count: {source.count('sydeConnectDropdownToggle(drop')}")
    print(f"data:Refresh count: {source.count('function data:Refresh(options, value)')}")


if __name__ == "__main__":
    main()
