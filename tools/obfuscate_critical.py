#!/usr/bin/env python3
"""Obfuscate critical Alleral distribution artifacts (readable sources -> protected outputs)."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from luau_obfuscator import obfuscate_source  # noqa: E402

# (readable source, distribution output, profile)
TARGETS: list[tuple[str, str, str]] = [
    ("core/internal/telemetry.luau", "core/telemetry.luau", "full"),
    ("core/internal/analytics.luau", "core/analytics.luau", "full"),
]


def obfuscate_file(src: Path, dst: Path, profile: str) -> None:
    if not src.is_file():
        raise FileNotFoundError(f"Missing source: {src}")
    plain = src.read_text(encoding="utf-8")
    protected = obfuscate_source(plain, profile=profile)
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(protected, encoding="utf-8")
    print(f"Protected {src.relative_to(ROOT)} -> {dst.relative_to(ROOT)} ({len(protected.splitlines())} lines)")


def main() -> None:
    for src_rel, dst_rel, profile in TARGETS:
        obfuscate_file(ROOT / src_rel, ROOT / dst_rel, profile)
    print("Done.")


if __name__ == "__main__":
    main()
