#!/usr/bin/env bash

# Runs inside the seat1 Hyprland session (exec-once): makes sure the virtual
# display exists, then starts the seat1 Sunshine instance.

DIR="$HOME/.config/hypr/sunshine-seat1"
STATE_DIR="$HOME/.config/sunshine-seat1"

log() { logger -t sunshine-seat1 "$*"; }

mkdir -p "$STATE_DIR"

# Hyprland's headless backend may start with only the auto-created FALLBACK
# output. Make sure our named virtual display exists and FALLBACK is disabled
# so Sunshine has exactly one output to capture.
if ! hyprctl monitors -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null; then
    hyprctl output create headless HEADLESS-1
    sleep 0.5
fi
hyprctl keyword monitor "HEADLESS-1,1920x1080@60,0x0,1"
if hyprctl monitors -j | jq -e '.[] | select(.name == "FALLBACK")' >/dev/null; then
    hyprctl keyword monitor "FALLBACK,disable"
fi

log "virtual display ready, starting sunshine (XDG_SEAT=$XDG_SEAT)"
exec sunshine "$DIR/sunshine.conf"
