# Plan: Quickshell desktop-shell implementation (`dotfiles/quickshell/`)

*Reviewed and approved by architect agent on 2026-07-27 — corrections merged. This is the authoritative implementation plan; it supersedes plan.md where they differ.*

## Overview

Create a third desktop-shell implementation for this Hyprland dotfiles repo using Quickshell (QML), as a feature-for-feature migration of `dotfiles/ags/`. `dotfiles/waybar/` and `dotfiles/ags/` are left untouched. The motivation is lower resource usage and snappier behavior, so the implementation must lean on Quickshell's built-in native services instead of shelling out or polling wherever possible.

### Verified environment facts (checked on this machine; re-verified by architect)

- `qs` / `quickshell` binaries exist at `/usr/bin/qs`, owned by AUR package **`noctalia-qs` 0.0.12-1.4**, which `Provides: quickshell` and `Conflicts: quickshell`. Neither `quickshell` nor `noctalia-qs` is in `pkglist-aur.txt`.
- `install_dependencies.sh` installs the AUR list via `yay -S --noconfirm --needed - <pkglist-aur.txt` — so whatever name we add must install cleanly on this machine (see ADR-A1).
- Installed QML modules under `/usr/lib/qt6/qml/Quickshell/`:
  - `Quickshell.Hyprland` — singleton with `workspaces`, `toplevels` (HyprlandToplevel: `title`, `workspace`, `activated`, `urgent`), `monitors`, `focusedWorkspace`, `focusedMonitor`, `dispatch()`. Also provides **`HyprlandFocusGrab`** (confirmed in `_FocusGrab/` qmltypes) — used for popup click-outside-close.
  - `Quickshell.Services.Pipewire`, `Quickshell.Services.Mpris`, `Quickshell.Services.SystemTray`, `Quickshell.Services.Notifications` (full NotificationServer), `Quickshell.Services.UPower`, `Quickshell.DBusMenu`.
  - `Quickshell.Bluetooth` — adapters/devices with `pair`, `connect`, `forget`, `battery`, `discovering`.
  - `Quickshell.Networking` — NM-backed WiFi with `networks` (AccessPoint: `known`, `signalStrength`, `security`, `connect`, `forget`, `connectWithPsk`), `wifiEnabled`, `scannerEnabled`, `devices`. **Confirmed present in the installed noctalia-qs build** (`/usr/lib/qt6/qml/Quickshell/Networking/` with qmltypes). Likely a noctalia fork addition — vanilla `quickshell` may lack it, which is why network access goes through a facade (ADR-A2).
  - `Quickshell.Io` — `Process`, `FileView` (with change watching), `Socket`, stream parsers.
  - `Quickshell.Widgets` — `IconImage`, `ClippingRectangle`, wrapper types.
- `qt6-multimedia` 6.11.1 is installed with QML plugin (`/usr/lib/qt6/qml/QtMultimedia`) → usable for YTM audio playback. `mpv` is NOT installed.
- `qmllint` and `qmlformat` are available at `/usr/bin`. `qs` has **no** `--check` subcommand in this build; confirmed subcommands: `log`, `list`, `kill`, `ipc`; confirmed flags: `-d` (daemonize), `-n`/`--no-duplicate` (default on), `-p` (path), `-c` (named config).
- Statusbar selection mechanism (verified against actual scripts): `~/.config/hypr/user_settings/statusbar.sh` contains the bar name (currently `ags`); `dotfiles/hypr/scripts/launchbar.sh` defaults to `waybar`, greps the settings file for `ags`, then runs `$HOME/.config/$STATUS_BAR_TYPE/launch.sh`. `dotfiles/hypr/scripts/statusbar-switcher.sh` is the rofi switcher (kills ags/waybar/swaync, writes the settings file). Both need small additions to know about quickshell — we do NOT edit them; the README documents the diffs. (Note: the string `quickshell` does not contain `ags`, so an `elif grep -q "quickshell"` branch is safe with the existing first check.)
- `dotfiles/hypr/conf/autostart.conf:15` has `exec-once = swaync` — swaync is the notification daemon for the waybar setup and is autostarted unconditionally. The AGS launch.sh kills it; ours must too (see R3).
- Dotfiles are deployed via GNU Stow (`apply.sh`) → `dotfiles/quickshell/` becomes `~/.config/quickshell/`, which is exactly quickshell's default config path (`qs` with no args runs `~/.config/quickshell/shell.qml`).
- Bridge protocol re-verified against `dotfiles/ags/ytm_bridge.py` and `YouTubeService.ts`: one-shot argv-JSON in, single JSON line on stdout; request-id guards (`searchRequestId`, `radioRequestId`, `playRequestId`) exist in the AGS service; `.venv/bin/python` and `.venv/bin/yt-dlp` paths relative to the config dir.
- `PopupWindow.tsx` defaults to `Astal.Keymode.EXCLUSIVE` (not on-demand) and `Astal.Layer.OVERLAY` — keyboard parity target for QML popups (ADR-A3).

## Goals and scope

**In scope**
- New `dotfiles/quickshell/` implementing every feature of the AGS shell: top bar (Workspaces, Taskbar, ClientTitle, Clock+MediaBar center group, SystemMonitor, ToolsRow, Battery, SysTray, QuickSettings, PowerMenu), ControlPanel popup (main/network/bluetooth/audio pages, brightness slider, DND + notification list), CenterPopup (calendar + YouTube search | media player), notification popups, volume OSD, power menu button.
- Same visual style: Catppuccin Mocha palette, spacing, radii, pill shapes from `style.scss`, ported to a QML `Theme` singleton.
- Working YouTube Music integration reusing `ytm_bridge.py` verbatim protocol (one-shot: `python ytm_bridge.py '<json>'` → single JSON line on stdout).
- `launch.sh` mirroring AGS lifecycle, `README.md` documenting Hyprland config changes, `pkglist-aur.txt` addition.

**Out of scope / explicit deviations (documented in README)**
- MPRIS *export* of the built-in YTM player (AGS registers `org.mpris.MediaPlayer2.YouTubeMusic` via GJS DBus export — confirmed in YouTubeService.ts). Quickshell QML cannot export arbitrary D-Bus objects. All in-shell controls work identically; only external `playerctl` control of the YTM player is lost. Every other MPRIS player is still controlled via `Quickshell.Services.Mpris`.
- The unused/vestigial AGS bits are not ported: `YouTubeMusicPopup.tsx` login flow references `YouTubeService.startLogin()` which does not exist in `YouTubeService.ts`, and `YouTubeMusicPopup` is not wired in `app.ts` (verified: app.ts wires Bar, OSD, NotificationPopups, ControlPanel, CenterPopup only). Port `YouTubeSearch` only; skip the dead popup. (Confirm with user if login UI is wanted later.)
- GTK `Gtk.Calendar` is replaced by a QML calendar built from `QtQuick.Controls` `MonthGrid` + `DayOfWeekRow` (Qt6 has no drop-in calendar widget), styled to match.

## Architecture decisions

### 1. Directory / module layout (idiomatic Quickshell)

```
dotfiles/quickshell/
├── shell.qml                     # ShellRoot: Variants-per-screen Bar, OSD, NotificationPopups; ControlPanel; CenterPopup
├── launch.sh                     # process lifecycle (mirrors ags/launch.sh)
├── README.md                     # selection instructions + deviations + runtime-test status
├── ytm_bridge.py                 # copied as-is from dotfiles/ags/ytm_bridge.py
├── setup_venv.sh                 # copied from ags (creates .venv with ytmusicapi + yt-dlp)
├── .gitignore                    # .venv/, __pycache__/, oauth.json, browser.json, credentials.json, bridge.log
├── Theme/
│   ├── qmldir                    # singleton Theme
│   └── Theme.qml                 # colors, fonts, radii, spacing from style.scss
├── Services/                     # all `pragma Singleton` + qmldir
│   ├── qmldir
│   ├── Panels.qml                # popup visibility + control-panel nav page (replaces App.toggle_window + ControlPanelNav)
│   ├── Network.qml               # facade over Quickshell.Networking (sole importer of that module — see ADR-A2)
│   ├── Brightness.qml            # brightnessctl set + FileView sysfs watch (replaces BrightnessService.ts)
│   ├── SystemStats.qml           # cpu/mem/temp via FileView + 2s Timer (replaces SystemMonitor state)
│   ├── Tools.qml                 # hypridle/hyprsunset/record/monitor-suspend status polling (replaces ToolsState)
│   ├── NotificationStore.qml     # NotificationServer wrapper, popup timers, DND flag, list retention
│   └── Ytm.qml                   # bridge calls, yt-dlp URL extraction, MediaPlayer playback, queue/radio
├── Bar/
│   ├── Bar.qml                   # PanelWindow, exclusive, top-anchored; 3-section layout
│   ├── Workspaces.qml
│   ├── Taskbar.qml
│   ├── ClientTitle.qml
│   ├── ClockWidget.qml
│   ├── MediaBar.qml              # yt / mpris / empty switcher
│   ├── SystemMonitor.qml
│   ├── ToolsRow.qml
│   ├── BatteryLevel.qml
│   ├── SysTray.qml
│   ├── QuickSettings.qml
│   └── PowerMenu.qml
├── Panels/
│   ├── PopupWindow.qml           # reusable: content-sized overlay window + HyprlandFocusGrab (see ADR-A3)
│   ├── ControlPanel.qml          # StackView/StackLayout of the 4 pages
│   ├── MainPage.qml              # ConnectivityToggles, BrightnessSlider, AudioWidget, NotificationSection
│   ├── NetworkPage.qml           # NetworkWidget + saved networks subview (talks to Services/Network.qml only)
│   ├── BluetoothPage.qml
│   ├── AudioPage.qml             # DeviceList output/input
│   ├── TogglePill.qml
│   ├── AudioEndpoint.qml         # volume row + expandable device list
│   ├── DeviceList.qml
│   ├── NotificationList.qml
│   ├── NotificationItem.qml      # shared by list + popups
│   ├── DndSwitch.qml
│   ├── CenterPopup.qml           # calendar+search | separator | media player
│   ├── CalendarView.qml          # MonthGrid-based
│   ├── MediaPlayer.qml           # mpris big player + YTM big player stack
│   └── YouTubeSearch.qml
├── Osd/
│   └── VolumeOsd.qml
└── NotificationPopups/
    └── NotificationPopups.qml
```

Root `shell.qml` uses `Variants { model: Quickshell.screens }` for per-monitor Bar, OSD and NotificationPopups (AGS maps `app.get_monitors()` the same way). ControlPanel and CenterPopup are single windows.

### 2. AGS → Quickshell service mapping

| AGS (Astal) | Quickshell replacement | Notes |
|---|---|---|
| AstalHyprland workspaces/clients/focused | `Quickshell.Hyprland` singleton (`workspaces`, `toplevels`, `focusedWorkspace`, `activeToplevel`) | Native IPC, no polling. Workspace focus via `Hyprland.dispatch("workspace N")`; client focus via `dispatch("focuswindow address:0x…")` |
| AstalWp (audio) | `Quickshell.Services.Pipewire` (`Pipewire.defaultAudioSink/Source`, `PwObjectTracker`, `node.audio.volume/muted`) | Volume icon computed in QML helper |
| AstalMpris | `Quickshell.Services.Mpris` (`Mpris.players`) | Position via 1s Timer, same as AGS ticker |
| AstalTray | `Quickshell.Services.SystemTray` + `QsMenuAnchor`/`QsMenuOpener` (DBusMenu) | |
| AstalNotifd (daemon) | `Quickshell.Services.Notifications.NotificationServer` | Quickshell becomes the notification daemon; swaync must stay killed (launch.sh; autostart.conf autostarts it — see R3). DND is a local flag in `NotificationStore` |
| AstalBattery | `Quickshell.Services.UPower` (`UPower.displayDevice`) | Hide widget when battery not present, like AGS |
| AstalNetwork + NM | `Services/Network.qml` facade → `Quickshell.Networking` backend | Widgets never import `Quickshell.Networking` directly (ADR-A2). Ethernet toggle: keep `nmcli device connect/disconnect` via `Process` exactly as AGS does |
| AstalBluetooth | `Quickshell.Bluetooth` | `forget` replaces delete; per-device battery available |
| AstalPowerProfiles | UPower power-profile API if present, else `powerprofilesctl` via `Process` | Verify at implementation |
| GJS Gio subprocess/polls | `Quickshell.Io.Process` | Tools row scripts, brightnessctl, wlogout.sh, system-monitor.sh, cliphist.sh |
| GJS file reads (/proc, hwmon, sysfs) | `Quickshell.Io.FileView` (with `watchChanges` for backlight) | Less overhead than spawning |
| Gst playbin (YTM) | `QtMultimedia` `MediaPlayer` + `AudioOutput` | qt6-multimedia already installed |
| GObject state singletons | `pragma Singleton` QML objects | |
| scss classes | `Theme` singleton properties consumed by components | |

### 3. Theme port (`style.scss` → `Theme.qml`)

Export as readonly properties: the full Catppuccin Mocha palette (`base #1e1e2e`, `mantle #181825`, `surface0 #313244`, `surface1 #45475a`, `surface2 #585b70`, `overlay0 #6c7086`, `text #cdd6f4`, `subtext0 #a6adc8`, `subtext1 #bac2de`, `blue #89b4fa`, `mauve #cba6f7`, `red #f38ba8`, `green #a6e3a1`, `yellow #f9e2af`, `peach #fab387`, `sapphire #74c7ec`, `sky #89dceb`, `lavender #b4befe`, etc.), `barBackground rgba(30,30,46,0.3)`, `borderColor rgba(186,194,222,0.2)`, font family `"JetBrains Mono"`, and shared metrics: module radius 10, panel radius 16, pill radius 20, OSD radius 99 (pill), module margins 4–5px, paddings as in scss. Per-widget accent colors (cpu=sapphire, memory=mauve, temp=peach, clock=blue, powermenu=red, tools-toggle=sapphire, workspace-active=mauve on base, etc.) become properties or are referenced inline from the palette.

### 4. Popup windows

`PopupWindow.qml`: a `PanelWindow` sized/positioned to its content via alignment + margin properties matching AGS (`control-panel`: right-aligned, top margin 40, right margin 5, 400×~800; `center-popup`: h-centered, top margin 40, width 800), `WlrLayershell.layer: Layer.Overlay`, `exclusionMode: ExclusionMode.Ignore`, `color: "transparent"` with the styled content `Rectangle` inside.

- **Click-outside close**: `HyprlandFocusGrab { windows: [popupWindow]; active: <open flag>; onCleared: close() }` — the idiomatic Quickshell mechanism (confirmed available in the installed build). This avoids a full-screen transparent input surface per popup (cheaper, and no risk of swallowing clicks meant for other layers). Fallback if the grab misbehaves with nested windows: the AGS-style full-surface overlay window with a MouseArea (keep the option one abstraction away inside PopupWindow.qml).
- **Keyboard**: `WlrKeyboardFocus.Exclusive` while visible, `WlrKeyboardFocus.None` when hidden — matching AGS `Keymode.EXCLUSIVE` (verified in PopupWindow.tsx). This guarantees `Keys.onEscapePressed` fires and YouTubeSearch text entry works without an extra click. Do NOT use OnDemand.
- Windows stay logically toggled via `visible: Panels.controlPanelOpen` etc. — same as AGS toggle_window semantics. Use `LazyLoader` with visibility-bound activation for ControlPanel/CenterPopup as a free perf win.

### 5. YouTube Music (`Services/Ytm.qml`)

Keep the bridge protocol byte-for-byte (verified against `ytm_bridge.py` + `YouTubeService.ts`):
- Request: `.venv/bin/python ~/.config/quickshell/ytm_bridge.py '{"type":"search","query":{"query":"…","filter":"songs"}}'` (also `check_auth`, `radio` with `query=<videoId>`, `library_playlists`, `playlist`).
- Response: single JSON line on stdout: `{"type":…, "data":…}` or `{"error":…}`; `library_playlists` may carry both `data` and `error`.
- Implementation: `Process` per request kind with `StdioCollector`, request-id guards replicating AGS's stale-response protection (`searchRequestId`, `radioRequestId`, `playRequestId`).
- Pass the JSON as a single argv element (Process `command` list) — no shell quoting layer, so titles with quotes cannot break the invocation.

Playback: `extractAudioUrl` via `Process` running `.venv/bin/yt-dlp -f bestaudio -g https://youtube.com/watch?v=<id>`; feed URL to `MediaPlayer`. Port queue semantics exactly: `play()` resets queue unless invoked from `playCurrent`; `next/previous` (previous seeks to 0 if position > 5s); radio fills queue from `radio` response (filter tracks with `videoId`, map title/artist/last-thumbnail). AGS did *not* auto-advance on EOS (EOS just set isPlaying=false); replicate for parity, note as candidate improvement in README.

State exposed: `currentTitle`, `currentArtist`, `currentCover`, `isPlaying`, `position`, `duration`, `isLoggedIn`, `searchResults`, `isSearching`, `searchQuery`, `searchFilter`, `userPlaylists`, `libraryError`. `check_auth` on startup, then `library_playlists` (single-flight guard).

### 6. Notifications

`NotificationStore.qml` owns a `NotificationServer` (actions, body markup, image, persistence enabled). Behavior parity with AGS PopupManager:
- New notification → if `!dnd`, add to popup list with 5s timer; suppress Bluetooth "100%" battery notifications (same filter).
- Popup timeout/dismiss hides the popup (300ms slide animation) but keeps the notification in the tracked list for the control-panel `NotificationList` until user dismissal, matching notifd.
- `dnd` toggle + "clear all" button.
- App icon resolution: `Quickshell.iconPath()` + `DesktopEntries.heuristicLookup(appName)` once per notification (mirrors the AGS Apps fuzzy-query cache); prefer `n.image`, then app icon, then `appIcon`, then fallback `dialog-information-symbolic`.
- Call `notification.tracked = true` (or the equivalent retention API) so notifications outlive the server callback, per Quickshell notification semantics.

### 7. Bar details worth calling out

- **Workspaces**: sorted by id, active = focusedWorkspace, click activates.
- **Taskbar**: `Hyprland.toplevels` sorted by `workspace.id`; icon from client class via `DesktopEntries.heuristicLookup` + `Quickshell.iconPath` with the `dev.zed.Zed → zed` substitution map; click focuses; tooltip = title.
- **ClientTitle**: `Hyprland.activeToplevel.title`, elided.
- **Clock**: `SystemClock` (no Timer) formatted `hh:mm AP - dd MMM`; button toggles CenterPopup.
- **MediaBar**: 3-state stack (youtube / active-mpris / empty); active = first playing player; scrolling ticker for >25 chars driven by 1s Timer only while playing, with `(pos/len)` suffix.
- **SystemMonitor**: labels `  N%`, ` N.NG`, ` N°C` with the same hwmon discovery order (coretemp/k10temp/zenpower on temp1/temp3, fallback); click launches `~/.config/hypr/user_settings/system-monitor.sh`.
- **ToolsRow**: 300ms slide reveal, buttons calling `~/.config/hypr/scripts/{cliphist,hypridle,hyprsunset,record,monitor-suspend}.sh toggle`, 2s status polling parsing waybar-style JSON (`class|alt|text`), active-state colors per scss; power-profile cycle button.
- **QuickSettings**: DND icon + volume icon, toggles ControlPanel.
- **PowerMenu**: runs `bash -c '~/.config/hypr/scripts/wlogout.sh'`.
- **Bar window**: `PanelWindow` top/left/right anchored, exclusive zone auto, translucent `Theme.barBackground`.

## Architecture Decision Records (architect additions)

### ADR-A1: Package `noctalia-qs` in pkglist-aur.txt, not `quickshell`
- **Status**: Accepted
- **Context**: Task requirement 5 says "add quickshell to pkglist-aur.txt if not present". But the machine's installed provider is `noctalia-qs`, which `Provides: quickshell` and `Conflicts: quickshell`. `install_dependencies.sh` runs `yay -S --noconfirm --needed - <pkglist-aur.txt`; listing `quickshell` would conflict with the installed package and break the non-interactive install. Additionally, the implementation is developed against this build's qmltypes, including `Quickshell.Networking`, which may not exist in vanilla quickshell.
- **Decision**: Add `noctalia-qs` to `pkglist-aur.txt` (alphabetically after `nautilus-sendto-debug`). README documents that any `quickshell` provider ≥ this API surface works, and that vanilla `quickshell` requires the nmcli network fallback (ADR-A2) and is otherwise untested.
- **Consequences**: Requirement 5 is satisfied in spirit (the quickshell provider is pinned); reproducing the machine via `install_dependencies.sh` keeps working; no conflict at install time.

### ADR-A2: Network facade singleton from day one
- **Status**: Accepted
- **Context**: `Quickshell.Networking` is confirmed in the installed noctalia-qs build but is probably a fork addition; vanilla upstream may lack it. The plan originally treated an nmcli-backed fallback as a contingency.
- **Decision**: `Services/Network.qml` is the **only** file that imports `Quickshell.Networking`. It exposes a widget-facing API (wifiEnabled, scanning, accessPoints list with ssid/strength/security/known/active, connect/forget/connectPsk, wired state + toggle). NetworkPage/MainPage consume only the facade.
- **Consequences**: Swapping to an nmcli/`Process` backend (or a future upstream Networking module) touches exactly one file. Slight indirection cost, justified by the portability risk. Do NOT generalize this pattern to Bluetooth/Pipewire/etc. — those modules are upstream-stable; facades there would be over-engineering.

### ADR-A3: Popup input model — HyprlandFocusGrab + Exclusive keyboard
- **Status**: Accepted
- **Context**: AGS PopupWindow uses a full-surface overlay window with `Keymode.EXCLUSIVE`. The original plan proposed a full-surface QML window with `OnDemand` keyboard focus. OnDemand would not deliver Esc/typing until the user clicks inside; a full-screen transparent input surface is also the more expensive pattern in Quickshell.
- **Decision**: Content-sized popup windows + `HyprlandFocusGrab` for click-outside close; `WlrKeyboardFocus.Exclusive` while visible, `None` when hidden.
- **Consequences**: Matches AGS behavior (Esc closes, search box types immediately), lower surface cost. Fallback path (full-surface overlay) kept inside PopupWindow.qml if the grab proves unreliable.

## Implementation steps

Ordered; each step leaves the config loadable (`qmllint`-clean) so validation can run incrementally.

1. **Scaffold + theme.** Create `dotfiles/quickshell/` with `shell.qml` (empty ShellRoot), `Theme/Theme.qml` + `qmldir`, `Services/Panels.qml` + `qmldir`, `.gitignore`. Port every color/metric from `dotfiles/ags/style.scss`.
2. **Bar skeleton + simple widgets.** `Bar/Bar.qml` (3-region layout), `Workspaces.qml`, `Taskbar.qml`, `ClientTitle.qml`, `ClockWidget.qml`, `PowerMenu.qml`. Wire into `shell.qml` via `Variants`. *Depends on 1.*
3. **System widgets.** `Services/SystemStats.qml` + `Bar/SystemMonitor.qml`; `Services/Tools.qml` + `Bar/ToolsRow.qml`; `Bar/BatteryLevel.qml` (UPower); `Bar/SysTray.qml` (SystemTray + QsMenuAnchor); `Bar/QuickSettings.qml` (stub DND until step 6). *Depends on 2.*
4. **Popup framework + ControlPanel.** `Panels/PopupWindow.qml` (per ADR-A3), `TogglePill.qml`, `ControlPanel.qml` with page nav in `Services/Panels.qml`; `MainPage.qml` with ConnectivityToggles, BrightnessSlider (`Services/Brightness.qml`: brightnessctl probe, sysfs FileView watch, set via `brightnessctl set N% -q`), `AudioEndpoint.qml`, `DeviceList.qml`, `AudioPage.qml`. *Depends on 1–3.*
5. **Network + Bluetooth pages.** `Services/Network.qml` facade first (ADR-A2), then `NetworkPage.qml`: wired section (nmcli connect/disconnect switch), WiFi switch, scan, deduped-by-SSID AP list sorted by strength (~3s re-sort throttle like AGS), connect on click, forget with confirm/cancel flow, saved-networks subview. `BluetoothPage.qml`: power switch, 15s-capped discovery, connected-first device list, pair+connect / disconnect, battery % + icon. *Depends on 4.*
6. **Notifications.** `Services/NotificationStore.qml`, `Panels/NotificationItem.qml` (expand-on-click body, time label, action buttons, close, slide animations), `NotificationPopups/NotificationPopups.qml` (top-right, per-monitor, width 400), `NotificationList.qml` + `DndSwitch.qml` in MainPage; finalize QuickSettings DND icon. *Depends on 4.*
7. **Media: MPRIS + OSD.** `Panels/MediaPlayer.qml` (cover art, title/artist/album, seek slider with 1s position timer, prev/play-pause/next incl. 56px round play button), `Bar/MediaBar.qml` stack + ticker, `Osd/VolumeOsd.qml` (Pipewire default-sink watcher, 2s auto-hide, bottom-centered pill). *Depends on 2, 4.*
8. **YouTube Music.** Copy `ytm_bridge.py` and `setup_venv.sh` unchanged. `Services/Ytm.qml` (bridge Processes with request-id guards, yt-dlp extraction, MediaPlayer+AudioOutput, queue/radio/transport/seek, auth check + library load). `Panels/YouTubeSearch.qml` (search entry, 4 filter chips, thumbnail results, play-or-drill-down, radio button on songs). Integrate YT branch into MediaBar and MediaPlayer stacks. *Depends on 7.*
9. **CenterPopup.** `CalendarView.qml` (MonthGrid + DayOfWeekRow, styled per scss), `CenterPopup.qml` (calendar+YouTubeSearch | separator | MediaPlayer, 800 wide, top-centered). *Depends on 7, 8.*
10. **Lifecycle + docs + packaging.**
    - `launch.sh` (executable), mirroring `ags/launch.sh`: kill running instances (`qs kill` — confirmed subcommand — then `pkill -x qs`, `pkill statusbar`, `pkill gjs`, `pkill swaync`), then `HYPRLAND_INSTANCE_SIGNATURE=$(hyprctl instances -j | jq -r '.[0].instance') qs -d` (`-d` confirmed).
    - `README.md`: dependencies (`noctalia-qs` via AUR per ADR-A1 — any `quickshell` provider with the same module surface works; `qt6-multimedia`, `brightnessctl`, `jq`, venv via `setup_venv.sh`); selection without editing repo hypr config: `echo quickshell > ~/.config/hypr/user_settings/statusbar.sh` plus the exact 3-line diff for `launchbar.sh` (`elif grep -q "quickshell" …`) and the optional `statusbar-switcher.sh` third option; note that `autostart.conf` autostarts swaync and launch.sh kills it (same as AGS), including the theoretical login-order race (R3); YTM auth (browser.json/oauth.json); documented deviations (MPRIS export, YTM login popup, calendar widget, EOS auto-advance); runtime-test status.
    - Add `noctalia-qs` to `pkglist-aur.txt` (alphabetical, after `nautilus-sendto-debug`). Do NOT add `quickshell` (Conflicts — ADR-A1).
11. **Validation pass** (see below); fix all qmllint errors, document false-positive warnings.

## Risk assessment

- **R1 — `Quickshell.Networking` portability.** Confirmed present in the installed noctalia-qs build; likely absent in vanilla `quickshell`. Mitigation is structural now (ADR-A2 facade) + packaging pins the working provider (ADR-A1). Residual risk is only for users who install vanilla quickshell — documented in README.
- **R2 — noctalia-qs 0.0.12 vs upstream API drift.** Develop against the installed qmltypes; qmllint against `/usr/lib/qt6/qml`.
- **R3 — Notification daemon ownership.** NotificationServer must own `org.freedesktop.Notifications`. `autostart.conf` autostarts swaync unconditionally; launch.sh kills it before starting qs — identical to the AGS arrangement, so parity holds. Residual race: if swaync starts *after* launch.sh's pkill during login, it wins the bus name until the bar is relaunched. Same race exists today with AGS; document in README rather than modifying hypr config (out of scope by requirement).
- **R4 — YTM playback format.** `yt-dlp -g` returns googlevideo URLs (often webm/opus); Qt6 FFmpeg backend should handle them, else constrain to `-f "bestaudio[ext=m4a]/bestaudio"`. Runtime test required.
- **R5 — Tray menus.** DBusMenu rendering is the flakiest area; may need `QsMenuOpener` custom rendering for nested menus. Budget extra time.
- **R6 — Hyprland client focus/icon mapping.** Focusing may need `dispatch("focuswindow address:…")`; icon lookup by appId can miss — same substitution-map escape hatch as AGS.
- **R7 — Popup input behavior.** Addressed by ADR-A3 (HyprlandFocusGrab + Exclusive keyboard while visible, None when hidden). Verify the grab releases cleanly on close so bar clicks work immediately after.
- **R8 — Stow deployment.** `~/.config/quickshell` symlinks into the repo, so `.venv/` and auth files land in the repo tree — `.gitignore` must cover them (same situation as AGS: verify against `dotfiles/ags/.gitignore`, which currently misses oauth.json/credentials.json/bridge.log — ours must include them).
- **R9 — Two shells fighting.** launch.sh kills `statusbar`/`gjs`/`swaync` mirroring the AGS script's cleanup so switching is clean; `qs -n` (default) prevents duplicate qs instances of the same config.

## Test strategy

Static (runnable here):
1. `qmllint -I /usr/lib/qt6/qml -I dotfiles/quickshell $(find dotfiles/quickshell -name '*.qml')` — the second `-I` is required so local modules (`Theme`, `Services`) resolve. Gate on **errors only**; qmllint is known to emit false-positive warnings for Quickshell attached properties/singletons — triage and document them, do not chase warning-zero.
2. `qmlformat --check` if available (available at /usr/bin/qmlformat).
3. `python -m py_compile dotfiles/quickshell/ytm_bridge.py` + `diff` against the AGS copy (must be identical).
4. `bash -n` on launch.sh / setup_venv.sh.
5. Grep-audit parity checklist: every AGS widget/feature mapped to a QML file.

Runtime (limited — the shell cannot run headlessly; be explicit about what was NOT tested):
6. Attempt `timeout 10 qs -p /home/sergiom/Code/hyprconfig/dotfiles/quickshell` inside the live Hyprland session (absolute path; requires `WAYLAND_DISPLAY` in env) — QML load/binding errors surface on stderr even without interaction. Use `--allow-duplicate` if the user's bar is already a qs instance. If no Wayland access from the agent sandbox: state clearly "config parses (qmllint) but was not runtime-tested".
7. Manual checklist for the user (README): workspaces, taskbar focus, clock popup, YTM search→play→radio→next, OSD, brightness, wifi connect/forget, BT pair, notifications + DND, tray menus, power menu, tools toggles, battery, monitor hotplug, popup Esc/click-outside close, bar clickable immediately after popup close.

## Success criteria

- `dotfiles/quickshell/` complete; `waybar/`, `ags/`, `hypr/` untouched (git diff: new dir + one `pkglist-aur.txt` line + `.agents/` docs only; the pre-existing `dotfiles/btop/btop.conf` modification is unrelated — leave it alone).
- qmllint error-free across all QML (warnings triaged and documented).
- Feature parity checklist fully mapped (each AGS widget has a counterpart or a documented deviation).
- `launch.sh` executable, mirroring the AGS lifecycle; README selection steps require no repo hypr-config edits.
- `ytm_bridge.py` identical to the AGS copy; bridge invocations match the protocol exactly (argv-JSON, no shell interpolation).
- `noctalia-qs` present in `pkglist-aur.txt`; `quickshell` NOT added (ADR-A1).

## Architect Notes

Review verdict: the plan is well-grounded — I independently re-verified its environment claims (installed module list, `qs` CLI surface, bridge protocol in `ytm_bridge.py`/`YouTubeService.ts`, `app.ts` window wiring, `launchbar.sh`/`statusbar.sh` selection mechanism, stow layout) and they all check out. The service mapping and step ordering are sound and not over-engineered. Changes made:

1. **Packaging correction (was blocking): `noctalia-qs` instead of `quickshell` in pkglist-aur.txt (ADR-A1).** The installed provider `noctalia-qs` *Conflicts* with `quickshell`, and `install_dependencies.sh` installs the list non-interactively via `yay --noconfirm --needed`. Listing `quickshell` would break dependency installation on this exact machine and would also pull a build that may lack `Quickshell.Networking`, which the implementation targets. Requirement 5 is satisfied by pinning the actual quickshell provider; README explains the provider situation.

2. **Keyboard-focus correction (was blocking for UX parity): `WlrKeyboardFocus.Exclusive`, not `OnDemand` (ADR-A3).** I verified `PopupWindow.tsx` defaults to `Astal.Keymode.EXCLUSIVE`. With OnDemand, Esc-to-close and immediate typing in YouTubeSearch would not work until the user clicks the surface — a behavioral regression from AGS.

3. **Popup mechanism upgraded to `HyprlandFocusGrab` (verified available in the installed build's `Quickshell/Hyprland/_FocusGrab` qmltypes).** Content-sized windows + focus grab replace the planned full-screen transparent overlay window per popup — cheaper (aligned with the migration's resource-usage motivation) and the idiomatic Quickshell pattern. The AGS-style full-surface fallback is retained inside PopupWindow.qml.

4. **Network facade promoted from contingency to architecture (ADR-A2).** `Services/Network.qml` is now the sole importer of `Quickshell.Networking` from step 5 onward, so the R1 portability risk is contained to one file by construction instead of by later refactor. Explicitly scoped to networking only — facades over the stable upstream modules (Bluetooth, Pipewire, Mpris) would be over-engineering.

5. **swaync autostart made explicit (R3).** Verified `dotfiles/hypr/conf/autostart.conf:15` runs `exec-once = swaync`. The plan's launch.sh already kills swaync (parity with AGS), but the login-order race with bus-name ownership is now documented as a known, pre-existing condition rather than left implicit.

6. **Validation hardening.** Added `-I dotfiles/quickshell` to the qmllint invocation (without it, local `Theme`/`Services` singleton imports fail to resolve and the lint gate is meaningless); gate defined as errors-only with warning triage, since qmllint false-positives on Quickshell attached properties are expected. Runtime smoke-test step now specifies absolute path and `--allow-duplicate`.

7. **Small corrections/verifications folded in:** `qs kill` and `-d` confirmed to exist in this build (the plan assumed them); bridge invocation pinned to argv-list (no shell quoting layer) to make the "protocol byte-for-byte" claim robust against titles containing quotes; noted `dotfiles/ags/.gitignore` does not cover oauth/credentials/bridge.log so the new `.gitignore` must (R8); added notification `tracked` retention note per Quickshell's notification lifetime semantics; success criteria notes the pre-existing dirty `btop.conf` is unrelated and must not be touched.

Not changed (considered and rejected): auto-advance on YTM EOS (parity first, listed as README candidate improvement); porting `YouTubeMusicPopup` login UI (dead code in AGS, confirmed unwired in `app.ts`); editing `launchbar.sh`/`statusbar-switcher.sh` (explicitly out of scope per requirements — README diffs suffice).

---
*Last updated: 2026-07-27*
