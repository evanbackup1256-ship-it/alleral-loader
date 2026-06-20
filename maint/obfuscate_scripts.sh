#!/bin/bash
# Fast single-pass obfuscation -- all transformations in one Perl invocation.
# Skips bootstrap.luau and loader.luau.
# Uses content-hash cache (.obfuscation_cache) to skip unchanged files.
set -e

CACHE_DIR=".obfuscation_cache"
mkdir -p "$CACHE_DIR"

OBFUSCATE_FILES=()

for f in "$@"; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  [[ "$base" == "bootstrap.luau" || "$base" == "loader.luau" ]] && echo "Skipping $base" && continue

  size=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo 0)
  [ "$size" -lt 50 ] && continue

  # Check cache: skip if unchanged since last obfuscation
  src_hash=$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$f" 2>/dev/null | cut -d' ' -f1)
  cache_file="$CACHE_DIR/${src_hash}.done"
  if [ -f "$cache_file" ]; then
    echo "Skipping $base (unchanged)"
    continue
  fi

  OBFUSCATE_FILES+=("$f")
done

if [ ${#OBFUSCATE_FILES[@]} -eq 0 ]; then
  echo "No files need obfuscation"
  exit 0
fi

# Process all files in a single Perl invocation
for f in "${OBFUSCATE_FILES[@]}"; do
  base=$(basename "$f")
  size=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo 0)

  perl -i -0777 -pe '
    use strict; use warnings;
    my $src = $_;
    return if length($src) < 50;
    my ($version_marker) = $src =~ /local\s+VERSION\s*=\s*"([^"]+)"/;

    my $eq = "";
    while (index($src, "]$eq]") >= 0) {
      $eq .= "=";
    }
    my $open = "[" . $eq . "[";
    my $close = "]" . $eq . "]";
    my $marker = defined $version_marker && $version_marker ne ""
      ? "-- ALLERAL_VERSION: $version_marker\n"
      : "";
    $src = $marker
      . "local __alleral_source = " . $open . "\n"
      . $src
      . "\n" . $close . "\n"
      . "local __alleral_load = (getgenv and getgenv().loadstring) or loadstring or load\n"
      . "if type(__alleral_load) ~= \"function\" then error(\"loadstring unavailable\") end\n"
      . "local __alleral_chunk, __alleral_err = __alleral_load(__alleral_source, \"Alleral/game-source\")\n"
      . "if type(__alleral_chunk) ~= \"function\" then error(tostring(__alleral_err or \"compile failed\")) end\n"
      . "if setfenv and getfenv then pcall(setfenv, __alleral_chunk, getfenv()) end\n"
      . "return __alleral_chunk()\n";

    $_ = $src;
  ' "$f"

  # Mark as processed in cache
  src_hash=$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$f" 2>/dev/null | cut -d' ' -f1)
  touch "$CACHE_DIR/${src_hash}.done"
  echo "Done: $base ($size bytes)"
done

echo "Obfuscation complete: ${#OBFUSCATE_FILES[@]} file(s) processed"
