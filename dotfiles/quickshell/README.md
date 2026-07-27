# Quickshell desktop shell

A Quickshell/QML third desktop-shell implementation for this Hyprland dotfiles repo, feature-matching the existing AGS bar. `dotfiles/waybar/` and `dotfiles/ags/` are left untouched.

## Motivation

Lower resource usage and snappier updates than AGS by using Quickshell's native D-Bus/Hyprland/PipeWire/Mpris/UPower/SystemTray/Notification services instead of shelling out or polling.

## Dependencies

- `noctalia-qs` (AUR, already in `pkglist-aur.txt`) — provides the `quickshell` binary on this machine. There is no dependency on Noctalia itself: every module imported here is upstream Quickshell API. Any provider recent enough to include `Quickshell.Networking` (merged upstream January 2026, e.g. `quickshell-git`) works.
- `qt6-multimedia` (already installed) — used for the YouTube Music player.
- `brightnessctl` — brightness control.
- `jq` — used by `launch.sh`.
- `powerprofilesctl` — power-profile cycling in the tools row.
- Python virtual environment with `ytmusicapi` and `yt-dlp` — run `~/.config/quickshell/hyprconfig/setup_venv.sh` after first deploy.

## Deployment layout

`~/.config/quickshell/` is a **multi-config directory** (it may hold other quickshell configs such as `dms` or `noctalia-shell`), so this directory is *not* stowed. Instead, `apply.sh` links it in as a named config:

```
~/.config/quickshell/hyprconfig -> ~/Code/hyprconfig/dotfiles/quickshell
```

`launch.sh` runs quickshell with `qs -d -p <this directory>`, so it works both via the symlink and straight from the repo.

## How to select Quickshell

`statusbar-switcher.sh` (Super+Alt+S) now offers Waybar / AGS / Quickshell, and `launchbar.sh` resolves the quickshell choice to `~/.config/quickshell/hyprconfig/launch.sh`. Manually:

```bash
cd ~/Code/hyprconfig
./apply.sh                                        # stows dotfiles + creates the named-config link
~/.config/quickshell/hyprconfig/setup_venv.sh     # one-time: python venv for the YTM bridge
echo quickshell > ~/.config/hypr/user_settings/statusbar.sh
~/.config/hypr/scripts/launchbar.sh
```

## Note on swaync / notification daemon

`dotfiles/hypr/conf/autostart.conf` runs `exec-once = swaync` unconditionally. `launch.sh` kills swaync before starting Quickshell, because Quickshell owns the `org.freedesktop.Notifications` bus name. This is the same arrangement as AGS. A theoretical login-order race exists if swaync starts *after* `launch.sh` runs; in that case relaunch the bar or restart the session.

## YouTube Music authentication

YouTube Music uses the same bridge as AGS (`ytm_bridge.py`). Auth files live in the config directory (`~/.config/quickshell/hyprconfig/`):

- `browser.json` or `oauth.json` + `credentials.json` from `ytmusicapi`.

If auth is missing, `setup_venv.sh` has already installed the Python dependencies; run the browser/OAuth setup from the same virtual environment.

## Known deviations from AGS

- **MPRIS export of the built-in YTM player**: AGS exports `org.mpris.MediaPlayer2.YouTubeMusic` via GJS D-Bus. Quickshell QML cannot export arbitrary D-Bus objects, so external `playerctl` control of the internal YTM player is lost. In-shell controls (play/pause/next/previous/seek/search/radio) are unchanged, and every other MPRIS player still works.
- **GTK calendar widget**: Replaced by a QML `MonthGrid` + `DayOfWeekRow` calendar styled to match the Catppuccin theme.
- **AGS YouTubeMusicPopup login UI**: That popup references `YouTubeService.startLogin()` which does not exist in `YouTubeService.ts`, and the popup is not wired in `app.ts`. Only the working `YouTubeSearch` widget from `CenterPopup` is ported.
- **YTM end-of-stream auto-advance**: AGS stopped on EOS (`isPlaying = false`). The Quickshell port replicates this; auto-advance is a possible future improvement.

## Runtime test status

- **Static**: All QML files were parsed with `/usr/lib/qt6/bin/qmllint` and `/usr/lib/qt6/bin/qmlformat`. The remaining diagnostics are warnings (unqualified singleton access, property overrides, etc.) and some expected unresolved-type noise due to `pragma Singleton` resolution. No hard syntax errors remain.
- **Python**: `ytm_bridge.py` was byte-compiled and `diff`ed against the AGS copy (identical).
- **Shell**: `launch.sh` and `setup_venv.sh` pass `bash -n`.
- **Runtime**: this agent cannot run a Wayland shell headlessly. The config was not runtime-tested in a live session. First run with `qs -p ~/.config/quickshell/hyprconfig` may reveal binding/service errors that static lint cannot catch. Manual testing should cover: workspace clicks, taskbar focus, clock/center popup, YTM search/play/radio/next, volume OSD, brightness slider, Wi-Fi connect/forget, Bluetooth pair/connect, notification popups + DND + list, tray menus, power menu, tools toggles, battery display, and popup Esc/click-outside-close behavior.

## Known remaining gaps

- **Brightness OSD**: AGS showed a brightness slider OSD when the backlight changed. Quickshell's `Brightness` service watches the sysfs file; the OSD was not implemented because it adds a second `PanelWindow` and the AGS OSD was a transient popup that is better verified at runtime.
- **YTM library playlists**: The `userPlaylists` / `libraryError` properties are loaded but not yet surfaced in the YouTube search UI.
- **Network saved-networks / forget UI**: The network page shows a disconnect icon for saved networks and a password prompt for unknown secured networks; a dedicated "Saved Networks" subview is not implemented yet.
