#!/usr/bin/env python3
"""Write ios/Kernel/Resources/books.json (the app's ranked list) from the root books.json.

books.json is the only file to hand-edit. The web shelf, picks, library and
book_rankings.md outputs were retired 2026-09-21.

It refuses to write anything if an entry cannot be rendered. The predecessor
(scripts/export-books.py) skipped unparseable entries silently and shipped an app
missing 40 of 111 books for months, which is the whole reason this file exists.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BOOKS = ROOT / "books.json"

# Hard requirements: without these the row cannot be rendered at all.
REQUIRED = {
    "ranked": ("rank", "title", "author", "goodreadsURL", "notes"),
    "recent": ("title",),
    "toRead": ("title",),
    "summary": ("title",),
    "pick": ("rank", "title", "blurb"),
}
# Soft: renders fine when blank (the page has always tolerated an empty author
# div), but it is missing content worth surfacing rather than burying.
EXPECTED = {"recent": ("author",), "toRead": ("author",), "summary": ("author",)}


def load():
    books = json.loads(BOOKS.read_text())
    problems = []
    for i, b in enumerate(books):
        section = b.get("section")
        if section not in REQUIRED:
            problems.append(f"entry {i}: unknown section {section!r}")
            continue
        for field in REQUIRED[section]:
            if b.get(field) in (None, ""):
                problems.append(f"entry {i} ({b.get('title', '?')}): missing {field}")
    if problems:
        raise SystemExit("books.json is not renderable:\n  " + "\n  ".join(problems))

    gaps = [f"{b['title']}: no {f}"
            for b in books
            for f in EXPECTED.get(b.get("section"), ())
            if not b.get(f)]
    for g in gaps:
        print(f"warning: {g}")
    return books


def by(books, section):
    return [b for b in books if b["section"] == section]


# --- iOS resources -----------------------------------------------------------

def write_ios(books):
    res = ROOT / "ios/Kernel/Resources"
    ranked = [{
        "rank": b["rank"],
        "title": b["title"],
        "goodreadsURL": b["goodreadsURL"],
        "author": b["author"],
        "rating": b.get("rating"),
        "reviewCount": b.get("reviewCount"),
        "badges": b.get("badges", []),
        "cover": b.get("cover"),
        "notes": b["notes"],
    } for b in by(books, "ranked")]
    (res / "books.json").write_text(json.dumps(ranked, indent=2, ensure_ascii=False) + "\n")
    (res / "topics.json").write_text(topics_json())   # the browse-by-topic keywords from topics.js
    return len(ranked)


def topics_json():
    """The JSON object literal in topics.js, checked, for Topics.swift."""
    js = (ROOT / "topics.js").read_text()
    body = js[js.index("const TOPICS = ") + 15:js.index("};") + 1]
    return json.dumps(json.loads(body), indent=2, ensure_ascii=False) + "\n"


if __name__ == "__main__":
    books = load()
    n = write_ios(books)
    unrated = sum(1 for b in by(books, "ranked") if b.get("rating") is None)
    print(f"OK: {len(books)} entries -> ios resources (web shelf retired 2026-09-21)")
    print(f"  ranked {n} ({unrated} with no Goodreads rating, all still shipped)")
