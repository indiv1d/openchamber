#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

version="$(check_versions)"
mkdir -p "$DIST"

case "$(uname -s)" in
  Linux)
    require docker
    check_memory
    builder_image builder-wine.Dockerfile openchamber-builder-wine

    log "building the Windows x64 installer on Linux"
    docker run --rm \
      -v "$ROOT:/app" \
      -v openchamber-build-node-modules-windows:/app/node_modules \
      -w /app \
      -e NODE_OPTIONS=--max-old-space-size=4096 \
      -e OPENCHAMBER_TARGET_ARCH=x64 \
      -e OPENCHAMBER_OPENCODE_SERVER_PLATFORM=win32 \
      -e OPENCHAMBER_TARGET_PLATFORM=win32 \
      -e ELECTRON_BUILDER_ARCH=x64 \
      -e CSC_IDENTITY_AUTO_DISCOVERY=false \
      -e WINEDEBUG=-all \
      openchamber-builder-wine bash -lc '
        set -euo pipefail
        bun install --frozen-lockfile
        cd packages/electron
        bun run build:web-assets
        bun run bundle:main
        cd /app
        bun install --frozen-lockfile --os win32 --cpu x64
        cd packages/electron
        bun run prepare:opencode-server
        bun run prepare:ripgrep
        node ./scripts/package.mjs --win --x64 --publish=never
      '
    log "cross-build cannot verify the packaged Windows server; run the Windows host path to verify"
    ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    require bun
    require node

    log "building the Windows x64 installer on Windows"
    cd "$ROOT"
    bun install --frozen-lockfile
    cd packages/electron
    export OPENCHAMBER_TARGET_ARCH=x64
    export CSC_IDENTITY_AUTO_DISCOVERY=false
    bun run build:web-assets
    bun run prepare:opencode-server
    bun run verify:opencode-server
    bun run prepare:ripgrep
    bun run bundle:main
    node ./scripts/rebuild-native.mjs
    node ./scripts/package.mjs --win --x64 --publish=never
    bun run verify:opencode-server:packaged
    ;;
  *)
    die "run this script on Linux or Windows"
    ;;
esac

collect_patterns 'OpenChamber-*-win-*'
write_build_info "$version"
write_hashes
log "done: $DIST"
