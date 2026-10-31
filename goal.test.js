import { weekStart, load, add, render } from './goal.js';
import assert from 'node:assert/strict';
const mem = () => { const m = new Map(); return { getItem: k => m.get(k) ?? null, setItem: (k, v) => m.set(k, v) }; };
const wed = new Date(2026, 9, 28, 15), thu = new Date(2026, 9, 29, 9), nextSun = new Date(2026, 10, 1, 9);
assert.equal(new Date(weekStart(wed)).getDay(), 0);
let s = { ...load(mem(), wed), target: 60 };
s = add(add(s, 300, wed), 600, thu);
assert.equal(s.secs, 900); assert.deepEqual(s.days, [3, 4]);
const n = add(s, 60, nextSun);   // a new week starts from zero and keeps the goal
assert.equal(n.secs, 60); assert.deepEqual(n.days, [0]); assert.equal(n.target, 60);
const el = {}; render(el, s, thu);
assert.match(el.innerHTML, /15 of 60 min/); assert.match(el.innerHTML, /class="gd on today"/);
render(el, { ...s, target: 0 }, thu); assert.doesNotMatch(el.innerHTML, /of 60 min/); assert.match(el.innerHTML, /No weekly goal/);
console.log('goal ok');

// Reading stats: books, chapters, listening minutes, highlights and notes add up across books.
{
  const { readingStats } = await import('./goal.js');
  const s = readingStats([{ content: '# A\n\nx\n\n# B\n\ny', marks: [{ ch: 0, text: 'x' }], notes: { 1: 'n', finished: '2026-10-30' } }, { content: '', marks: [], notes: {} }]);   // finished is not a note
  assert.deepEqual(s, { books: 2, chapters: 2, minutes: 1, highlights: 1, notes: 1 });
}
