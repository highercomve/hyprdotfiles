#!/usr/bin/env bash

# crash-diagnose.sh <pid> [name] [exe] [signal]
# Opens a terminal running claude against a recorded core dump. Clicked from a
# crash-watch notification, or run by hand against any PID in `coredumpctl list`.

set -euo pipefail

pid=${1:?usage: crash-diagnose.sh <pid> [name] [exe] [signal]  (see: coredumpctl list)}
if [[ ! $pid =~ ^[0-9]+$ ]]; then
  echo "Not a PID: $pid" >&2
  exit 1
fi
name=${2:-unknown}
exe=${3:-unknown}
signal=${4:-unknown}

# Looked up live so a hand-run PID still gets a timestamp; tolerate a rotated
# core costing us only that.
when=$(coredumpctl list "$pid" --no-pager --no-legend 2>/dev/null | tail -1 | awk '{print $1" "$2" "$3}') || true
when=${when:-unknown}

prompt=$(cat <<PROMPT
A process crashed on this machine and I want to know why.

What systemd-coredump recorded:
  process:  $name
  PID:      $pid
  binary:   $exe
  signal:   $signal
  time:     $when

Investigate the crash:
1. Start from \`coredumpctl info $pid\` for the metadata and captured stack trace.
2. If the trace is unsymbolized or shallow, get a real backtrace with
   \`coredumpctl debug $pid\` (gdb: \`bt full\`, \`info threads\`). Missing symbols
   can be fetched via debuginfod (DEBUGINFOD_URLS=https://debuginfod.archlinux.org).
3. Check the surrounding journal for context:
   \`journalctl --user -t $name -S -1h\` and \`journalctl _PID=$pid\`.
4. Check the package/version (\`pacman -Qo $exe\`, \`pacman -Qi <pkg>\`) and look
   for known upstream reports matching the trace.

Then report: what crashed, the failing frame(s), the most likely root cause,
whether it looks like a local config problem or an upstream bug, and what I
should do about it. Do not change any system state without asking first.
PROMPT
)

terminal=$(cat "$HOME/.config/hypr/user_settings/terminal.sh" 2>/dev/null || echo alacritty)
command -v "$terminal" >/dev/null || terminal=alacritty

cd "$HOME"
exec setsid "$terminal" --title="Crash Diagnosis: $name" --class=dotfiles-floating -e claude "$prompt"
