#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[ "$(uname -s)" = "Linux" ] || die "run this script on Linux; use deploy/macos.sh on a Mac"

version="$(check_versions)"
arch="${1:-arm64}"
case "$arch" in
  arm64|x64) ;;
  *) die "usage: $0 [arm64|x64]" ;;
esac
mkdir -p "$DIST"

require docker
check_memory
builder_image builder-macos.Dockerfile openchamber-builder-macos

log "building unsigned macOS $arch packages on Linux"
docker run --rm \
  -v "$ROOT:/app" \
  -v openchamber-build-node-modules-macos:/app/node_modules \
  -w /app \
  -e NODE_OPTIONS=--max-old-space-size=4096 \
  -e OPENCHAMBER_TARGET_ARCH="$arch" \
  -e OPENCHAMBER_UPDATER_URL="$UPDATER_URL" \
  -e OPENCHAMBER_OPENCODE_SERVER_PLATFORM=darwin \
  -e OPENCHAMBER_TARGET_PLATFORM=darwin \
  -e ELECTRON_BUILDER_ARCH="$arch" \
  -e OPENCHAMBER_MACOS_CROSS=1 \
  -e CSC_IDENTITY_AUTO_DISCOVERY=false \
  -e VERSION="$version" \
  openchamber-builder-macos bash -lc '
    set -euo pipefail
    bun install --frozen-lockfile
    cd packages/electron
    bun run build:web-assets
    bun run bundle:main
    cd /app
    bun install --frozen-lockfile --os darwin --cpu "$OPENCHAMBER_TARGET_ARCH"
    cd packages/electron
    bun run prepare:opencode-server
    bun run prepare:ripgrep
    rm -rf dist
    node ./scripts/package.mjs --mac "--$OPENCHAMBER_TARGET_ARCH" --dir --publish=never

    case "$OPENCHAMBER_TARGET_ARCH" in
      arm64) app="dist/mac-arm64/OpenChamber.app" ;;
      x64) app="dist/mac/OpenChamber.app" ;;
    esac
    [ -d "$app" ] || { echo "packaged OpenChamber.app not found at $app" >&2; exit 1; }

    rcodesign sign "$app"
    rcodesign print-signature-info "$app" >/dev/null

    executable="$app/Contents/MacOS/OpenChamber"
    wanted_arch="arm64"
    [ "$OPENCHAMBER_TARGET_ARCH" = "x64" ] && wanted_arch="x86_64"
    if ! file "$executable" | grep -q "$wanted_arch"; then
      file "$executable" >&2
      echo "packaged executable is not $wanted_arch" >&2
      exit 1
    fi

    artifact="OpenChamber-$VERSION-mac-$OPENCHAMBER_TARGET_ARCH"
    dist="/app/packages/electron/dist"
    (cd "$(dirname "$app")" && zip -qry "$dist/$artifact.zip" OpenChamber.app)

    stage="dist/dmg-stage"
    rm -rf "$stage"
    mkdir -p "$stage"
    cp -a "$app" "$stage/"
    ln -sfn /Applications "$stage/Applications"
    image="dist/$artifact.img"
    size_mb=$(( $(du -sk "$stage" | awk "{print \$1}") / 1024 + 64 ))
    dd if=/dev/zero of="$image" bs=1M count="$size_mb" status=none
    mkfs.hfsplus -v "OpenChamber $VERSION" "$image" >/dev/null
    hfsplus "$image" addall "$stage" -s clone_link
    dmg build "$image" "$dist/$artifact.dmg"
    rm -rf "$stage" "$image"
  '

log "cross-built app is ad-hoc signed; macOS shows the quarantine prompt on first launch"
log "cross-build cannot verify the packaged macOS server; run the Mac path to verify"
collect_patterns 'OpenChamber-*-mac-*'
write_build_info "$version"
write_hashes
log "done: $DIST"
