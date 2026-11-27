FROM node:24-bookworm

COPY --from=oven/bun:1.4.5 /usr/local/bin/bun /usr/local/bin/bun
RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx

# hfsprogs lives in non-free and provides mkfs.hfsplus, the formatter the
# DMG step needs off macOS.
RUN sed -i 's/^Components: main$/Components: main non-free/' /etc/apt/sources.list.d/debian.sources \
  && apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    cmake \
    curl \
    file \
    g++ \
    git \
    hfsprogs \
    libbz2-dev \
    liblzma-dev \
    libssl-dev \
    make \
    pkg-config \
    zip \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

# electron-builder builds the DMG with a macOS-only dmgbuild. Its `dmg` and
# `hfsplus` tools write the same UDIF image on Linux.
ARG LIBDMG_HFSPLUS_COMMIT=e18579b391950589b9ed16ee630c54ce4319bb29
RUN git clone https://github.com/mozilla/libdmg-hfsplus.git /tmp/libdmg-hfsplus \
  && cd /tmp/libdmg-hfsplus \
  && git checkout "$LIBDMG_HFSPLUS_COMMIT" \
  && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
  && cmake --build build -j"$(nproc)" \
  && cmake --install build \
  && cd / \
  && rm -rf /tmp/libdmg-hfsplus

# arm64 macOS runs only signed code. rcodesign writes the ad-hoc signature that
# after-pack would otherwise apply with codesign on a Mac.
ARG RCODESIGN_VERSION=0.29.0
ARG RCODESIGN_SHA256=dbe85cedd8ee4217b64e9a0e4c2aef92ab8bcaaa41f20bde99781ff02e600002
RUN curl -fsSL -o /tmp/rcodesign.tar.gz \
      "https://github.com/indygreg/apple-platform-rs/releases/download/apple-codesign/${RCODESIGN_VERSION}/apple-codesign-${RCODESIGN_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
  && echo "${RCODESIGN_SHA256}  /tmp/rcodesign.tar.gz" | sha256sum -c - \
  && tar -xzf /tmp/rcodesign.tar.gz -C /tmp \
  && install -m 0755 "/tmp/apple-codesign-${RCODESIGN_VERSION}-x86_64-unknown-linux-musl/rcodesign" /usr/local/bin/rcodesign \
  && rm -rf /tmp/rcodesign.tar.gz "/tmp/apple-codesign-${RCODESIGN_VERSION}-x86_64-unknown-linux-musl"

WORKDIR /app
