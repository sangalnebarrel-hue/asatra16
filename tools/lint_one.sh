#!/usr/bin/env bash
# Quick check of one script: syntax (luau-compile) and Roblox API names (luau-lsp strict,
# reporting only property/method/enum errors on Roblox types).
# Usage: tools/lint_one.sh src/path/File.luau   (env: LUAU_COMPILE, LUAU_LSP, LSP_DEFS, SOURCEMAP)
set -uo pipefail
f=$1
"$LUAU_COMPILE" --null "$f" >/dev/null || exit 1
tmp=$(mktemp -d)
cp "$f" "$tmp/strict.luau"; sed -i '1i --!strict' "$tmp/strict.luau"
"$LUAU_LSP" analyze ${SOURCEMAP:+--sourcemap="$SOURCEMAP"} --definitions="$LSP_DEFS" "$tmp/strict.luau" 2>&1 \
  | grep -F "strict.luau" | grep -E "external type|EnumItem|Enum\.|Unknown global|SyntaxError" | grep -v "external type 'Instance'" | grep -v "Table type '" \
  | sed -E 's/^[^(]*\(([0-9]+),([0-9]+)\)/line \1:\2/' | awk '{split($2,a,":"); $2=(a[1]-1)":"a[2]; print}'
rm -rf "$tmp"
echo "lint done: $f"
