#!/usr/bin/env bash

# Started by session.sh as a sibling of the seat1 Hyprland (with an ambient
# CAP_SYS_NICE that Hyprland's children can't have): waits for the
# compositor, makes sure the virtual display exists, then starts the seat1
# Sunshine instance.

DIR="$HOME/.config/hypr/sunshine-seat1"
STATE_DIR="$HOME/.config/sunshine-seat1"
ENV_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/sunshine-seat1.env"

log() { logger -t sunshine-seat1 "$*"; }

mkdir -p "$STATE_DIR"

# ready.sh (hyprland.start hook) publishes WAYLAND_DISPLAY, DISPLAY and
# HYPRLAND_INSTANCE_SIGNATURE once the compositor is up.
for _ in $(seq 1 300); do
    [ -f "$ENV_FILE" ] && break
    sleep 0.1
done
if [ ! -f "$ENV_FILE" ]; then
    log "compositor env file $ENV_FILE never appeared, giving up"
    exit 1
fi
# shellcheck disable=SC1090
. "$ENV_FILE"
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-Hyprland}"

case "$(grep CapAmb /proc/self/status)" in
    *800000*) log "CAP_SYS_NICE ambient: yes" ;;
    *)        log "CAP_SYS_NICE ambient: NO (encoder context will run at normal priority)" ;;
esac

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
hyprctl eval 'hl.monitor({ output = "HEADLESS-1", mode = "1920x1200@120", position = "0x0", scale = 1 })'
if hyprctl monitors -j | jq -e '.[] | select(.name == "FALLBACK")' >/dev/null; then
    hyprctl eval 'hl.monitor({ output = "FALLBACK", disabled = true })'
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

# Sunshine only resizes the virtual display on app launch (global_prep_cmd);
# this re-applies the client's FPS on every stream start. See connect-watch.sh.
"$DIR/connect-watch.sh" &
WATCH_PID=$!
trap 'kill "$WATCH_PID" 2>/dev/null' EXIT

sunshine "$DIR/sunshine.conf"
