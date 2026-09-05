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
