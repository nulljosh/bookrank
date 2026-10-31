// Book covers for the web library, split out of library.html.
import { matchCover, coverCandidates } from './listen.js';

/** A thumb(row) maker; save(row, url) keeps a newly found cover on the row. */
export function thumbs(save) {
  // Order: the row's saved cover, books.json by fuzzy title, then Open Library: a title
  // search, then a general search, each yielding work/ISBN/edition image candidates that are
  // probed by actually loading them. The first hit is written to the row's `cover` column so
  // it is found once, for every device and the apps. A miss is retried next visit, never cached.
  const books = fetch('books.json').then(r => r.json()).catch(() => []);
  const loads = url => new Promise(res => { const i = new Image(); i.onload = () => res(url); i.onerror = () => res(null); i.src = url; });
  async function firstLoadable(urls) { for (const u of urls) if (await loads(u)) return u; return null; }
  async function olCandidates(title) {
    const out = [];
    for (const param of ['title', 'q']) {
      try {
        const r = await fetch(`https://openlibrary.org/search.json?${param}=${encodeURIComponent(title)}&limit=2&fields=cover_i,isbn,edition_key`);
        for (const d of (await r.json()).docs || []) out.push(...coverCandidates(d));
      } catch {}
    }
    // Last resort: Google Books. Its unauthenticated quota is per client, so the browser
    // usually has it even when a server would not.
    try {
      const r = await fetch(`https://www.googleapis.com/books/v1/volumes?q=intitle:${encodeURIComponent(title)}&maxResults=3&fields=items(volumeInfo(imageLinks))`);
      for (const it of (await r.json()).items || []) { const t = it.volumeInfo?.imageLinks?.thumbnail; if (t) out.push(t.replace(/^http:/, 'https:')); }
    } catch {}
    return [...new Set(out)];
  }
  async function resolveCover(row) {
    if (row.cover) return row.cover;
    const u = matchCover(row.title, await books) || await firstLoadable(await olCandidates(row.title));
    if (u) { row.cover = u; save(row, u); }
    return u;
  }
  // A missing cover is looked up only when its row comes near the screen, so a 500-book shelf
  // does not fire 500 Open Library searches on load.
  const nearScreen = new IntersectionObserver(es => es.forEach(e => { if (e.isIntersecting) { nearScreen.unobserve(e.target); e.target.load(); } }), { rootMargin: '600px' });
  function thumb(row) {
    const img = Object.assign(document.createElement('img'), { className: 'thumb', alt: '', loading: 'lazy' });
    img.onerror = () => { img.removeAttribute('src'); img.className = 'thumb-empty'; };   // offline, the cover host is out of reach
    img.load = () => resolveCover(row).then(u => { if (u) img.src = u; else img.className = 'thumb-empty'; });
    if (row.cover) img.load(); else nearScreen.observe(img);
    return img;
  }
  return thumb;
}
