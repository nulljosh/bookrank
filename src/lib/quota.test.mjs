import assert from 'node:assert/strict';
import { tooMany, CAPS } from './quota.js';
const store = new Map();
const cache = { match: async k => store.has(k.url) ? new Response(store.get(k.url)) : undefined, put: async (k, r) => { store.set(k.url, await r.text()); } };
const req = ip => new Request('https://x/api/ask', { headers: { 'CF-Connecting-IP': ip } });
const t = 1e12;
for (let i = 0; i < CAPS.ask; i++) assert.equal(await tooMany(req('1.1.1.1'), 'ask', cache, t), false);
assert.equal(await tooMany(req('1.1.1.1'), 'ask', cache, t), true);            // over the hour's cap
assert.equal(await tooMany(req('2.2.2.2'), 'ask', cache, t), false);           // someone else is fine
assert.equal(await tooMany(req('1.1.1.1'), 'ask', cache, t + 3.6e6), false);   // next hour starts fresh
assert.equal(await tooMany(req('1.1.1.1'), 'narrate', cache, t), false);       // caps are per route
assert.equal(await tooMany(req('1.1.1.1'), 'ask', undefined, t), false);       // no cache (node): never blocks
console.log('quota ok');
