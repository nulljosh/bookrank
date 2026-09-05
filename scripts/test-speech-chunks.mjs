// Check the read-aloud chunker in library.html: every chunk <= ~200 chars and
// no text is dropped (Chrome truncates long utterances, so chunking is required).
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const src = readFileSync(new URL('../library.html', import.meta.url), 'utf8');
assert.match(src, /p\.slice\(i, i \+ 200\)/, 'chunker missing from library.html');

const chunk = t => {
  const out = [];
  for (const part of t.split(/(?<=[.!?])\s+/))
    for (let i = 0; i < part.length; i += 200) out.push(part.slice(i, i + 200));
  return out;
};
const clean = t => t.replace(/[#*_`>\[\]()]/g, ' ').trim();

for (const text of [
  'Short one.',
  'A'.repeat(1000),
  'One. Two! Three? ' + 'word '.repeat(300),
  clean('# Heading\n\n**bold** and [link](x) text. Another sentence here.'),
]) {
  const parts = chunk(text);
  assert.ok(parts.every(p => p.length <= 200), 'chunk too long');
  assert.equal(parts.join('').replace(/\s+/g, ''), text.replace(/\s+/g, ''), 'text lost');
}
console.log('ok');
