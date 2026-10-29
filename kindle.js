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
