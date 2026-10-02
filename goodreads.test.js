import { parseFeed, userId, cleanTitle, parseProfile } from './functions/api/goodreads.js';
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
assert.deepEqual(parseProfile('<meta property="og:title" content="Joshua Trommel"><meta property="og:image" content="https://images.gr-assets.com/users/1/62164337.jpg">'), { name: 'Joshua Trommel', avatar: 'https://images.gr-assets.com/users/1/62164337.jpg', about: null, interests: null, genres: [] });
const prof = parseProfile('<div class="infoBoxRowTitle">About Me</div>\n<div class="infoBoxRowItem">I read <b>a lot</b>.<br/>Mostly at night.</div><div class="infoBoxRowTitle">Interests</div><div class="infoBoxRowItem">chess, running</div><h2 class="x"><div></div>Favorite Genres</h2></div><div class="bigBoxBody"><div class="bigBoxContent containerWithHeaderContent"><a href="/genres/biography">Biography</a>, <a href="/genres/humor-and-comedy">Humor and Comedy</a></div>');
assert.equal(prof.about, 'I read a lot.\nMostly at night.'); assert.equal(prof.interests, 'chess, running'); assert.deepEqual(prof.genres, ['Biography', 'Humor and Comedy']);
assert.equal(parseProfile('<meta property="og:image" content="https://s.gr-assets.com/assets/nophoto/user/u_200x266.png">').avatar, null);
console.log('goodreads ok');
