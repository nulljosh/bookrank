#!/usr/bin/env python3
"""Resolve a hotlinked cover image for every entry in books.json.

Covers are served straight from Open Library's CDN (free, no key, no rate limit on the
image host) — nothing is downloaded into this repo. Only the lookup hits the search API.
Goodreads has no free cover API and blocks bulk scraping, so its slug is used only as an id.

    python3 scripts/fetch-covers.py                 # look up missing covers, write them into books.json
    python3 scripts/fetch-covers.py --dry-run       # list books with no cover yet
    python3 scripts/fetch-covers.py --retry-misses  # re-query books cached as "no cover"

covers.json caches a null for a book both APIs answered on without a cover, so ordinary
re-runs skip it. That null is only ever written when the lookup actually completed — a
network, policy or quota error is reported and left uncached, never remembered as a miss.
"""
import json, re, sys, time, urllib.error, urllib.parse, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BOOKS = ROOT / "books.json"
CACHE = ROOT / "scripts" / "covers.json"  # slug -> cover URL, so re-runs cost no requests
UA = "bookrank.heyitsmejosh.com cover lookup (trommatic@icloud.com)"
SLUG = re.compile(r"goodreads\.com/book/show/([^\"?]+)")


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for wait in (0, 5, 20):  # ponytail: brief backoff, Open Library rarely 429s
        time.sleep(wait)
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code != 429:
                raise
    raise RuntimeError("429 after retries: " + url)


def cache_key(book):
    """Stable cache key for one books.json entry."""
    slug = SLUG.search(book.get("goodreadsURL") or "")
    if slug:
        return slug.group(1)
    # ponytail: no Goodreads link (recent/summary/pick rows) -> key off the text instead
    text = (book.get("title", "") + " " + (book.get("author") or "")).lower()
    return "t:" + re.sub(r"[^a-z0-9]+", "-", text).strip("-")


def google(title, author):
    """Google Books covers what Open Library doesn't — newer and niche titles mostly."""
    q = urllib.parse.urlencode({"q": f"{title} {author}".strip(), "maxResults": 3})
    for item in get("https://www.googleapis.com/books/v1/volumes?" + q).get("items", []):
        link = item.get("volumeInfo", {}).get("imageLinks", {}).get("thumbnail")
        if link:
            # served over http with page-curl styling by default; neither is wanted
            return link.replace("http://", "https://").replace("&edge=curl", "")
    return None


def lookup(title, author):
    # drop co-authors, barcodes, credentials and "(partial: ch. 1-4)" noise
    author = re.sub(r"\(.*?\)", "", author).split("&")[0].split("·")[0].split(",")[0].strip()
    queries = [{"title": title, "author": author}, {"q": f"{title} {author}"}, {"title": title}]
    for params in queries:
        params.update(limit=3, fields="cover_i")
        for doc in get("https://openlibrary.org/search.json?" + urllib.parse.urlencode(params)).get("docs", []):
            if doc.get("cover_i"):
                return f"https://covers.openlibrary.org/b/id/{doc['cover_i']}-M.jpg"
    # ponytail: no try/except here on purpose. A network or quota error is NOT a
    # miss — swallowing it wrote None into the cache, and None is permanent unless
    # --retry-misses is passed. That is how five real books ended up flagged
    # "no cover on Open Library" forever. Let it raise; main() logs and moves on
    # without touching the cache, so the next run tries again.
    return google(title, author)


def main():
    dry = "--dry-run" in sys.argv
    retry = "--retry-misses" in sys.argv
    cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
    books = json.loads(BOOKS.read_text())
    failed = []

    for book in books:
        key, title, author = cache_key(book), book.get("title", ""), book.get("author") or ""
        cached = key in cache and not (retry and cache[key] is None)
        if not title or cached or (book.get("cover") and not retry):
            continue
        if dry:
            print("missing:", title, "—", author)
            continue
        try:
            url = lookup(title, author)
        except Exception as e:
            failed.append((title, e)); print("fail:", key, e); continue
        if not url:
            cache[key] = None  # a real miss: both APIs answered, neither had a cover
            print("no cover:", title, "—", author)
        else:
            cache[key] = url
            print("ok:", key)
        time.sleep(1)  # ponytail: Open Library asks for gentle pacing on bulk reads

    if dry:
        return
    CACHE.write_text(json.dumps(cache, indent=2, sort_keys=True) + "\n")

    for book in books:
        if not book.get("cover"):
            book["cover"] = cache.get(cache_key(book))
    BOOKS.write_text(json.dumps(books, indent=2, ensure_ascii=False) + "\n")

    wired = sum(1 for b in books if b.get("cover"))
    print(f"covers on {wired} of {len(books)} entries. Run scripts/build.py to publish them.")
    if failed:
        # Loud on purpose: "covers wired: 127" on its own reads like success even
        # when every lookup died, which is how the last round of misses went unnoticed.
        print(f"\n{len(failed)} lookup(s) FAILED and were not cached — re-run to retry:")
        for title, e in failed:
            print(f"  {title}: {e}")


if __name__ == "__main__":
    main()
