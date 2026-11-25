#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

require docker
check_memory
version="$(check_versions)"
mkdir -p "$DIST"

log "building $IMAGE:$version and $IMAGE:latest"
DOCKER_BUILDKIT=1 docker build -t "$IMAGE:$version" -t "$IMAGE:latest" "$ROOT"

log "saving the image"
docker save "$IMAGE:$version" | gzip -9 > "$DIST/openchamber-$version-docker.tar.gz"

write_build_info "$version"
write_hashes
log "done: $DIST"
