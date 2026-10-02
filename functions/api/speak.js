// POST { text, host: "A"|"B", token? } -> { audio: base64 mp3, words: [{ i, n, t }] }
// Natural voices through ElevenLabs, with the time each word starts (i = char index, n = length,
// t = seconds) so the player can light the word as it is spoken. Every line is cached at the edge,
// so a line is paid for once. Same gate as /api/narrate: signed in, or a live share token.
// ponytail: per-colo Cache API, not a global store; move to R2 if a popular book re-bills per region.
import { isSignedIn, isShared } from "./narrate.js";

const VOICES = { A: "Xb7hH8MSUJpSbSDYk0k2", B: "JBFqnCBsd6RMkjVDRZzb" }; // Alice (clear educator), George (warm storyteller): default voices a free plan can use
const MODEL = "eleven_flash_v2_5";
const MAX = 600;

export async function onRequest({ request, env }) {
  if (request.method !== "POST") return json({ error: "POST only" }, 405);
  if (!env.ELEVENLABS_API_KEY) return json({ error: "Natural voices are off." }, 503);
  const body = await request.json().catch(() => ({}));
  const text = String(body.text || "").trim().slice(0, MAX);
  const voice = VOICES[body.host === "B" ? "B" : "A"];
  if (!text) return json({ error: "Nothing to say." }, 400);
  const token = typeof body.token === "string" && body.token.length > 8 ? body.token : "";
  if (!(token ? await isShared(token) : await isSignedIn(request.headers.get("authorization") || ""))) return json({ error: "Sign in required." }, 401);

  const hash = [...new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(`${MODEL}|${voice}|${text}`)))].map(b => b.toString(16).padStart(2, "0")).join("");
  const key = new Request(`https://speak.cache/v1/${hash}`);
  const hit = await caches.default.match(key);
  if (hit) return hit;

  const r = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voice}/with-timestamps?output_format=mp3_44100_64`, {
    method: "POST",
    headers: { "xi-api-key": env.ELEVENLABS_API_KEY, "Content-Type": "application/json" },
    body: JSON.stringify({ text, model_id: MODEL }),
  });
  if (!r.ok) return json({ error: "The voice service did not answer." }, 502);
  const out = await r.json();
  const res = json({ audio: out.audio_base64, words: words(text, out.alignment || out.normalized_alignment) });
  res.headers.set("Cache-Control", "public, max-age=31536000, immutable");
  await caches.default.put(key, res.clone());
  return res;
}

/** ElevenLabs gives a start time per character; the player wants one per word. */
export function words(text, al) {
  if (!al?.characters?.length) return [];
  const starts = al.character_start_times_seconds;
  const list = [];
  for (const m of text.matchAll(/\S+/g)) {
    const t = starts[Math.min(m.index, starts.length - 1)];
    if (typeof t === "number") list.push({ i: m.index, n: m[0].length, t });
  }
  return list;
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}
