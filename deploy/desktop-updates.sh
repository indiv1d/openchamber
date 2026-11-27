#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[ "$(uname -s)" = "Linux" ] || die "run this script on Linux"

usage() {
  printf 'usage: %s [--version <X.Y.Z-fork.N>]\n' "$0" >&2
  exit 2
}

requested=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --version) [ "$#" -ge 2 ] || usage; requested="$2"; shift 2 ;;
    *) usage ;;
  esac
done

current="$(check_versions)"
base="${current%%-*}"
next=1
if [[ "$current" =~ -fork\.([0-9]+)$ ]]; then
  next=$(( BASH_REMATCH[1] + 1 ))
fi
version="${requested:-$base-fork.$next}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+-fork\.[0-9]+$ ]] || die "version must look like X.Y.Z-fork.N, got $version"

version_greater() {
  [ "$1" != "$2" ] || return 1
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" = "$1" ]
}

require docker
require sha256sum
require node
check_memory

published=""
if [ -f "$UPDATE_PUBLISH_DIR/latest.yml" ]; then
  published="$(sed -n 's/^version: //p' "$UPDATE_PUBLISH_DIR/latest.yml" | head -n 1)"
fi
if [ -n "$published" ] && ! version_greater "$version" "$published"; then
  die "published version is $published; $version is not newer. Pass --version with a higher fork build."
fi

set_version() {
  local file="$1"
  sed -i -E "0,/\"version\": \"[^\"]*\"/s//\"version\": \"$version\"/" "$file"
}

log "releasing $version (base $base)"
for file in package.json packages/ui/package.json packages/web/package.json packages/electron/package.json packages/vscode/package.json packages/sdk/package.json; do
  set_version "$ROOT/$file"
done
[ "$(check_versions)" = "$version" ] || die "package versions did not update to $version"

log "building Linux, Windows, macOS arm64 and macOS x64"
./deploy/linux.sh
./deploy/windows.sh
./deploy/macos-cross.sh arm64
./deploy/macos-cross.sh x64

shopt -s nullglob
artifacts=("$DIST/OpenChamber-$version-"*)
[ "${#artifacts[@]}" -gt 0 ] || die "no artifacts for $version in $DIST"

mkdir -p "$UPDATE_PUBLISH_DIR"
cp -f "${artifacts[@]}" "$UPDATE_PUBLISH_DIR/"

manifests="$(mktemp -d "$UPDATE_PUBLISH_DIR/.manifests.XXXXXX")"
trap 'rm -rf "$manifests"' EXIT
node "$ROOT/packages/electron/scripts/write-update-manifests.mjs" \
  --dist "$UPDATE_PUBLISH_DIR" \
  --out "$manifests" \
  --version "$version"
mv -f "$manifests"/*.yml "$UPDATE_PUBLISH_DIR/"
rmdir "$manifests"
trap - EXIT

(
  cd "$UPDATE_PUBLISH_DIR"
  sha256sum OpenChamber-* > SHA256SUMS
)

log "published $version to $UPDATE_PUBLISH_DIR"
log "feed: $UPDATER_URL"
log "files:"
for file in "$UPDATE_PUBLISH_DIR"/OpenChamber-"$version"-* "$UPDATE_PUBLISH_DIR"/latest*.yml; do
  printf '  %s\n' "$(basename "$file")"
done
