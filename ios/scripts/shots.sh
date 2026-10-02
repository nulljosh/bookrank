#!/bin/sh
# Fresh screenshots on every minor/major bump and every UI fix, so the store, README and landing never lag the app.
#   sh scripts/shots.sh        (from ios/)
# Store set: fastlane snapshot on the devices in fastlane/Snapfile -> fastlane/screenshots/en-US.
# QA set: the signed-out sign-in and create-account screens -> $SHOTS_DIR (default /tmp/bookrank-shots), phone and iPad.
set -e
cd "$(dirname "$0")/.."
fastlane snapshot --only_testing BookrankUITests/PreviewScreenshot/testTakeScreenshots --skip_open_summary
export SIMCTL_CHILD_SHOTS_DIR="${SHOTS_DIR:-/tmp/bookrank-shots}"
mkdir -p "$SIMCTL_CHILD_SHOTS_DIR"
for id in $(xcrun simctl list devices booted | grep -E "iPhone|iPad" | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'); do
  xcodebuild test -project Bookrank.xcodeproj -scheme Bookrank -destination "platform=iOS Simulator,id=$id" \
    -only-testing:BookrankUITests/PreviewScreenshot/testSignInScreens CODE_SIGNING_ALLOWED=NO >/dev/null 2>&1 && echo "signin shots ok $id"
done
echo "shots in fastlane/screenshots/en-US and $SIMCTL_CHILD_SHOTS_DIR"
