# Spine Roadmap

## In progress — chapter summaries (2026-07-27)
Resuming per `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Misc/Books/ROADMAP.md`:
- [ ] Sobriety For Dummies: 297 HEICs, 18 chapter folders (`intro`, `1`–`17`) — `intro` chapter in progress (2026-07-26)
- [ ] IBS For Dummies: chapters 1-15 COMPLETE (pp. 1-225), ~51 images remain (ch. 16+); resume at IMG_4618.HEIC per iCloud folder CLAUDE.md (2026-07-27)

## iOS/Mac app — ASC submission
Confirmed via `asc apps list` (2026-07-26): the live ASC record is **Spinework** (id `6792376485`, bundle `com.heyitsmejosh.spine`) — this supersedes any older "Spinelist"/"BooksApp"/id `6787499076`/`6787499349` references elsewhere in this repo's docs, which are stale. Version `1.0` (version-id `5a7e626c-8a83-4fde-a1fd-6cb9dc4cc3e2`) is in `PREPARE_FOR_SUBMISSION`.
- [ ] **App availability** — not automatable, confirmed dead end: both `asc web` and `asc pricing` lack a CLI path for this; must be set in the ASC dashboard (Pricing and Availability) — **needs you**
- [ ] Privacy policy URL (warning, non-blocking) — empty for en-US app-info localization; add a URL if the site gets a privacy policy page

## Someday / Explore
- [ ] Once all book summaries are finished, integrate as quizzes/masterclasses in Lexly (cross-ref lexly roadmap) — first step of syncing several repos together
- [ ] Goodreads **sign-in/sync** integration (separate from the ranked-shelf-scrape above, which is done and needed no auth) — Goodreads deprecated its public API for new developer keys in 2020; confirm current auth options exist before scoping. No deadline pinned
- [ ] Landing page split: separate marketing page from the rankings-list homepage
- [ ] iOS/Mac companion app ("Digest") — BLOCKED, needs a backend decision (Supabase vs static JSON) before scaffolding; no API/data layer exists yet. Multi-session project
- [ ] Books skill: treat each raw folder as a chapter (auto-create chapter folders) in the summarize pipeline
- [ ] Replace shell-script deps in the summarize pipeline with native implementation where sensible
- [ ] Consider moving the Books iCloud folder into this repo (gitignore raws; commit only summarized pdf/html) — undecided

## Known-done
- No raw HEICs remain anywhere in the iCloud source folder as of 2026-07-20 (superseded — new photos added since for Down Economy/Sobriety/IBS)
- No stray empty files in this repo (verified 2026-07-20)
