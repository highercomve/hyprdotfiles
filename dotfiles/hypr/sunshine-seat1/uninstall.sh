#!/usr/bin/env bash

# Reverts everything install.sh set up, returning the machine to a normal
# single-seat configuration (AMD iGPU back on seat0, no seat1 session).
# Usage: sudo ~/.config/hypr/sunshine-seat1/uninstall.sh
#
# User-level state is left untouched on purpose:
#   ~/.config/sunshine-seat1/  (Sunshine pairing/state)
#   ~/.local/bin/sunshine      (the Sunshine binary)
#
# The activation-environment PATH shims (bin/systemctl,
# bin/dbus-update-activation-environment) live in this directory and only apply
# to session.sh, so they disappear with the folder itself — nothing to revert.
# Their seat0 counterpart does live outside, and is removed below.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo $0" >&2
    exit 1
fi

DIR="$(cd "$(dirname "$0")" && pwd)"
HYPR_DIR="$(cd "$DIR/.." && pwd)"

echo "==> Stopping and disabling the seat1 session service"
systemctl disable --now sunshine-seat1.service 2>/dev/null || true
rm -f /etc/systemd/system/sunshine-seat1.service
systemctl daemon-reload

echo "==> Removing udev rules (AMD iGPU + virtual input revert to seat0)"
rm -f /etc/udev/rules.d/72-sunshine-virtual-seat.rules
udevadm control --reload-rules
udevadm trigger -s input
udevadm trigger -s drm

echo "==> Removing polkit rule"
rm -f /etc/polkit-1/rules.d/49-sunshine-seat1.rules

echo "==> Removing desktop launcher"
rm -f /home/sergiom/.local/share/applications/sunshine-seat1.desktop

# The seat0 side of the activation-environment fix (README > Activation-
# environment isolation). It only exists because two compositors shared one
# xdg-desktop-portal-hyprland; with seat1 gone there is nothing left to race.
# Harmless if left behind — it no-ops when no foreign instance owns the portal
# — but it belongs to this feature, so take it with us.
echo "==> Removing the seat0 portal-rebind safety net"
for f in "$HYPR_DIR/conf/autostart.lua" "$HYPR_DIR/conf/autostart.conf"; do
    [ -f "$f" ] && grep -q 'portal-rebind\.sh' "$f" || continue
    # We run as root; put the config file back the way we found it.
    owner="$(stat -c '%u:%g' "$f")"
    perl -0777 -pi -e \
        's/^[ \t]*(?:--|#) Safety net for the two-compositor setup.*?portal-rebind\.sh.*?\n[ \t]*\n//ms' "$f"
    chown "$owner" "$f"
    echo "    stripped the exec-once from ${f#"$HYPR_DIR"/}"
done
rm -f "$HYPR_DIR/scripts/portal-rebind.sh"

# Optional extra documented in the README (wired-preferred NM dispatcher).
# Only present if it was installed manually.
if [ -f /etc/NetworkManager/dispatcher.d/99-wired-preferred ]; then
    echo "==> Removing wired-preferred NetworkManager dispatcher"
    rm -f /etc/NetworkManager/dispatcher.d/99-wired-preferred
fi

echo "==> Waiting for logind to reassign devices..."
sleep 2

echo
echo "==> seat1 should now be empty / gone:"
loginctl seat-status seat1 --no-pager 2>/dev/null || echo "(seat1 no longer exists — good)"
echo
echo "Done. GDM stops spawning a seat1 greeter after the next reboot."
