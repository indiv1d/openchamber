# Fork builds

Русская версия: [README.ru.md](./README.ru.md).

This fork is built by hand. GitHub Actions are disabled in the repository
settings, and the upstream workflow files stay in the tree so an upstream merge
does not conflict on them. Desktop builds check the fork's update feed; the
Docker image and standalone server do not. The product name, `appId`, version
base and links are the same as upstream, but every installer and image is
produced from this repository.

The version follows `X.Y.Z-fork.N` and `deploy/desktop-updates.sh` sets it.
When upstream releases a new version, merge it, add the new translation keys,
and release.

## Requirements

Linux build host:

- x86_64 Linux with Docker
- Node.js 24 on the host for `deploy/desktop-updates.sh`, which writes the update manifests
- 4 vCPU, 8 GB RAM and at least 4 GB swap are recommended for a Vite build
- about 20 GB of free disk for caches, Electron downloads and artifacts

Windows builds run on Linux through wine. If the wine build fails, run
`deploy/windows.sh` on a Windows machine with Git Bash. macOS builds run on a Mac
or, without the DMG window layout and notarization, on Linux with
`deploy/macos-cross.sh`.

No code signing certificates are configured. The macOS cross-build signs the app
ad hoc; macOS and Windows artifacts are otherwise unsigned.

## Commands

Docker image:

```bash
./deploy/docker.sh
```

Linux AppImage, deb and rpm:

```bash
./deploy/linux.sh
```

Windows NSIS installer:

```bash
./deploy/windows.sh
```

macOS DMG and ZIP, on a Mac:

```bash
./deploy/macos.sh          # arm64
./deploy/macos.sh x64
```

macOS DMG and ZIP, cross-built on Linux:

```bash
./deploy/macos-cross.sh          # arm64
./deploy/macos-cross.sh x64
```

All scripts write to `dist/` by default. Set `DIST` and `IMAGE` to change the
output directory and the Docker image name.

## Artifacts

Names match upstream:

- `OpenChamber-<version>-linux-x86_64.AppImage`
- `OpenChamber-<version>-linux-amd64.deb`
- `OpenChamber-<version>-linux-x86_64.rpm`
- `OpenChamber-<version>-win-x64.exe`
- `OpenChamber-<version>-mac-arm64.dmg`
- `OpenChamber-<version>-mac-arm64.zip`
- `OpenChamber-<version>-mac-x64.dmg`
- `OpenChamber-<version>-mac-x64.zip`
- `openchamber-<version>-docker.tar.gz`

`dist/BUILD.txt` names the version, commit and build time. `dist/SHA256SUMS`
hashes every artifact.

## Installing the Docker image

The build host has no registry. Load the archive on the target machine:

```bash
docker load < openchamber-<version>-docker.tar.gz
```

Then point the service in `docker-compose.yml` at `openchamber:<version>` or
`openchamber:latest`.

## Unsigned installers

macOS blocks an app that is not notarized on first launch. Open it from the
context menu and choose Open, or remove the quarantine flag:

```bash
xattr -d com.apple.quarantine /Applications/OpenChamber.app
```

Windows SmartScreen shows a warning. Choose More info and then Run anyway.

## Updates

Desktop builds check `https://openchamber.update.indi.one/desktop/stable/`.
They never fall back to the upstream GitHub or `downloads.openchamber.dev` feeds,
so a fork install can only be replaced by another fork release. Set
`OPENCHAMBER_UPDATES_DISABLED=1` at run time to turn checks off in a build.

Versions use `X.Y.Z-fork.N`: `X.Y.Z` is the upstream version the fork is built
from, `N` counts fork builds of that base. A rebuild with the same base bumps
`N`. Never publish a version without the `-fork.N` suffix, because a later
`X.Y.Z-fork.N+1` sorts below it and installed clients never receive it. Install
the first fork build by hand, since an upstream `X.Y.Z` sorts above `X.Y.Z-fork.1`.

Release everything with:

```bash
./deploy/desktop-updates.sh
./deploy/desktop-updates.sh --version 2.8.2-fork.1
```

The script sets the version in every workspace, builds Linux, Windows and both
macOS architectures, writes `latest.yml`, `latest-linux.yml` and
`latest-mac.yml` next to the artifacts, and copies them to
`/srv/openchamber/updates/desktop/stable/`. `OPENCHAMBER_UPDATE_ROOT` changes
the root, `OPENCHAMBER_UPDATER_URL` changes the baked feed and must keep the
same path. `deploy/Caddyfile.example` serves that directory with manifests
uncached and artifacts cached forever.

`electron-updater` verifies every downloaded file against the `sha512` and size
in the manifest. The release directory also gets `SHA256SUMS` for manual checks.

macOS auto-update uses the ad-hoc signature of the cross-build. Test one real
update on a Mac before relying on it, because Squirrel may refuse a bundle that
is signed only ad hoc. When it does, macOS stays on manual DMG updates.

The Docker image and standalone server installs keep updates off through
`OPENCHAMBER_UPDATES_DISABLED=1`. Only desktop builds check for updates.

## Windows cross-build

The Linux wine path installs the normal Linux dependencies for the web build,
then reinstalls the win32 optional packages so the bundled server, ripgrep and
terminal modules match Windows. It cannot verify the packaged Windows server on
Linux. Run the script on Windows once to confirm the installer and the bundled
server, then use either path for later builds.

## macOS cross-build

`./deploy/macos-cross.sh` builds the macOS artifacts on the Linux host. The
packaging differs from `deploy/macos.sh`: `after-pack` skips `codesign`, the
bundle is signed ad hoc with `rcodesign`, and the DMG is written by
`libdmg-hfsplus` instead of `dmgbuild`.

- The ad-hoc signature lets Apple Silicon start the app. Gatekeeper still warns
  because the build is not notarized.
- The DMG holds the app and the `/Applications` link. The window background and
  icon positions of the Mac build are not applied.
- The packaged server is not started on Linux. Confirm the app and its bundled
  server on a Mac before shipping.

Build either architecture with `./deploy/macos-cross.sh arm64` or
`./deploy/macos-cross.sh x64`; the x64 artifacts use `mac-x64` in their names.
