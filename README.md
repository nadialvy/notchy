# Notchy

Turn the MacBook notch into a little status display for your Claude Code sessions.

Prompt Claude, switch to your browser, and keep an eye on progress from the notch
instead of switching back to Terminal every few minutes.

- **Dots next to the notch** show every session at a glance: purple is working, green is done, orange needs you.
- **Hover the notch** to see each session: project, your last prompt, what Claude is doing, task progress and time spent.
- **When a session finishes**, the notch peeks open for a few seconds with Claude's last message.
- **When Claude needs permission** (or asks you a question), the notch pulses orange until you answer.
- **Click a session** to jump straight to its Terminal tab.

## Requirements

- macOS 14 or later, ideally a MacBook with a notch (other screens get a fake notch at the top center)
- Swift 5.10+ (the Xcode Command Line Tools are enough, full Xcode isn't needed)
- Claude Code running in Terminal.app (other terminals still work, but clicking a session only brings Terminal forward)

## Install

```bash
git clone https://github.com/nadialvy/notchy.git
cd notchy
./scripts/install.sh   # builds the app into ~/Applications and the hook into ~/.notchy/bin
./scripts/hooks.sh     # adds the hook to ~/.claude/settings.json (shows a diff first)
```

Sessions started after this show up automatically. The first time you click a session,
macOS asks whether Notchy may control Terminal. Allow it so Notchy can switch tabs.

Use the menu bar icon to turn sounds on or off, enable Launch at Login, or quit.

To uninstall:

```bash
./scripts/hooks.sh --remove
rm -rf ~/Applications/Notchy.app ~/.notchy
```

## How it works

Claude Code [hooks](https://docs.claude.com/en/docs/claude-code/hooks) call `notchy-hook` on session
events. The hook writes a small JSON file per session to `~/.notchy/sessions/` and exits right away,
so it never slows Claude down. Notchy watches that folder and updates the notch.

See [CONTEXT.md](CONTEXT.md) for the vocabulary and [docs/adr](docs/adr) for the design decisions.

## Development

```bash
./scripts/build.sh                                        # build/Notchy.app
build/Notchy.app/Contents/MacOS/Notchy --snapshot /tmp/n  # render each notch state to PNG
```
