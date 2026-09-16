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

# bin/ goes first: it holds a `systemctl` shim that swallows Hyprland's
# automatic `--user import-environment` / `unset-environment` calls. The
# systemd --user manager is per-USER, not per-seat, so without the shim this
# headless compositor hijacks the seat0 desktop's activation environment and
# xdg-desktop-portal-hyprland gets bound to a session that dies seconds later,
# leaving it spinning at ~150% CPU. See bin/systemctl for the full story.
export PATH="$HOME/.config/hypr/sunshine-seat1/bin:$HOME/.local/bin:$PATH"

# The unit registers the logind session as type "unspecified" so GDM's
# conflicting-session killer ignores it (see sunshine-seat1.service). Do NOT
# re-export XDG_SESSION_TYPE=wayland here: libseat's logind backend calls
# SetType(getenv("XDG_SESSION_TYPE")) right after TakeControl (seatd
# logind.c), which would retype the logind session to "wayland" at runtime
# and put it back on GDM's kill list. init.sh exports it for the app tree
# instead, after the compositor's libseat handshake is done.

# GDM also spawns a greeter on seat1 (it manages every graphical seat). Make
# sure OUR session is the active one on the seat, otherwise the compositor
# gets paused devices. Allowed passwordless via the polkit rule.
if [ -n "${XDG_SESSION_ID:-}" ]; then
    loginctl activate "$XDG_SESSION_ID" || true
fi

# systemd >= 261's pam_systemd grants this session an ambient CAP_WAKE_ALARM.
# Everything spawned here inherits it, and bwrap (Steam/Proton) refuses to run
# with unexpected permitted caps ("Unexpected capabilities but not setuid") ->
# Steam dies with a bogus "requires user namespaces" error and 'steam
# -shutdown' then hangs forever. Drop all ambient caps before the compositor
# starts; the inheritable set stays, which is harmless.
#
# Exception: CAP_SYS_NICE (granted by the unit's AmbientCapabilities=) stays.
# Hyprland uses it for realtime scheduling and Sunshine needs it for a
# high-priority EGL/VAAPI context on amdgpu — otherwise the log warns
# "context priority set to HIGH but CAP_SYS_NICE capability is missing" and
# encoding competes on equal terms with whatever else the iGPU does.
# steam.sh drops it again before launching Steam.
#
# Hyprland lowers its own ambient caps right after start (NInit::
# lowerAmbientCaps), so a Sunshine spawned BY Hyprland would never see the
# cap. Start the Sunshine launcher here as a sibling instead; it waits for
# the env file that hyprland.lua's start hook writes via ready.sh.
DIR="$HOME/.config/hypr/sunshine-seat1"
rm -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/sunshine-seat1.env"
setpriv --ambient-caps=-all,+sys_nice "$DIR/init.sh" &

exec setpriv --ambient-caps=-all,+sys_nice Hyprland --config "$DIR/hyprland.lua"
