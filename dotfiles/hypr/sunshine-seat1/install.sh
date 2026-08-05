#!/usr/bin/env bash

# One-shot root installer for the isolated Sunshine seat1 streaming session.
# Usage: sudo ~/.config/hypr/sunshine-seat1/install.sh

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo $0" >&2
    exit 1
fi

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing udev rules (Sunshine virtual input + AMD iGPU -> seat1)"
install -m 644 "$DIR/72-sunshine-virtual-seat.rules" /etc/udev/rules.d/
udevadm control --reload-rules
udevadm trigger -s input
# Reassigns the (unused) AMD iGPU DRM device to seat1. The local session only
# holds it as an idle secondary GPU; a brief revocation is harmless.
udevadm trigger -s drm

echo "==> Waiting for logind to reassign the iGPU..."
sleep 2
loginctl seat-status seat1 --no-pager 2>/dev/null || echo "(seat1 appears once a device or session lands on it)"

echo "==> Installing polkit rule (passwordless start/stop for the launcher)"
install -m 644 "$DIR/49-sunshine-seat1.rules" /etc/polkit-1/rules.d/

echo "==> Installing desktop launcher"
install -m 644 -o sergiom -g sergiom "$DIR/sunshine-seat1.desktop" \
    /home/sergiom/.local/share/applications/

echo "==> Installing systemd unit"
install -m 644 "$DIR/sunshine-seat1.service" /etc/systemd/system/
systemctl daemon-reload
# Deliberately NOT enabled: a session already open at boot makes the GDM
# greeter answer the login with "there is already a session running". The
# desktop's conf/autostart.lua starts it after login instead (toggle.sh
# autostart). Start it once here so this install is usable right away.
systemctl disable sunshine-seat1.service 2>/dev/null || true
systemctl start sunshine-seat1.service

echo "==> Waiting for the session to come up..."
sleep 5

echo
echo "==> Sessions (expect a new one on seat1):"
loginctl list-sessions
echo
echo "==> Service status:"
systemctl --no-pager --lines=10 status sunshine-seat1.service || true
echo
echo "Next steps:"
echo "  - Pair Moonlight via the web UI: https://$(hostname):48990"
echo "  - Moonlight host entry: $(hostname):48989"
echo "  - Logs: journalctl -u sunshine-seat1 -f"
