# Spine Roadmap

## From Notes (imported 2026-07-28)
- [ ] Physics I For Dummies (Surrey Libraries, barcode 3 9090 0472 4516 8) was returned past-due before pages could be scanned — no photos captured, book no longer in hand. Skip it unless re-borrowed.

## In progress — chapter summaries (2026-07-28)
- [ ] Books photographed as cover only, no pages captured yet (nothing to summarize until pages are shot): **Accounting For Canadians For Dummies** 4th ed. (Cecile Laurin CPA CA, Tage C. Tracy) · **Physics I For Dummies** 4th ed. (Cynthia B. Phillips PhD, Shana Priwer — Surrey Libraries barcode 3 9090 0472 4516 8) · **Trading For Canadians For Dummies** 2nd ed. (Lita Epstein, Grayson D. Roze)

### Remaining-work count (as of 2026-07-28 night)
**BACKLOG CLEAR.** All photographed books have been summarized and synced. IBS, Sobriety, Statistics, and Good Feng Shui are complete. Every HEIC has been processed and deleted from iCloud. Next entry will arrive when a new book is photographed and added to the queue.

## iOS/Mac app — ASC submission
- [ ] **App availability** — not automatable, confirmed dead end: both `asc web` and `asc pricing` lack a CLI path for this; must be set in the ASC dashboard (Pricing and Availability) — **needs you**

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
