import re
import sys
from pathlib import Path


def lua_unescape(s: str) -> str:
    out = []
    i = 0
    while i < len(s):
        if s[i] == "\\" and i + 1 < len(s) and s[i + 1].isdigit():
            j = i + 1
            num = ""
            while j < len(s) and s[j].isdigit() and len(num) < 3:
                num += s[j]
                j += 1
            out.append(chr(int(num) % 256))
            i = j
            continue
        out.append(s[i])
        i += 1
    return "".join(out)


def decrypt(data: str, key: str) -> str:
    key_len = len(key)
    out = []
    for i in range(1, len(data) + 1):
        ki = i % key_len
        out.append(chr((ord(data[i - 1]) ^ ord(key[ki])) % 256))
    return "".join(out)


def deobfuscate_file(path: Path) -> tuple[str, list[str]]:
    content = path.read_text(encoding="utf-8", errors="replace")
    pattern = re.compile(r'v7\("((?:\\.|[^"\\])*)","((?:\\.|[^"\\])*)"\)')
    strings: list[str] = []

    def repl(match: re.Match) -> str:
        a = lua_unescape(match.group(1))
        b = lua_unescape(match.group(2))
        dec = decrypt(a, b)
        strings.append(dec)
        return repr(dec)

    output = pattern.sub(repl, content)
    return output, strings


def main() -> None:
    if len(sys.argv) < 2:
        print("usage: xor_deobfuscate.py <file> [out]")
        sys.exit(1)
    src = Path(sys.argv[1])
    out, strings = deobfuscate_file(src)
    dst = Path(sys.argv[2]) if len(sys.argv) > 2 else src.with_suffix(".deobfuscated.lua")
    dst.write_text(out, encoding="utf-8")
    print(f"Wrote {dst} ({len(strings)} strings)")
    for s in sorted(set(strings), key=len):
        if any(c.isalpha() for c in s) and len(s) >= 3:
            if "http" in s or "Service" in s or "Auto" in s or "Remote" in s or s[0].isupper():
                print(repr(s))


if __name__ == "__main__":
    main()
