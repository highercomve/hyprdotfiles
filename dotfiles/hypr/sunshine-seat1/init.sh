#!/usr/bin/env bash

# Runs inside the seat1 Hyprland session (exec-once): makes sure the virtual
# display exists, then starts the seat1 Sunshine instance.

DIR="$HOME/.config/hypr/sunshine-seat1"
STATE_DIR="$HOME/.config/sunshine-seat1"

log() { logger -t sunshine-seat1 "$*"; }

mkdir -p "$STATE_DIR"

# The logind session is deliberately type "unspecified" (GDM dodge, see
# sunshine-seat1.service) and session.sh keeps XDG_SESSION_TYPE unset for the
# compositor. Apps launched under Sunshine still expect a normal wayland
# session env, and by now libseat's handshake is long done, so this can't
# leak into a logind SetType.
export XDG_SESSION_TYPE=wayland

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

# The Sunshine AppImage bundles libva < 2.24, which cannot bind Mesa's VA
# driver (exports only __vaDriverInit_1_24): vaapi init fails, Sunshine falls
# back to nvenc, and cross-GPU capture (AMD compositor -> NVIDIA encoder)
# yields a black screen. Preload the host libva, which matches the driver.
export LD_PRELOAD="/usr/lib/libva.so.2:/usr/lib/libva-drm.so.2${LD_PRELOAD:+:$LD_PRELOAD}"
# The main Hyprland config exports LIBVA_DRIVER_NAME=nvidia; that breaks vaapi
# on the iGPU if it ever leaks into this session.
unset LIBVA_DRIVER_NAME

# A Proton prefix link left in ntfs-3g's IntxLNK format (drive once mounted
# with ntfs-3g, now pinned to ntfs3 in fstab) makes the game die instantly —
# over a stream that just looks like the launch silently failing. Self-heal
# before Sunshine can launch anything.
python3 "$DIR/fix-steam-links.py" 2>&1 | while IFS= read -r line; do log "fix-links: $line"; done

log "virtual display ready, starting sunshine (XDG_SEAT=$XDG_SEAT)"
exec sunshine "$DIR/sunshine.conf"
