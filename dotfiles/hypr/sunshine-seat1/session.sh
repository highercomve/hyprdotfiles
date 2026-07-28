#!/usr/bin/env bash

# ExecStart of sunshine-seat1.service: launches the headless Hyprland instance
# that hosts the isolated Sunshine streaming session on seat1.
#
# The seat1 session owns the AMD iGPU (assigned via udev rule) as its KMS
# device/allocator; it has no physical connectors, so all output goes to a
# virtual HEADLESS display that Sunshine captures. Games can still render on
# the RTX 4070 through its render node (render nodes are not seat-gated).
#
# Logs: journalctl -u sunshine-seat1

export PATH="$HOME/.local/bin:$PATH"

# GDM also spawns a greeter on seat1 (it manages every graphical seat). Make
# sure OUR session is the active one on the seat, otherwise the compositor
# gets paused devices. Allowed passwordless via the polkit rule.
if [ -n "${XDG_SESSION_ID:-}" ]; then
    loginctl activate "$XDG_SESSION_ID" || true
fi

exec Hyprland --config "$HOME/.config/hypr/sunshine-seat1/hyprland.conf"
