import './goodreads-parse.js';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
const { shelf, status, day } = globalThis.GR;

// Archived public pages (goodreads.com, 2025), trimmed to a few rows.
const rows = shelf(readFileSync(new URL('./test/fixtures/goodreads/shelf.html', import.meta.url), 'utf8'));
assert.equal(rows.length, 3);
assert.deepEqual(rows[0], {
  id: '7759341668', bookId: '6305619', title: 'Use of Weapons', author: 'Iain M. Banks',
  cover: 'https://i.gr-assets.com/images/S/compressed.photo.goodreads.com/books/1624577523l/6305619._SY475_.jpg',
  rating: 3, review: null, started: '2025-07-21', readAt: '2025-09-08', pages: 352,
  url: 'https://www.goodreads.com/book/show/6305619-use-of-weapons',
});

// The owner's own list: editable stars carry data-rating, and a long review hides its full text in freeText.
const own = `<tr id="review_1" class="bookalike review"><td class="field title"><div class="value"><a title="T" href="/book/show/9.T">The Book</a></div></td>
<td class="field author"><div class="value"><a href="/author/show/1">Doe, Jane *</a></div></td>
<td class="field rating"><div class="value"><div class="stars" data-resource-id="9" data-rating="4"></div></div></td>
<td class="field review"><div class="value"><span id="freeTextContainer1">Loved it, the ending&hellip;</span><span id="freeText1" style="display:none">Loved it, the ending<br />made me cry.</span><a href="#">...more</a></div></td></tr>`;
const o = shelf(own)[0];
assert.equal(o.author, 'Jane Doe'); assert.equal(o.rating, 4); assert.equal(o.review, 'Loved it, the ending\nmade me cry.');
assert.equal(o.readAt, null); assert.equal(o.pages, null);
assert.deepEqual(shelf('<html>sign in</html>'), []);

const st = status(readFileSync(new URL('./test/fixtures/goodreads/status.html', import.meta.url), 'utf8'));
assert.ok(Object.keys(st).length >= 2);
assert.deepEqual(status('<div id="user_status_2"><span class="user_status_header"> X is on page 230 of 368 of <a href="https://www.goodreads.com/book/show/229200852-flesh">Flesh</a> </span></div><div id="user_status_1"><span class="user_status_header"> X is 10% done with <a href="/book/show/229200852-flesh">Flesh</a></span></div>'),
  { 229200852: { page: 230, of: 368, percent: 63 } });   // newest update wins
assert.deepEqual(status('<div id="user_status_3"><span class="user_status_header">X is 85% done with <a href="/book/show/5-men">Men</a></span></div>')['5'], { page: null, of: null, percent: 85 });
assert.equal(day('Sep 08, 2025'), '2025-09-08'); assert.equal(day('Mar 1990'), '1990-03-01'); assert.equal(day('not set'), null);
console.log('goodreads-parse ok');
