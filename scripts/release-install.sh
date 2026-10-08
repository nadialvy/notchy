#!/bin/bash
# Installer shipped inside the release zip (as install.sh).
# Installs the prebuilt Notchy.app next to this script, then registers the Claude Code hooks.
set -euo pipefail
cd "$(dirname "$0")"

# The app isn't notarized, so clear the "downloaded from the internet" flag before opening it.
xattr -dr com.apple.quarantine Notchy.app 2>/dev/null || true

pkill -x Notchy 2>/dev/null || true
mkdir -p ~/Applications ~/.notchy/bin
rm -rf ~/Applications/Notchy.app
cp -R Notchy.app ~/Applications/
cp Notchy.app/Contents/MacOS/notchy-hook ~/.notchy/bin/notchy-hook

open ~/Applications/Notchy.app
echo "Installed ~/Applications/Notchy.app and ~/.notchy/bin/notchy-hook"

./hooks.sh
