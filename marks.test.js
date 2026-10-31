import { mergeMarks } from './marks.js';
import assert from 'node:assert/strict';
const m = (ch, text) => ({ ch, text });
const a = m(0, 'a'), b = m(0, 'b'), c = m(1, 'c'), d = m(2, 'd');
// Phone added c, laptop (base [a, b]) adds d: both stay.
assert.deepEqual(mergeMarks([a, b], [a, b, d], [a, b, c]), [a, b, d, c]);
// Phone removed b; the laptop still holds it from before and saves: b stays gone.
assert.deepEqual(mergeMarks([a, b], [a, b], [a]), [a]);
// This device removed a: the row's old copy does not bring it back.
assert.deepEqual(mergeMarks([a, b], [b], [a, b]), [b]);
// Both added the same line: once.
assert.deepEqual(mergeMarks([], [c], [c]), [c]);
// Same text in another chapter is another highlight.
assert.deepEqual(mergeMarks([], [m(0, 'c')], [c]), [m(0, 'c'), c]);
console.log('marks ok');

// Export: a section per book, chapter titles, quotes in chapter order.
const { marksMarkdown } = await import('./marks.js');
{
  const md = marksMarkdown([
    { title: 'Book A', content: '# One\n\nx\n\n# Two\n\ny', marks: [{ ch: 1, text: 'later line' }, { ch: 0, text: 'first line' }] },
    { title: 'No marks', content: '', marks: [] },
    { title: 'Note only', content: '# Only\n\nz', marks: [], notes: { 0: 'My own thought.', finished: '2026-10-30' } },   // finished is not a chapter
  ]);
  assert.equal(md, '# Highlights\n\n## Book A\n\n### One\n\n> first line\n\n### Two\n\n> later line\n\n## Note only\n\n### Only\n\nMy own thought.\n');
}

// Today's five: same day, same five; another day, another order; never more than five.
{
  const { dailyFive } = await import('./marks.js');
  const all = Array.from({ length: 12 }, (_, i) => m(0, `line ${i}`));
  const a = dailyFive(all, '2026-10-28'), b = dailyFive([...all].reverse(), '2026-10-28');
  assert.equal(a.length, 5); assert.deepEqual(a, b);
  assert.notDeepEqual(dailyFive(all, '2026-10-29'), a);
  assert.deepEqual(dailyFive(all.slice(0, 2), '2026-10-28').length, 2);
  // Pinned: the apps' dailyFive (HighlightsView.swift) must give this same list.
  assert.deepEqual(a.map(x => x.text), ['line 11', 'line 10', 'line 8', 'line 9', 'line 6']);
}

import { catchUp } from './marks.js';
{
  const q = { listen: { for: 'v1', pos: { ch: 2, line: 0, at: 1000 }, marks: [{ ch: 0, text: 'a' }] }, updated_at: 'v1' };
  const later = catchUp(q, { for: 'v1', pos: { ch: 5, line: 3, at: 2000 }, marks: [{ ch: 1, text: 'b' }] });
  assert.deepEqual(later.listen.pos, { ch: 5, line: 3, at: 2000 });   // the other device got further, later
  assert.equal(later.listen.marks.length, 2);                          // both highlights stay
  assert.deepEqual(catchUp(q, { for: 'v1', pos: { ch: 1, line: 0, at: 500 } }).listen.pos.ch, 2);   // ours is newer
  assert.deepEqual(catchUp(q, { for: 'v0', pos: { ch: 9, at: 9999 } }), q);   // the text changed since: leave it
  assert.deepEqual(catchUp({ cover: 'x' }, { for: 'v1' }), { cover: 'x' });
  console.log('catchUp ok');
}
