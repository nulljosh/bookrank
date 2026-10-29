// An EPUB you own (no DRM) becomes a book: one chapter per section of its reading order.
// Unzipped in the browser with DecompressionStream; nothing is uploaded but the text you save.
// The apps do the same in Ebook.swift. ponytail: plain text only; images and tables are dropped.

/** The files of a zip, by name. Stored and deflated entries only, which is all EPUBs use. */
export async function unzip(buf) {
  const b = new Uint8Array(buf), v = new DataView(b.buffer, b.byteOffset, b.byteLength), files = new Map();
  let end = b.length - 22;
  while (end >= 0 && v.getUint32(end, true) !== 0x06054b50) end--;
  if (end < 0) throw new Error('That file is not an EPUB.');
  let p = v.getUint32(end + 16, true);
  for (let n = v.getUint16(end + 10, true); n > 0; n--) {
    const method = v.getUint16(p + 10, true), size = v.getUint32(p + 20, true);
    const nameLen = v.getUint16(p + 28, true), extra = v.getUint16(p + 30, true), note = v.getUint16(p + 32, true), local = v.getUint32(p + 42, true);
    const name = new TextDecoder().decode(b.subarray(p + 46, p + 46 + nameLen));
    const start = local + 30 + v.getUint16(local + 26, true) + v.getUint16(local + 28, true), raw = b.subarray(start, start + size);
    files.set(name, method === 0 ? raw : new Uint8Array(await new Response(new Blob([raw]).stream().pipeThrough(new DecompressionStream('deflate-raw'))).arrayBuffer()));
    p += 46 + nameLen + extra + note;
  }
  return files;
}

const decode = s => s.replace(/&(#x[0-9a-f]+|#\d+|amp|lt|gt|quot|apos|nbsp);/gi, (m, e) =>
  e[0] === '#' ? String.fromCodePoint(e[1].toLowerCase() === 'x' ? parseInt(e.slice(2), 16) : +e.slice(1)) : { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ' }[e.toLowerCase()]);
const text = s => decode(s.replace(/<[^>]+>/g, '')).replace(/\s+/g, ' ').trim();

/** A section's XHTML as Markdown: its first heading as the chapter title, paragraphs and list items as text. */
export function section(xhtml) {
  const body = (xhtml.match(/<body[\s\S]*<\/body>/i) || [xhtml])[0];
  const title = text((body.match(/<h[1-3][^>]*>([\s\S]*?)<\/h[1-3]>/i) || [])[1] || '');
  const parts = [...body.matchAll(/<(p|li|h[4-6])[^>]*>([\s\S]*?)<\/\1>/gi)].map(m => (m[1].toLowerCase() === 'li' ? '- ' : '') + text(m[2])).filter(t => t.replace('- ', ''));
  return { title, text: parts.join('\n\n') };
}

/** { title, markdown } for a whole EPUB: "# Title", then "## " per section in reading order. */
export async function epubToMarkdown(buf) {
  const files = await unzip(buf), str = n => files.has(n) ? new TextDecoder().decode(files.get(n)) : '';
  const opfPath = (str('META-INF/container.xml').match(/full-path="([^"]+)"/) || [])[1];
  const opf = str(opfPath || '');
  if (!opf) throw new Error('That file is not an EPUB.');
  const dir = opfPath.includes('/') ? opfPath.slice(0, opfPath.lastIndexOf('/') + 1) : '';
  const items = Object.fromEntries([...opf.matchAll(/<item\b[^>]*>/g)].map(m => [(m[0].match(/id="([^"]+)"/) || [])[1], (m[0].match(/href="([^"]+)"/) || [])[1]]));
  const title = text((opf.match(/<dc:title[^>]*>([\s\S]*?)<\/dc:title>/) || [])[1] || 'Untitled');
  let md = `# ${title}\n`, n = 0;
  for (const [, idref] of opf.matchAll(/<itemref\b[^>]*idref="([^"]+)"/g)) {
    const s = section(str(dir + decodeURIComponent(items[idref] || '')));
    if (s.text.length < 200) continue;   // covers, title pages, copyright
    md += `\n## ${s.title || `Section ${++n}`}\n\n${s.text}\n`;
  }
  return { title, markdown: md };
}
