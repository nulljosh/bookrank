// Browse by topic: a book's topics from its title, on the device. The keyword list below is plain JSON; scripts/build.py
// copies it into the apps as topics.json for Topics.swift. A book can sit in more than one topic.
// ponytail: title only; read the opening text too if titles leave too many books out.
const TOPICS = {
  "AI and tech": ["ai", "artificial intelligence", "machine learning", "agentic", "computer", "computing", "software", "programming", "code", "coding", "hackers?", "system design", "apple", "macos", "iphone", "internet", "tech", "technology", "video games?", "game design", "data"],
  "Money": ["money", "invest\\w*", "econom\\w*", "financ\\w*", "trading", "stocks?", "markets?", "budget\\w*", "tax\\w*", "debt", "wealth", "accounting", "business"],
  "Health": ["health\\w*", "exercise", "fitness", "diet", "nutrition", "sleep", "ibs", "sobriety", "sober", "medical", "medicine", "autism", "adhd", "anxiety"],
  "Science and math": ["science", "physics", "statistics", "biology", "chemistry", "math\\w*", "calculus", "algebra", "pre-calculus", "universe", "evolution"],
  "Lives and history": ["history", "biography", "becoming", "life of", "first \\d+ years", "memoir", "brothers", "optimist", "contrarian", "steve jobs"]
};

const RE = Object.fromEntries(Object.entries(TOPICS).map(([t, ks]) => [t, new RegExp(`\\b(?:${ks.join('|')})\\b`, 'i')]));
export const topicsOf = title => Object.keys(RE).filter(t => RE[t].test(title || ''));
/** The topics two books or more share, in the list's own order. */
export const shelfTopics = titles => Object.keys(RE).filter(t => titles.filter(x => RE[t].test(x || '')).length >= 2);
