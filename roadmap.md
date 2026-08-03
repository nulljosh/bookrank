# Spine Roadmap

## Shipped 2026-08-03 — macOS 1.0 SUBMITTED
- [x] macOS 1.0 submitted for review (submission `bc9a7d5f-e2d1-4456-952f-6b1ab42b977a`, WAITING_FOR_REVIEW 2026-08-03T17:39Z). Cleared all 7 review-doctor gates: description/keywords/supportUrl (copied from iOS, "Spine"→"Uprighty"), copyright, review details (`f1fa5193-…`, demo account not required), macOS screenshot (`APP_DESKTOP` 1440×900, asset `e067f782-…`), and a first-ever Mac build.
- [x] Fixed the app's own branding, which still said "Spine" everywhere: `LibraryView.swift:41` header text, plus `CFBundleDisplayName`/`CFBundleName` on both iOS and macOS targets (`project.yml`, `Info.plist`). Mac app previously would have installed as "SpineMac".
- [x] Added a `SpineMac` scheme to `project.yml` (didn't exist — only the iOS `Spine` scheme was defined, so the Mac target couldn't be archived).
- [x] Created the missing `MAC_APP_STORE` provisioning profile "Uprighty Mac App Store" (`L6CK4VG2TF`, bundle `DZ68U4M7CX`) — none existed for `com.heyitsmejosh.spine`.

### Mac packaging gotchas (reusable for other apps)
- `xcodebuild -exportArchive` could NOT export this: it insists the MAS profile contain the *installer* cert, which Apple rejects ("no current certificates ... compatible with MAC_APP_STORE profiles"). Working path is manual: copy `.app` out of the archive → drop the profile in as `Contents/embedded.provisionprofile` → `codesign --force --sign "3rd Party Mac Developer Application: …" --entitlements ios/Spine/SpineMac.entitlements --options runtime --timestamp` → `productbuild --component <app> /Applications --sign "3rd Party Mac Developer Installer: …"` → `asc builds upload --pkg`.
- A MAS-signed `.app` will not launch locally (no receipt), so it can't be screenshotted. For screenshots, take a second copy of the archive's `.app`, `xattr -cr` it, `codesign --force --deep --sign -` (ad-hoc), then `open` it.
- Build number 2 upload silently **FAILED** (codes 90345 + 90189) with no error surfaced by `asc builds upload` — it reported success. Only `asc builds uploads list` showed the failure. Re-uploading as build 3 went through unchanged. Always verify via `asc builds uploads list` after an upload, not the upload command's own output.

## Blocked on Joshua
- [x] **iOS 1.0 "Spine" branding — RESOLVED 2026-08-03.** Joshua authorized pulling the in-review submission. Cancelled `5e2f9349`, rebuilt as build 5 (`586d2fda`, VALID) with the corrected branding, rewrote the store description from "Spine is a curated collection…" to "Uprighty is…", resubmitted as `8895e7cb` — WAITING_FOR_REVIEW. Shared `Spine/Info.plist` and `sources: [Spine]` meant the macOS fix already covered iOS source; only the binary and the description were stale.
- [ ] Icon refresh (currently a yellow/blue two-bar abstract mark; roadmap asks for "a simpler refresh") — a design decision, not a code fix. Icon asset itself is technically valid (1024×1024, no alpha) so it is not blocking review.
- [ ] Marketing/support domain still `spine.heyitsmejosh.com` while the app is Uprighty. `uprighty.heyitsmejosh.com` does not resolve; `spine.` returns 200, so the ASC supportUrl and privacyPolicyUrl were deliberately left pointing at the working domain (a dead support URL is itself a review rejection). Decide whether the domain follows the rename — if yes, add the Cloudflare CNAME first, then update `metadata/app-info/en-US.json` + `metadata/version/1.0/en-US.json`. Same open question as Voxprint's `echo.` domain.

## Build gotchas (2026-08-03)
- **xcodegen silently ignores `CFBundleVersion`, `CFBundleShortVersionString`, and `UISupportedInterfaceOrientations~ipad` in `info.properties`** — it rewrites `Spine/Info.plist` with its own defaults and resets the build number to `1` every run. Run `python3 ios/scripts/prepare-plist.py <build-number>` AFTER `xcodegen generate` and BEFORE archiving.
- **ITMS-90474** killed build 4: iPad builds must declare all four orientations or set `UIRequiresFullScreen`. `prepare-plist.py` now writes the orientations. `xcodebuild` warns about this at archive time ("All interface orientations must be supported…") — that warning is a hard upload failure, not cosmetic.
- **`asc builds upload` reports success on failed uploads.** Always pass `--verify-timeout 120s` and confirm with `asc builds uploads list`.
- **`asc review submit` is broken** — it creates the submission, adds the version, then fails its own validation claiming the submission "does not contain target version". The version *is* attached. Use `asc review submissions-submit --id <id> --confirm` instead.

## From Notes PDF (imported 2026-08-02)
- [ ] Research history + COVID-event books (e.g. the Fauci book — read, was "ok"; and The Great Reset) and add some of them to the list (from Books.pdf note).
- [ ] Finish processing raw files in the iCloud Books folder — ongoing, may take a few more sessions since new books get added every few days.
- [ ] Design inspiration for the "Digest" companion app (see Someday/Explore item above, currently blocked on backend decision): a saved "Reading Tracker App" reference design — discover/organize/track favorite books in one place, "Beginner Friendly" tag, ~4-10 days scope shown in the reference. From Spine inspiration.pdf note: "integrate into our apps and codebase. This one in particular would be like, for spine. Our books app."

## From Notes (imported 2026-07-28)
- [ ] Physics I For Dummies (Surrey Libraries, barcode 3 9090 0472 4516 8) was returned past-due before pages could be scanned — no photos captured, book no longer in hand. Skip it unless re-borrowed.

## In progress — chapter summaries (2026-07-28)
- [ ] Books photographed as cover only, no pages captured yet (nothing to summarize until pages are shot): **Accounting For Canadians For Dummies** 4th ed. (Cecile Laurin CPA CA, Tage C. Tracy) · **Physics I For Dummies** 4th ed. (Cynthia B. Phillips PhD, Shana Priwer — Surrey Libraries barcode 3 9090 0472 4516 8) · **Trading For Canadians For Dummies** 2nd ed. (Lita Epstein, Grayson D. Roze)

### Remaining-work count (as of 2026-07-28 night)
**BACKLOG CLEAR.** All photographed books have been summarized and synced. IBS, Sobriety, Statistics, and Good Feng Shui are complete. Every HEIC has been processed and deleted from iCloud. Next entry will arrive when a new book is photographed and added to the queue.

## From Notes (imported 2026-07-29)
- [ ] Meta: asc-name-creator (or a rename skill) should auto-update repo name, folder name, and README references when a project is renamed, instead of requiring a manual follow-up each time — filed as a process gap, not app-specific

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

## From App Store.pdf (imported 2026-07-29)
- [ ] Icon needs a simpler refresh (currently a yellow/blue two-bar abstract mark) — see `## Blocked on Joshua` above. Status corrected 2026-08-03: iOS 1.0 is WAITING_FOR_REVIEW and macOS 1.0 is now submitted, neither is "Prepare for Submission" any more.
