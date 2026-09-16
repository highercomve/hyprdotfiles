#!/usr/bin/env bash

# Runs from hyprland.lua's "hyprland.start" hook, inside the compositor's
# environment. Publishes the session variables init.sh needs (it runs as a
# sibling of Hyprland, not a child — see session.sh) and thereby signals
# that the compositor is ready.

out="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/sunshine-seat1.env"
{
    for v in WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE HYPRLAND_CMD XDG_CURRENT_DESKTOP XDG_BACKEND MOZ_ENABLE_WAYLAND _JAVA_AWT_WM_NONREPARENTING; do
        [ -n "${!v:-}" ] && printf 'export %s=%q\n' "$v" "${!v}"
    done
} > "$out.tmp" && mv -f "$out.tmp" "$out"
