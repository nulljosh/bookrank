# Spine Roadmap

## In progress — chapter summaries (2026-07-27)
Resuming per `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Misc/Books/ROADMAP.md`:
- [ ] Sobriety For Dummies: DONE = intro, ch. 1-11, 16, 17. REMAINING = ch. 12 (11 imgs), 13 (11), 14 (12), 15 (18, mindfulness ch., longest) = 52 HEICs in `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Misc/Books/for dummies/sobriety/<N>/`. Per summarize-books skill: sips -Z 700 q50 -> Read -> write `<ch>/summary.md` -> rm *.HEIC -> re-merge sobriety-for-dummies-summary.md -> sync-summaries.sh -> commit incl. ios/Spine/Resources/summaries/. Badge already live. NOTE 2026-07-28: parallel cold subagents burned session usage far faster than expected (~6 agents took session 47%->93%); next run use ONE agent at a time, or process inline.
- [ ] Statistics For Dummies: NOT STARTED — 245 HEICs across 23 folders (`intro`, `1`–`21`, `Remainder `) in `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Misc/Books/for dummies/statistics/`. Largest remaining book. Per-chapter counts: intro 11, 1:8, 2:6, 3:6, 4:12, 5:13, 6:7, 7:13, 8:7, 9:8, 10:4, 11:9, 12:7, 13:11, 14:13, 15:9, 16:17, 17:18, 18:17, 19:22, 20:13, 21:15, Remainder 6. No repo entry/badge yet.
- [x] Stray single-image folders — RESOLVED 2026-07-28: all three were cover photos only, no pages scanned. Covers deleted; books logged below as not-yet-photographed:
- [ ] Books photographed as cover only, no pages captured yet (nothing to summarize until pages are shot): **Accounting For Canadians For Dummies** 4th ed. (Cecile Laurin CPA CA, Tage C. Tracy) · **Physics I For Dummies** 4th ed. (Cynthia B. Phillips PhD, Shana Priwer — Surrey Libraries barcode 3 9090 0472 4516 8) · **Trading For Canadians For Dummies** 2nd ed. (Lita Epstein, Grayson D. Roze)
- [x] IBS For Dummies: COMPLETE 2026-07-28 — all chapters through ch. 23 summarized, HEICs cleared

## iOS/Mac app — ASC submission
Confirmed via `asc apps list` (2026-07-26): the live ASC record is **Spinework** (id `6792376485`, bundle `com.heyitsmejosh.spine`) — this supersedes any older "Spinelist"/"BooksApp"/id `6787499076`/`6787499349` references elsewhere in this repo's docs, which are stale. Version `1.0` (version-id `5a7e626c-8a83-4fde-a1fd-6cb9dc4cc3e2`) is in `PREPARE_FOR_SUBMISSION`.
- [ ] **App availability** — not automatable, confirmed dead end: both `asc web` and `asc pricing` lack a CLI path for this; must be set in the ASC dashboard (Pricing and Availability) — **needs you**
- [x] Privacy policy URL — privacy.html added, https://spine.heyitsmejosh.com/privacy.html (2026-07-28)

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
