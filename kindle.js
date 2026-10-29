// Kindle highlights from My Clippings.txt (the file on a Kindle plugged in by USB, under documents/).
// Each book's highlights become a "Kindle highlights" chapter on its summary, or a new book when there is none.
// Same parse as Kindle.swift in the apps. Notes and bookmarks are skipped; the same line twice is kept once.
export function parseClippings(text) {
  const books = new Map();
  for (const entry of text.replace(/﻿/g, '').split(/^==========\s*$/m)) {
    const [head = '', meta = '', , ...rest] = entry.trim().split(/\r?\n/);
    if (!/Your Highlight|Votre surlignement|Ihre Markierung|Tu subrayado/i.test(meta)) continue;
    const line = rest.join(' ').trim();
    if (!line) continue;
    const m = head.trim().match(/^(.*?)\s*\(([^()]*)\)\s*$/);
    const title = (m ? m[1] : head).trim(), author = m ? m[2].trim() : '';
    if (!books.has(title)) books.set(title, { title, author, lines: [] });
    const b = books.get(title);
    if (!b.lines.includes(line)) b.lines.push(line);
  }
  return [...books.values()];
}

// The chapter to add: only the lines the summary does not already have, as a list. '' when nothing is new.
export function kindleChapter(content, lines) {
  const fresh = lines.filter(l => !(content || '').includes(l));
  return fresh.map(l => `- ${l}`).join('\n');
}

// Readwise's CSV export (readwise.io/export): the same shape as the Kindle books, under a Readwise highlights chapter.
import { csv } from './goodreads-export.js';
export function parseReadwise(text) {
  const [head, ...rows] = csv(text.replace(/^﻿/, ''));
  const h = head.indexOf('Highlight'), t = head.indexOf('Book Title'), a = head.indexOf('Book Author');
  if (h < 0 || t < 0) return null;
  const books = new Map();
  for (const r of rows) {
    const title = (r[t] || '').trim(), line = (r[h] || '').replace(/\s+/g, ' ').trim();
    if (!title || !line) continue;
    if (!books.has(title)) books.set(title, { title, author: (r[a] || '').trim(), lines: [] });
    if (!books.get(title).lines.includes(line)) books.get(title).lines.push(line);
  }
  return [...books.values()];
}
