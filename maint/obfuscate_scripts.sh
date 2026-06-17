#!/bin/bash
# Heavily obfuscate .luau scripts for the public repo.
# Original sources stay clean in the private repo.
#
# Does NOT touch bootstrap.luau or loader.luau - those need to stay readable.
#
# Techniques:
#   1. Strip comments (delegated to strip_comments.sh)
#   2. Rename local variables to random short names
#   3. Heavy minification - collapse to minimal lines

for f in "$@"; do
  [ -f "$f" ] || continue
  base=$(basename "$f")

  # Skip core loader files
  if [[ "$base" == "bootstrap.luau" || "$base" == "loader.luau" ]]; then
    echo "Skipping $base"
    continue
  fi

  src=$(cat "$f")

  # ── Step 1: Rename local variables ──
  # Collect all "local name" declarations, generate short replacements
  declare -A rename_map
  declare -A used_names
  count=0

  # Protected names that must not be renamed
  protected='\b(Iris|MacLib|game|workspace|Players|RunService|UserInputService|StarterGui|ENV|_G|script|Instance|Vector[23]|Color3|UDim[2]?|CFrame|Ray|Region3|NumberRange|NumberSequence|ColorSequence|BrickColor|TweenInfo|Random|Rect|DateTime|tick|time|wait|spawn|delay|pcall|xpcall|print|warn|error|assert|type|typeof|tostring|tonumber|next|pairs|ipairs|select|unpack|setmetatable|getmetatable|rawget|rawset|rawlen|string|table|math|coroutine|debug|os|io|bit32|buffer|utf8)\b'

  while IFS= read -r line; do
    if [[ $line =~ ^[[:space:]]*local[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
      varname="${BASH_REMATCH[1]}"

      # Skip built-in / protected names
      if echo "$varname" | grep -qE "$protected"; then
        continue
      fi
      # Skip very short names (already obfuscated or single-letter loop vars)
      if [ ${#varname} -le 2 ]; then
        continue
      fi

      # Generate a unique 2-3 char replacement
      seed="$varname$count"
      newname=$(echo "$seed" | md5sum 2>/dev/null | head -c 3 || echo "_$count")
      # Ensure starts with letter
      if [[ "$newname" =~ ^[0-9] ]]; then
        newname="x$newname"
      fi
      # Avoid collisions
      while [ -n "${used_names[$newname]}" ]; do
        count=$((count + 1))
        newname=$(echo "$varname$count" | md5sum 2>/dev/null | head -c 3)
        if [[ "$newname" =~ ^[0-9] ]]; then
          newname="x$newname"
        fi
      done

      rename_map["$varname"]="$newname"
      used_names["$newname"]=1
      count=$((count + 1))
    fi
  done <<< "$src"

  # Apply renames using perl for word-boundary safety
  for old_name in "${!rename_map[@]}"; do
    new_name="${rename_map[$old_name]}"
    # Only replace whole words, not inside strings (basic approach)
    src=$(echo "$src" | perl -pe "s/\b$old_name\b/$new_name/g" 2>/dev/null)
  done

  # ── Step 2: Heavy minify ──
  # Remove leading whitespace
  src=$(echo "$src" | sed 's/^[[:space:]]*//')
  # Remove trailing whitespace
  src=$(echo "$src" | sed 's/[[:space:]]*$//')
  # Collapse multiple spaces to one
  src=$(echo "$src" | tr -s ' ')
  # Remove newlines (put entire script on one line per function)
  src=$(echo "$src" | perl -0pe 's/\n(?!\n)/ /g' 2>/dev/null)
  # Collapse spaces again after newline removal
  src=$(echo "$src" | tr -s ' ')
  # Remove spaces around certain tokens
  src=$(echo "$src" | sed 's/ = /=/g')
  src=$(echo "$src" | sed 's/= /=/g')
  src=$(echo "$src" | sed 's/ , /,/g')
  src=$(echo "$src" | sed 's/ (/ (/g')
  src=$(echo "$src" | sed 's/( /(/g')
  src=$(echo "$src" | sed 's/ )/)/g')
  src=$(echo "$src" | sed 's/\.\. /\.\./g')
  src=$(echo "$src" | sed 's/ \.\./\.\./g')

  echo "$src" > "$f"
  echo "Obfuscated: $base (${#rename_map[@]} vars)"
done
