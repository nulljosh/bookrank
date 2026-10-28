// Reads a signed-in Goodreads account's own pages into plain data, on the device. The apps load
// this file into a hidden web view that holds the person's Goodreads session (cookies never leave
// the device) and call GR.sync(); goodreads-parse.test.js runs the same parsers in Node.
// Plain regex over the HTML so Node and the web view run identical code.
(function (g) {
  const NAMED = { amp: "&", lt: "<", gt: ">", quot: '"', apos: "'", nbsp: " ", ldquo: "“", rdquo: "”", lsquo: "‘", rsquo: "’", mdash: "—", ndash: "–", hellip: "…" };
  const decode = s => String(s || "").replace(/&(#x[0-9a-f]+|#\d+|\w+);/gi, (m, e) =>
    e[0] === "#" ? String.fromCodePoint(e[1] === "x" || e[1] === "X" ? parseInt(e.slice(2), 16) : +e.slice(1)) : NAMED[e] ?? m);
  const text = s => decode(String(s || "").replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]+>/g, "")).replace(/[ \t\r\f\v]+/g, " ").replace(/ ?\n ?/g, "\n").trim();
  const MONTHS = { jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6, jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12 };
  /** "Sep 08, 2025" -> "2025-09-08", "Sep 2025" -> "2025-09-01". */
  const day = s => {
    const m = String(s || "").match(/([A-Za-z]{3})[a-z]*\.?\s+(?:(\d{1,2}),\s*)?(\d{4})/);
    if (!m || !MONTHS[m[1].toLowerCase()]) return null;
    return `${m[3]}-${String(MONTHS[m[1].toLowerCase()]).padStart(2, "0")}-${String(m[2] || 1).padStart(2, "0")}`;
  };
  const cell = (row, name) => ((row.match(new RegExp(`<td class="field ${name}"[^>]*>([\\s\\S]*?)</td>`)) || [])[1] || "").replace(/<label>[\s\S]*?<\/label>/, "");

  /** One page of /review/list/<id>?shelf=... -> books. Tolerant: any missing field is null. */
  function shelf(html) {
    return String(html).split(/<tr id="review_/).slice(1).map(r => {
      const row = r.split("</tr>")[0];
      const t = cell(row, "title"), link = t.match(/href="(\/book\/show\/(\d+)[^"]*)"/);
      const title = text((t.match(/<a [^>]*>([\s\S]*?)<\/a>/) || [])[1]?.replace(/<span[\s\S]*?<\/span>/g, ""));
      const author = text((cell(row, "author").match(/<a [^>]*>([\s\S]*?)<\/a>/) || [])[1]).replace(/\s*\*$/, "");
      const rc = cell(row, "rating");
      const given = +(rc.match(/data-rating="(\d)"/) || [])[1] || 0;
      const rating = given || (rc.match(/staticStar p10/g) || []).length || null;
      const rv = cell(row, "review");
      const full = rv.match(/<span id="freeText\d+"[^>]*>([\s\S]*?)<\/span>/) || rv.match(/<span id="freeTextContainer\d+"[^>]*>([\s\S]*?)<\/span>/);
      const review = text(full ? full[1] : rv.replace(/<a [^>]*>\.\.\.more<\/a>/, "")).replace(/^None$/, "") || null;
      const cover = (cell(row, "cover").match(/src="([^"]+)"/) || [])[1] || null;
      return {
        id: (r.match(/^(\d+)/) || [])[1] || null,
        bookId: link ? link[2] : null,
        title, author: /,/.test(author) ? author.split(/,\s*/).reverse().join(" ") : author,
        cover: cover && cover.replace(/\._S[XY]\d+_\./, "._SY475_."),
        rating, review,
        started: day((cell(row, "date_started").match(/date_started_value">([^<]+)/) || [])[1]),
        readAt: day((cell(row, "date_read").match(/date_read_value">([^<]+)/) || [])[1]),
        pages: +(text(cell(row, "num_pages")).match(/\d+/) || [])[0] || null,
        url: link ? `https://www.goodreads.com${link[1]}` : null,
      };
    }).filter(b => b.title);
  }

  /** /user_status/list/<id> -> { bookId: { page, of, percent } }, newest update per book. */
  function status(html) {
    const out = {};
    for (const b of String(html).split(/<div id="user_status_\d+">/).slice(1)) {
      const head = text((b.match(/user_status_header">([\s\S]*?)<\/span>/) || [])[1]);
      const id = (b.match(/\/book\/show\/(\d+)/) || [])[1];
      if (!id || out[id]) continue;
      const pg = head.match(/is on page (\d+) of (\d+)/), pc = head.match(/is (\d+)% done/);
      if (pg) out[id] = { page: +pg[1], of: +pg[2], percent: Math.round(100 * pg[1] / pg[2]) };
      else if (pc) out[id] = { page: null, of: null, percent: +pc[1] };
      else if (/is starting/.test(head)) out[id] = { page: 0, of: null, percent: 0 };
    }
    return out;
  }

  /** In the web view: who is signed in, then every page of the three shelves and the latest progress. */
  async function sync(maxPages = 10) {
    const me = await fetch("/review/list?shelf=read", { credentials: "include" });
    const user = (me.url.match(/\/review\/list\/(\d+)/) || [])[1];
    if (!user) return JSON.stringify({ signedIn: false });
    const out = { signedIn: true, user, shelves: {} };
    for (const s of ["currently-reading", "read", "to-read"]) {
      const seen = new Set(), books = [];
      for (let p = 1; p <= maxPages; p++) {
        const html = await (await fetch(`/review/list/${user}?shelf=${s}&per_page=100&sort=date_read&order=d&page=${p}`, { credentials: "include" })).text();
        const fresh = shelf(html).filter(b => !seen.has(b.id));
        fresh.forEach(b => seen.add(b.id));
        books.push(...fresh);
        if (!fresh.length) break;
      }
      out.shelves[s] = books;
    }
    out.status = status(await (await fetch(`/user_status/list/${user}`, { credentials: "include" })).text());
    return JSON.stringify(out);
  }

  g.GR = { shelf, status, sync, day };
})(globalThis);
