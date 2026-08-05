-- Autostart (migrated from conf/autostart.conf).
-- hl.exec_cmd spawns asynchronously; order below preserves the original
-- exec-once order.

hl.on("hyprland.start", function()
    -- Import session env into dbus/systemd FIRST, before anything that talks
    -- to a portal. Without this, xdg-desktop-portal-{hyprland,gtk} are
    -- dbus-activated with no WAYLAND_DISPLAY, crash ("Couldn't connect to a
    -- wayland compositor"), and org.freedesktop.portal.Desktop never starts
    -- -> 120s timeouts that stall waybar, ags, and every GTK app launch
    -- (e.g. ghostty). Must stay the first exec.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")

    -- Safety net for the two-compositor setup (sunshine-seat1):
    -- xdg-desktop-portal-hyprland binds to whichever Hyprland instance owned
    -- the shared activation env when it was dbus-activated, and never
    -- re-attaches. If it is already up against a foreign or dead instance,
    -- rebind it here — that is what spins at ~150% CPU on a hung-up wayland
    -- socket. No-op in the normal case.
    hl.exec_cmd("~/.config/hypr/scripts/portal-rebind.sh")

    -- Isolated seat1 streaming session (Sunshine). Started here rather than
    -- enabled at boot: a logind session that is already open when the GDM
    -- greeter runs makes it answer the login with "there is already a session
    -- running". No-op if the unit isn't installed or the session is parked
    -- via user_settings/sunshine-seat1-disabled.
    hl.exec_cmd("~/.config/hypr/sunshine-seat1/toggle.sh autostart")

    -- Start listeners
    hl.exec_cmd("~/.config/hypr/scripts/listeners.sh --startall")

    -- Status bar (waybar/ags/quickshell per user_settings/statusbar.sh)
    hl.exec_cmd("~/.config/hypr/scripts/launchbar.sh")

    -- Sway Notification Center
    hl.exec_cmd("swaync")

    -- Idle management daemon for screen locking and power saving
    hl.exec_cmd("hypridle")

    -- Wallpaper daemon
    hl.exec_cmd("hyprpaper")

    -- Screen sharing/recording portal is launched automatically via dbus
    -- activation now that the env is imported above — starting it here too
    -- caused a double-launch race + segfault.
    -- hl.exec_cmd("xdg-desktop-portal-hyprland")

    -- Polkit authentication agent
    hl.exec_cmd("hyprpolkitagent")

    -- Clipboard history (text + images)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Another Polkit agent, often used for compatibility with GNOME apps
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Restore the last set wallpaper
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper-restore.sh")

    -- Apply GTK settings and themes
    hl.exec_cmd("~/.config/hypr/scripts/gtk.sh")

    -- User-defined autostarts / cleanup
    hl.exec_cmd("~/.config/hypr/scripts/autostart.sh")
    hl.exec_cmd("~/.config/hypr/scripts/cleanup.sh")

    -- Tray applets
    hl.exec_cmd("~/.config/hypr/scripts/nm-applet.sh")
    hl.exec_cmd("~/.config/hypr/scripts/blueman-applet.sh")

    -- GhostPen — AI text editing overlay daemon (trigger with Ctrl+Shift+A)
    -- GHOSTPEN_STT_SERVER=1 exposes its whisper model as an OpenAI-compatible
    -- STT endpoint on 0.0.0.0:8771, so Hermes (in its container) transcribes
    -- voice notes through GhostPen's GPU whisper. Model = Settings → Captions;
    -- override with GHOSTPEN_STT_MODEL / GHOSTPEN_STT_BIND.
    hl.exec_cmd("env GHOSTPEN_STT_SERVER=1 ~/.local/bin/ghostpen")
end)
