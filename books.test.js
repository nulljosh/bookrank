// node --test — books.json drives rankings.html and library.html. Nothing validates it at
// load time, so a duplicated rank or a missing title renders a broken row rather than
// erroring. ponytail: data integrity only; the pages are static HTML with no logic to test.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const books = require('./books.json');

const SECTIONS = ['ranked', 'recent', 'toRead', 'summary', 'pick'];
const ranked = books.filter(b => b.section === 'ranked');

test('the shelf is non-empty', () => {
  assert.ok(Array.isArray(books));
  assert.ok(books.length > 0);
});

test('every book has the fields the pages read', () => {
  for (const b of books) {
    assert.ok(b.title, 'a book is missing its title');
    assert.ok(SECTIONS.includes(b.section), `"${b.title}" has unknown section "${b.section}"`);
    // `pick` rows are pointers to a book listed in full elsewhere, so they carry no author.
    if (b.section !== 'pick') assert.ok(b.author, `"${b.title}" is missing its author`);
  }
});

test('picks are a self-contained, densely numbered list', () => {
  // rankings.html renders picks as their own list of title + notes — they do NOT have to
  // exist elsewhere on the shelf, and two of the five deliberately do not. What they do
  // need is the blurb that justifies the pick, and a gapless number for .pick-num.
  const picks = books.filter(b => b.section === 'pick');
  for (const b of picks) assert.ok(b.blurb, `pick "${b.title}" has no blurb explaining it`);
  const nums = picks.map(b => b.rank).sort((a, x) => a - x);
  assert.deepEqual(nums, Array.from({ length: picks.length }, (_, i) => i + 1));
});

test('ranks are a dense 1..N with no gaps or duplicates', () => {
  // rankings.html sorts and prints these straight out. A gap or a repeat is invisible in
  // the markup but wrong on the page, and it is the thing that actually drifts when a
  // book is inserted by hand.
  const ranks = ranked.map(b => b.rank).sort((a, x) => a - x);
  assert.deepEqual(ranks, Array.from({ length: ranked.length }, (_, i) => i + 1));
});

test('ratings are on Goodreads scale', () => {
  for (const b of books) {
    if (b.rating == null) continue;
    assert.ok(b.rating > 0 && b.rating <= 5, `"${b.title}" has rating ${b.rating}`);
  }
});

test('no book appears twice within one section', () => {
  // Across sections is fine and intentional — a ranked book is often also a pick, and a
  // recent read is often also a summary. Twice inside ONE section is always a mistake:
  // it is how "Cracking the Coding Interview" ended up at both rank 16 and rank 98.
  for (const section of SECTIONS) {
    const titles = books.filter(b => b.section === section).map(b => b.title);
    assert.equal(new Set(titles).size, titles.length, `a book is listed twice in "${section}"`);
  }
});
