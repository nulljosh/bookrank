// The read-aloud chunker (listen.js): every chunk <= 200 chars, no text dropped, offsets
// point back into the line (Chrome truncates long utterances, so chunking is required).
import assert from 'node:assert/strict';
import { chunk, plain } from '../listen.js';

for (const text of [
  'Short one.',
  'A'.repeat(1000),
  'One. Two! Three? ' + 'word '.repeat(300),
  plain('# Heading\n\n**bold** and [link](x) text. Another sentence here.'),
]) {
  const parts = chunk(text);
  assert.ok(parts.every(p => p.text.length <= 200), 'chunk too long');
  assert.equal(parts.map(p => p.text).join('').replace(/\s+/g, ''), text.replace(/\s+/g, ''), 'text lost');
  assert.ok(parts.every(p => text.slice(p.offset, p.offset + p.text.length) === p.text), 'offset drift');
}
console.log('ok');
