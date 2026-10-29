// node --test: an EPUB built here (stored and deflated entries) comes back as chapters in reading order.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { deflateRawSync } from 'node:zlib';
import { epubToMarkdown, section } from './epub.js';

function zip(entries) {   // a minimal zip writer for the test: [name, string, deflate?]
  const parts = [], dir = []; let off = 0;
  for (const [name, body, deflate] of entries) {
    const raw = Buffer.from(body), data = deflate ? deflateRawSync(raw) : raw, n = Buffer.from(name);
    const h = Buffer.alloc(30); h.writeUInt32LE(0x04034b50, 0); h.writeUInt16LE(deflate ? 8 : 0, 8); h.writeUInt32LE(data.length, 18); h.writeUInt32LE(raw.length, 22); h.writeUInt16LE(n.length, 26);
    const c = Buffer.alloc(46); c.writeUInt32LE(0x02014b50, 0); c.writeUInt16LE(deflate ? 8 : 0, 10); c.writeUInt32LE(data.length, 20); c.writeUInt32LE(raw.length, 24); c.writeUInt16LE(n.length, 28); c.writeUInt32LE(off, 42);
    parts.push(h, n, data); dir.push(c, n); off += 30 + n.length + data.length;
  }
  const d = Buffer.concat(dir), e = Buffer.alloc(22); e.writeUInt32LE(0x06054b50, 0); e.writeUInt16LE(entries.length, 10); e.writeUInt32LE(d.length, 12); e.writeUInt32LE(off, 16);
  return Buffer.concat([...parts, d, e]);
}
const long = 'This paragraph is long enough to count as a real section of the book, with plenty of words in it. '.repeat(3);

test('section takes the heading as the title and keeps paragraphs and list items', () => {
  assert.deepEqual(section('<html><body><h2>One &amp; Two</h2><p>First <em>para</em>.</p><ul><li>Item</li></ul></body></html>'), { title: 'One & Two', text: 'First para.\n\n- Item' });
});

test('epubToMarkdown follows the spine and skips the cover', async () => {
  const buf = zip([
    ['mimetype', 'application/epub+zip'],
    ['META-INF/container.xml', '<container><rootfiles><rootfile full-path="OEBPS/content.opf"/></rootfiles></container>', true],
    ['OEBPS/content.opf', '<package><metadata><dc:title>My Book</dc:title></metadata><manifest><item id="c" href="cover.xhtml"/><item id="b" href="two.xhtml"/><item id="a" href="one.xhtml"/></manifest><spine><itemref idref="c"/><itemref idref="a"/><itemref idref="b"/></spine></package>', true],
    ['OEBPS/cover.xhtml', '<body><p>Cover</p></body>', true],
    ['OEBPS/one.xhtml', `<body><h1>Start</h1><p>${long}</p></body>`, true],
    ['OEBPS/two.xhtml', `<body><p>${long}</p></body>`],
  ]);
  const { title, markdown } = await epubToMarkdown(buf);
  assert.equal(title, 'My Book');
  assert.match(markdown, /^# My Book\n\n## Start\n\nThis paragraph/);
  assert.match(markdown, /\n## Section 1\n\nThis paragraph/);
  assert.doesNotMatch(markdown, /Cover/);
});
