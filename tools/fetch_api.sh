#!/usr/bin/env bash
# Downloads the Roblox API declarations (@rbxts/types, generated from Roblox's API dump)
# into .cache/rbxts-types for tools/lint_api.py.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .cache/rbxts-types && cd .cache/rbxts-types
npm pack @rbxts/types >/dev/null
tar xzf rbxts-types-*.tgz && rm -f rbxts-types-*.tgz
echo "API declarations in $(pwd)/package"
