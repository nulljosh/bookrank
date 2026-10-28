// POST { text, title, question } -> { answer }
// Answers one question about one chapter, from that chapter's notes only. Signed-in accounts
// only (same gate as narrate), so this is not a free public chatbot.
import { isSignedIn } from "./narrate.js";

const MODEL = "@cf/meta/llama-3.3-70b-instruct-fp8-fast";
const MAX_CHARS = 24000;

export async function onRequest({ request, env }) {
  if (request.method !== "POST") return json({ error: "POST only" }, 405);
  if (!(await isSignedIn(request.headers.get("authorization") || ""))) return json({ error: "Sign in required." }, 401);
  const body = await request.json().catch(() => ({}));
  const text = String(body.text || "").trim().slice(0, MAX_CHARS);
  const question = String(body.question || "").trim().slice(0, 500);
  if (!text || !question) return json({ error: "Ask a question about a chapter." }, 400);
  let out;
  try {
    out = await env.AI.run(MODEL, { messages: messages(String(body.title || "this book").slice(0, 200), text, question), max_tokens: 400 });
  } catch {
    return json({ error: "Could not answer that right now." }, 502);
  }
  const answer = (out?.response || "").trim();
  return answer ? json({ answer }) : json({ error: "Could not answer that right now." }, 502);
}

export function messages(title, text, question) {
  return [
    { role: "system", content:
      "You answer a reader's question about one book chapter, using only the chapter notes given. " +
      "Plain spoken English, 1 to 4 short sentences, no markdown, no lists. " +
      "If the notes do not cover it, say so in one sentence and offer what they do say that is closest." },
    { role: "user", content: `Book: ${title}\n\nChapter notes:\n${text}\n\nQuestion: ${question}` },
  ];
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: { "content-type": "application/json" } });
}
