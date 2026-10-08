#!/bin/bash
# Builds a universal Notchy.app and packages it as build/Notchy-<version>.zip for a GitHub release.
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/build.sh --universal

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
STAGE=build/Notchy
ZIP=build/Notchy-$VERSION.zip
rm -rf "$STAGE" "$ZIP"
mkdir -p "$STAGE"
cp -R build/Notchy.app "$STAGE/"
cp scripts/release-install.sh "$STAGE/install.sh"
cp scripts/hooks.sh "$STAGE/hooks.sh"
cp -R opencode "$STAGE/opencode"
ditto -c -k --keepParent "$STAGE" "$ZIP"

echo "Packaged $ZIP"
echo "Publish: gh release create v$VERSION $ZIP --title \"Notchy $VERSION\" --notes-file <notes.md>"
