// GET -> { paid } for the signed-in account. POST -> { url } of the Stripe Payment Link for the $1 that
// unlocks natural voices on the web (the apps are paid upfront in the App Store). The webhook flips the flag.
// Env: STRIPE_PAYMENT_LINK, TTS_KV (binding).
import { userOf } from "./speak.js";

export async function onRequest({ request, env }) {
  const uid = await userOf(request.headers.get("authorization") || "");
  if (!uid) return json({ error: "Sign in required." }, 401);
  if (request.method === "GET") return json({ paid: !!(env.TTS_KV && await env.TTS_KV.get(`paid:${uid}`)) });
  if (request.method !== "POST") return json({ error: "GET or POST" }, 405);
  if (!env.STRIPE_PAYMENT_LINK) return json({ error: "Checkout is off." }, 503);
  // A Stripe Payment Link needs no API key: client_reference_id rides along and comes back in the webhook.
  return json({ url: `${env.STRIPE_PAYMENT_LINK}?client_reference_id=${encodeURIComponent(uid)}` });
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}
