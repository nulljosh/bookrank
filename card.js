// A highlight as a square image card to share: the line in Kernel Sans on Kernel gold, the book under it.
// Same card as HighlightCard in the apps. Drawn on a canvas; nothing leaves the page unless you share it.
export async function card(text, book) {
  await document.fonts.load('600 52px "Kernel Sans"').catch(() => {});
  const c = Object.assign(document.createElement('canvas'), { width: 1080, height: 1080 }), g = c.getContext('2d');
  g.fillStyle = '#f5b83d'; g.fillRect(0, 0, 1080, 1080);
  g.fillStyle = '#1d1d1f';
  // Shrink the type until the line fits in eleven rows.
  let size = 64, rows;
  do { g.font = `600 ${size}px "Kernel Sans", -apple-system, Helvetica, Arial, sans-serif`; rows = wrap(g, text, 920); } while (rows.length > 11 && (size -= 4) > 28);
  const lh = size * 1.25, top = (1080 - rows.length * lh) / 2 - 40;
  rows.slice(0, 11).forEach((r, i) => g.fillText(r, 80, top + (i + 1) * lh));
  g.font = '500 34px "Kernel Sans", -apple-system, Helvetica, Arial, sans-serif';
  g.fillText(book.length > 48 ? book.slice(0, 47) + '…' : book, 80, 960);
  g.font = '700 34px "Kernel Sans", -apple-system, Helvetica, Arial, sans-serif';
  g.textAlign = 'right'; g.fillText('Kernel.', 1000, 960);
  return new Promise(res => c.toBlob(res, 'image/png'));
}

function wrap(g, text, width) {
  const rows = []; let row = '';
  for (const w of text.split(/\s+/)) {
    const next = row ? row + ' ' + w : w;
    if (g.measureText(next).width > width && row) { rows.push(row); row = w; } else row = next;
  }
  if (row) rows.push(row);
  return rows;
}
