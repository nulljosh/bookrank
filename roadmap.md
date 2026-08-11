# Bookrank Roadmap

(The `Spine` names below are Xcode target/path names, not the product name — the app and site are Bookrank.)

### Mac packaging gotchas (reusable for other apps)
- `xcodebuild -exportArchive` could NOT export this: it insists the MAS profile contain the *installer* cert, which Apple rejects ("no current certificates ... compatible with MAC_APP_STORE profiles"). Working path is manual: copy `.app` out of the archive → drop the profile in as `Contents/embedded.provisionprofile` → `codesign --force --sign "3rd Party Mac Developer Application: …" --entitlements ios/Spine/SpineMac.entitlements --options runtime --timestamp` → `productbuild --component <app> /Applications --sign "3rd Party Mac Developer Installer: …"` → `asc builds upload --pkg`.
- A MAS-signed `.app` will not launch locally (no receipt), so it can't be screenshotted. For screenshots, take a second copy of the archive's `.app`, `xattr -cr` it, `codesign --force --deep --sign -` (ad-hoc), then `open` it.
- Build number 2 upload silently **FAILED** (codes 90345 + 90189) with no error surfaced by `asc builds upload` — it reported success. Only `asc builds uploads list` showed the failure. Re-uploading as build 3 went through unchanged. Always verify via `asc builds uploads list` after an upload, not the upload command's own output.

## The Optimist (Keach Hagey) — summaries in progress
- [x] Done: prologue + ch. 1-14 **and the Epilogue** (ch. 11-12 inline, ch. 13-14 + Epilogue via per-chapter subagents, all 2026-08-11; raw HEICs deleted after write).
- **ORDERING GOTCHA:** the Epilogue is already appended at the END of `summaries/the-optimist.md`. Ch. 15-17 must be **inserted before it**, not appended, or the book reads out of order.
- Method that works (cheapest): one subagent per chapter, told to `Write` its markdown to a scratch file and reply with only the path — never to return the text. The parent then `cat`s it on. Returning the markdown makes the parent re-emit the whole chapter, which is what actually burns the session budget.
- Remaining raw photos in iCloud `Misc/Books/The optimist /`: **ch. 15 (11 imgs), 16 (10), 17 (9)** = 30 images. These finish the book.
- Budget note (measured 2026-08-11): **one chapter of ~11-14 photos costs ~10-11% of a 5-hour session block.** Two chapters per session is the realistic ceiling.
- Process with the `summarize-books` skill. Convert at `sips -Z 1500 -s formatOptions 65` (the skill's default -Z 700 is NOT legible for this book's type size).
- After finishing, rebuild `the-optimist-summary.md` by concatenating chapter summaries in order, copy to `summaries/the-optimist.md` + `ios/Spine/Resources/summaries/the-optimist.md`, and update the "(partial: prologue, ch. 1-N)" note in `index.html`.

## Raw photo backlog — NOT clear (recount 2026-08-11)
The "BACKLOG FULLY CLEAR (375/375)" note below is wrong: 404 HEICs are still in iCloud (429 at recount, minus Optimist ch. 11-14 + Epilogue) — 380 left `Documents/Misc/Books/`.
- **AI in Business For Dummies** — 134 imgs. Book **returned to the library 2026-08-11**; photos are the only remaining source, so these can't be re-shot. Existing `summaries/ai-in-business.md` is partial.
- **macOS Tahoe For Dummies** — 215 imgs. Also **returned 2026-08-11**, same situation; `summaries/macos-tahoe.md` is partial.
- **The Optimist** — 30 imgs left (ch. 15-17), see section above.
Vision cost: ~18-20k tokens per ~11 pages at `-Z 1500`. Full 429 is far more than one session's budget — work a chapter or two at a time.

## Blocked on Joshua
- [ ] Icon refresh (currently a yellow/blue two-bar abstract mark; roadmap asks for "a simpler refresh") — a design decision, not a code fix. Icon asset itself is technically valid (1024×1024, no alpha) so it is not blocking review.

## Build gotchas (2026-08-03)
- **xcodegen silently ignores `CFBundleVersion`, `CFBundleShortVersionString`, and `UISupportedInterfaceOrientations~ipad` in `info.properties`** — it rewrites `Spine/Info.plist` with its own defaults and resets the build number to `1` every run. Run `python3 ios/scripts/prepare-plist.py <build-number>` AFTER `xcodegen generate` and BEFORE archiving.
- **ITMS-90474** killed build 4: iPad builds must declare all four orientations or set `UIRequiresFullScreen`. `prepare-plist.py` now writes the orientations. `xcodebuild` warns about this at archive time ("All interface orientations must be supported…") — that warning is a hard upload failure, not cosmetic.
- **`asc builds upload` reports success on failed uploads.** Always pass `--verify-timeout 120s` and confirm with `asc builds uploads list`.
- **`asc review submit` is broken** — it creates the submission, adds the version, then fails its own validation claiming the submission "does not contain target version". The version *is* attached. Use `asc review submissions-submit --id <id> --confirm` instead.
- **ITMS-90886 / TestFlight ineligibility (builds 1-5)** — the iOS `Spine` target had **no entitlements file at all**, so the signed bundle carried no `application-identifier` while the embedded profile did. Apple flags that combination "not required to fix", but it silently makes every build **TestFlight-ineligible**. Fixed 2026-08-03 with `ios/Spine/Spine.entitlements` (just `application-identifier` = `$(AppIdentifierPrefix)$(CFBundleIdentifier)`) wired via `CODE_SIGN_ENTITLEMENTS` in `project.yml` — hand-committed rather than xcodegen-generated, since xcodegen drops keys in this project. Verify any future build before uploading:
  ```
  codesign -d --entitlements :- /path/to/Payload/Spine.app
  ```
  Distribution signature must show `application-identifier`, `beta-reports-active: true`, and `get-task-allow: false`. Build 6 is the first correct one.
- **Cancelling a review submission moves the version to `DEVELOPER_REJECTED`**, not back to `PREPARE_FOR_SUBMISSION`. `attach-build` fails while the cancel is still `CANCELING` — wait for `DEVELOPER_REJECTED`, then attach. (Note: `DEVELOPER_REJECTED` is also the state that makes an app record undeletable — see Lexly Mac.)
- **A freshly uploaded build needs `usesNonExemptEncryption` set before it can be submitted**: `asc builds update --app <id> --build-number <n> --platform IOS --uses-non-exempt-encryption=false`. Without it, submission fails with an "associated errors" blob that doesn't name the field obviously.

## Same signing defect in other repos — SWEEP COMPLETE 2026-08-04
All seven repos fixed and verified on real Release archives (`codesign -d --entitlements :-`), not simulator builds — with no provisioning profile `AppIdentifierPrefix` resolves empty and the check silently passes on nothing.

Repos that already reference entitlements (epiphany, healstack, lexly, litigate, notes, nyc, sparkjar, talli, voxprint) were not re-verified in this sweep.

**Note:** every fixed repo now needs a rebuild + resubmit for the fix to actually reach users — the correction only affects future builds, never the one already in review.

## From Notes PDF (imported 2026-08-02)
- [ ] Research history + COVID-event books (e.g. the Fauci book — read, was "ok"; and The Great Reset) and add some of them to the list (from Books.pdf note).
- STANDING (not an open task): process raw files in the iCloud Books folder as new books get photographed. As of the **BACKLOG CLEAR** note below, every HEIC has been processed and deleted from iCloud, so there is nothing outstanding right now — re-open only when new photos land.
- [ ] Design inspiration for the "Digest" companion app (see Someday/Explore below, blocked on the same backend decision): a saved "Reading Tracker App" reference design — discover/organize/track favorite books in one place, "Beginner Friendly" tag, ~4-10 days scope shown in the reference. From Spine inspiration.pdf note: "integrate into our apps and codebase. This one in particular would be like, for spine. Our books app."

## From Notes (imported 2026-07-28)
- NOTE (not a task): Physics I For Dummies (Surrey Libraries, barcode 3 9090 0472 4516 8) was returned past-due before pages could be scanned. Skip unless re-borrowed.

## In progress — chapter summaries (2026-07-28)
- [ ] Books photographed as cover only, no pages captured yet (nothing to summarize until pages are shot): **Physics I For Dummies** 4th ed. (Cynthia B. Phillips PhD, Shana Priwer — Surrey Libraries barcode 3 9090 0472 4516 8) · **Trading For Canadians For Dummies** 2nd ed. (Lita Epstein, Grayson D. Roze)

### Remaining-work count (as of 2026-08-10 night)
**Original backlog fully clear (375/375 HEICs completed).** All 5 original photographed books have been summarized and synced: IBS, Sobriety, Statistics, Good Feng Shui, macOS Tahoe, Accounting, AI in Business, Data Science For Dummies. Now actively working on new books: The Optimist (prologue + ch. 1-7 shipped 2026-08-10, remaining chapters pending), AI in Business (intro shipped, remaining chapters pending). Next photographed books will be added to the queue as they arrive.

## From Notes (imported 2026-07-29)
- [ ] Meta: asc-name-creator (or a rename skill) should auto-update repo name, folder name, and README references when a project is renamed, instead of requiring a manual follow-up each time — filed as a process gap, not app-specific

## Someday / Explore
- [ ] Goodreads **sign-in/sync** integration (separate from the ranked-shelf-scrape above, which is done and needed no auth) — Goodreads deprecated its public API for new developer keys in 2020; confirm current auth options exist before scoping. No deadline pinned
- [ ] Landing page split: separate marketing page from the rankings-list homepage
- [ ] iOS/Mac companion app ("Digest") — BLOCKED, needs a backend decision (Supabase vs static JSON) before scaffolding; no API/data layer exists yet. Multi-session project. (Same blocker noted in CLAUDE.md's "Imported from Books (tracker app).pdf" — this is the current, consolidated entry.)
- [ ] Books skill: treat each raw folder as a chapter (auto-create chapter folders) in the summarize pipeline
- [ ] Replace shell-script deps in the summarize pipeline with native implementation where sensible
- [ ] Consider moving the Books iCloud folder into this repo (gitignore raws; commit only summarized pdf/html) — undecided

## Known-done
- No raw HEICs remain anywhere in the iCloud source folder as of 2026-07-20 (superseded — new photos added since for Down Economy/Sobriety/IBS)
- No stray empty files in this repo (verified 2026-07-20)
