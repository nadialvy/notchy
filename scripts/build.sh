#!/bin/bash
# Builds Notchy.app into ./build without Xcode.
# Pass --universal to build for both Apple Silicon and Intel (used for releases).
set -euo pipefail
cd "$(dirname "$0")/.."

APP=build/Notchy.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

if [ "${1:-}" = "--universal" ]; then
  for arch in arm64 x86_64; do
    swift build -c release --triple "$arch-apple-macosx14.0"
  done
  for bin in Notchy notchy-hook; do
    lipo -create -output "$APP/Contents/MacOS/$bin" \
      ".build/arm64-apple-macosx/release/$bin" ".build/x86_64-apple-macosx/release/$bin"
  done
else
  swift build -c release
  BIN="$(swift build -c release --show-bin-path)"
  cp "$BIN/Notchy" "$BIN/notchy-hook" "$APP/Contents/MacOS/"
fi

cp Resources/Info.plist "$APP/Contents/"
codesign --force --deep --sign - "$APP" >/dev/null

echo "Built $APP"
