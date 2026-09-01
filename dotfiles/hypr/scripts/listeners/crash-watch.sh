#!/usr/bin/env bash

# crash-watch.sh — announce process crashes and offer an AI diagnosis.
# (Inspired by Omarchy Quattro's crash capture.)
#
# systemd-coredump journals every core dump under a fixed MESSAGE_ID with
# structured COREDUMP_* fields. We tail the journal for those entries and send
# a notification with a "Diagnose with AI" action; clicking it (quickshell's
# NotificationItem invokes actions) opens a terminal running claude with the
# crash facts. Managed by listeners.sh: start/stop with
#   ~/.config/hypr/scripts/listeners.sh start|stop crash-watch

set -uo pipefail

# See systemd.journal-fields(7).
readonly COREDUMP_MESSAGE_ID=fc2e22bc6ee647b6b90729ab34a250b1

DIAGNOSE="$HOME/.config/hypr/scripts/crash-diagnose.sh"

# Crash loops dump core repeatedly; announce each program at most once a window.
readonly dedupe_seconds=${CRASH_DEDUPE_SECONDS:-60}

# Extended regex of process names never worth announcing (e.g. "^(foo|bar)$").
readonly ignore_pattern=${CRASH_IGNORE:-}

declare -A last_notified

announce() {
  local name=$1 pid=$2 exe=$3 signal=$4

  # notify-send -A blocks until the action is clicked or the notification is
  # dismissed, so it runs in the background. quickshell keeps the notification
  # in history after the popup times out, so the button stays clickable there.
  (
    action=$(notify-send \
      --app-name="crash-watch" \
      --urgency=critical \
      -A diagnose="Diagnose with AI" \
      "Process crashed: $name" \
      "${signal} — PID ${pid}" 2>/dev/null)
    [[ $action == diagnose ]] && exec "$DIAGNOSE" "$pid" "$name" "$exe" "$signal"
  ) &
}

# -n 0 so a restart does not re-announce crashes already dealt with.
journalctl -f -n 0 -o json "MESSAGE_ID=$COREDUMP_MESSAGE_ID" 2>/dev/null |
  while IFS= read -r entry; do
    # A dash for empty/missing fields: an empty tab-separated field would
    # collapse under IFS and shift every field after it.
    IFS=$'\t' read -r uid comm pid exe signal < <(
      jq -r 'def field: if . == null or . == "" then "-" else . end;
             [(._UID | field),
              (.COREDUMP_COMM | field),
              (.COREDUMP_PID | field),
              (.COREDUMP_EXE | field),
              (.COREDUMP_SIGNAL_NAME | field)] | @tsv' <<<"$entry" 2>/dev/null
    )

    [[ $pid =~ ^[0-9]+$ ]] || continue

    # Only this user's crashes; a daemon dumping core is a root problem.
    [[ $uid =~ ^[0-9]+$ ]] || continue
    ((uid == UID)) || continue

    # comm is truncated to 15 chars, prefer the executable's basename. A
    # process can set comm to anything, so keep it one path component.
    name=$comm
    [[ $exe == /* ]] && name=${exe##*/}
    name=${name##*/}
    [[ -n $name && $name != "-" && $name != "." && $name != ".." ]] || name=unknown

    [[ -n $ignore_pattern && $name =~ $ignore_pattern ]] && continue

    now=$EPOCHSECONDS
    (((now - ${last_notified[$name]:-0}) < dedupe_seconds)) && continue
    last_notified[$name]=$now

    announce "$name" "$pid" "$exe" "$signal"
  done
