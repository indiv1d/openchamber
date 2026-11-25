FROM node:24-bookworm

COPY --from=oven/bun:1.4.5 /usr/local/bin/bun /usr/local/bin/bun
RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx

RUN dpkg --add-architecture i386 \
  && apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    dpkg \
    fakeroot \
    file \
    g++ \
    git \
    libarchive-tools \
    make \
    mono-complete \
    pkg-config \
    python3 \
    rpm \
    wine \
    wine32 \
    wine64 \
    xvfb \
    xz-utils \
  && rm -rf /var/lib/apt/lists/*

ENV WINEDEBUG=-all
WORKDIR /app
