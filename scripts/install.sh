#!/bin/bash
# Builds Notchy, installs it to ~/Applications, and puts the hook at ~/.notchy/bin/notchy-hook.
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/build.sh

pkill -x Notchy 2>/dev/null || true
mkdir -p ~/Applications ~/.notchy/bin
rm -rf ~/Applications/Notchy.app
cp -R build/Notchy.app ~/Applications/
cp build/Notchy.app/Contents/MacOS/notchy-hook ~/.notchy/bin/notchy-hook

open ~/Applications/Notchy.app
echo "Installed ~/Applications/Notchy.app and ~/.notchy/bin/notchy-hook"
echo "Next: ./scripts/hooks.sh to register the Claude Code hooks"
