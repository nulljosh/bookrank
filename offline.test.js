// The web library keeps every list and summary it loads, and serves that copy when the network fails.
// Runs the real block from library.html against a fake db and a fake Cache Storage.
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
const src = readFileSync('library.html', 'utf8');
const block = src.slice(src.indexOf('const offline = {'), src.indexOf('const rows = {'));
const store = new Map();
globalThis.caches = { open: async () => ({ put: async (k, r) => { store.set(k, await r.text()); }, match: async k => store.has(k) ? new Response(store.get(k)) : undefined }) };
let uid = 'u1';
const db = { auth: { getSession: async () => ({ data: { session: uid ? { user: { id: uid } } : null } }) } };
const { cached } = new Function('db', `${block}; return { cached };`)(db);
let online = true;
const q = data => async () => online ? { data, error: null } : { data: null, error: new Error('Failed to fetch') };
const settle = () => new Promise(r => setTimeout(r, 10));

assert.deepEqual((await cached('list', q([{ id: 1 }]))).data, [{ id: 1 }]);          // online: passes through and remembers
await settle();
online = false;
const off = await cached('list', q(null));
assert.deepEqual(off.data, [{ id: 1 }]); assert.equal(off.offline, true);            // offline: serves the last copy
assert.ok((await cached('never-opened', q(null))).error);                            // never seen: the real error surfaces
uid = 'u2';
assert.ok((await cached('list', q(null))).error);                                    // another account never sees u1's copy

// An expired token with no network keeps the session (so the kept copies above stay reachable); a refused refresh signs out.
const { createClient } = await import('./spark.js');
const jwt = '.' + Buffer.from(JSON.stringify({ exp: 1 })).toString('base64url') + '.';
const mem = () => { const m = { 'spark.session': JSON.stringify({ access_token: jwt, refresh_token: 'r', user: { id: 'u1' } }) }; return { getItem: k => m[k] ?? null, setItem: (k, v) => { m[k] = v; }, removeItem: k => { delete m[k]; } }; };
globalThis.fetch = async () => { throw new TypeError('Failed to fetch'); };
assert.equal((await createClient('https://x', '', { storage: mem() }).auth.getSession()).data.session?.user.id, 'u1');
globalThis.fetch = async () => new Response('{"error":"bad refresh token"}', { status: 401 });
assert.equal((await createClient('https://x', '', { storage: mem() }).auth.getSession()).data.session, null);
console.log('offline ok');
