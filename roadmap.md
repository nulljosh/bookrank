## 2026-08-27 — one source of truth + web account deletion DONE; iOS auth is next

Shipped today (see git log):
- `books.json` is the single source of truth. `scripts/build.py` generates rankings.html rows,
  book_rankings.md and all three iOS JSON resources. **The app went from 71 to 111 ranked books** —
  the old `export-books.py` regex required a `**Rating:**` line and silently dropped the 40 without
  one. `Book.swift` rating/reviewCount are now optional; they were non-optional, so shipping those
  40 would have crashed decoding. `scripts/test-build.py` pins both.
- Account deletion on the web (`library.html` Profile, typed DELETE confirmation). The shared
  `delete-account` Edge Function had **no CORS/OPTIONS handler**, so the browser call could never
  have worked; redeployed as v2, additively. Source now vendored at
  `supabase/functions/delete-account/index.ts` (it previously existed only as a deployment).
  Verified with a throwaway account: user gone, summary cascade-deleted, owner's 20 untouched.

### Phase C DONE 2026-08-29 — Supabase auth + account deletion in the iOS/macOS app

Shipped: `AuthStore.swift` (email+password, no third-party provider — that would make
Sign in with Apple mandatory under 4.8), `SessionKeychainStorage.swift` copied verbatim
from lexly, `AccountView.swift` with sign in/up/out, password reset and Delete account
behind a typed DELETE, `DataStore.loadSummaries()` fetching slug/title/content in one
query, and the `summaries` section in `LibraryView` that had been written months ago and
never rendered. `SummaryEntry` now matches the real table, which has no author column.
`BookrankMac.entitlements` gained `com.apple.security.network.client` (verified present in
the signed bundle). Both schemes build. supabase-swift resolves to **2.55.1** here, not the
2.48.0 the siblings pin — `from: "2.5.1"` allows it and it built clean, but that is drift
worth knowing about if a sibling ever needs to match.

Also removed a stale `ios/Spine.xcodeproj` left over from the rename: two `.xcodeproj` in
one directory made bare `xcodebuild` refuse to pick one.

**Still not for submission.** The listing copy and screenshots describe bundled offline
summaries that no longer exist. Left to do before it could ship: refresh the App Store
description + screenshots, and verify auth email delivery (below).

<details><summary>Original Phase C plan, kept for reference</summary>

Full plan at `~/.claude/plans/there-should-be-one-serialized-octopus.md`. Deferred on usage budget,
not on any blocker. Decisions already made: **auth optional** (browse signed-out, sign in only for
summaries — the Guideline 4.2 answer), **email+password only** (a third-party provider would make
Sign in with Apple mandatory under 4.8).

Mostly a transplant — lexly, healstack and litigate all already do this against the same project:
- [ ] `ios/project.yml`: add `packages: Supabase: {url: https://github.com/supabase/supabase-swift.git, from: "2.5.1"}` (healstack's pin, NOT litigate's stale `supabase-community` URL) and wire both targets. This is the repo's first SwiftPM dependency.
- [ ] **`BookrankMac.entitlements` needs `com.apple.security.network.client`.** It is sandboxed without it today, so Mac auth will fail silently. Edit the committed file by hand — xcodegen drops keys in this project.
- [ ] `Models/AuthStore.swift`: structural copy of `healstack/ios/Services/AuthService.swift` (`@Observable @MainActor` + one `authStateChanges` loop handling `.initialSession`). Keep the session `signIn` returns rather than re-reading `try? auth.session` — that swallowed refresh failures and caused a macOS 2.1 rejection in lexly. Bypass auth under `UITEST_SNAPSHOT` so screenshot automation still runs.
- [ ] `Models/SessionKeychainStorage.swift`: copy verbatim from `lexly/ios/Sources/Shared/`. Needed because Bookrank ships a Mac target.
- [ ] Credentials hardcoded in Swift (lexly style) — `scripts/prepare-plist.py` rewrites Info.plist here, so `$(SUPABASE_URL)` substitution is the fragile choice.
- [ ] `DataStore.swift`: replace `summaryIndex = []` with a `bookrank_summaries` fetch. `SummaryDetailView` and `LibraryView.summaries` are still in the tree.
- [ ] `Views/AccountView.swift`: sign in/up/out + Delete account. Reuse the raw-`URLRequest` bearer helper at `healstack/ios/Services/AuthService.swift:103`; the endpoint needs no further work.
- [ ] Account deletion is a hard Guideline 5.1.1(v) blocker — it ships in the same pass as auth, not after.
- [ ] Do NOT submit afterwards: listing metadata and screenshots still describe bundled offline summaries.

</details>

### Open, small
- [x] "Statistics for Dummies" author filled 2026-08-29 (Deborah J. Rumsey); `build.py` no longer warns.
- [x] Read-aloud from the summary list, 2026-08-29. The editor's speech code became one shared
  `speakText()` called by both the editor button and a per-row Listen button; the list query
  omits `content`, so a row fetches its body on first press.
- [ ] Auth email deliverability still unverified (shared spark SMTP).

## Direction settled 2026-08-27 — Bookrank is a personal shelf, not a product

Evidence: `bookrank_summaries` is 20 rows / 1 owner / no edits since the 2026-08-19 import.
Nobody but the owner has ever signed up. The content (books read, library loans) is
inherently personal, and a multi-tenant reading tracker means competing with
Goodreads/StoryGraph with no distribution. So: **single-user, keep the auth layer only as
the owner's private sync.** This closes the personal-vs-product question that several items
below were implicitly blocked on.

Consequences — DO:
- [ ] **One source of truth for the book list.** Today it is three hand-maintained copies
  that have already drifted: 134 `li.book` rows in `rankings.html`, 71 books in
  `ios/Bookrank/Resources/books.json`, 444 lines in `book_rankings.md`. Adding a book means
  editing all three. Generate the latter two from one JSON. Highest value in the repo, and
  it was worth doing under either direction. (Related: the 2026-08-17 clobber incident where
  a 499KB summary was replaced by a 304KB one and only `git diff` caught it.)
- [ ] **iOS/macOS ships a hollow shell.** `DataStore.summaryIndex = []`, no auth, no search,
  no way to add a book — a stranger downloading it can do nothing (Guideline 4.2 risk). Fix
  is Supabase auth in the app so the *owner* can read their own summaries. NOTE: the
  "Digest companion app — BLOCKED, needs a backend decision (Supabase vs static JSON)" item
  below is **stale**. Supabase won on 2026-08-19 when summaries moved. Unblock it.
- [ ] **Account deletion** becomes a hard Guideline 5.1.1(v) submission blocker the moment
  the app offers accounts, i.e. the moment the item above lands. Build it in the same pass,
  not after a rejection.
- [ ] **Verify auth email delivery** before relying on password reset. Signup confirmation and
  reset both go through the shared `spark` project's SMTP; all 15 users show confirmed, so
  confirmations may simply be off. A sibling project (Sparkjar) has a dead Resend key.
  Unverified either way — check, don't assume.
- [ ] Read-aloud (shipped 2026-08-27) only reads the editor textarea; you cannot listen from
  the summary list without opening the editor. Small gap in an otherwise-done feature.

Consequences — DROP (do not re-litigate):
- Per-user shelves / ratings / loans. Single-tenant is the decision.
- Per-book public pages and SEO/indexable summaries. There is no audience to court.

## DONE 2026-08-19 — summaries moved behind per-user accounts

Chapter summaries of purchased/library books were public in this repo and bundled in the
shipping app. All of that is closed:

- Supabase `spark` (`tjsxsqlxjmanwvmywwvw`), table `bookrank_summaries`, owner-only RLS
  (verified: `set local role anon` reads 0 rows).
- `library.html` — email/password sign-in, list, markdown editor/preview, create/edit/delete.
  Any visitor can register and write their own summaries; nothing is public.
- All 20 existing summaries imported into the owner's account (2.54 MB, 20 rows).
  Re-import tool: `scripts/import-summaries.py`.
- `summary.html` deleted, the 26 `Summary` badges in `rankings.html` repoint to `library.html`,
  index copy updated.
- **Git history purged** (`git filter-repo`, force-pushed). Pre-purge backups kept outside the
  repo: `~/Documents/Code/.bookrank-prepurge.bundle` and `.bookrank-summaries-backup/`.
- iOS/macOS app no longer bundles any summary: `Resources/summaries/` and
  `summaries-index.json` deleted, `DataStore.summaryIndex` is `[]`, the Summaries section is
  out of `LibraryView`. Builds clean for `generic/platform=iOS Simulator`.

Open:
- [ ] iOS/macOS have no way to read summaries now. Needs Supabase auth in the app
  (`supabase-swift`) fetching `bookrank_summaries`; `SummaryDetailView` and the
  `LibraryView.summaries` section are still in the tree, ready to be re-wired.
- [ ] AI-generated summaries for a book a user picks needs a backend (Cloudflare Worker +
  model key) — cannot live in a static page. The editor is manual entry for now.
- [ ] App Store listing/screenshots still advertise bundled offline summaries; update before
  the next submission.

## Mac packaging gotchas (reusable for other apps)
- `xcodebuild -exportArchive` could NOT export this: it insists the MAS profile contain the *installer* cert, which Apple rejects ("no current certificates ... compatible with MAC_APP_STORE profiles"). Working path is manual: copy `.app` out of the archive → drop the profile in as `Contents/embedded.provisionprofile` → `codesign --force --sign "3rd Party Mac Developer Application: …" --entitlements ios/Bookrank/BookrankMac.entitlements --options runtime --timestamp` → `productbuild --component <app> /Applications --sign "3rd Party Mac Developer Installer: …"` → `asc builds upload --pkg`.
- A MAS-signed `.app` will not launch locally (no receipt), so it can't be screenshotted. For screenshots, take a second copy of the archive's `.app`, `xattr -cr` it, `codesign --force --deep --sign -` (ad-hoc), then `open` it.
- Build number 2 upload silently **FAILED** (codes 90345 + 90189) with no error surfaced by `asc builds upload` — it reported success. Only `asc builds uploads list` showed the failure. Re-uploading as build 3 went through unchanged. Always verify via `asc builds uploads list` after an upload, not the upload command's own output.

## Done 2026-08-18 — stale listing metadata fixed and staged

The live 1.0 listing said **"Uprighty"** in the description and pointed `supportUrl` at
`spine.heyitsmejosh.com`, which is dead (curl returns 000; `bookrank.heyitsmejosh.com` returns 200).
ASC locks version metadata on a READY_FOR_SALE version, so the fix needed a new version row.

Created and populated **1.0.1** on both platforms, `PREPARE_FOR_SUBMISSION`:
- iOS `8df5fc2e-233c-4430-bcd2-da9d938fa698`
- macOS `7a8c6577-4018-41bf-bfb3-776ad8c08cff`

Applied to both (verified by re-read): corrected description opening with "Bookrank", `supportUrl`
set to `https://bookrank.heyitsmejosh.com`, and a What's New line.

- **CLOSED 2026-08-25** (done — iOS and macOS 1.0.1 are both READY_FOR_SALE). Was: ~~1.0.1 still needs a build.~~ `asc validate` reports the one remaining blocking error,
  `build.required.missing`. Every existing build (highest is `6`, 2026-08-03) was consumed by 1.0 —
  attaching build `6` fails with "The specified pre-release build could not be added." This needs a
  fresh archive + upload with a bumped build number. The metadata above is already staged and will
  carry onto whatever build gets attached, so that work is done and does not need redoing.

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
- [ ] Root cause fixed in `~/.claude/skills/summarize-books/SKILL.md` the same day: validation now requires >1500 chars AND >=250 chars per source image, and the skill explicitly forbids shortening a summary to save budget when deletion follows (stop and report instead). Nothing to do here, recorded so the fix isn't re-litigated.

## Blocked on Joshua
- [ ] Icon refresh (currently a yellow/blue two-bar abstract mark; roadmap asks for "a simpler refresh") — a design decision, not a code fix. Icon asset itself is technically valid (1024×1024, no alpha) so it is not blocking review.

## Build gotchas (2026-08-03)
- **xcodegen silently ignores `CFBundleVersion`, `CFBundleShortVersionString`, and `UISupportedInterfaceOrientations~ipad` in `info.properties`** — it rewrites `Bookrank/Info.plist` with its own defaults and resets the build number to `1` every run. Run `python3 ios/scripts/prepare-plist.py <build-number>` AFTER `xcodegen generate` and BEFORE archiving.
- **ITMS-90474** killed build 4: iPad builds must declare all four orientations or set `UIRequiresFullScreen`. `prepare-plist.py` now writes the orientations. `xcodebuild` warns about this at archive time ("All interface orientations must be supported…") — that warning is a hard upload failure, not cosmetic.
- **`asc builds upload` reports success on failed uploads.** Always pass `--verify-timeout 120s` and confirm with `asc builds uploads list`.
- **`asc review submit` is broken** — it creates the submission, adds the version, then fails its own validation claiming the submission "does not contain target version". The version *is* attached. Use `asc review submissions-submit --id <id> --confirm` instead.
- **ITMS-90886 / TestFlight ineligibility (builds 1-5)** — the iOS `Bookrank` target had **no entitlements file at all**, so the signed bundle carried no `application-identifier` while the embedded profile did. Apple flags that combination "not required to fix", but it silently makes every build **TestFlight-ineligible**. Fixed 2026-08-03 with `ios/Bookrank/Bookrank.entitlements` (just `application-identifier` = `$(AppIdentifierPrefix)$(CFBundleIdentifier)`) wired via `CODE_SIGN_ENTITLEMENTS` in `project.yml` — hand-committed rather than xcodegen-generated, since xcodegen drops keys in this project. Verify any future build before uploading:
  ```
  codesign -d --entitlements :- /path/to/Payload/Bookrank.app
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
- [ ] Hook up Goodreads syncing / integration / login.
- [ ] (Context from note: all library books returned.)

## 2026-08-18 — 1.0.1 iOS submitted
- Fixed: header said "Uprighty" (bad cross-project rename) -> "Bookrank".
- Fixed: library.json loans cleared (books returned); section hides when empty.
- Fixed: prepare-plist.py now writes CFBundleShortVersionString from project.yml
  MARKETING_VERSION (xcodegen was dropping it — plist said 1.0 vs ASC 1.0.1).
- Screenshots re-shot (iPhone 11 Pro Max + iPad Pro 13") and replaced on ASC.
- Build 7 uploaded, attached, encryption declared. iOS 1.0.1 WAITING_FOR_REVIEW.
- DONE (verified 2026-08-24): macOS 1.0.1 is now READY_FOR_SALE, so the archive/upload
  described here happened. Both platforms are live at 1.0.1.

## Braindump 2026-08-19
- [ ] Shortcuts for adding summaries to an account
- [ ] Finish the raw book files sitting in the iCloud folder
- [ ] API routes covering summary create/read/update
- [ ] In-app book file upload so a user can generate summaries for a book on their profile
- [ ] All book summary content is user-specific — store in Supabase

## Ingested 2026-08-22
- [ ] Finish the raw iCloud books folder. Possible duplicates in the accounting folder — first 3 chapters. Dedupe before summarizing.

## Deferred from 2026-08-22 night (session limit)
- [ ] Run `python3 scripts/fetch-covers.py --retry-misses` — the Google Books fallback is committed but the run never finished, so 8 rows still show the dashed placeholder instead of art. One command, then commit `rankings.html`.
- [ ] Delete the dead iOS summaries code — `SummaryDetailView`, the `summaries` section in `LibraryView`, `SummaryEntry`, and the `summarySlug` badge branch all read `store.summaryIndex`, which `DataStore` hardcodes to `[]` since summaries moved behind Supabase on 2026-08-19. None of it can render. Needs one xcodebuild to confirm both targets still compile.
- [ ] **STILL OPEN — CANNOT be fixed without a new version, proven 2026-08-25.** Tried the direct
      edit: `asc apps info edit --app 6792376485 --platform IOS --version 1.0.1 --description ...`
      returns *"Attribute 'description' cannot be edited at this time"* because every version row
      is `READY_FOR_SALE`. Apple only allows description edits on an editable (unreleased) version,
      so this rides along with the next release — it is not a standalone task and should not
      trigger a release of its own. **Do not retry the direct edit; it will fail the same way.**
      The inaccuracy is real though: the live copy says "dive into detailed summaries" as if they
      ship in the app, while the corrected local copy says they live on the web behind your own
      account. Original note follows: The live listing still reads "...ranked by rating with chapter-by-chapter summaries for finished books", advertising bundled summaries the app no longer carries (they moved behind per-user Supabase accounts). `metadata/version/1.0/en-US.json` holds the corrected copy locally but 1.0.1 shipped without it, so this is a live Guideline 2.3.1 accurate-metadata risk. Push it with the next version: `asc metadata push --app 6792376485 --version <v> --platform IOS --dir ./metadata` (the workflow does NOT push metadata on its own). Original note follows:
- [ ] **`~/Documents/Code/uprighty/` is a DIVERGED clone of this repo, not just a stale one — do
      not delete it yet.** Checked 2026-08-24: it sits 171 commits behind origin/main *and* holds
      commits that exist nowhere else (`af54ff0 docs: whitepaper + README link`, `3e34ca1 Add
      marketing landing page at /, move rankings app to /rankings.html`, `761ac52 wip: partial
      work from /work notes ingest`). `af54ff0` is not in this clone's object store at all, so
      those changes would be lost with the folder. Working tree is clean, so nothing is at risk
      today. Someone needs to cherry-pick or explicitly discard the unique commits, and only then
      remove the folder. The prior note that it was merely "155 behind" understated this.

- [ ] **Port the books-wip content onto main, then retire `uprighty/`.** The folder
      `~/Documents/Code/uprighty` shares this repo's remote but is NOT a stale clone: verified
      2026-08-24 it held 175 commits / 138 files / ~33k insertions existing nowhere else (every
      `covers/*.jpg`, `summaries/the-optimist.md`, `summaries/statistics-for-dummies.md`), while
      this tree has no `summaries/` directory at all. Rescued to `origin/books-wip`.
      **Do not merge the branch** — the two diverged 2026-06-18 and `main` is itself 171 commits
      ahead (Spine->Bookrank rename, cover-fetch pipeline, live site, `scripts/import-summaries.py`,
      `sync-summaries.sh`), so a merge would drag two months of superseded history over the live
      repo. Instead: branch off current `main`, copy `summaries/` + `covers/` across, run the
      existing import scripts, verify the site builds. Careful with covers — b85e7e5 deliberately
      dropped ~12M of dead ones, so a bulk restore would undo that on purpose-deleted files.
      Delete `uprighty/` only once the content is on `main`; keep `origin/books-wip` as the archive.

## From Apple Notes (imported 2026-08-25)

- [ ] Ship the app. Make sure Goodreads syncing and connection works — login with Goodreads, scan all read books and collections.

## WebMCP + REST API rollout -- shipped 2026-08-27

Done. 6 tools on `library.html` only: `list_summaries`, `get_summary`, `whoami`, `create_summary`, `save_summary`, and a gated `delete_summary`. Tools go through the `rows` data layer, never the editor functions, so a tool call cannot disturb what the user has open. `index.html` and `rankings.html` are static and deliberately carry no tools.

See `docs/API.md` for the full tool table, linked from the README.
