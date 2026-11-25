# Fork builds

Русская версия: [README.ru.md](./README.ru.md).

This fork is built by hand. It does not use GitHub Actions and it does not check
for updates. The product name, `appId`, version and links are the same as
upstream, but every installer and image is produced from this repository.

The version is read from `package.json` and is not changed here. When upstream
releases a new version, merge it, add the new translation keys, and rebuild.

## Requirements

Linux build host:

- x86_64 Linux with Docker
- 4 vCPU, 8 GB RAM and at least 4 GB swap are recommended for a Vite build
- about 20 GB of free disk for caches, Electron downloads and artifacts

Windows builds run on Linux through wine. If the wine build fails, run
`deploy/windows.sh` on a Windows machine with Git Bash. macOS builds run on a Mac.

No code signing certificates are configured. macOS and Windows artifacts are
unsigned.

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

All scripts write to `dist/` by default. Set `DIST` and `IMAGE` to change the
output directory and the Docker image name.

## Artifacts

Names match upstream:

- `OpenChamber-<version>-linux-x64.AppImage`
- `OpenChamber-<version>-linux-amd64.deb`
- `OpenChamber-<version>-linux-x86_64.rpm`
- `OpenChamber-<version>-win-x64.exe`
- `OpenChamber-<version>-mac-arm64.dmg`
- `OpenChamber-<version>-mac-arm64.zip`
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

macOS blocks an unsigned app on first launch. Open it from the context menu and
choose Open, or remove the quarantine flag:

```bash
xattr -d com.apple.quarantine /Applications/OpenChamber.app
```

Windows SmartScreen shows a warning. Choose More info and then Run anyway.

## Updates are off

The Docker image sets `OPENCHAMBER_UPDATES_DISABLED=1`. The desktop app sets the
same variable before it starts its server, and the desktop updater is not
started. The About page hides the update controls.

To enable updates in a source checkout only, set `OPENCHAMBER_UPDATES_DISABLED=0`
before starting the server. Shipped builds stay off.

## Windows cross-build

The Linux wine path installs the normal Linux dependencies for the web build,
then reinstalls the win32 optional packages so the bundled server, ripgrep and
terminal modules match Windows. It cannot verify the packaged Windows server on
Linux. Run the script on Windows once to confirm the installer and the bundled
server, then use either path for later builds.
