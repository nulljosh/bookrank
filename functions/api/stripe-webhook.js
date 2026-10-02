// Stripe tells us a $1 checkout finished; flag that account as paid in KV so /api/speak opens up.
// Env: STRIPE_WEBHOOK_SECRET, TTS_KV (binding). Signature is checked with WebCrypto (no SDK on Workers).
export async function onRequest({ request, env }) {
  if (request.method !== "POST") return new Response("POST only", { status: 405 });
  const body = await request.text();
  if (!(await sigOk(body, request.headers.get("stripe-signature") || "", env.STRIPE_WEBHOOK_SECRET || "", Date.now() / 1000))) {
    return new Response("bad signature", { status: 400 });
  }
  const ev = JSON.parse(body);
  const s = ev.data?.object;
  if (ev.type === "checkout.session.completed" && s?.payment_status === "paid" && s.client_reference_id && env.TTS_KV) {
    await env.TTS_KV.put(`paid:${s.client_reference_id}`, "1");
  }
  return new Response("ok");
}

/** Stripe-Signature is "t=<unix>,v1=<hex hmac of `t.body`>". Reject stale (over 5 minutes) or wrong signatures. */
export async function sigOk(body, header, secret, now) {
  const parts = Object.fromEntries(header.split(",").map(p => p.split("=")));
  if (!secret || !parts.t || !parts.v1 || Math.abs(now - +parts.t) > 300) return false;
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const mac = [...new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${parts.t}.${body}`)))].map(b => b.toString(16).padStart(2, "0")).join("");
  return mac === parts.v1;
}
