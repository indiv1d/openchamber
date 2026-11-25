#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

require docker
check_memory
version="$(check_versions)"
mkdir -p "$DIST"

builder_image builder.Dockerfile openchamber-builder-linux

log "building Linux x64 packages"
docker run --rm \
  -v "$ROOT:/app" \
  -v openchamber-build-node-modules-linux:/app/node_modules \
  -w /app \
  -e NODE_OPTIONS=--max-old-space-size=4096 \
  -e OPENCHAMBER_TARGET_ARCH=x64 \
  -e OPENCHAMBER_UPDATES_DISABLED=1 \
  openchamber-builder-linux bash -lc '
    set -euo pipefail
    bun install --frozen-lockfile
    cd packages/electron
    bun run build:web-assets
    bun run prepare:opencode-server
    bun run verify:opencode-server
    bun run prepare:ripgrep
    bun run bundle:main
    bun run rebuild:native
    node ./scripts/package.mjs --linux --x64 --publish=never
    bun run verify:opencode-server:packaged
    bun run verify:linux-appimage
  '

collect_patterns 'OpenChamber-*-linux-*'
write_build_info "$version"
write_hashes
log "done: $DIST"
