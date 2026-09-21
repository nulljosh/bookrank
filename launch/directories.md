# Directory listings

Reuse this for AlternativeTo, Indie Hackers products, Uneed, SaaSHub and dev.to.

Name: Bookrank

One-liner: Find the book worth reading next in ten seconds.

Description: A ranked shelf built from Goodreads ratings and review volume, not one person's taste, plus private chapter summaries and your own shelves. Free on web, iPhone, iPad and Mac.

Category: Books / Productivity

Links
Web: https://bookrank.heyitsmejosh.com
App Store: https://apps.apple.com/app/id6792376485
GitHub: https://github.com/nulljosh/bookrank

## Per-directory notes

- AlternativeTo: list as a free alternative to Goodreads-style to-be-read trackers.
- Indie Hackers products: post under the maker's product page, use the maker story from producthunt.md.
- BetaList: skip, Bookrank is already live, BetaList is pre-launch only.
- Uneed: standard listing above.
- SaaSHub: standard listing above, note it is free with no paid tier.
- dev.to: build-story post. Bookrank has a real technical hook worth writing up: books.json is the single generated source of truth for the site, the markdown export and the iOS resource JSON, rebuilt by scripts/build.py after every edit instead of hand-kept in sync. Chapter summary playback generates a two-host conversation through Workers AI, with the transcript following the audio line by line and the next chapter prepared ahead of time so there's no gap between chapters.
