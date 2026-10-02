// POST { text, host: "A"|"B", ch?, token? } -> { audio: base64 mp3, words: [{ i, n, t }] }
// Natural voices through ElevenLabs, with the time each word starts (i = char index, n = length,
// t = seconds) so the player can light the word as it is spoken. Same gate as /api/narrate:
// signed in, or a live share token.
//
// The plan is a few dollars a month, so this spends carefully:
//  - every line is stored for good in KV by (model, voice, text): a line is paid for once, ever
//  - a monthly character budget for the whole app and a daily one per account; over either, the
//    answer is 429 and the player drops to the device voice, so Listen never breaks
//  - chapter one of a book gets the better model (TTS_MODEL_BEST); the rest use the cheap one
// Natural voices are what the $1 buys. The App Store apps are paid upfront, so they say so with an
// X-Bookrank-App header; on the web a signed-in account needs a paid flag in KV (set by the Stripe
// webhook). Unpaid gets 402 and the player uses the device voice. Share links stay open. The header is
// not proof, only the cheap check; the gate stays off until STRIPE_PAYMENT_LINK is set, so nothing breaks before checkout exists; the character caps below bound the cost either way.
// Env (all optional): ELEVENLABS_API_KEY, TTS_KV (binding), TTS_MODEL, TTS_MODEL_BEST, TTS_VOICE_A,
// TTS_VOICE_B, TTS_MONTHLY_CHARS (default 25000), TTS_DAILY_CHARS (default 6000).
import { isSignedIn, isShared } from "./narrate.js";

const SUPABASE_URL = "https://tjsxsqlxjmanwvmywwvw.supabase.co";
const SUPABASE_ANON = "sb_publishable_3a5WLExQ3oF_kPV3KRCjdg_iEOiHO90";
const DEFAULTS = { A: "Xb7hH8MSUJpSbSDYk0k2", B: "JBFqnCBsd6RMkjVDRZzb" }; // Alice, George: voices the free plan can use
const MAX = 600;

export async function onRequest({ request, env }) {
  if (request.method !== "POST") return json({ error: "POST only" }, 405);
  if (!env.ELEVENLABS_API_KEY) return json({ error: "Natural voices are off." }, 503);
  const body = await request.json().catch(() => ({}));
  const text = String(body.text || "").trim().slice(0, MAX);
  const host = body.host === "B" ? "B" : "A";
  if (!text) return json({ error: "Nothing to say." }, 400);
  const token = typeof body.token === "string" && body.token.length > 8 ? body.token : "";
  const auth = request.headers.get("authorization") || "";
  if (!(token ? await isShared(token) : await isSignedIn(auth))) return json({ error: "Sign in required." }, 401);

  const uid = token ? null : await userOf(auth);
  if (env.STRIPE_PAYMENT_LINK && !token && !(request.headers.get("x-bookrank-app") || (uid && env.TTS_KV && await env.TTS_KV.get(`paid:${uid}`)))) {
    return json({ error: "Natural voices are $1.", pay: true }, 402);
  }

  const voice = (host === "B" ? env.TTS_VOICE_B : env.TTS_VOICE_A) || DEFAULTS[host];
  const model = pickModel(env, +body.ch);
  const key = `a:${await sha(`${model}|${voice}|${text}`)}`;
  const hdr = { ...JSON_HEADERS, "X-Tts-Store": env.TTS_KV ? "kv" : "none" };  // whether the line store is bound, for QA

  if (env.TTS_KV) {
    const hit = await env.TTS_KV.get(key);
    if (hit) return new Response(hit, { headers: { ...hdr, "X-Tts-Cache": "hit" } });
  }

  const who = token ? `t:${token.slice(0, 12)}` : `u:${uid || "x"}`;
  const caps = { month: +env.TTS_MONTHLY_CHARS || 25000, day: +env.TTS_DAILY_CHARS || 6000 };
  const over = await spend(env.TTS_KV, who, text.length, caps, new Date());
  if (over) return json({ error: `Voice limit reached (${over}). Using the device voice.` }, 429);

  const r = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voice}/with-timestamps?output_format=mp3_44100_64`, {
    method: "POST",
    headers: { "xi-api-key": env.ELEVENLABS_API_KEY, "Content-Type": "application/json" },
    body: JSON.stringify({ text, model_id: model }),
  });
  if (!r.ok) return json({ error: "The voice service did not answer." }, 502);
  const out = await r.json();
  const payload = JSON.stringify({ audio: out.audio_base64, words: words(text, out.alignment || out.normalized_alignment) });
  if (env.TTS_KV) await env.TTS_KV.put(key, payload);
  return new Response(payload, { headers: { ...hdr, "X-Tts-Cache": "miss" } });
}

/** Chapter one (index 0) of a book gets the better model, everything else the cheap one. */
export function pickModel(env, ch) {
  const cheap = env.TTS_MODEL || "eleven_flash_v2_5";
  return ch === 0 && env.TTS_MODEL_BEST ? env.TTS_MODEL_BEST : cheap;
}

/** Charge `chars` against the month and the day. Returns "month" or "day" when a cap is hit, else null.
 *  Without a KV binding there is nothing to count against, so it does not block (the plan itself still caps). */
export async function spend(kv, who, chars, caps, now) {
  if (!kv) return null;
  const day = now.toISOString().slice(0, 10), month = day.slice(0, 7);
  const mk = `m:${month}`, dk = `d:${who}:${day}`;
  const [m, d] = await Promise.all([kv.get(mk), kv.get(dk)]).then(r => r.map(v => +v || 0));
  if (m + chars > caps.month) return "month";
  if (d + chars > caps.day) return "day";
  await Promise.all([kv.put(mk, String(m + chars)), kv.put(dk, String(d + chars), { expirationTtl: 172800 })]);
  return null;
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

export async function userOf(auth) {
  if (!auth.startsWith("Bearer ")) return null;
  const r = await fetch(`${SUPABASE_URL}/auth/v1/user`, { headers: { authorization: auth, apikey: SUPABASE_ANON } });
  return r.ok ? (await r.json()).id || null : null;
}

async function sha(s) {
  return [...new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s)))].map(b => b.toString(16).padStart(2, "0")).join("");
}

const JSON_HEADERS = { "Content-Type": "application/json", "Cache-Control": "public, max-age=31536000, immutable" };
function json(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}
