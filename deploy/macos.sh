#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[ "$(uname -s)" = "Darwin" ] || die "run this script on macOS"

require bun
require node

arch="${1:-arm64}"
case "$arch" in
  arm64|x64) ;;
  *) die "usage: $0 [arm64|x64]" ;;
esac

version="$(check_versions)"
mkdir -p "$DIST"

log "building unsigned macOS $arch packages"
cd "$ROOT"
bun install --frozen-lockfile
cd packages/electron
export CSC_IDENTITY_AUTO_DISCOVERY=false
export OPENCHAMBER_UPDATER_URL="$UPDATER_URL"
bun run build:web-assets
bun run prepare:opencode-server
bun run verify:opencode-server
bun run prepare:ripgrep
bun run bundle:main
bun run rebuild:native
rm -rf dist
bunx electron-builder --mac "--$arch" --publish=never -c.mac.notarize=false
bun run verify:opencode-server:packaged

collect_patterns 'OpenChamber-*-mac-*'
write_build_info "$version"
write_hashes
log "done: $DIST"
