import { parseScript } from './functions/api/narrate.js';
import assert from 'node:assert/strict';
const s = parseScript('Intro junk\nA: Hello there.\n**B:** Why does it matter?\nB : because.\n');
assert.deepEqual(s, [
  { host: 'A', line: 'Hello there.' },
  { host: 'B', line: 'Why does it matter?' },
  { host: 'B', line: 'because.' },
]);
assert.deepEqual(parseScript(''), []);
console.log('narrate ok');
import { messages } from './functions/api/narrate.js';
const sys = (ch, total) => messages('T', 'x', ch, total)[0].content;
assert.match(sys(0, 3), /chapter 1 of 3.*introducing/);
assert.match(sys(1, 3), /no greeting/i);
assert.doesNotMatch(sys(1, 3), /introducing the book/);
assert.match(sys(2, 3), /last chapter.*one thing to remember/);
assert.match(sys(0, 1), /Open briefly/);
console.log('prompt ok');
