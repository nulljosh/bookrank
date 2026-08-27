#!/usr/bin/env python3
"""Generate every book-list surface from the root books.json.

books.json is the only file to hand-edit. This writes:
  - ios/Bookrank/Resources/books.json   (ranked list for the app)
  - ios/Bookrank/Resources/picks.json   (top picks)
  - ios/Bookrank/Resources/library.json (to-read; loans stay empty by policy)
  - book_rankings.md                    (markdown mirror of the ranked list)
  - rankings.html                       (rows inside the generated:* markers only)

It refuses to write anything if an entry cannot be rendered. The predecessor
(scripts/export-books.py) skipped unparseable entries silently and shipped an app
missing 40 of 111 books for months, which is the whole reason this file exists.
"""
import html
import json
import re
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


def esc(s):
    return html.escape(s, quote=False)


def cover_html(b):
    if b.get("cover"):
        return (f'<img class="cover" src="{b["cover"]}" alt="" loading="lazy" '
                f'width="44" height="66" referrerpolicy="no-referrer">')
    return '<div class="cover cover-empty" aria-hidden="true"></div>'


# --- rankings.html rows ------------------------------------------------------

def row_simple(b):
    """Recently Read / To Read / Summaries row."""
    title = esc(b["title"])
    if b.get("linked"):
        title = f'<a href="library.html">{title}</a>'
    if b.get("badge"):
        title += ' <a href="library.html" class="badge">Summary</a>'
    return (f'<li class="book"><div class="rank">·</div>{cover_html(b)}'
            f'<div class="book-info"><div class="book-title">{title}</div>'
            f'<div class="author">{esc(b.get("author") or "")}</div></div></li>')


def row_ranked(b):
    rating = ""
    if b.get("rating") is not None:
        badges = "".join(f'<span class="badge">{esc(x)}</span>' for x in b.get("badges", []))
        rating = (f'<div class="rating"><span class="rating-value">{b["rating"]:.2f}/5</span>'
                  f'<span class="reviews">{esc(b["reviewCount"])}</span>{badges}</div>')
    return (f'<li class="book"><div class="rank">{b["rank"]:02d}</div>{cover_html(b)}'
            f'<div class="book-info"><div class="book-title">'
            f'<a href="{b["goodreadsURL"]}" target="_blank">{esc(b["title"])}</a></div>'
            f'<div class="author">{esc(b["author"])}</div>{rating}'
            f'<div class="notes">{esc(b["notes"])}</div></div></li>')


def row_pick(b):
    return (f'<li><span class="pick-num">{b["rank"]:02d}</span>{cover_html(b)}'
            f'<span class="book-info"><strong>{esc(b["title"])}</strong>: '
            f'{esc(b["blurb"])}</span></li>')


def write_html(books):
    page = ROOT / "rankings.html"
    text = page.read_text()
    blocks = {
        "recent": (by(books, "recent"), row_simple, "      "),
        "toRead": (by(books, "toRead"), row_simple, "      "),
        "picks": (by(books, "pick"), row_pick, "      "),
        "summaries": (by(books, "summary"), row_simple, "      "),
        "ranked": (by(books, "ranked"), row_ranked, "      "),
    }
    for name, (rows, render, indent) in blocks.items():
        marker = re.compile(
            rf"(<!-- generated:{name} -->\n).*?(\n\s*<!-- /generated -->)", re.S)
        if not marker.search(text):
            raise SystemExit(f"rankings.html is missing the generated:{name} markers")
        body = "\n".join(indent + render(b) for b in rows)
        text = marker.sub(lambda m: m.group(1) + body + m.group(2), text, count=1)
    page.write_text(text)


# --- book_rankings.md --------------------------------------------------------

MD_HEAD = """# BOOK RANKINGS - BEST TO WORST
**Based on Goodreads Ratings, Review Volume, and Cultural Relevance**
Updated: May 2026

---

## RANKING METHODOLOGY
Books are scored using a weighted algorithm:
- **Rating** (50%) -- Goodreads average out of 5
- **Volume** (25%) -- Log-scaled review count (more reviews = more reliable signal)
- **Relevance** (25%) -- Cultural impact, timelessness, and subject importance

---

## RANKED LIST
"""


def write_md(books):
    out = [MD_HEAD]
    for b in by(books, "ranked"):
        out.append(f'\n### {b["rank"]}. [{b["title"]}]({b["goodreadsURL"]}) by {b["author"]}')
        if b.get("rating") is not None:
            badge = f' ({b["badges"][0]})' if b.get("badges") else ""
            out.append(f'\n**Rating:** {b["rating"]:.2f}/5 | **Reviews:** {b["reviewCount"]}{badge}')
        out.append(f'\n**Notes:** {b["notes"]}\n')
    (ROOT / "book_rankings.md").write_text("".join(out))


# --- iOS resources -----------------------------------------------------------

def write_ios(books):
    res = ROOT / "ios/Bookrank/Resources"
    ranked = [{
        "rank": b["rank"],
        "title": b["title"],
        "goodreadsURL": b["goodreadsURL"],
        "author": b["author"],
        "rating": b.get("rating"),
        "reviewCount": b.get("reviewCount"),
        "badges": b.get("badges", []),
        "notes": b["notes"],
    } for b in by(books, "ranked")]
    picks = [{"title": b["title"], "blurb": b["blurb"]} for b in by(books, "pick")]
    # ponytail: loans stays [] — every library book is returned and checkout
    # tracking is explicitly banned (see CLAUDE.md). Not a placeholder.
    library = {
        "dueDate": None,
        "loans": [],
        "toRead": [{"title": b["title"], "author": b["author"], "summarySlug": None}
                   for b in by(books, "toRead")],
    }
    for name, data in (("books", ranked), ("picks", picks), ("library", library)):
        (res / f"{name}.json").write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    return len(ranked)


if __name__ == "__main__":
    books = load()
    write_html(books)
    write_md(books)
    n = write_ios(books)
    unrated = sum(1 for b in by(books, "ranked") if b.get("rating") is None)
    print(f"OK: {len(books)} entries -> rankings.html, book_rankings.md, ios resources")
    print(f"  ranked {n} ({unrated} with no Goodreads rating, all still shipped)")
