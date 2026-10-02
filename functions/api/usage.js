// GET -> how much natural voice this account and the app have used, so the apps can show a meter.
// { you: { day, month }, app: { month }, caps: { day, month } } in characters; about 2,500 characters is a chapter.
import { userOf, capsOf } from "./speak.js";

export async function onRequest({ request, env }) {
  const uid = await userOf(request.headers.get("authorization") || "");
  if (!uid) return json({ error: "Sign in required." }, 401);
  const now = new Date(), day = now.toISOString().slice(0, 10), month = day.slice(0, 7), kv = env.TTS_KV;
  const n = async k => (kv ? +(await kv.get(k)) || 0 : 0);
  const [yourDay, yourMonth, appMonth] = await Promise.all([n(`d:u:${uid}:${day}`), n(`um:u:${uid}:${month}`), n(`m:${month}`)]);
  return json({ you: { day: yourDay, month: yourMonth }, app: { month: appMonth }, caps: capsOf(env), chapter: 2500 });
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json", "Cache-Control": "no-store" } });
}
