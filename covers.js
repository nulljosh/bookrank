// Book covers and share links, split out of listen.js to keep it readable.

// Thumbnails: exact title match first, then either title starting with the other
// ("Adult Autism" vs "Adult Autism Essentials"), then a contains match.
const norm = s => String(s || '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
export function matchCover(title, books) {
  const t = norm(title); if (!t) return null;
  const withCover = books.filter(b => b.cover);
  const pick = f => withCover.find(b => f(norm(b.title)))?.cover || null;
  return pick(n => n === t) || pick(n => n.startsWith(t) || t.startsWith(n)) || pick(n => n.includes(t) || t.includes(n));
}

// Candidate cover URLs from one Open Library search doc: the work cover, then each ISBN
// and edition, which often carry a cover the work does not. `default=false` makes a miss a
// 404 the browser can detect instead of a placeholder image.
export function coverCandidates(doc) {
  if (!doc) return [];
  const out = [];
  if (doc.cover_i) out.push(`https://covers.openlibrary.org/b/id/${doc.cover_i}-M.jpg`);
  for (const i of (doc.isbn || []).slice(0, 4)) out.push(`https://covers.openlibrary.org/b/isbn/${i}-M.jpg?default=false`);
  for (const k of (doc.edition_key || []).slice(0, 3)) out.push(`https://covers.openlibrary.org/b/olid/${k}-M.jpg?default=false`);
  return out;
}

// Public share URL for a token.
export const shareUrl = (origin, token) => `${origin}/share.html?t=${token}`;
