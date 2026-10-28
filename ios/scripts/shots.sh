#!/bin/sh
# Fresh screenshots on every minor/major bump and every UI fix, so the store, README and landing never lag the app.
#   sh scripts/shots.sh        (from ios/)
# Store set: fastlane snapshot on the devices in fastlane/Snapfile -> fastlane/screenshots/en-US.
# QA set: the signed-out sign-in and create-account screens -> $SHOTS_DIR (default /tmp/kernel-shots), phone and iPad.
set -e
cd "$(dirname "$0")/.."
fastlane snapshot --only_testing KernelUITests/PreviewScreenshot/testTakeScreenshots --skip_open_summary
export SIMCTL_CHILD_SHOTS_DIR="${SHOTS_DIR:-/tmp/kernel-shots}"
mkdir -p "$SIMCTL_CHILD_SHOTS_DIR"
for name in "iPhone 11 Pro Max" "iPad Pro 13-inch (M5)"; do
  xcodebuild test -project Kernel.xcodeproj -scheme Kernel -destination "platform=iOS Simulator,name=$name" \
    -only-testing:KernelUITests/PreviewScreenshot/testSignInScreens CODE_SIGNING_ALLOWED=NO >/dev/null 2>&1 && echo "signin shots ok $name"
done
xcrun simctl shutdown all
echo "shots in fastlane/screenshots/en-US and $SIMCTL_CHILD_SHOTS_DIR"
