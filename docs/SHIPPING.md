# Shipping

Always set `ASC_BYPASS_KEYCHAIN=1` for `asc`. ASC app 6792376485, one record for iOS and Mac, bundle `com.heyitsmejosh.spine`, team QMM486NPYC.

## Web

`sh scripts/build-site.sh`, then `npx wrangler pages deploy dist --project-name bookrank --branch main --commit-dirty=true`. A push deploys nothing. Bump `CACHE` in `sw.js` when a precached file changes.

## iPhone and iPad

1. `asc versions create`, then set What's New. `asc publish` fails its own check when What's New is empty.
2. The listing in every language: `sh scripts/store-listing.sh <version id>` puts `docs/store/listing.json` (English, French, Spanish, German) on the new version. Fresh screenshots: `sh ios/scripts/shots.sh`; the French, Spanish and German sets sit in `ios/fastlane/screenshots/<locale>`. If fastlane hangs in `simctl diagnose` after a passing run, the PNGs are already in `~/Library/Caches/tools.fastlane/screenshots`.
3. `asc workflow run ship-ios VERSION:<v>`. It edits `ios/project.yml`, runs xcodegen and `ios/scripts/prepare-plist.py <build>`, because xcodegen drops the version, build number and iPad orientations.
4. Afterwards `git checkout ios/Kernel/Info.plist`.
5. Once the version is live: `sh scripts/promo.sh` sets the promotional text from `docs/store/listing.json` (no review needed), and an in-app event goes up if the release has one ([events.md](store/events.md)).

The app and its widget extension (`com.heyitsmejosh.spine.widgets`, from 88.0.0) share the App Group `group.com.heyitsmejosh.spine`; on the Mac (90.0.0) the group is `QMM486NPYC.com.heyitsmejosh.spine`, since a Mac group carries the team id. Signing is automatic, so the first archive after 88 registers the group and the extension's App ID; archive with `-allowProvisioningUpdates` (or once from Xcode) if the workflow stops on a missing profile.

## Mac

Archive `KernelMac` and export with `ios/ExportOptionsMac.plist` (automatic signing). Then `asc builds upload --pkg`, set `asc builds update --uses-non-exempt-encryption=false`, and `asc review submit --platform MAC_OS`.

If export fails, the manual path works: copy the `.app` out of the archive, embed the current profile from `asc signing fetch --bundle-id com.heyitsmejosh.spine --profile-type MAC_APP_STORE`, sign with the entitlements Xcode expanded into the archive (`codesign -d --entitlements - --xml <archive app>`), not the source file, then `productbuild` with the installer certificate. A Mac App Store signed app will not launch locally; for screenshots ad-hoc sign a copy.

## Gotchas

- `asc builds upload` can say success when Apple's processing failed. Check `asc builds uploads list`.
- ASC allows five open review submissions per app and empty drafts cannot be cancelled. Reuse one: `asc versions attach-build`, `asc review items add --item-type appStoreVersions`, `asc review submissions-submit --id <id> --confirm`.
- Cancelling a submission moves the version to `DEVELOPER_REJECTED`. Wait for that state before attaching a build.
- Review notes must stay true. Mention the Goodreads sign-in (Goodreads' own page in a web view, nothing sent to Kernel) and where to find Listen.
- Store screenshots avoid the objectionable text in The Contrarian and The Optimist.
