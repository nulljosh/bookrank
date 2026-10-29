// Search by meaning: the lines of a book that say something (not headings, not scraps), and the closest of
// them to a search by cosine. The vectors come from /api/embed; library.html keeps them per book version.
// The apps do the same on the device in Meaning.swift.
import { chapters, blocks } from './listen.js';

export function lines(content) {
  const out = [];
  for (const [ch, c] of chapters(content).entries())
    blocks(c.text).forEach((b, line) => { if (!b.md.startsWith('#') && b.line.length >= 30) out.push({ ch, line, title: c.title, text: b.line }); });
  return out;
}

export const cosine = (a, b) => {
  let d = 0, x = 0, y = 0;
  for (let i = 0; i < a.length; i++) { d += a[i] * b[i]; x += a[i] * a[i]; y += b[i] * b[i]; }
  return d / (Math.sqrt(x * y) || 1);
};

// ponytail: a plain scan over every line; fine to tens of thousands, an ANN index past that.
export function closest(qv, books, n = 5, floor = 0.6) {
  const hits = [];
  for (const b of books) b.lines.forEach((l, i) => { const score = cosine(qv, b.vecs[i]); if (score >= floor) hits.push({ ...l, id: b.id, book: b.title, score }); });
  return hits.sort((a, b) => b.score - a.score).slice(0, n);
}

/** Connections: the lines in your other books closest in meaning to one line, with a higher bar than search. */
export function related(v, books, exceptId, n = 3, floor = 0.7) {
  return closest(v, books.filter(b => b.id !== exceptId), n, floor);
}
