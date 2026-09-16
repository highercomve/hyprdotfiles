#!/usr/bin/env bash

# ExecStopPost of sunshine-seat1.service.
#
# PAMName=login + pam_systemd move everything session.sh starts into a logind
# session scope (session-N.scope under user.slice), OUT of the unit's own
# cgroup. On stop, systemd therefore only signals the main PID (Hyprland);
# init.sh, Sunshine and connect-watch.sh survive in the old scope. A Sunshine
# that outlives its compositor keeps the ports, and the next start dies with
# "Couldn't bind RTSP server to port [...], Address already in use".
#
# Kill every seat1 logind session of ours that is not the one this hook runs
# in (ExecStopPost gets its own PAM session too). This also mops up sessions
# leaked by earlier crashes. Runs as the service user; killing one's own
# sessions needs no polkit auth.

me=$(id -un)
own="${XDG_SESSION_ID:-}"

stale_sessions() {
    loginctl list-sessions --no-legend 2>/dev/null |
        awk -v u="$me" -v own="$own" '$3 == u && $4 == "seat1" && $1 != own { print $1 }'
}

for sig in TERM KILL; do
    ids=$(stale_sessions)
    [ -z "$ids" ] && exit 0
    for s in $ids; do
        logger -t sunshine-seat1 "stop: killing leftover seat1 session $s (SIG$sig)"
        loginctl kill-session --signal="$sig" "$s" 2>/dev/null || true
    done
    for _ in $(seq 1 10); do
        [ -z "$(stale_sessions)" ] && exit 0
        sleep 0.5
    done
done
exit 0
