// POST { texts: [string] } -> { vectors: [[number]] }
// Search by meaning on the web: each line of your summaries becomes a vector once (kept in the browser by
// meaning.js), and each search one more; the closest lines win. Signed-in accounts only, and metered in KV
// like Ask, so it cannot become a free embedding endpoint. The apps do this on the device instead.
import { tooMany, slowDown } from "../../src/lib/quota.js";
import { userOf, spend } from "./speak.js";

const MODEL = "@cf/baai/bge-small-en-v1.5";
const MAX_TEXTS = 100, MAX_CHARS = 2000;

export async function onRequest({ request, env }) {
  if (await tooMany(request, "embed")) return slowDown();
  if (request.method !== "POST") return json({ error: "POST only" }, 405);
  const uid = await userOf(request.headers.get("authorization") || "");
  if (!uid) return json({ error: "Sign in required." }, 401);
  const body = await request.json().catch(() => ({}));
  const texts = (Array.isArray(body.texts) ? body.texts : []).slice(0, MAX_TEXTS).map(t => String(t).slice(0, MAX_CHARS)).filter(t => t.trim());
  if (!texts.length) return json({ error: "Nothing to read." }, 400);
  const chars = texts.reduce((n, t) => n + t.length, 0);
  const over = await spend(env.TTS_KV, `u:${uid}`, chars, { day: +env.EMBED_DAILY_CHARS || 3000000, month: +env.EMBED_MONTHLY_CHARS || 60000000 }, new Date(), "embed:");
  if (over) return json({ error: "Search by meaning is resting until tomorrow." }, 429);
  try {
    const out = await env.AI.run(MODEL, { text: texts });
    return json({ vectors: out.data.map(v => v.map(x => Math.round(x * 1e4) / 1e4)) });   // 4 places is plenty for ranking, and a quarter of the bytes
  } catch {
    return json({ error: "Could not read that right now." }, 502);
  }
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: { "content-type": "application/json" } });
}
