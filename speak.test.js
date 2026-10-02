import { words } from './functions/api/speak.js';
import assert from 'node:assert/strict';
const text = 'Hi there you';
const al = { characters: [...text], character_start_times_seconds: [...text].map((_, i) => i * 0.1) };
assert.deepEqual(words(text, al), [{ i: 0, n: 2, t: 0 }, { i: 3, n: 5, t: 0.30000000000000004 }, { i: 9, n: 3, t: 0.9 }]);
assert.deepEqual(words(text, null), []);
console.log('speak ok');
