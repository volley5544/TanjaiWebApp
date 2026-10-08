#!/usr/bin/env node
// Read-only Firestore inspector (GET only — never writes).
//
//   node tools/firestore-inspect/read.mjs <alias|projectId> <collection> [--show f1,f2] [--limit N]
//
// Auth reuses the Firebase CLI login (same approach as sawadLoanUniversal's
// tools/firestore-import): the CLI's cloud-platform access token is read from
// ~/.config/configstore/firebase-tools.json and refreshed by shelling out to
// the CLI when near expiry. No service-account key is needed — never point
// this at the keys in etc/secret.
//
// Field VALUES are masked unless named in --show, so config collections that
// hold credentials don't get printed by accident.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const args = process.argv.slice(2);
const flag = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args.splice(i, 2)[1] : undefined;
};
const show = (flag('--show') ?? '').split(',').filter(Boolean);
const limit = Number(flag('--limit') ?? 20);
const [target, collection] = args;
if (!target || !collection) {
  console.error('usage: read.mjs <alias|projectId> <collection> [--show f1,f2] [--limit N]');
  process.exit(2);
}

const aliases = JSON.parse(fs.readFileSync(path.join(repoRoot, '.firebaserc'), 'utf8')).projects ?? {};
const project = aliases[target] ?? target;

function readCliTokens() {
  const file = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const tokens = JSON.parse(fs.readFileSync(file, 'utf8')).tokens;
  if (!tokens?.access_token) throw new Error('Run "firebase login" first.');
  return tokens;
}

function accessToken() {
  let tokens = readCliTokens();
  if ((tokens.expires_at ?? 0) - Date.now() < 120_000) {
    execFileSync('firebase', ['projects:list', '--json'], { stdio: 'ignore' });
    tokens = readCliTokens();
  }
  return tokens.access_token;
}

// Firestore typed value -> plain JS.
function plain(v) {
  if (v == null) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('nullValue' in v) return null;
  if ('timestampValue' in v) return v.timestampValue;
  if ('referenceValue' in v) return v.referenceValue.split('/documents/')[1];
  if ('arrayValue' in v) return (v.arrayValue.values ?? []).map(plain);
  if ('mapValue' in v) {
    return Object.fromEntries(Object.entries(v.mapValue.fields ?? {}).map(([k, x]) => [k, plain(x)]));
  }
  return '?';
}

function typeOf(v) {
  return Object.keys(v ?? {})[0]?.replace('Value', '') ?? '?';
}

const url =
  `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/` +
  `${collection}?pageSize=${limit}`;
const res = await fetch(url, { headers: { Authorization: `Bearer ${accessToken()}` } });
const body = await res.json();
if (!res.ok) {
  console.log(`${project}/${collection}: HTTP ${res.status} ${body.error?.status ?? ''}`);
  process.exit(1);
}
const docs = body.documents ?? [];
if (!docs.length) console.log(`${project}/${collection}: (empty)`);
for (const d of docs) {
  const out = {};
  for (const [k, v] of Object.entries(d.fields ?? {})) {
    out[k] = show.includes(k) ? plain(v) : `<${typeOf(v)}>`;
  }
  console.log(`${project}/${d.name.split('/documents/')[1]}`, JSON.stringify(out));
}
