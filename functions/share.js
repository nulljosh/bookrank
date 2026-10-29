// /share?t=<token>: the same page, with the book's title and cover in the link preview, so a shared
// link shows up in Messages, Slack or X as a card instead of a bare URL. No token, or a dead one: the page as is.
// Search engines may index it only if the owner has a public profile (`listed`).
const API = "https://api.jaybulb.com";   // KERNEL_API overrides it for a local test
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);

export function cardMeta(row, url) {
  const title = `${row.title} · Kernel`;
  const desc = `Chapter summaries of ${row.title}, to read or hear.`;
  const image = /^https:\/\//.test(row.cover || "") ? row.cover : new URL("/og.png", url).href;
  return [["og:title", title], ["og:description", desc], ["og:image", image], ["og:url", url], ["og:type", "article"],
    ["twitter:card", row.cover ? "summary" : "summary_large_image"], ["twitter:title", title], ["twitter:image", image]]
    .map(([k, v]) => `<meta ${k.startsWith("og:") ? "property" : "name"}="${k}" content="${esc(v)}">`).join("\n") + `\n<meta name="description" content="${esc(desc)}">`;
}

export async function onRequestGet({ request, env }) {
  const page = await env.ASSETS.fetch(request);
  const t = new URL(request.url).searchParams.get("t");
  if (!t || !page.ok) return page;
  const rows = await fetch(`${env.KERNEL_API || API}/rpc/shared_summary`, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ t }) })
    .then((r) => (r.ok ? r.json() : [])).catch(() => []);
  const row = Array.isArray(rows) ? rows[0] : null;
  if (!row?.title) return page;
  return new HTMLRewriter()
    .on("title", { element: (e) => e.setInnerContent(`${row.title} · Kernel`) })
    .on("head", { element: (e) => e.append(cardMeta(row, request.url), { html: true }) })
    // Listed only when the owner turned on a public profile; every other shared page stays out of search.
    .on('meta[name="robots"]', { element: (e) => { if (row.listed) e.setAttribute("content", "index, follow"); } })
    .transform(page);
}
