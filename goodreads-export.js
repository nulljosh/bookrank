// Goodreads on the web, from the export file Goodreads gives you (goodreads.com/review/import, "Export Library").
// Read in the browser and kept in this browser only; nothing goes to Kernel's server. The apps read the same
// shelves through a Goodreads sign-in instead (goodreads-parse.js).

/** CSV rows, quotes and newlines inside quotes included. */
export function csv(text) {
  const rows = [[]]; let cell = '', q = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) { if (c === '"') { if (text[i + 1] === '"') { cell += '"'; i++; } else q = false; } else cell += c; }
    else if (c === '"') q = true;
    else if (c === ',') { rows.at(-1).push(cell); cell = ''; }
    else if (c === '\n' || c === '\r') { if (c === '\r' && text[i + 1] === '\n') i++; rows.at(-1).push(cell); cell = ''; rows.push([]); }
    else cell += c;
  }
  rows.at(-1).push(cell);
  return rows.filter(r => r.some(Boolean));
}

/** The export's books, in the shape the web's shelves already draw: { reading, read, toRead }. */
export function parseExport(text) {
  const [head, ...rows] = csv(text.replace(/^﻿/, ''));
  const at = name => head.indexOf(name);
  if (at('Title') < 0 || at('Exclusive Shelf') < 0) throw new Error('That is not a Goodreads export file.');
  const get = (r, name) => (r[at(name)] ?? '').trim();
  const out = { reading: [], read: [], toRead: [] };
  for (const r of rows) {
    const isbn = (get(r, 'ISBN13') || get(r, 'ISBN')).replace(/[^0-9X]/gi, '');   // exported as ="978..."
    const rating = +get(r, 'My Rating') || null, pages = +get(r, 'Number of Pages') || null;
    const book = {
      title: get(r, 'Title'), author: get(r, 'Author'), isbn: isbn || null, rating, pages,
      cover: isbn ? `https://covers.openlibrary.org/b/isbn/${isbn}-M.jpg` : null,
      readAt: get(r, 'Date Read').replace(/\//g, '-') || null,   // 2025/09/08 -> 2025-09-08
      url: get(r, 'Book Id') ? `https://www.goodreads.com/book/show/${get(r, 'Book Id')}` : null,
    };
    const shelf = get(r, 'Exclusive Shelf');
    (shelf === 'currently-reading' ? out.reading : shelf === 'to-read' ? out.toRead : shelf === 'read' ? out.read : []).push(book);
  }
  return out;
}
