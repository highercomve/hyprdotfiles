#!/usr/bin/env bash

# global_prep_cmd of the seat1 Sunshine: match the virtual display to the
# Moonlight client's requested resolution/FPS before the app launches.
#
# Sunshine only runs prep commands on app *launch*, not on resume, so a later
# client reconnecting with a different FPS would otherwise be capped at the
# stale refresh rate. connect-watch.sh re-runs this on every stream start,
# passing the FPS it saw in the log; W/H then come from the state file this
# script writes (Sunshine never logs the client's resolution).
#
# NOTE: this instance runs a Lua config, and `hyprctl keyword` is a silent
# no-op with the Lua parser ("keyword can't work with non-legacy parsers").
# Use `hyprctl eval` with the hl.monitor() API instead.

STATE="$HOME/.config/sunshine-seat1/display-mode"

if [ -z "${SUNSHINE_CLIENT_WIDTH:-}" ] && [ -f "$STATE" ]; then
    # Called from connect-watch.sh: reuse the last launch's geometry.
    read -r SAVED_W SAVED_H _ < "$STATE"
fi

W="${SUNSHINE_CLIENT_WIDTH:-${SAVED_W:-1920}}"
H="${SUNSHINE_CLIENT_HEIGHT:-${SAVED_H:-1200}}"
FPS="${SUNSHINE_CLIENT_FPS:-120}"

cur=$(hyprctl monitors -j 2>/dev/null \
    | jq -r '.[] | select(.name == "HEADLESS-1") | "\(.width) \(.height) \(.refreshRate | round)"')
if [ "$cur" = "$W $H $FPS" ]; then
    exit 0
fi

hyprctl eval "hl.monitor({ output = \"HEADLESS-1\", mode = \"${W}x${H}@${FPS}\", position = \"0x0\", scale = 1 })"
printf '%s %s %s\n' "$W" "$H" "$FPS" > "$STATE"
logger -t sunshine-seat1 "virtual display set to ${W}x${H}@${FPS}"
