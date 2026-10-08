# Notchy

Turn the MacBook notch into a little status display for your Claude Code and opencode sessions.

Prompt your agent, switch to your browser, and keep an eye on progress from the notch
instead of switching back to Terminal every few minutes.

- **Dots next to the notch** show every session at a glance: purple is working, green is done, orange needs you.
- **Hover the notch** to see each session: project, your last prompt, what the agent is doing, task progress and time spent.
- **When a session finishes**, the notch peeks open for a few seconds with the agent's last message.
- **When the agent needs permission** (or asks you a question), the notch pulses orange until you answer.
- **Click a session** to jump straight to its Terminal tab.

## Requirements

- macOS 14 or later, ideally a MacBook with a notch (other screens get a fake notch at the top center)
- Works on both Apple Silicon and Intel Macs
- [Claude Code](https://docs.claude.com/en/docs/claude-code) or [opencode](https://opencode.ai) (1.2+), running in Terminal.app
  (other terminals still work, but clicking a session only brings Terminal forward)

## Install

1. Open the [**Releases**](https://github.com/nadialvy/notchy/releases/latest) page and download `Notchy-x.y.z.zip`.
2. Double-click the zip to unpack it. You get a `Notchy` folder.
3. Open Terminal and run the installer from that folder:

   ```bash
   cd ~/Downloads/Notchy
   ./install.sh
   ```

   It copies the app to `~/Applications`, puts the hook in `~/.notchy/bin`, and opens Notchy. Then it
   connects whichever agents you have:

   - **opencode:** adds the plugin `~/.config/opencode/plugins/notchy.js`.
   - **Claude Code:** shows the change it wants to make to `~/.claude/settings.json`. Type `y` to save it.

   Run opencode or Claude Code at least once before installing, so their config folders exist.

Sessions started after this show up automatically. The first time you click a session,
macOS asks whether Notchy may control Terminal. Allow it so Notchy can switch tabs.

Use the menu bar icon to turn sounds on or off, enable Launch at Login, or quit.

> **Why a script instead of dragging the app?** Notchy isn't signed with an Apple Developer ID,
> so macOS would block it when you double-click it. The installer clears that block for you.
> The Claude Code step also needs `jq`, which macOS 15+ already has. On macOS 14, run `brew install jq` first.

### Build from source

```bash
git clone https://github.com/nadialvy/notchy.git
cd notchy
./scripts/install.sh   # builds the app, installs the hook and (if you use opencode) the opencode plugin
./scripts/hooks.sh     # Claude Code only: adds the hook to ~/.claude/settings.json (shows a diff first)
```

### Uninstall

```bash
~/Downloads/Notchy/hooks.sh --remove   # or ./scripts/hooks.sh --remove from the repo
rm -rf ~/Applications/Notchy.app ~/.notchy ~/.config/opencode/plugins/notchy.js
```

## How it works

Claude Code [hooks](https://docs.claude.com/en/docs/claude-code/hooks) call `notchy-hook` on session
events. The hook writes a small JSON file per session to `~/.notchy/sessions/` and exits right away,
so it never slows Claude down. Notchy watches that folder and updates the notch.

For opencode, the plugin in [`opencode/notchy.js`](opencode/notchy.js) turns opencode events into the
same payloads Claude Code sends and passes them to `notchy-hook`, so both agents end up in the same place.

See [CONTEXT.md](CONTEXT.md) for the vocabulary and [docs/adr](docs/adr) for the design decisions.

## Development

```bash
./scripts/build.sh                                        # build/Notchy.app
build/Notchy.app/Contents/MacOS/Notchy --snapshot /tmp/n  # render each notch state to PNG
./scripts/release.sh                                      # universal build/Notchy-<version>.zip for a release
```

Building from source needs Swift 5.10+ (the Xcode Command Line Tools are enough).
