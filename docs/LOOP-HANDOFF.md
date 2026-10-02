# Bookrank loop handoff (2026-10-02, evening)

## What the loop is

v1.1 loop works the roadmap.md "## v1.1" section: iOS sample chapter + resubmit (done), Mac sample chapter, real-phone test of voices/audio/lock, Web offline service worker, iOS VoiceOver labels, daily nudge notification, landing/screenshots refresh after approval, and cleanup (watch app retirement or port to summaries, delete books.json and build.py). Wakes about every 25 minutes to pick the next item.

## Where things stand

iOS 1.0.5 rejected on audio guideline 2.5.4 (review notes were stale), fixed with signed-out "Try a sample chapter" (Art of War, device voice, no account), testSampleListen UI test passes on iPhone simulator, resubmitted and WAITING_FOR_REVIEW with exact steps in review notes. Mac 1.0.5 still WAITING_FOR_REVIEW with honest review notes added (was empty). Both builds have voices, Goodreads, offline, search, export, sign-in redesigned (all platforms), screenshots retaken and automated, og.png live, monetization ($0.99 upfront iOS/Mac, $1 web Stripe). Web accessibility pass complete. Mac needs sample chapter and orange tint on sign-out buttons. Real-phone test of voices and background audio pending. App Review lesson: keep notes true every release; if Apple asks again, Joshua records 20s on real phone showing it works.

## Next, in order

- Real-phone test (Lily and Brian voices, locked screen, background audio continues)
- Mac sample chapter (like iOS, for v1.1 Mac build)
- Web offline (service worker caches last opened summaries, readable without network)
- iOS VoiceOver labels (chapter reader and sign-in, Dynamic Type check)
- Daily nudge (one local notification with random chapter line)
- Landing and app screenshots refresh after iOS approved (bump version, ship both platforms)
- Watch app (port summaries list read-only, or retire the watchOS target)
- Cleanup (delete books.json, scripts/build.py, covers.json once nothing reads them)

## Restart prompt

```
/loop 25m ~/Documents/Code/bookrank; continue the v1.1 loop working roadmap.md "## v1.1" section: real-phone test of voices/audio/lock, Mac sample chapter, Web offline (service worker), iOS VoiceOver labels, daily nudge notification, landing/screenshots refresh after 1.0.5 approved, watch app retirement or port. Check app Review notes stay true every release; if Apple asks for proof, Joshua records 20s on physical phone. Run live QA on each step. Commit progress to bookrank/roadmap.md and memory/project_bookrank.md, update journal checkpoint, deploy vault and master.md. No subagents, finish each step fully before moving to the next.
```
