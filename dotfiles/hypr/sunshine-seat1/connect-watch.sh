#!/usr/bin/env bash

# Re-applies the Moonlight client's FPS to HEADLESS-1 on every stream start.
#
# Sunshine has no per-connection hook (only global_prep_cmd, which runs on app
# launch, not on resume), and its capture rate is bounded by the output's
# refresh rate. So a client that connects at 120 fps to an app launched by a
# 90 fps client stays capped at 90.
#
# Sunshine logs "[wlgrab] Requested frame rate [Nfps]" both for the real
# stream and for every encoder probe/re-init, and a mode change itself makes
# Sunshine re-init capture (-> another such line). Reacting to every line
# therefore feeds back into a resize storm that breaks capture ("Couldn't
# import RGB Image"). Only the first such line after "CLIENT CONNECTED" is
# the stream's; act on that one and re-arm on the next connect.
#
# Started by init.sh next to Sunshine; dies with it.

DIR="$HOME/.config/hypr/sunshine-seat1"
LOG="$HOME/.config/sunshine-seat1/sunshine.log"

touch "$LOG"
armed=0
tail -n 0 -F "$LOG" 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *'CLIENT CONNECTED'*) armed=1; continue ;;
    esac
    [ "$armed" = 1 ] || continue
    [[ "$line" =~ \[wlgrab\]\ Requested\ frame\ rate\ \[([0-9]+)fps\] ]] || continue
    armed=0
    SUNSHINE_CLIENT_FPS="${BASH_REMATCH[1]}" "$DIR/resize.sh"
done
