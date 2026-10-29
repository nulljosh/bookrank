// POST { text, host: "A"|"B", ch?, token? } -> { audio: base64 mp3, words: [{ i, n, t }] }
// Natural voices through ElevenLabs, with the time each word starts (i = char index, n = length,
// t = seconds) so the player can light the word as it is spoken. Same gate as /api/narrate:
// signed in, or a live share token.
//
// The plan is a few dollars a month, so this spends carefully:
//  - every line is stored for good in KV by (model, voice, text): a line is paid for once, ever
//  - a monthly character budget for the whole app and a daily one per account; over either (or when
//    the ElevenLabs plan itself runs dry) the line goes to Cloudflare's Aura voice, with its own
//    larger caps; only past those is the answer 429 and the player drops to the device voice
//  - chapter one of a book gets the better model (TTS_MODEL_BEST); the rest use the cheap one
// Natural voices are what the $1 buys. The App Store apps are paid upfront, so they say so with an
// X-Bookrank-App header; on the web a signed-in account needs a paid flag in KV (set by the Stripe
// webhook). Unpaid gets 402 and the player uses the device voice. Share links stay open. The header is
// not proof, only the cheap check; the gate stays off until STRIPE_PAYMENT_LINK is set, so nothing breaks before checkout exists; the character caps below bound the cost either way.
// Env (all optional): ELEVENLABS_API_KEY, TTS_KV (binding), TTS_MODEL, TTS_MODEL_BEST, TTS_VOICE_A,
// TTS_VOICE_B, TTS_MONTHLY_CHARS (default 50000), TTS_DAILY_CHARS (default 8000), AI (binding),
// TTS_AURA_VOICE (default thalia), TTS_AURA_MONTHLY_CHARS (default 2000000), TTS_AURA_DAILY_CHARS (default 60000).
import { isSignedIn, isShared } from "./narrate.js";
import { appProof } from "./apple.js";

const API = "https://api.jaybulb.com";
export const DEFAULTS = { A: "Xb7hH8MSUJpSbSDYk0k2", B: "JBFqnCBsd6RMkjVDRZzb" }; // Alice, George: voices the free plan can use
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
  if (!(token ? await isShared(token) : await isSignedIn(auth, request.headers.get("apikey")))) return json({ error: "Sign in required." }, 401);

  const uid = token ? null : await userOf(auth, request.headers.get("apikey"));
  if (env.STRIPE_PAYMENT_LINK && !token && !(await boughtApp(request, auth) || (uid && env.TTS_KV && await env.TTS_KV.get(`paid:${uid}`)))) {
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
  const over = await spend(env.TTS_KV, who, text.length, capsOf(env), new Date());

  // ElevenLabs while its budget lasts; past it, or when its plan runs dry, Cloudflare's own
  // Aura voice, so Listen keeps a natural voice instead of dropping to the device one.
  const r = over ? null : await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voice}/with-timestamps?output_format=mp3_44100_64`, {
    method: "POST",
    headers: { "xi-api-key": env.ELEVENLABS_API_KEY, "Content-Type": "application/json" },
    body: JSON.stringify({ text, model_id: model }),
  });
  if (r?.ok) {
    const out = await r.json();
    const payload = JSON.stringify({ audio: out.audio_base64, words: words(text, out.alignment || out.normalized_alignment) });
    if (env.TTS_KV) await env.TTS_KV.put(key, payload);
    return new Response(payload, { headers: { ...hdr, "X-Tts-Cache": "miss" } });
  }
  return aura(env, text, who, hdr, over);
}

/** Cloudflare Workers AI's Aura-2 voice: $0.03 per 1,000 characters, no monthly wall. Stored for
 *  good like the ElevenLabs lines, with its own daily cap per account so one listener can't run up the bill. */
async function aura(env, text, who, hdr, why) {
  const fail = json({ error: why ? `Voice limit reached (${why}). Using the device voice.` : "The voice service did not answer." }, why ? 429 : 502);
  if (!env.AI) return fail;
  const speaker = env.TTS_AURA_VOICE || "thalia";
  const key = `a:${await sha(`aura-2|${speaker}|${text}`)}`;
  if (env.TTS_KV) {
    const hit = await env.TTS_KV.get(key);
    if (hit) return new Response(hit, { headers: { ...hdr, "X-Tts-Cache": "hit", "X-Tts-Voice": "aura" } });
  }
  const over = await spend(env.TTS_KV, who, text.length, { month: +env.TTS_AURA_MONTHLY_CHARS || 2000000, day: +env.TTS_AURA_DAILY_CHARS || 60000 }, new Date(), "aura:");
  if (over) return json({ error: `Voice limit reached (${over}). Using the device voice.` }, 429);
  let mp3;
  try {
    const out = await env.AI.run("@cf/deepgram/aura-2-en", { text, speaker, encoding: "mp3", bit_rate: AURA_BPS }, { returnRawResponse: true });
    mp3 = new Uint8Array(await new Response(out.body ?? out).arrayBuffer());
  } catch { return fail; }
  if (!mp3.length) return fail;
  const payload = JSON.stringify({ audio: b64(mp3), words: estWords(text, mp3.length * 8 / AURA_BPS) });
  if (env.TTS_KV) await env.TTS_KV.put(key, payload);
  return new Response(payload, { headers: { ...hdr, "X-Tts-Cache": "miss", "X-Tts-Voice": "aura" } });
}
const AURA_BPS = 48000;  // constant-bitrate mp3, so bytes give the length in seconds

/** Aura gives no timings; spread the words over the clip by character position. ponytail: close
 *  enough to light the right word; real timings would need a speech-to-text pass. */
export function estWords(text, secs) {
  return [...text.matchAll(/\S+/g)].map(m => ({ i: m.index, n: m[0].length, t: +(secs * m.index / text.length).toFixed(3) }));
}

function b64(bytes) {
  let s = "";
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
}

/** Chapter one (index 0) of a book gets the better model, everything else the cheap one. */
export function pickModel(env, ch) {
  const cheap = env.TTS_MODEL || "eleven_flash_v2_5";
  return ch === 0 && env.TTS_MODEL_BEST ? env.TTS_MODEL_BEST : cheap;
}

/** One place for the budget. ~2,500 characters is a chapter; 50,000 a month fits the $5 ElevenLabs plan, 8,000 a day is about three chapters. */
export const capsOf = env => ({ month: +env.TTS_MONTHLY_CHARS || 50000, day: +env.TTS_DAILY_CHARS || 8000 });

/** Charge `chars` against the month and the day. Returns "month" or "day" when a cap is hit, else null.
 *  Without a KV binding there is nothing to count against, so it does not block (the plan itself still caps). */
export async function spend(kv, who, chars, caps, now, pre = "") {
  if (!kv) return null;
  const day = now.toISOString().slice(0, 10), month = day.slice(0, 7);
  const mk = `${pre}m:${month}`, dk = `${pre}d:${who}:${day}`, uk = `${pre}um:${who}:${month}`;
  const [m, d] = await Promise.all([kv.get(mk), kv.get(dk)]).then(r => r.map(v => +v || 0));
  if (m + chars > caps.month) return "month";
  if (d + chars > caps.day) return "day";
  const u = +(await kv.get(uk)) || 0;   // what this account spent this month, for the usage readout
  await Promise.all([kv.put(mk, String(m + chars)), kv.put(dk, String(d + chars), { expirationTtl: 172800 }), kv.put(uk, String(u + chars), { expirationTtl: 3456000 })]);
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

// The installed apps still sign in through Supabase and send its anon key as `apikey`; a token
// spark-api does not know is looked up there so their daily cap and usage meter work. Drop when they move over.
export async function userOf(auth, apikey = null) {
  if (!auth.startsWith("Bearer ")) return null;
  const r = await fetch(`${API}/auth/user`, { headers: { authorization: auth } });
  if (r.ok) return (await r.json()).id || null;
  if (!apikey) return null;
  const sb = await fetch("https://tjsxsqlxjmanwvmywwvw.supabase.co/auth/v1/user", { headers: { authorization: auth, apikey } });
  return sb.ok ? (await sb.json()).id || null : null;
}

// The header alone let any signed-in web user skip the $1, so it only counts for a session the
// installed apps hold: a Supabase token that spark-api does not know.
// ponytail: someone who signs up on Supabase directly can still pass this; App Store proof
// (StoreKit AppTransaction JWS, verified here) closes it when the apps move to jaybulb-api.
// The App Store price pays for the voices: a signed AppTransaction from a bought copy (new builds),
// or the old header from a build that still signs in through Supabase.
async function boughtApp(request, auth) {
  const proof = request.headers.get("x-kernel-receipt");
  if (proof) return !!(await appProof(proof, { bundleId: "com.heyitsmejosh.spine" }));
  return !!request.headers.get("x-bookrank-app") && await viaApp(auth, request.headers.get("apikey"));
}

export async function viaApp(auth, apikey) {
  if (!auth.startsWith("Bearer ") || !apikey) return false;
  if ((await fetch(`${API}/auth/user`, { headers: { authorization: auth } })).ok) return false;
  return (await fetch("https://tjsxsqlxjmanwvmywwvw.supabase.co/auth/v1/user", { headers: { authorization: auth, apikey } })).ok;
}

export async function sha(s) {
  return [...new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s)))].map(b => b.toString(16).padStart(2, "0")).join("");
}

const JSON_HEADERS = { "Content-Type": "application/json", "Cache-Control": "public, max-age=31536000, immutable" };
function json(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}
