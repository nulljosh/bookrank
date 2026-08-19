# Bookrank Roadmap

(The `Spine` names below are Xcode target/path names, not the product name — the app and site are Bookrank.)

### Mac packaging gotchas (reusable for other apps)
- `xcodebuild -exportArchive` could NOT export this: it insists the MAS profile contain the *installer* cert, which Apple rejects ("no current certificates ... compatible with MAC_APP_STORE profiles"). Working path is manual: copy `.app` out of the archive → drop the profile in as `Contents/embedded.provisionprofile` → `codesign --force --sign "3rd Party Mac Developer Application: …" --entitlements ios/Spine/SpineMac.entitlements --options runtime --timestamp` → `productbuild --component <app> /Applications --sign "3rd Party Mac Developer Installer: …"` → `asc builds upload --pkg`.
- A MAS-signed `.app` will not launch locally (no receipt), so it can't be screenshotted. For screenshots, take a second copy of the archive's `.app`, `xattr -cr` it, `codesign --force --deep --sign -` (ad-hoc), then `open` it.
- Build number 2 upload silently **FAILED** (codes 90345 + 90189) with no error surfaced by `asc builds upload` — it reported success. Only `asc builds uploads list` showed the failure. Re-uploading as build 3 went through unchanged. Always verify via `asc builds uploads list` after an upload, not the upload command's own output.

## Raw photo backlog — NOT clear (recount 2026-08-11)
The "BACKLOG FULLY CLEAR (375/375)" note below is wrong: 404 HEICs are still in iCloud (429 at recount) — 380 left `Documents/Misc/Books/`.
- **AI in Business For Dummies** — 134 imgs. Book **returned to the library 2026-08-11**; photos are the only remaining source, so these can't be re-shot. Existing `summaries/ai-in-business.md` is partial.
- **macOS Tahoe For Dummies** — 215 imgs. Also **returned 2026-08-11**, same situation; `summaries/macos-tahoe.md` is partial.
- **The Optimist** — 30 imgs left (ch. 15-17), see section above.
Vision cost: ~18-20k tokens per ~11 pages at `-Z 1500`. Full 429 is far more than one session's budget — work a chapter or two at a time.

### HAZARD: `sync-summaries.sh` overwrites repo copies with iCloud merges
- [ ] **It is a one-way clobber, not a merge, and iCloud is not always the fuller source.** On 2026-08-17 a routine run silently replaced `summaries/the-optimist.md` (498,993 b, all 17 chapters) with the stale iCloud merge (303,925 b) — The Optimist's ch. 11-14 folders no longer exist in iCloud, so **git is the only copy of those four chapters**. Caught in `git diff` before commit and restored from HEAD; nothing was lost.
- [ ] Always `git diff --stat` after running the sync and treat any *shrinking* summary file as a regression to investigate, never a change to commit.
- [ ] Note the iCloud book folder is literally named `The optimist ` **with a trailing space** — `ls`/`find` on the un-spaced name returns "No such file or directory" and looks like the folder is missing entirely.

### DATA LOSS 2026-08-17 — AI in Business ch. 11-14
- [ ] **AI in Business ch. 11, 12, 13, 14 have only ~700-byte one-paragraph stub summaries, and their source HEICs were deleted.** A summarizing agent running low on token budget degraded to one-paragraph outputs near the end of its run; those stubs cleared the skill's then-current ">300 chars" validation gate, which triggered deletion of the originals. Ch. 7-10 from the same run are fine (3-26KB).
- [ ] **Unrecoverable without re-borrowing the book** — per the note above, AI in Business was returned to the library 2026-08-11, so the photos were the only source and re-photographing is not currently possible. Either borrow it again to re-shoot ch. 11-14, or accept the stubs and mark the book partial on the site.
- [ ] Root cause fixed in `~/.claude/skills/summarize-books/SKILL.md` the same day: validation now requires >1500 chars AND >=250 chars per source image, and the skill explicitly forbids shortening a summary to save budget when deletion follows (stop and report instead). Nothing to do here, recorded so the fix isn't re-litigated.

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
- [ ] iOS/Mac companion app ("Digest") — BLOCKED, needs a backend decision (Supabase vs static JSON) before scaffolding; no API/data layer exists yet. Multi-session project. (Same blocker noted in CLAUDE.md's "Imported from Books (tracker app).pdf" — this is the current, consolidated entry.)
- [ ] Books skill: treat each raw folder as a chapter (auto-create chapter folders) in the summarize pipeline
- [ ] Replace shell-script deps in the summarize pipeline with native implementation where sensible
- [ ] Consider moving the Books iCloud folder into this repo (gitignore raws; commit only summarized pdf/html) — undecided

## Known-done
- No raw HEICs remain anywhere in the iCloud source folder as of 2026-07-20 (superseded — new photos added since for Down Economy/Sobriety/IBS)
- No stray empty files in this repo (verified 2026-07-20)

## From Apple Notes (imported 2026-08-11)
- [ ] Finish the remaining raw book files — last session was cut off halfway (ran out of usage)

> Resume note (2026-08-11): a `wip: partial work from /work notes ingest` commit holds unfinished, unverified changes for the items above. Review `git show 761ac52` before building on it — it was committed mid-flight and not reviewed. (It is now pushed, as of 2026-08-13.)

## From Apple Notes (imported 2026-08-13)
- [ ] **App Store listing metadata is stale and partly broken — BLOCKED on a new version.** Two problems on the live listing, both verified 2026-08-13 via `asc apps info view --app 6792376485`:
  1. `description` still opens "**Uprighty** is a curated collection of book rankings…" — the pre-rename name.
  2. `supportUrl` is **`https://spine.heyitsmejosh.com`, which is DEAD** (curl → connection failure; that CNAME was deleted from Cloudflare during the rename). A live App Store listing pointing at a dead support URL is a Guideline 1.5 risk on its own, and is the more urgent of the two. Correct value: `https://bookrank.heyitsmejosh.com` (200).
  Both `asc apps info edit --app 6792376485 --locale en-US --description … --support-url …` calls fail with *"Attribute 'description'/'supportUrl' cannot be edited at this time"* — **both** MAC_OS 1.0 and IOS 1.0 are now `READY_FOR_SALE`, and ASC locks version-level metadata on a live version. Unblocking needs a new version (e.g. 1.0.1) created in `PREPARE_FOR_SUBMISSION`, which then carries these edits. Deliberately not created here: version creation is staging that only pays off at the next submission, and submissions were frozen until 2026-08-18. Freeze now lifted — **do this as step 1 of the next Bookrank submission.** Ready-to-paste corrected description: "Bookrank is a curated collection of book rankings and recommendations, ranked by rating with chapter-by-chapter summaries for finished books. Browse the current top-rated reads, track what's next on your list, and dive into detailed summaries pulled straight from the books themselves."

### Audit note: no registration/login exists, by design (2026-08-13)
There is no auth anywhere in this repo — no sign-in/sign-up form, no Supabase client, no
password or account handling in any of `index.html`, `rankings.html`, `summary.html`,
`privacy.html`. This is deliberate and stated in two places:
- `index.html:164` — "The whole shelf is a static site — no tracking, no account."
- `privacy.html:24` — "It has no accounts, no login, no analytics, no cookies, and no tracking scripts."
- `privacy.html:27` — the iOS/macOS app "sends no data to us and has no server component."

So "add registration and login" is a product decision, not a missing implementation: it would
mean introducing a backend (the same Supabase-vs-static-JSON call already blocking the "Digest"
companion app above) and rewriting the privacy policy. Not built — decide the backend first.

## Summary backlog — partially cleared 2026-08-16

**Recount:** the "~465 photos" figure was high. The real starting count was **380**. Of those,
**84 have been processed and deployed**; **296 remain**.

Done this session (all merged, synced, committed, pushed, verified live):
- **The Optimist — COMPLETE (prologue + ch 1–17).** Ch 15 (ChatGPT), 16 (The Blip),
  17 (Prometheus Unbound) added, 30 photos.
  **CORRECTION (2026-08-16):** this session first claimed chapters 11–14 "were never
  photographed". That was wrong, and the claim covered up real data loss — the ch 15–17
  append in `845215d` silently DROPPED ~790 lines of existing ch 11–14 summaries that had
  been written earlier in `5e9b422` (ch 11) and `bd101f1` (ch 13–14). Recovered from
  `845215d^` and spliced back in (`6b71959`); the rankings label is back to "complete".
  **Lesson: the absence of a source photo folder proves nothing** — folders are deleted
  after processing, so "no folder" is the expected steady state for a *finished* chapter.
  Check `git log -S "Chapter N" -- summaries/<slug>.md` before ever concluding a chapter
  is missing, and diff chapter counts before/after any merge that rewrites a summary file.
- **AI in Business — ch 3, 4, 5, 6, 15, 16, 17.** 63 photos. Now at intro + ch 1–6, 15–17.

Still pending (296 photos):

| Book | Pending chapter folders | Photos |
|------|------------------------|--------|
| macOS Tahoe For Dummies (`for dummies/mac tahoe`) | 3–20, `21-24` | 215 |
| AI in Business For Dummies (`for dummies/ai in business`) | 7–14 | 80 |
| Trading For Dummies (`for dummies/Trading`) | 1 stray `IMG_6096.HEIC`, no chapter structure | 1 |

### Correct conversion settings (verified 2026-08-16)

The skill's `-Z 700` is unusably illegible for these pages, and the previously recorded
`-r 270 -Z 1700` is also wrong — **`-r 270` rotates the wrong way**. What actually works:

```bash
sips -Z 1500 -r -90 -s format jpeg -s formatOptions 45 in.HEIC --out out.jpg
```

That lands at ~180–245KB/page, safely under the Read tool's 256KB limit, and is fully legible.
`-Z 1700` produces ~400KB files that the Read tool rejects.

Other notes for whoever resumes:
- `~/Documents/Code/spine` **does not exist** — the repo is `bookrank`. The `summarize-books`
  skill still says `spine`; it is stale.
- `index.html` is a landing page, not the book list. Summary badges live in **`rankings.html`**.
  The skill's instruction to edit index.html is stale too.
- `ls` is aliased to eza on this machine and chokes on paths passed positionally — use `/bin/ls`.
- Cost observed: roughly 3–5% of a session's usage per ~11-photo chapter.

Detection command:
```bash
B=~/Library/Mobile\ Documents/com~apple~CloudDocs/Documents/Misc/Books
find "$B" -mindepth 3 -maxdepth 3 -type d '!' -exec test -e "{}/summary.md" ';' -print
```

## Ingested 2026-08-18
- [ ] Remove italics from the header.
- [ ] Move header text to the top-left corner.
- [ ] All list items should show a book cover thumbnail — currently only the bottom "All Rankings" section does. Apply that same styling to the entire list.
- [ ] Hook up Goodreads syncing / integration / login.
- [ ] (Context from note: all library books returned.)
