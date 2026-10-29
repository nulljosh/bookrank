// Search inside a book: the first chapter line (as the notes show it) that holds `q`, any case.
// The apps' findLine() in SummaryDetailView.swift follows the same rule.
import { chapters, blocks } from './listen.js';

export function findLine(content, q) {
  q = String(q || '').trim().toLowerCase();
  if (!q) return null;
  for (const [ch, c] of chapters(content).entries()) {
    const lines = blocks(c.text), line = lines.findIndex(l => l.line.toLowerCase().includes(q));
    if (line >= 0) return { ch, line, title: c.title, text: lines[line].line };
  }
  return null;
}
