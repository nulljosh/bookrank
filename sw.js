// ponytail: network-first for pages, cache-first for the hashed assets they name.
// Bump CACHE to evict everything a previous version stored.
const CACHE = "kernel-v30";
// Pages under their pretty paths (Pages 308s /x.html to /x), plus everything they load, so the shelf opens with no connection.
const FILES = ["/", "/library", "/share", "/profile", "/privacy", "/listen.js", "/listen.css", "/covers.js", "/goal.js", "/marks.js", "/search.js", "/meaning.js", "/card.js", "/goodreads-export.js", "/kindle.js", "/epub.js", "/spark.js",
  "/webmcp.js", "/onboarding.js", "/tokens.css", "/brand/tokens.css", "/books.json", "/favicon.svg", "/icon-192.png", "/manifest.webmanifest",
  ...["Regular", "Medium", "Semibold", "Bold"].map(w => `/fonts/KernelSans-${w}.woff2`),
  "https://cdn.jsdelivr.net/npm/marked@15.0.12/marked.min.js", "https://cdnjs.cloudflare.com/ajax/libs/dompurify/3.1.7/purify.min.js"];
const CDN = ["https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"];   // pinned versions, so a cached copy never goes stale
// /library.html and /library are one page; the cache keeps it under the pretty path.
const pretty = u => { const url = new URL(u); url.pathname = url.pathname.replace(/(\/index)?\.html$/, "") || "/"; url.search = ""; return url.href; };

self.addEventListener("install", e => {
  // A single missing file fails the whole addAll, so tolerate misses.
  e.waitUntil(caches.open(CACHE)
    .then(c => Promise.all(FILES.map(f => c.add(f).catch(() => {}))))
    .then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys()
    .then(ks => Promise.all(ks.filter(k => k.startsWith("kernel-") && k !== CACHE)   // bookrank-data (the offline books) outlives every version
      .map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

const save = (req, res) => {
  if (res.ok && (res.type === "basic" || res.type === "cors")) {
    const copy = res.clone();
    caches.open(CACHE).then(c => c.put(req, copy));
  }
  return res;
};

self.addEventListener("fetch", e => {
  // Same-origin GETs and the two CDN scripts only; APIs are cross-origin and stay network-only.
  // /api/ answers change per query (each Goodreads shelf), so they never come from here.
  const url = new URL(e.request.url);
  if (e.request.method !== "GET" || url.pathname.startsWith("/api/") || (url.origin !== location.origin && !CDN.includes(url.origin))) return;

  // HTML must never come from cache first: it names the hashed bundles, so one
  // stale page pins a whole stale build and the site stops shipping updates to
  // anyone who has already visited. Network first, cache only as an offline fallback.
  if (e.request.mode === "navigate") {
    e.respondWith(
      fetch(e.request)
        .then(res => save(pretty(e.request.url), res))
        .catch(() => caches.match(pretty(e.request.url))
          .then(hit => hit || caches.match(FILES[0])))
    );
    return;
  }

  // Everything else is content-hashed, so a cache hit is always the right file.
  e.respondWith(
    caches.match(e.request, { ignoreSearch: true }).then(hit => hit ||
      fetch(e.request).then(res => save(e.request, res)))
  );
});
