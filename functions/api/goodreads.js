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
  if (url.searchParams.get("profile")) return profile(user);
  if (!SHELVES.has(shelf)) return json({ error: "Unknown shelf." }, 400);

  const cache = caches.default;
  const key = new Request(`https://goodreads.cache/v2/${user}/${shelf}`) // bump vN when the parse changes;
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

/** ?profile=1 -> { name, avatar } from the public profile page's Open Graph tags. */
async function profile(user) {
  const r = await fetch(`https://www.goodreads.com/user/show/${user}`, { headers: { "User-Agent": "Mozilla/5.0 (Bookrank)" } });
  if (!r.ok) return json({ error: "No Goodreads profile with that link." }, 404);
  const p = parseProfile(await r.text());
  // Goodreads sometimes serves bots a stripped page; no name means we did not get the real profile.
  if (!p.name) return json({ error: "Goodreads did not answer. Try again in a minute." }, 502);
  return json(p);
}

export function parseProfile(html) {
  const og = (p) => decode((html.match(new RegExp(`<meta property="og:${p}" content="([^"]*)"`)) || [])[1] || "");
  const avatar = og("image");
  // Profile rows render as <div class="infoBoxRowTitle">About Me</div><div class="infoBoxRowItem">...</div>.
  const row = (t) => { const m = html.match(new RegExp(`infoBoxRowTitle">\\s*${t}\\s*</div>\\s*<div class="infoBoxRowItem"[^>]*>([\\s\\S]*?)</div>`)); return m ? decode(m[1].replace(/<br\s*\/?>/g, "\n").replace(/<[^>]+>/g, "")).replace(/\s*\.\.\.more$/, "").trim() || null : null; };
  const g = html.match(/Favorite Genres<\/h2>[\s\S]*?<div class="bigBoxContent[^"]*">([\s\S]*?)<\/div>/);
  const genres = g ? [...g[1].matchAll(/<a href="\/genres\/[^"]+">([^<]+)<\/a>/g)].map(m => decode(m[1])) : [];
  return { name: og("title") || null, avatar: /gr-assets\.com\/users\//.test(avatar) ? avatar : null, about: row("About Me"), interests: row("Interests"), genres, quote: bestQuote(html) };
}

/** The profile's liked quotes -> the one to show: most liked among those short enough to read at a
 *  glance (220 chars), else the most recent. ponytail: likes are the only quality signal on the page. */
export function bestQuote(html) {
  const qs = html.split('<div class="quote mediumText').slice(1).map(b => {
    const raw = (b.match(/<div class="quoteText">([\s\S]*?)<\/div>/) || [])[1] || "";
    const flat = decode(raw.replace(/<br\s*\/?>/g, " ").replace(/<[^>]+>/g, " ")).replace(/\s+/g, " ").trim();
    const [text, author] = flat.split(/\s*\u2015\s*/);
    const likes = +((b.match(/>(\d[\d,]*) likes</) || [])[1] || "0").replace(/,/g, "");
    return { text: (text || "").replace(/^[\u201c"]|[\u201d"]$/g, "").trim(), author: (author || "").split(",")[0].trim() || null, likes };
  }).filter(q => q.text);
  const short = qs.filter(q => q.text.length <= 220).sort((a, b) => b.likes - a.likes);
  const q = short[0] || qs[0];
  return q ? { text: q.text, author: q.author } : null;
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

const NAMED = { ldquo: "\u201c", rdquo: "\u201d", lsquo: "\u2018", rsquo: "\u2019", mdash: "\u2014", ndash: "\u2013", hellip: "\u2026", nbsp: " " };
function decode(s) {
  return s.replace(/^<!\[CDATA\[|\]\]>$/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&apos;|&#39;/g, "'").replace(/&(ldquo|rdquo|lsquo|rsquo|mdash|ndash|hellip|nbsp);/g, (_, n) => NAMED[n]).replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16))).replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(+d)).trim();
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } });
}
