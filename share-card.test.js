import assert from 'node:assert/strict';
import { cardMeta } from './functions/share.js';
const m = cardMeta({ title: 'A "quoted" <b>book</b>', cover: 'https://covers.openlibrary.org/b/id/1-L.jpg' }, 'https://bookrank.jaybulb.com/share?t=x');
assert.match(m, /property="og:title" content="A &quot;quoted&quot; &lt;b&gt;book&lt;\/b&gt; · Kernel"/);
assert.match(m, /og:image" content="https:\/\/covers.openlibrary.org/);
assert.doesNotMatch(m, /<b>/);
assert.match(cardMeta({ title: 'T', cover: 'javascript:x' }, 'https://bookrank.jaybulb.com/share?t=x'), /og:image" content="https:\/\/bookrank.jaybulb.com\/og.png"/);
console.log('share card ok');
