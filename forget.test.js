import assert from 'node:assert/strict';
import { forgetKeys } from './functions/api/forget.js';
import { sha, DEFAULTS } from './functions/api/speak.js';
const kv = ['d:u:me:2026-10-29', 'um:u:me:2026-10', 'd:u:other:2026-10-29', 'aura:d:u:me:2026-10-29'];
const list = async p => kv.filter(k => k.startsWith(p));
const rows = [{ listen: { chapters: { 0: [{ host: 'A', line: 'Hello there.' }], 1: [{ host: 'A', line: 'Hello there.' }] } } }, { listen: null }];
const keys = await forgetKeys('me', rows, {}, list);
assert.ok(keys.includes('paid:me') && keys.includes('d:u:me:2026-10-29') && keys.includes('um:u:me:2026-10') && keys.includes('aura:d:u:me:2026-10-29'));
assert.ok(!keys.some(k => k.includes('other')));   // never another account's counters
assert.ok(keys.includes(`a:${await sha(`eleven_flash_v2_5|${DEFAULTS.A}|Hello there.`)}`));   // the stored line, once per voice
assert.equal(keys.filter(k => k.startsWith('a:')).length, 3);   // one line (deduped) x two voices, plus Aura
console.log('forget ok');
