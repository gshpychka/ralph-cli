#!/usr/bin/env bash
# Updates sources.json to the latest upstream release of ralph-cli.
# Wired in via `passthru.updateScript` so nixpkgs-style update tooling
# (and `nix-update`) can invoke it.

set -euo pipefail

UPSTREAM="mikeyobrien/ralph-orchestrator"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES="$SCRIPT_DIR/sources.json"

current=$(jq -r .version "$SOURCES")
latest=$(curl -fsSL "https://api.github.com/repos/$UPSTREAM/releases/latest" \
  | jq -r '.tag_name | ltrimstr("v")')

if [ -z "$latest" ] || [ "$latest" = "null" ]; then
  echo "Failed to fetch latest version from GitHub" >&2
  exit 1
fi

if [ "$current" = "$latest" ]; then
  echo "ralph-cli is already at $current"
  exit 0
fi

echo "ralph-cli: $current -> $latest"

new=$(jq --arg v "$latest" '.version = $v | .platforms = {}' "$SOURCES")

while read -r system name; do
  [ -z "$system" ] && continue
  url="https://github.com/$UPSTREAM/releases/download/v$latest/ralph-cli-$name.tar.xz"
  echo "  prefetching $name"
  hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
  new=$(jq --arg s "$system" --arg n "$name" --arg h "$hash" \
    '.platforms[$s] = {name: $n, hash: $h}' <<<"$new")
done <<EOF
aarch64-darwin aarch64-apple-darwin
x86_64-darwin x86_64-apple-darwin
aarch64-linux aarch64-unknown-linux-gnu
x86_64-linux x86_64-unknown-linux-gnu
EOF

printf '%s\n' "$new" > "$SOURCES"
echo "wrote $SOURCES at $latest"
