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
if [ -d ~/.config/opencode ]; then
  mkdir -p ~/.config/opencode/plugins
  cp opencode/notchy.js ~/.config/opencode/plugins/notchy.js
  echo "Installed the opencode plugin at ~/.config/opencode/plugins/notchy.js"
fi

open ~/Applications/Notchy.app
echo "Installed ~/Applications/Notchy.app and ~/.notchy/bin/notchy-hook"
echo "Next (Claude Code): ./scripts/hooks.sh to register the hooks"
