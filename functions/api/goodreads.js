// GET /api/goodreads?user=<id or profile URL>&shelf=read|currently-reading|to-read
// -> { user, shelf, books: [{ title, author, isbn, cover, readAt, rating, url }] }
// Goodreads closed its API and OAuth in 2020, so there is no Goodreads sign-in to offer.
// A public profile's shelves are still published as RSS; this reads them, follows the
// pages, and hands back plain JSON the web and iOS apps can sync from. No credentials.
// ponytail: 10 pages (1000 books) per shelf and a one-hour edge cache; raise either if a
// real shelf outgrows it.
const SHELVES = new Set(["read", "currently-reading", "to-read"]);
const MAX_PAGES = 10;

export async function onRequest({ request }) {
  const url = new URL(request.url);
  const user = userId(url.searchParams.get("user") || "");
  const shelf = url.searchParams.get("shelf") || "read";
  if (!user) return json({ error: "Paste your Goodreads profile link." }, 400);
  if (!SHELVES.has(shelf)) return json({ error: "Unknown shelf." }, 400);

  const cache = caches.default;
  const key = new Request(`https://goodreads.cache/${user}/${shelf}`);
  const hit = await cache.match(key);
  if (hit) return hit;

  const books = [];
  for (let page = 1; page <= MAX_PAGES; page++) {
    const r = await fetch(`https://www.goodreads.com/review/list_rss/${user}?shelf=${shelf}&page=${page}`, { headers: { "User-Agent": "Mozilla/5.0 (Bookrank)" } });
    if (r.status === 404) return json({ error: "No Goodreads profile with that link." }, 404);
    if (!r.ok) return json({ error: "Goodreads did not answer. Try again in a minute." }, 502);
    const items = parseFeed(await r.text());
    books.push(...items);
    if (items.length < 100) break;
  }
  const res = json({ user, shelf, books });
  res.headers.set("Cache-Control", "public, max-age=3600");
  await cache.put(key, res.clone());
  return res;
}

/** A profile URL (goodreads.com/user/show/62164337-josh) or a bare id -> "62164337". */
export function userId(s) {
  const m = String(s).trim().match(/(?:user\/show\/|review\/list(?:_rss)?\/)?(\d{3,})/);
  return m ? m[1] : "";
}

/** Goodreads' RSS -> books. Workers have no DOMParser, and the feed is regular enough for this. */
export function parseFeed(xml) {
  return [...xml.matchAll(/<item>([\s\S]*?)<\/item>/g)].map(([, it]) => {
    const tag = (t) => decode((it.match(new RegExp(`<${t}>([\\s\\S]*?)</${t}>`)) || [])[1] || "");
    const read = tag("user_read_at");
    return {
      title: cleanTitle(tag("title")),
      author: tag("author_name"),
      isbn: tag("isbn") || null,
      cover: tag("book_large_image_url") || tag("book_image_url") || null,
      readAt: read ? new Date(read).toISOString().slice(0, 10) : null,
      rating: +tag("user_rating") || null,
      url: tag("link") || null,
    };
  });
}

/** "AI in Business For Dummies (For Dummies (Business & Personal Finance))" -> "AI in Business For Dummies". */
export function cleanTitle(t) {
  let s = t.trim();
  while (/\s*\([^()]*(\([^()]*\))?[^()]*\)\s*$/.test(s) && /\(.*(Dummies|Series|#\d|Edition|Book \d)/i.test(s.match(/\([^()]*(\([^()]*\))?[^()]*\)\s*$/)[0])) {
    s = s.replace(/\s*\([^()]*(\([^()]*\))?[^()]*\)\s*$/, "");
  }
  return s;
}

function decode(s) {
  return s.replace(/^<!\[CDATA\[|\]\]>$/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&#39;/g, "'").trim();
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } });
}
