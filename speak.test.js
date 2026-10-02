import { words, spend, pickModel } from './functions/api/speak.js';
import { sigOk } from './functions/api/stripe-webhook.js';
import assert from 'node:assert/strict';
const text = 'Hi there you';
const al = { characters: [...text], character_start_times_seconds: [...text].map((_, i) => i * 0.1) };
assert.deepEqual(words(text, al), [{ i: 0, n: 2, t: 0 }, { i: 3, n: 5, t: 0.30000000000000004 }, { i: 9, n: 3, t: 0.9 }]);
assert.deepEqual(words(text, null), []);
const kv = (() => { const m = new Map(); return { get: async k => m.get(k) ?? null, put: async (k, v) => { m.set(k, v); } }; })();
const caps = { month: 100, day: 40 }, day1 = new Date('2026-10-02T12:00:00Z'), day2 = new Date('2026-10-03T12:00:00Z');
assert.equal(await spend(null, 'u:a', 999, caps, day1), null);        // no KV: never blocks
assert.equal(await spend(kv, 'u:a', 30, caps, day1), null);
assert.equal(await spend(kv, 'u:a', 20, caps, day1), 'day');            // 50 > the day's 40
assert.equal(await spend(kv, 'u:b', 40, caps, day1), null);             // another account has its own day
assert.equal(await spend(kv, 'u:c', 31, caps, day1), 'month');          // 30+40+31 > 100 for the app
assert.equal(await spend(kv, 'u:a', 30, caps, day2), null);             // a new day resets the account
assert.equal(pickModel({}, 0), 'eleven_flash_v2_5');
assert.equal(pickModel({ TTS_MODEL_BEST: 'best' }, 0), 'best');
assert.equal(pickModel({ TTS_MODEL_BEST: 'best' }, 3), 'eleven_flash_v2_5');
const sign = async (body, secret, t) => { const k = await crypto.subtle.importKey('raw', new TextEncoder().encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']); return [...new Uint8Array(await crypto.subtle.sign('HMAC', k, new TextEncoder().encode(`${t}.${body}`)))].map(b => b.toString(16).padStart(2, '0')).join(''); };
const mac = await sign('{}', 'whsec_x', 1000);
assert.equal(await sigOk('{}', `t=1000,v1=${mac}`, 'whsec_x', 1100), true);   // good signature
assert.equal(await sigOk('{"a":1}', `t=1000,v1=${mac}`, 'whsec_x', 1100), false); // body changed
assert.equal(await sigOk('{}', `t=1000,v1=${mac}`, 'whsec_y', 1100), false);  // wrong secret
assert.equal(await sigOk('{}', `t=1000,v1=${mac}`, 'whsec_x', 2000), false);  // stale
assert.equal(await sigOk('{}', '', 'whsec_x', 1100), false);                  // no header
console.log('speak ok');
