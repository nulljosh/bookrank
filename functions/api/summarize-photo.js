// POST multipart/form-data { image } -> { text }
// Reads a photographed book page with Workers AI vision and returns the text/summary
// of that page. The image lives only in this request's memory: it is never written to
// disk, R2, or Supabase. Requires a signed-in Bookrank account (checked against Supabase
// auth) so this can't become a free public OCR endpoint.
const VISION_MODEL = "@cf/llava-hf/llava-1.5-7b-hf";
const SUPABASE_URL = "https://tjsxsqlxjmanwvmywwvw.supabase.co";
const SUPABASE_ANON = "sb_publishable_3a5WLExQ3oF_kPV3KRCjdg_iEOiHO90";
const MAX_BYTES = 8 * 1024 * 1024;

export async function onRequest({ request, env }) {
  if (request.method !== "POST") return json({ error: "POST only" }, 405);

  const auth = request.headers.get("authorization") || "";
  const authed = await isSignedIn(auth);
  if (!authed) return json({ error: "Sign in required." }, 401);

  const form = await request.formData().catch(() => null);
  const file = form?.get("image");
  if (!file || typeof file === "string") return json({ error: "No image." }, 400);
  if (file.size > MAX_BYTES) return json({ error: "Image too large." }, 400);

  const bytes = [...new Uint8Array(await file.arrayBuffer())];

  let out;
  try {
    out = await env.AI.run(VISION_MODEL, {
      image: bytes,
      prompt:
        "This is a photo of a page from a book. Summarize what happens or what is argued " +
        "on this page in 2-4 plain sentences. Do not describe the physical page, just its content.",
      max_tokens: 512,
    });
  } catch {
    return json({ error: "Could not read that photo." }, 502);
  }

  const text = (out?.description || out?.response || "").trim();
  if (!text) return json({ error: "Could not read that photo." }, 502);
  return json({ text });
}

async function isSignedIn(authHeader) {
  if (!authHeader.startsWith("Bearer ")) return false;
  const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { authorization: authHeader, apikey: SUPABASE_ANON },
  });
  return res.ok;
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: { "content-type": "application/json" } });
}
