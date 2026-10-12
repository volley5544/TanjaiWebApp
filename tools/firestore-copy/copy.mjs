#!/usr/bin/env node
// Copy Firestore collections between projects (prod → UAT) over the REST API.
//
//   node tools/firestore-copy/copy.mjs --list <alias|projectId>
//       read-only: top-level collections with document counts
//   node tools/firestore-copy/copy.mjs <from> <to> <collection...> [--dry-run]
//       copies every document of the named top-level collections (and their
//       sub-collections), keeping document ids; existing target docs with the
//       same id are overwritten, other target docs are left alone.
//
// Auth reuses the Firebase CLI login (like tools/firestore-inspect/read.mjs);
// never point this at the service-account keys in etc/secret.
// `referenceValue`s that point into the source project are rewritten to the
// target project. Only copy what the target environment needs — prod holds
// user data and credentials that must not be duplicated into UAT.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const aliases = JSON.parse(fs.readFileSync(path.join(repoRoot, '.firebaserc'), 'utf8')).projects ?? {};
const resolve = (t) => aliases[t] ?? t;

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

const base = (p) => `https://firestore.googleapis.com/v1/projects/${p}/databases/(default)/documents`;

async function api(method, url, body) {
  const res = await fetch(url, {
    method,
    headers: { Authorization: `Bearer ${accessToken()}`, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(`${method} ${url.split('/documents')[1] ?? url}: HTTP ${res.status} ${json.error?.status ?? ''}`);
  return json;
}

/** Collection ids directly under `parent` ('' = root). */
async function collectionIds(project, parent = '') {
  const ids = [];
  let pageToken;
  do {
    const r = await api('POST', `${base(project)}${parent ? '/' + parent : ''}:listCollectionIds`, { pageSize: 300, pageToken });
    ids.push(...(r.collectionIds ?? []));
    pageToken = r.nextPageToken;
  } while (pageToken);
  return ids;
}

/** All documents of a collection path (paged). */
async function documents(project, collPath) {
  const docs = [];
  let pageToken = '';
  do {
    const r = await api('GET', `${base(project)}/${collPath}?pageSize=300${pageToken ? `&pageToken=${pageToken}` : ''}`);
    docs.push(...(r.documents ?? []));
    pageToken = r.nextPageToken ?? '';
  } while (pageToken);
  return docs;
}

function rewriteRefs(value, from, to) {
  if (value == null || typeof value !== 'object') return value;
  if ('referenceValue' in value) {
    return { referenceValue: value.referenceValue.replace(`projects/${from}/`, `projects/${to}/`) };
  }
  if ('arrayValue' in value) {
    return { arrayValue: { values: (value.arrayValue.values ?? []).map((v) => rewriteRefs(v, from, to)) } };
  }
  if ('mapValue' in value) {
    const f = value.mapValue.fields ?? {};
    return { mapValue: { fields: Object.fromEntries(Object.entries(f).map(([k, v]) => [k, rewriteRefs(v, from, to)])) } };
  }
  return value;
}

async function copyCollection(from, to, collPath, dryRun, depth = 0) {
  const docs = await documents(from, collPath);
  let n = 0;
  for (const d of docs) {
    const rel = d.name.split('/documents/')[1];
    const fields = Object.fromEntries(Object.entries(d.fields ?? {}).map(([k, v]) => [k, rewriteRefs(v, from, to)]));
    if (!dryRun) await api('PATCH', `${base(to)}/${rel}`, { fields });
    n++;
    for (const sub of await collectionIds(from, rel)) {
      n += await copyCollection(from, to, `${rel}/${sub}`, dryRun, depth + 1);
    }
  }
  if (depth === 0) console.log(`${dryRun ? '[dry-run] ' : ''}${collPath}: ${n} document(s)`);
  return n;
}

const args = process.argv.slice(2);
if (args[0] === '--list') {
  const project = resolve(args[1]);
  for (const id of await collectionIds(project)) {
    const docs = await documents(project, id);
    console.log(`${project}/${id}: ${docs.length}`);
  }
} else {
  const dryRun = args.includes('--dry-run');
  const [from, to, ...collections] = args.filter((a) => a !== '--dry-run');
  if (!from || !to || !collections.length) {
    console.error('usage: copy.mjs --list <project> | copy.mjs <from> <to> <collection...> [--dry-run]');
    process.exit(2);
  }
  if (resolve(to) === 'sawad-new-ibs') {
    console.error('refusing to write into prod (sawad-new-ibs)');
    process.exit(2);
  }
  for (const c of collections) await copyCollection(resolve(from), resolve(to), c, dryRun);
}
