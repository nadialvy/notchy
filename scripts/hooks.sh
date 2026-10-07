#!/bin/bash
# Adds (or with --remove, removes) the Notchy hook in ~/.claude/settings.json.
# Shows a diff and asks before saving; pass --yes to skip the question.
# Existing hooks are left untouched and a backup is written next to the file.
set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
COMMAND='$HOME/.notchy/bin/notchy-hook'
EVENTS='["SessionStart","SessionEnd","UserPromptSubmit","PreToolUse","PostToolUse","PermissionRequest","Notification","Stop"]'
TOOL_EVENTS='["PreToolUse","PostToolUse","PermissionRequest"]'

remove=false
yes=false
for arg in "$@"; do
  case "$arg" in
    --remove) remove=true ;;
    --yes) yes=true ;;
    *) echo "usage: $0 [--remove] [--yes]" >&2; exit 1 ;;
  esac
done

mkdir -p "$(dirname "$SETTINGS")"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

ADD='
  reduce $events[] as $e (.;
    .hooks[$e] = ((.hooks[$e] // [])
      | if any(.[]?.hooks[]?; .command == $cmd) then .
        else . + [
          (if ($tools | index($e)) then {matcher: "*"} else {} end)
          + {hooks: [{type: "command", command: $cmd, timeout: 5}]}
        ] end))'

REMOVE='
  .hooks |= (with_entries(
    .value |= map(.hooks |= map(select(.command != $cmd)) | select(.hooks | length > 0))
  ) | with_entries(select(.value | length > 0)))'

filter=$ADD
$remove && filter=$REMOVE

next=$(mktemp)
jq --indent 2 --arg cmd "$COMMAND" --argjson events "$EVENTS" --argjson tools "$TOOL_EVENTS" "$filter" "$SETTINGS" > "$next"

if diff -q "$SETTINGS" "$next" >/dev/null; then
  echo "Nothing to change."
  rm "$next"
  exit 0
fi

diff -u "$SETTINGS" "$next" || true

if ! $yes; then
  read -r -p "Save these changes to $SETTINGS? [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] || { echo "Cancelled."; rm "$next"; exit 0; }
fi

cp "$SETTINGS" "$SETTINGS.notchy-backup"
mv "$next" "$SETTINGS"
echo "Saved. Backup at $SETTINGS.notchy-backup"
