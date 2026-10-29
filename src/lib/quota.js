// An hourly cap per person (by IP) on the routes that call a model or another site, so one caller cannot run
// up the Workers AI bill or get Goodreads to block us. Counted in the edge cache: free, and no KV writes.
// ponytail: per data centre and not atomic, so a burst can slip a few over; it is a brake, not a meter.
export const CAPS = { narrate: 120, ask: 60, embed: 600, photo: 120, goodreads: 60 };

export async function tooMany(request, route, cache = globalThis.caches?.default, now = Date.now()) {
  if (!cache) return false;
  const ip = request.headers.get("CF-Connecting-IP") || "local";
  const key = new Request(`https://quota.kernel.invalid/${route}/${encodeURIComponent(ip)}/${Math.floor(now / 3.6e6)}`);
  const hit = await cache.match(key);
  const n = hit ? Number(await hit.text()) || 0 : 0;
  if (n >= (CAPS[route] ?? 60)) return true;
  await cache.put(key, new Response(String(n + 1), { headers: { "Cache-Control": "max-age=3600" } }));
  return false;
}

export const slowDown = () => new Response(JSON.stringify({ error: "Too many requests this hour. Try again later." }),
  { status: 429, headers: { "content-type": "application/json", "retry-after": "600" } });
