import { createHash } from 'node:crypto';
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const MAC_MINIMUM_DARWIN_VERSION = '22.0.0';

const ARTIFACTS = {
  windows: /-win-x64\.exe$/,
  linuxAppImage: /-linux-(?:x64|x86_64)\.AppImage$/,
  linuxDeb: /-linux-amd64\.deb$/,
  linuxRpm: /-linux-x86_64\.rpm$/,
  macArm64: /-mac-arm64\.zip$/,
  macX64: /-mac-x64\.zip$/,
};

const sha512 = async (file) => {
  const hash = createHash('sha512');
  for await (const chunk of fs.createReadStream(file)) hash.update(chunk);
  return hash.digest('base64');
};

const blockMapSize = async (file) => {
  try {
    return (await fsp.stat(`${file}.blockmap`)).size;
  } catch {
    return null;
  }
};

const fileEntry = async (file) => {
  const entry = {
    url: path.basename(file),
    sha512: await sha512(file),
    size: (await fsp.stat(file)).size,
  };
  const blockMap = await blockMapSize(file);
  if (blockMap !== null) entry.blockMapSize = blockMap;
  return entry;
};

const serialize = ({ version, files, minimumSystemVersion, releaseDate }) => {
  const lines = [`version: ${version}`];
  if (minimumSystemVersion) lines.push(`minimumSystemVersion: ${minimumSystemVersion}`);
  lines.push('files:');
  for (const file of files) {
    lines.push(`  - url: ${file.url}`);
    lines.push(`    sha512: ${file.sha512}`);
    lines.push(`    size: ${file.size}`);
    if (file.blockMapSize !== undefined) lines.push(`    blockMapSize: ${file.blockMapSize}`);
  }
  lines.push(`releaseDate: '${releaseDate}'`);
  return `${lines.join('\n')}\n`;
};

const find = (files, pattern, label) => {
  const file = files.find((name) => pattern.test(name));
  if (!file) throw new Error(`Missing ${label} artifact in the build output`);
  return file;
};

export const writeUpdateManifests = async ({ dist, out, version }) => {
  if (!/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/.test(version)) {
    throw new Error(`Unsupported version ${JSON.stringify(version)}`);
  }
  const names = (await fsp.readdir(dist)).filter((name) => name.startsWith(`OpenChamber-${version}-`));
  if (names.length === 0) throw new Error(`No artifacts for version ${version} in ${dist}`);

  const at = (pattern, label) => path.join(dist, find(names, pattern, label));
  const releaseDate = new Date().toISOString();
  const manifests = {
    'latest.yml': serialize({
      version,
      files: [await fileEntry(at(ARTIFACTS.windows, 'Windows x64'))],
      releaseDate,
    }),
    'latest-linux.yml': serialize({
      version,
      files: [
        await fileEntry(at(ARTIFACTS.linuxAppImage, 'Linux AppImage')),
        await fileEntry(at(ARTIFACTS.linuxDeb, 'Linux deb')),
        await fileEntry(at(ARTIFACTS.linuxRpm, 'Linux rpm')),
      ],
      releaseDate,
    }),
    'latest-mac.yml': serialize({
      version,
      minimumSystemVersion: MAC_MINIMUM_DARWIN_VERSION,
      files: [
        await fileEntry(at(ARTIFACTS.macArm64, 'macOS arm64')),
        await fileEntry(at(ARTIFACTS.macX64, 'macOS x64')),
      ],
      releaseDate,
    }),
  };

  await fsp.mkdir(out, { recursive: true });
  for (const [name, content] of Object.entries(manifests)) {
    await fsp.writeFile(path.join(out, name), content);
  }
  return Object.keys(manifests);
};

const readArgument = (argv, name) => {
  const index = argv.indexOf(name);
  return index >= 0 ? argv[index + 1] : undefined;
};

const main = async () => {
  const argv = process.argv.slice(2);
  const dist = path.resolve(readArgument(argv, '--dist') || path.join(import.meta.dirname, '..', 'dist'));
  const out = readArgument(argv, '--out');
  const version = readArgument(argv, '--version');
  if (!out || !version) {
    console.error('usage: write-update-manifests.mjs --dist <dir> --out <dir> --version <version>');
    process.exit(2);
  }
  const written = await writeUpdateManifests({ dist, out: path.resolve(out), version });
  console.log(`[electron] wrote ${written.join(', ')} for ${version}`);
};

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}
