#!/usr/bin/env python3
"""Parse book_rankings.md into ios/Spine/Resources/books.json. Run after editing book_rankings.md."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "book_rankings.md"
DEST = ROOT / "ios/Spine/Resources/books.json"

entry_re = re.compile(
    r"^### (\d+)\. \[(.+?)\]\((.+?)\) by (.+?)\n"
    r"\*\*Rating:\*\* ([\d.]+)/5 \| \*\*Reviews:\*\* (.+?)(?: \((.+?)\))?\n"
    r"\*\*Notes:\*\* (.+?)$",
    re.MULTILINE,
)

text = SRC.read_text()
books = []
for m in entry_re.finditer(text):
    rank, title, url, author, rating, reviews, badge, notes = m.groups()
    books.append({
        "rank": int(rank),
        "title": title,
        "goodreadsURL": url,
        "author": author,
        "rating": float(rating),
        "reviewCount": reviews.strip(),
        "badges": [badge] if badge else [],
        "notes": notes.strip(),
    })

DEST.parent.mkdir(parents=True, exist_ok=True)
DEST.write_text(json.dumps(books, indent=2, ensure_ascii=False) + "\n")
print(f"OK: {len(books)} books -> {DEST}")
