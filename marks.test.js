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
