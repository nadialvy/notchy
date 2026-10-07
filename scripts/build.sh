#!/bin/bash
# Builds Notchy.app into ./build without Xcode.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
BIN="$(swift build -c release --show-bin-path)"

APP=build/Notchy.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/Notchy" "$BIN/notchy-hook" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
codesign --force --deep --sign - "$APP" >/dev/null

echo "Built $APP"
