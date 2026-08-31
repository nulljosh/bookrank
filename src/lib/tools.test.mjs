// One runnable check for the filtering, pagination and title resolution — the only real
// logic here. books.json's own integrity is covered by books.test.js.
import assert from 'node:assert/strict';
import { callTool, ToolError, SECTIONS } from './tools.js';

const s = callTool('list_sections');
assert.equal(s.sections.reduce((n, x) => n + x.count, 0), s.total);

const page = callTool('list_books', { section: 'ranked', limit: 5, offset: 2 });
assert.equal(page.results.length, 5);
assert.equal(page.results[0].title, callTool('list_books', { section: 'ranked', limit: 3 }).results[2].title);

// Every row is the same shape, including `pick` rows that carry no author of their own.
for (const b of callTool('list_books', { limit: 100 }).results) {
  assert.ok('author' in b && 'rank' in b && Array.isArray(b.badges));
}

const one = callTool('get_book', { title: page.results[0].title });
assert.equal(one.title, page.results[0].title);
assert.ok(callTool('search_books', { q: one.title }).total >= 1);

assert.throws(() => callTool('list_books', { section: 'nope' }), ToolError);
assert.throws(() => callTool('list_books', { offset: -1 }), ToolError);
assert.throws(() => callTool('search_books', { q: '' }), ToolError);
assert.throws(() => callTool('get_book', { title: 'zzzzz no such book' }), ToolError);
assert.ok(SECTIONS.includes('ranked'));
assert.equal(callTool('nope'), null);

console.log('tools: ok');
