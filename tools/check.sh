#!/usr/bin/env bash
# Builds the place and checks it:
#   1. tools/build.py (base place + remaster/ map pipeline + src/ scripts);
#   2. Luau syntax of every script that differs from the base place (tools/luau_syntax.luau);
#   3. Roblox API names in those scripts (tools/lint_api.py; needs tools/fetch_api.sh once);
#   4. an independent parse of the result with rbx-dom and the Paradise wiring checks
#      (tools/validate_place.luau).
# Needs: python3 (lz4, zstandard), lune 0.10+, npm (only for tools/fetch_api.sh).
# Usage: tools/check.sh [OUT.rbxl]   (env: LUNE, DOGROTS_ZSTD_LEVEL)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=${1:-build/DOGROTS_V34.rbxl}
LUNE=${LUNE:-lune}
log=$(mktemp)
trap 'rm -f "$log"' EXIT

python3 tools/build.py --out "$OUT" | tee "$log"
files=$(grep -E '^(changed|created) ' "$log" | awk '{print "src/" $2}')

echo "== syntax"
# shellcheck disable=SC2086
"$LUNE" run tools/luau_syntax.luau $files

echo "== Roblox API names"
if [ -d "${RBXTS_TYPES:-.cache/rbxts-types/package}" ]; then
  # shellcheck disable=SC2086
  python3 tools/lint_api.py $files
else
  echo "skipped: run tools/fetch_api.sh first"
fi

echo "== place"
"$LUNE" run tools/validate_place.luau "$OUT"
