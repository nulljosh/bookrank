import assert from 'node:assert/strict';
import { score, CASES } from './narrate-eval.mjs';
const notes = '# Two\n\nThe habit loop has four parts: cue, craving, response and reward, and each one can be designed on purpose by you.';
const good = Array.from({ length: 12 }, (_, i) => `Idea ${i + 1} matters because small steps add up. Think of a savings account growing.`);
const opts = { ch: 1, total: 5 };
assert.equal(score(good, notes, opts).pass, true);
assert.equal(score(good.slice(0, 5), notes, opts).checks.length, false);                       // too short
assert.equal(score(['Welcome back to the book!', ...good.slice(1)], notes, opts).checks.opening, false); // hello mid-book
assert.equal(score(['Welcome to the book!', ...good.slice(1)], notes, { ch: 0, total: 5 }).checks.opening, true);
assert.equal(score(['## Heading', ...good.slice(1)], notes, opts).checks.noMarkdown, false);
const parrot = [...good.slice(1), 'The habit loop has four parts: cue, craving, response and reward, and each one can be designed on purpose by you.'];
assert.ok(score(parrot, notes, opts).copied > 0);                                                // read-back is measured
assert.equal(score(good, notes, { ch: 4, total: 5 }).checks.closing, false);                     // last chapter must close
assert.equal(score([...good.slice(1), 'The one thing to remember: design the loop.'], notes, { ch: 4, total: 5 }).checks.closing, true);
assert.equal(score(good, notes, { ...opts, lang: 'fr' }).checks.language, false);               // English when French was asked
assert.ok(CASES.length >= 9 && CASES.some(c => c.lang === 'de'));
