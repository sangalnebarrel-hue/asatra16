#!/usr/bin/env bash
# Builds the place from src/ and checks every script that differs from the base place:
#   1. luau-compile (syntax) on all changed/new scripts;
#   2. luau-lsp analyze (Roblox API types) on them, reporting only diagnostics that the
#      base version of the same file did not already have.
# Needs: python3 (lz4, zstandard), lune, luau-compile, luau-lsp + globalTypes.d.luau.
# Usage: tools/check.sh OUT.rbxl   (env: LUNE, LUAU_COMPILE, LUAU_LSP, LSP_DEFS, WORK)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=${1:-build/DOGROTS.rbxl}
WORK=${WORK:-$(mktemp -d)}
BASE=place/DOGROTS_V13_RELEASE.rbxl
mkdir -p "$(dirname "$OUT")" "$WORK"

python3 tools/build_place.py "$BASE" src "$OUT" | tee "$WORK/build.txt"
files=$(grep -E '^(changed|created) ' "$WORK/build.txt" | awk '{print $2}')

echo "== syntax"
fail=0
for f in $files; do "$LUAU_COMPILE" --null "src/$f" >/dev/null || { echo "SYNTAX $f"; fail=1; }; done

echo "== types (new diagnostics only)"
"$LUNE" run tools/sourcemap.luau "$OUT" "$PWD/src" "$WORK/sourcemap.json" >/dev/null
rm -rf "$WORK/base" && mkdir -p "$WORK/base"
git archive HEAD src | tar -x -C "$WORK/base"
"$LUNE" run tools/sourcemap.luau "$BASE" "$WORK/base/src" "$WORK/base-sourcemap.json" >/dev/null
for f in $files; do
  "$LUAU_LSP" analyze --sourcemap="$WORK/sourcemap.json" --definitions="$LSP_DEFS" "src/$f" 2>&1 \
    | grep -F "src/$f" | grep -v "^\[" | sed -E 's/^[^(]*\(([0-9]+),[0-9]+\): //' | sort -u > "$WORK/new.txt" || true
  if [ -f "$WORK/base/src/$f" ]; then
    "$LUAU_LSP" analyze --sourcemap="$WORK/base-sourcemap.json" --definitions="$LSP_DEFS" "$WORK/base/src/$f" 2>&1 \
      | grep -F "src/$f" | grep -v "^\[" | sed -E 's/^[^(]*\(([0-9]+),[0-9]+\): //' | sort -u > "$WORK/old.txt" || true
  else
    : > "$WORK/old.txt"
  fi
  # Cyclic-require notes name absolute paths (base vs src), so they never match: skip them.
  extra=$(comm -13 "$WORK/old.txt" "$WORK/new.txt" | grep -v -E "^(LocalUnused|FunctionUnused|ImportUnused|LocalShadow|ImplicitReturn|SameLineStatement|MultiLineStatement|TableOperations)" | grep -v "Cyclic dependencies" || true)
  if [ -n "$extra" ]; then echo "-- $f"; echo "$extra"; fi
done

echo "== strict Roblox API check (changed/new files; property, method and enum names)"
for f in $files; do
  cp "src/$f" "$WORK/strict.luau"; sed -i '1i --!strict' "$WORK/strict.luau"
  "$LUAU_LSP" analyze --sourcemap="$WORK/sourcemap.json" --definitions="$LSP_DEFS" "$WORK/strict.luau" 2>&1 \
    | grep -F "strict.luau" | grep -E "external type|EnumItem|Enum\.|Unknown global" | grep -v "external type 'Instance'" | grep -v "Table type '" | sed -E 's/^[^(]*\(([0-9]+),([0-9]+)\)/  line \1:\2/' > "$WORK/strict.txt" || true
  if [ -s "$WORK/strict.txt" ]; then
    # Line numbers are shifted by the added --!strict line.
    echo "-- $f"; awk '{split($2,a,":"); $2=(a[1]-1)":"a[2]; print}' "$WORK/strict.txt"
  fi
done
exit $fail
