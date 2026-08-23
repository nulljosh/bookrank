#!/usr/bin/env python3
"""Patch keys into Bookrank/Info.plist that xcodegen refuses to honour.

Run AFTER `xcodegen generate` and BEFORE archiving:

    xcodegen generate && python3 scripts/prepare-plist.py 5

xcodegen rewrites Info.plist from project.yml's `info.properties`, but silently
drops CFBundleVersion, CFBundleShortVersionString and the ~ipad orientation key,
substituting its own defaults (build number always resets to "1"). Uploading that
plist fails App Store processing with ITMS-90474 (iPad multitasking requires all
four orientations unless UIRequiresFullScreen is set) and wastes a build number.

ponytail: string-patching generated XML instead of using plistlib round-trip,
because plistlib would reorder/normalise the whole file and bloat the git diff.
Switch to plistlib if this ever needs to set more than a couple of keys.
"""
import plistlib
import re
import sys
from pathlib import Path

PLIST = Path(__file__).resolve().parent.parent / "Bookrank" / "Info.plist"

IPAD_ORIENTATIONS = [
    "UIInterfaceOrientationPortrait",
    "UIInterfaceOrientationPortraitUpsideDown",
    "UIInterfaceOrientationLandscapeLeft",
    "UIInterfaceOrientationLandscapeRight",
]


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {Path(__file__).name} <build-number>", file=sys.stderr)
        return 2
    build = sys.argv[1]
    if not build.isdigit():
        print(f"build number must be numeric, got {build!r}", file=sys.stderr)
        return 2

    # ponytail: parse the one line rather than pull in a YAML dep.
    yml = (PLIST.parent.parent / "project.yml").read_text()
    marketing = re.search(r'MARKETING_VERSION:\s*"([^"]+)"', yml).group(1)

    data = plistlib.loads(PLIST.read_bytes())
    data["CFBundleVersion"] = build
    data["CFBundleShortVersionString"] = marketing
    data["UISupportedInterfaceOrientations~ipad"] = IPAD_ORIENTATIONS
    PLIST.write_bytes(plistlib.dumps(data))

    print(f"Info.plist: CFBundleShortVersionString={marketing}, CFBundleVersion={build}, {len(IPAD_ORIENTATIONS)} iPad orientations")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
