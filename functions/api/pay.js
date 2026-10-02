// GET -> { paid } for the signed-in account. POST -> { url } of a Stripe Checkout page for the $1 that
// unlocks natural voices on the web (the apps are paid upfront in the App Store). The webhook flips the flag.
// Env: STRIPE_SECRET_KEY, STRIPE_PRICE_ID, TTS_KV (binding).
import { userOf } from "./speak.js";

export async function onRequest({ request, env }) {
  const uid = await userOf(request.headers.get("authorization") || "");
  if (!uid) return json({ error: "Sign in required." }, 401);
  if (request.method === "GET") return json({ paid: !!(env.TTS_KV && await env.TTS_KV.get(`paid:${uid}`)) });
  if (request.method !== "POST") return json({ error: "GET or POST" }, 405);
  if (!env.STRIPE_SECRET_KEY || !env.STRIPE_PRICE_ID) return json({ error: "Checkout is off." }, 503);
  const origin = new URL(request.url).origin;
  const form = new URLSearchParams({
    mode: "payment", "line_items[0][price]": env.STRIPE_PRICE_ID, "line_items[0][quantity]": "1",
    client_reference_id: uid, success_url: `${origin}/library.html?paid=1`, cancel_url: `${origin}/library.html`,
  });
  const r = await fetch("https://api.stripe.com/v1/checkout/sessions", {
    method: "POST", headers: { authorization: `Bearer ${env.STRIPE_SECRET_KEY}`, "content-type": "application/x-www-form-urlencoded" }, body: form,
  });
  const out = await r.json().catch(() => ({}));
  return r.ok && out.url ? json({ url: out.url }) : json({ error: "Checkout did not open." }, 502);
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}
