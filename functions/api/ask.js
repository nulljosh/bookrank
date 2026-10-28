// POST { text, title, question } -> { answer }
// Answers one question about one chapter, from that chapter's notes only. Signed-in accounts
// only, and metered in KV like the voices (per account per day, the whole app per month), so it
// cannot become a free unmetered model proxy.
import { userOf, spend } from "./speak.js";

const MODEL = "@cf/meta/llama-3.3-70b-instruct-fp8-fast";
const MAX_CHARS = 24000;

export async function onRequest({ request, env }) {
  if (request.method !== "POST") return json({ error: "POST only" }, 405);
  const uid = await userOf(request.headers.get("authorization") || "");
  if (!uid) return json({ error: "Sign in required." }, 401);
  const body = await request.json().catch(() => ({}));
  const text = String(body.text || "").trim().slice(0, MAX_CHARS);
  const question = String(body.question || "").trim().slice(0, 500);
  if (!text || !question) return json({ error: "Ask a question about a chapter." }, 400);
  const over = await spend(env.TTS_KV, `u:${uid}`, text.length + question.length, { day: +env.ASK_DAILY_CHARS || 150000, month: +env.ASK_MONTHLY_CHARS || 5000000 }, new Date(), "ask:");
  if (over) return json({ error: over === "day" ? "That is enough questions for today. Try again tomorrow." : "Questions are paused for the rest of the month." }, 429);
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
