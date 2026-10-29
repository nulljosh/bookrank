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

// Your year as a card: the year big, a few numbers, one highlight. Same card as YearCard in the apps.
// `rows`: [[value, label]].
export async function yearCard(year, rows, quote, book) {
  await document.fonts.load('700 120px "Kernel Sans"').catch(() => {});
  const c = Object.assign(document.createElement('canvas'), { width: 1080, height: 1080 }), g = c.getContext('2d');
  const font = (w, px) => `${w} ${px}px "Kernel Sans", -apple-system, Helvetica, Arial, sans-serif`;
  g.fillStyle = '#f5b83d'; g.fillRect(0, 0, 1080, 1080); g.fillStyle = '#1d1d1f';
  g.font = font(700, 120); g.fillText(String(year), 80, 190);
  g.font = font(500, 40); g.fillText('in books', 80, 245);
  rows.slice(0, 4).forEach(([v, l], i) => {
    const y = 360 + i * 88;
    g.font = font(700, 60); g.fillText(String(v), 80, y);
    g.font = font(500, 34); g.fillText(l, 300, y - 4);
  });
  if (quote) {
    g.font = font(600, 34);
    const q = wrap(g, `“${quote}”`, 920).slice(0, 3), top = 900 - q.length * 44;
    q.forEach((r, i) => g.fillText(r, 80, top + i * 44));
    g.font = font(500, 28); g.fillText(book.length > 50 ? book.slice(0, 49) + '…' : book, 80, top + q.length * 44 + 8);
  }
  g.font = font(700, 34); g.textAlign = 'right'; g.fillText('Kernel.', 1000, 1000);
  return new Promise(res => c.toBlob(res, 'image/png'));
}
