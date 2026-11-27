import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

import { writeUpdateManifests } from './write-update-manifests.mjs';

const VERSION = '2.8.1-fork.2';

const makeArtifacts = () => {
  const dist = fs.mkdtempSync(path.join(os.tmpdir(), 'oc-manifests-dist-'));
  const out = fs.mkdtempSync(path.join(os.tmpdir(), 'oc-manifests-out-'));
  const files = {
    'OpenChamber-2.8.1-fork.2-win-x64.exe': 'windows',
    'OpenChamber-2.8.1-fork.2-linux-x86_64.AppImage': 'appimage',
    'OpenChamber-2.8.1-fork.2-linux-amd64.deb': 'deb',
    'OpenChamber-2.8.1-fork.2-linux-x86_64.rpm': 'rpm',
    'OpenChamber-2.8.1-fork.2-mac-arm64.zip': 'mac arm',
    'OpenChamber-2.8.1-fork.2-mac-x64.zip': 'mac intel',
  };
  for (const [name, content] of Object.entries(files)) {
    fs.writeFileSync(path.join(dist, name), content);
  }
  fs.writeFileSync(path.join(dist, 'OpenChamber-2.8.1-fork.2-win-x64.exe.blockmap'), 'blockmap');
  return { dist, out, files };
};

const digest = (content) => createHash('sha512').update(content).digest('base64');

const entryFor = (manifest, url) => {
  const lines = manifest.split('\n');
  const start = lines.findIndex((line) => line.trim() === `- url: ${url}`);
  assert.ok(start >= 0, `${url} is missing from the manifest`);
  const entry = {};
  for (const line of lines.slice(start + 1)) {
    const match = /^\s{4}(\w+): (.*)$/.exec(line);
    if (!match) break;
    entry[match[1]] = match[2];
  }
  return entry;
};

test('writes Windows, Linux and macOS manifests from the release artifacts', async () => {
  const { dist, out, files } = makeArtifacts();
  try {
    const written = await writeUpdateManifests({ dist, out, version: VERSION });
    assert.deepEqual(written.sort(), ['latest-linux.yml', 'latest-mac.yml', 'latest.yml']);

    const windows = fs.readFileSync(path.join(out, 'latest.yml'), 'utf8');
    assert.match(windows, new RegExp(`^version: ${VERSION}$`, 'm'));
    assert.equal(entryFor(windows, 'OpenChamber-2.8.1-fork.2-win-x64.exe').sha512, digest(files['OpenChamber-2.8.1-fork.2-win-x64.exe']));
    assert.equal(entryFor(windows, 'OpenChamber-2.8.1-fork.2-win-x64.exe').blockMapSize, '8');

    const linux = fs.readFileSync(path.join(out, 'latest-linux.yml'), 'utf8');
    for (const name of ['OpenChamber-2.8.1-fork.2-linux-x86_64.AppImage', 'OpenChamber-2.8.1-fork.2-linux-amd64.deb', 'OpenChamber-2.8.1-fork.2-linux-x86_64.rpm']) {
      assert.equal(entryFor(linux, name).size, String(files[name].length));
    }

    const mac = fs.readFileSync(path.join(out, 'latest-mac.yml'), 'utf8');
    assert.match(mac, /^minimumSystemVersion: 22\.0\.0$/m);
    assert.equal(entryFor(mac, 'OpenChamber-2.8.1-fork.2-mac-arm64.zip').sha512, digest(files['OpenChamber-2.8.1-fork.2-mac-arm64.zip']));
    assert.equal(entryFor(mac, 'OpenChamber-2.8.1-fork.2-mac-x64.zip').sha512, digest(files['OpenChamber-2.8.1-fork.2-mac-x64.zip']));
  } finally {
    fs.rmSync(dist, { recursive: true, force: true });
    fs.rmSync(out, { recursive: true, force: true });
  }
});

test('refuses a release with a missing platform artifact', async () => {
  const { dist, out } = makeArtifacts();
  try {
    fs.rmSync(path.join(dist, 'OpenChamber-2.8.1-fork.2-mac-x64.zip'));
    await assert.rejects(
      () => writeUpdateManifests({ dist, out, version: VERSION }),
      /Missing macOS x64 artifact/,
    );
  } finally {
    fs.rmSync(dist, { recursive: true, force: true });
    fs.rmSync(out, { recursive: true, force: true });
  }
});

test('refuses a version the updater cannot parse', async () => {
  const { dist, out } = makeArtifacts();
  try {
    await assert.rejects(
      () => writeUpdateManifests({ dist, out, version: '2.8.1.2' }),
      /Unsupported version/,
    );
  } finally {
    fs.rmSync(dist, { recursive: true, force: true });
    fs.rmSync(out, { recursive: true, force: true });
  }
});
