#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${DIST:-$ROOT/dist}"
IMAGE="${IMAGE:-openchamber}"
UPDATER_URL="${OPENCHAMBER_UPDATER_URL:-https://openchamber.update.indi.one/desktop/stable/}"
UPDATE_ROOT="${OPENCHAMBER_UPDATE_ROOT:-/srv/openchamber/updates}"
UPDATE_PUBLISH_DIR="${OPENCHAMBER_UPDATE_PUBLISH_DIR:-$UPDATE_ROOT/desktop/stable}"

log() {
  printf '[deploy] %s\n' "$*"
}

die() {
  printf '[deploy] error: %s\n' "$*" >&2
  exit 1
}

require() {
  command -v "$1" >/dev/null 2>&1 || die "missing $1"
}

read_version() {
  sed -n 's/^[[:space:]]*"version": "\([^"]*\)".*/\1/p' "$1" | head -n 1
}

check_versions() {
  local expected
  expected="$(read_version "$ROOT/package.json")"
  [ -n "$expected" ] || die "cannot read the version from package.json"
  local file actual
  for file in packages/ui/package.json packages/web/package.json packages/electron/package.json packages/vscode/package.json packages/sdk/package.json; do
    [ -f "$ROOT/$file" ] || continue
    actual="$(read_version "$ROOT/$file")"
    [ "$actual" = "$expected" ] || die "$file has version $actual, expected $expected"
  done
  printf '%s' "$expected"
}

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1"
  else
    shasum -a 256 "$1"
  fi
}

write_build_info() {
  local version="$1"
  local commit
  commit="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || printf 'unknown')"
  mkdir -p "$DIST"
  {
    printf 'version: %s\n' "$version"
    printf 'commit: %s\n' "$commit"
    printf 'built: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'updates: disabled\n'
  } > "$DIST/BUILD.txt"
}

write_hashes() {
  mkdir -p "$DIST"
  (
    cd "$DIST"
    for file in *; do
      [ "$file" = "SHA256SUMS" ] && continue
      [ -f "$file" ] || continue
      hash_file "$file"
    done > SHA256SUMS
  )
}

collect_patterns() {
  local pattern
  for pattern in "$@"; do
    find "$ROOT/packages/electron/dist" -maxdepth 1 -type f -name "$pattern" -exec cp -f {} "$DIST/" \;
  done
}

builder_image() {
  local dockerfile="$1"
  local tag="$2"
  docker build -f "$ROOT/deploy/$dockerfile" -t "$tag" "$ROOT/deploy"
}

check_memory() {
  [ -r /proc/meminfo ] || return 0
  local total
  total="$(awk '/^MemTotal:/{m=$2} /^SwapTotal:/{s=$2} END{print m+s+0}' /proc/meminfo)"
  if [ "${total:-0}" -lt 10000000 ]; then
    log "warning: $((total / 1024 / 1024)) GB RAM plus swap; the web build may need 10 GB. Add swap before building."
  fi
}
