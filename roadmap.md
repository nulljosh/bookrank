# Spine Roadmap

## In progress — chapter summaries (2026-07-26)
Resuming per `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Misc/Books/ROADMAP.md`:
- [x] Living Well in a Down Economy: tips #41–135 summarized and synced (2026-07-26 session)
- [ ] Living Well in a Down Economy: tips #136–175 remain (9+9+14+15+10 = 57 HEICs across `136-140`, `141-150`, `151-160`, `161-170`, `171-175`)
- [ ] Sobriety For Dummies: 297 HEICs, 18 chapter folders (`intro`, `1`–`17`), completely untouched — no badge yet
- [ ] IBS For Dummies: `remainder/` folder (85 images, likely Ch.11+) not yet started; needs a skim pass to detect chapter breaks first

## iOS/Mac app — ASC submission
Confirmed via `asc apps list` (2026-07-26): the live ASC record is **Spinework** (id `6792376485`, bundle `com.heyitsmejosh.spine`) — this supersedes any older "Spinelist"/"BooksApp"/id `6787499076`/`6787499349` references elsewhere in this repo's docs, which are stale. Version `1.0` (version-id `5a7e626c-8a83-4fde-a1fd-6cb9dc4cc3e2`) is in `PREPARE_FOR_SUBMISSION`.
- [x] Icon, signing (`CODE_SIGN_STYLE: Automatic`, team `QMM486NPYC`), bundle ID registration — done
- [x] Icon export blocker — resolved; `icon_1024.png` is 1024×1024, no alpha (script path bug fixed 2026-07-26: `make-appicon.sh` pointed at stale `ios/BooksApp/...`, corrected to `ios/Spine/...`)
- [x] iOS v1.0 build 2 uploaded 2026-07-22 (per global CLAUDE.md ship log)
- [x] Full `asc validate` remediation pass (2026-07-26) — went from 34 blocking errors to 2. Fixed via CLI: content rights declaration, all age-rating fields (`--all-none`), primary category (Books), build encryption declaration (both Info.plist `ITSAppUsesNonExemptEncryption=false` and the uploaded build's flag), en-US description/keywords/support URL, app-info subtitle, version copyright, and App Store review details (contact info + reviewer notes — no demo account needed, static content app)
- [ ] **App availability** — not automatable, confirmed dead end: both `asc web` and `asc pricing` lack a CLI path for this; must be set in the ASC dashboard (Pricing and Availability) — **needs you**
- [ ] **Screenshots** — at least one required device-size set must be uploaded; needs an actual simulator capture pass (skipped here per your standing "skip simulator by default" preference) — **needs you to say go, or I'll run the `appstore-screenshots` skill when asked**

## Someday / Explore
- [ ] Once all book summaries are finished, integrate as quizzes/masterclasses in Lexly (cross-ref lexly roadmap) — first step of syncing several repos together
- [ ] Goodreads integration ("sign in with Goodreads" companion sync) — Goodreads deprecated its public API for new developer keys in 2020; confirm current auth options exist before scoping. No deadline pinned
- [ ] Landing page split: separate marketing page from the rankings-list homepage
- [ ] iOS/Mac companion app ("Digest") — BLOCKED, needs a backend decision (Supabase vs static JSON) before scaffolding; no API/data layer exists yet. Multi-session project
- [ ] Books skill: treat each raw folder as a chapter (auto-create chapter folders) in the summarize pipeline
- [ ] Replace shell-script deps in the summarize pipeline with native implementation where sensible
- [ ] Consider moving the Books iCloud folder into this repo (gitignore raws; commit only summarized pdf/html) — undecided

## Known-done
- No raw HEICs remain anywhere in the iCloud source folder as of 2026-07-20 (superseded — new photos added since for Down Economy/Sobriety/IBS)
- No stray empty files in this repo (verified 2026-07-20)
