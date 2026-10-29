// POST /api/forget, signed in. The apps and the web call it just before deleting an account, so nothing about
// you stays here either: your voice usage counters, your $1 record, and the narration made from your books' lines.
// ponytail: a line another reader shares word for word is deleted too; it is simply made again if they play it.
import { userOf, pickModel, DEFAULTS, sha } from "./speak.js";
const API = "https://api.jaybulb.com";

/** Every TTS_KV key that belongs to this account: counters (`who` is `u:<uid>` in speak.js) and stored lines. */
export async function forgetKeys(uid, rows, env, list) {
  const keys = [`paid:${uid}`];
  for (const pre of ["d:", "um:", "aura:d:", "aura:um:"]) keys.push(...await list(`${pre}u:${uid}:`));
  const lines = new Set(rows.flatMap(r => Object.values(r.listen?.chapters || {}).flat().map(l => String(l?.line || "").trim().slice(0, 600))).filter(Boolean));
  const voices = [env.TTS_VOICE_A || DEFAULTS.A, env.TTS_VOICE_B || DEFAULTS.B], models = [...new Set([pickModel(env, 1), pickModel(env, 0)])];
  for (const t of lines) {
    for (const m of models) for (const v of voices) keys.push(`a:${await sha(`${m}|${v}|${t}`)}`);
    keys.push(`a:${await sha(`aura-2|${env.TTS_AURA_VOICE || "thalia"}|${t}`)}`);
  }
  return keys;
}

export async function onRequestPost({ request, env }) {
  const auth = request.headers.get("authorization") || "";
  const uid = await userOf(auth, request.headers.get("apikey"));
  if (!uid) return Response.json({ error: "Sign in required." }, { status: 401 });
  const kv = env.TTS_KV;
  if (!kv) return Response.json({ cleared: 0 });
  const rows = await fetch(`${API}/rest/bookrank_summaries?select=listen`, { headers: { authorization: auth } }).then(r => (r.ok ? r.json() : [])).catch(() => []);
  const list = async prefix => (await kv.list({ prefix })).keys.map(k => k.name);
  let cleared = 0;
  for (const k of await forgetKeys(uid, Array.isArray(rows) ? rows : [], env, list)) { try { await kv.delete(k); cleared++; } catch {} }
  return Response.json({ cleared });
}
