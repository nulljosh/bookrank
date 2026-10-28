import { parseFeed, userId, cleanTitle, parseProfile, bestQuote } from './functions/api/goodreads.js';
import assert from 'node:assert/strict';
assert.equal(userId('https://www.goodreads.com/user/show/62164337-josh'), '62164337');
assert.equal(userId('62164337'), '62164337');
assert.equal(userId('not a link'), '');
assert.equal(cleanTitle('AI in Business For Dummies (For Dummies (Business & Personal Finance))'), 'AI in Business For Dummies');
assert.equal(cleanTitle('Data Science For Dummies, 3rd Edition (For Dummies (Computer/Tech))'), 'Data Science For Dummies, 3rd Edition');
assert.equal(cleanTitle('The Optimist: Sam Altman, OpenAI, and the Race to Invent the Future'), 'The Optimist: Sam Altman, OpenAI, and the Race to Invent the Future');
assert.equal(cleanTitle('Isaac Newton (Penguin Lives)'), 'Isaac Newton (Penguin Lives)');
const xml = `<rss><channel><item><title><![CDATA[macOS Tahoe For Dummies (For Dummies (Computer/Tech))]]></title><link><![CDATA[https://www.goodreads.com/review/show/1]]></link>
<book_large_image_url><![CDATA[https://i.gr-assets.com/x.jpg]]></book_large_image_url><author_name>Guy Hart-Davis</author_name><isbn>1394373988</isbn>
<user_rating>4</user_rating><user_read_at><![CDATA[Tue, 11 Aug 2026 00:00:00 +0000]]></user_read_at></item>
<item><title>Brothers &amp; Sisters</title><author_name>A</author_name><isbn></isbn><user_rating>0</user_rating><user_read_at></user_read_at></item></channel></rss>`;
const b = parseFeed(xml);
assert.equal(b.length, 2);
assert.deepEqual(b[0], { title: 'macOS Tahoe For Dummies', author: 'Guy Hart-Davis', isbn: '1394373988', cover: 'https://i.gr-assets.com/x.jpg', readAt: '2026-08-11', rating: 4, url: 'https://www.goodreads.com/review/show/1' });
assert.equal(b[1].title, 'Brothers & Sisters'); assert.equal(b[1].isbn, null); assert.equal(b[1].readAt, null); assert.equal(b[1].rating, null);
assert.equal(parseFeed('<item><title>Man&amp;apos;s Search &#8212; &#x41;</title></item>')[0].title, "Man's Search \u2014 A");
assert.deepEqual(parseProfile('<meta property="og:title" content="Joshua Trommel"><meta property="og:image" content="https://images.gr-assets.com/users/1/62164337.jpg">'), { name: 'Joshua Trommel', avatar: 'https://images.gr-assets.com/users/1/62164337.jpg', about: null, interests: null, genres: [], quote: null });
const prof = parseProfile('<div class="infoBoxRowTitle">About Me</div>\n<div class="infoBoxRowItem">I read <b>a lot</b>.<br/>Mostly at night.</div><div class="infoBoxRowTitle">Interests</div><div class="infoBoxRowItem">chess, running</div><h2 class="x"><div></div>Favorite Genres</h2></div><div class="bigBoxBody"><div class="bigBoxContent containerWithHeaderContent"><a href="/genres/biography">Biography</a>, <a href="/genres/humor-and-comedy">Humor and Comedy</a></div>');
assert.equal(prof.about, 'I read a lot.\nMostly at night.'); assert.equal(prof.interests, 'chess, running'); assert.deepEqual(prof.genres, ['Biography', 'Humor and Comedy']);
assert.equal(parseProfile('<meta property="og:image" content="https://s.gr-assets.com/assets/nophoto/user/u_200x266.png">').avatar, null);
const q = (t, l) => `<div class="quote mediumText "><div class="quoteText">&ldquo;${t}&rdquo; &#8213; <a>Some Author</a>, <a>Book</a></div><a>${l} likes</a></div>`;
assert.deepEqual(bestQuote(q('x'.repeat(300), '9,999') + q('Short and loved.', '50') + q('Short.', '5')), { text: 'Short and loved.', author: 'Some Author' });
assert.equal(bestQuote(''), null);
assert.equal(parseFeed('<item><title>Half</title><user_rating>3.5</user_rating></item>')[0].rating, 3.5);   // Goodreads allows half stars now
console.log('goodreads ok');
import { parseReading } from './functions/api/goodreads.js';
// The public profile's Currently Reading box (structure from goodreads.com, 2026-10-28).
const box = `<div id="currentlyReadingReviews"> <div class="Updates no_border"> <div class="firstcol"> <a title="Acing" href="/book/show/62241112-acing"><img alt="Acing the System ..." src="https://i.gr-assets.com/b/62241112._SX98_.jpg" /></a> </div>
 <div class="userReview"> <strong><a href="/user/show/1-x">X</a></strong> is currently reading </div> <div><a class="bookTitle" href="/book/show/62241112-acing">Acing the System Design Interview</a></div> <div> <span class="by smallText">by</span> <a class="authorName" href="/author/show/1.Z">Zhiyong Tan</a> </div></div>
 <div class="Updates"> <div class="firstcol"><a href="/book/show/2-face"><img alt="Face" src="https://i.gr-assets.com/b/2._SX98_.jpg" /></a></div> <div class="userReview"> rated a book <span class=" staticStars notranslate" title="really liked it"><span class="staticStar p10">really liked it</span><span class="staticStar p10"></span><span class="staticStar p10"></span><span class="staticStar p10"></span><span class="staticStar p0"></span></span> </div>
 <div><a class="bookTitle" href="/book/show/2-face">Face with Tears of Joy &amp; More</a></div> <a class="authorName" href="/author/show/2.K">Keith Houston</a></div>
 </div><div class="bigBoxBottom"></div><div class="Updates"><a class="bookTitle" href="/book/show/9">Not in the box</a></div>`;
const cr = parseReading(box);
assert.equal(cr.length, 2);
assert.deepEqual(cr[0], { title: 'Acing the System Design Interview', author: 'Zhiyong Tan', isbn: null, cover: 'https://i.gr-assets.com/b/62241112._SY475_.jpg', readAt: null, rating: null, url: 'https://www.goodreads.com/book/show/62241112-acing' });
assert.equal(cr[1].title, 'Face with Tears of Joy & More'); assert.equal(cr[1].rating, 4);
assert.deepEqual(parseReading('<html>no box</html>'), []);
console.log('reading ok');
