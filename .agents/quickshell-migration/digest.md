# Quickshell Migration Digest

Generated from `/home/sergiom/Code/hyprconfig/.agents/quickshell-migration/implementation.md`.
All files listed in the implementation report exist on disk.

---

## Shell & lifecycle

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/shell.qml`
- L1-9: Imports Quickshell, Wayland, QtQuick, and local Bar/Panels/Osd/NotificationPopups dirs.
- L10-34: `ShellRoot` spawns per-screen `Bar`, `VolumeOsd`, `NotificationPopups` via `Variants` over `Quickshell.screens`; also instantiates singleton-like `ControlPanel` and `CenterPopup`.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/launch.sh`
- L1-12: Kills `qs`, `statusbar`, `gjs`, `swaync`; reads first Hyprland instance signature with `hyprctl instances -j | jq`; launches `qs -d` with HYPRLAND_INSTANCE_SIGNATURE set. No error handling if `hyprctl`/`jq` fail.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/setup_venv.sh`
- L1-18: Creates `./.venv` if missing, activates it, upgrades pip, installs `ytmusicapi` and `yt-dlp`. No error handling on pip failure.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/ytm_bridge.py`
- L1-10: Constants for bridge/auth files.
- L11-19: `friendly_error` maps HTTP/auth exceptions to user messages.
- L21-30: `get_yt_instance` tries browser.json, then oauth.json + credentials.json, then oauth.json alone; silently returns `None` on any exception.
- L32-88: `main` parses JSON argv, handles `check_auth`, `search`, `radio`, `library_playlists`, `playlist`; emits single JSON lines; catches all exceptions and prints `{"error": ...}`.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/.gitignore`
- L1-7: Ignores `.venv/`, `__pycache__/`, `oauth.json`, `browser.json`, `credentials.json`, `bridge.log`.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/README.md`
- L1-88: User-facing docs for dependencies, selection via `statusbar.sh`, `launchbar.sh` and `statusbar-switcher.sh` diffs, swaync note, YTM auth, known deviations, runtime test checklist.

---

## Theme

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Theme/Theme.qml`
- L1-58: Singleton exposing Catppuccin Mocha palette, fonts, radii, margins, and per-widget accent colors.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Theme/qmldir`
- L1: Registers `Theme` singleton.

---

## Services (singletons)

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/Panels.qml`
- L1-38: Singleton tracking `controlPanelOpen`, `centerPopupOpen`, `controlPanelPage`; provides toggle/open/close/switch functions.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/Network.qml`
- L1-115: Singleton importing `Quickshell.Networking` only here (ADR-A2).
- L8-11: Exposes `wifiEnabled`, `scanning`, `wiredConnected`, `accessPoints`.
- L14-49: `toggleWired`, `findWiredDevice`, `connectAp`, `forgetAp`.
- L51-73: 3s timer calls `refresh`; `refresh` updates wired/wifi state and AP list, with `apsEqual` diffing.
- L75-104: Helpers `findWifiDevice`, `scan`, `collectAps`.
- Error handling: ignores failed processes silently.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/Brightness.qml`
- L1-83: Singleton.
- L7-13: Declares `_brightnessPath` twice (lines 11 and 13 duplicate property declaration).
- L15-20: `FileView` watches `_brightnessPath`.
- L22-55: `initialize` chains `brightnessctl list`, `max`, `get`; sets `_max`, `screen`, then `available = true`.
- L57-65: `findBrightnessPath` runs `find` for sysfs brightness path.
- L67-81: `readBrightness` clamps value; `setValue` calls `brightnessctl set`.
- Error handling: early returns on non-zero exit / invalid numbers.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/SystemStats.qml`
- L1-98: Singleton.
- L11-13: Default `_hwmonPath` is hard-coded `/sys/class/hwmon/hwmon4/temp3_input`; `findHwmon` only probes the first `hwmon/name` and sets `_hwmonPath` to `temp1_input`, never `temp3_input`.
- L31-47: `FileView`s for `/proc/stat`, `/proc/meminfo`, and `_hwmonPath`.
- L49-62: 2s timer triggers `update()`.
- L64-97: Parses CPU jiffies, memory from meminfo, temperature from hwmon. Silent fallbacks if parsing fails.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/Tools.qml`
- L1-65: Singleton.
- L14-19: 2s timer calls `poll`.
- L21-48: Polls status of idle/sunset/record/monitor-suspend scripts via JSON; `toggle` invokes scripts with `toggle` and rechecks via `Qt.callLater`.
- L50-64: `cyclePowerProfile` reads current profile with `powerprofilesctl get`, cycles to next.
- Error handling: silent JSON parse catch.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/NotificationStore.qml`
- L1-115: Singleton owning notifications.
- L11-29: `NotificationServer` accepts actions/body markup/image/persistence; stores notifications, suppresses popups for Bluetooth 100% notifications or when DND enabled.
- L32-65: `addPopup`, `removePopup`, `dismissNotification`, `clearAll`.
- L68-75: `resolveIcon` tries `n.image`, desktop entry, `appIcon`, default.
- L77-114: Dynamic timer objects for popup timeout (5s) and close animation delay (300ms).
- Error handling: minimal; no explicit null checks before calling `n.dismiss()`.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/Ytm.qml`
- L1-204: Singleton for YouTube Music playback.
- L8-33: State: search results, playback, queue, auth, library error.
- L34-49: `MediaPlayer` + `AudioOutput`; position/duration/playback bindings.
- L53-71: `callBridge` spawns `python ytm_bridge.py <json>` via argv list; resolves parsed JSON.
- L73-88: Auth and library loading with request dedup via `_libraryLoading`.
- L90-124: `search` and `startRadio` with request IDs to drop stale responses.
- L126-165: `playCurrent`, `extractAudioUrl` (yt-dlp), `play` with queue reset and request-id dedup.
- L167-203: `next`, `previous`, `pause`, `resume`, `stop`, `seek`.
- Error handling: sets title to "Error loading stream" on missing URL; emits bridge-level errors as JSON.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/qmldir`
- L1-7: Registers Panels, Network, Brightness, SystemStats, Tools, NotificationStore, Ytm singletons.

---

## Bar widgets

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/Bar.qml`
- L1-69: `PanelWindow` anchored top-left-right, height 38, transparent; lays out left/center/right `RowLayout`s with workspace, taskbar, title, clock, media, system monitor, tools, battery, tray, quick settings, power.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/Workspaces.qml`
- L1-51: Sorts `Hyprland.workspaces`; clickable buttons dispatch `workspace <id>`.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/Taskbar.qml`
- L1-71: Sorts `Hyprland.toplevels`; displays icon from desktop entry; click activates toplevel. Has hard-coded class substitution for `dev.zed.Zed`.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/ClientTitle.qml`
- L1-31: Shows `Hyprland.activeToplevel?.title`, elided, max width 280.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/ClockWidget.qml`
- L1-27: Displays formatted date/time; click toggles center popup.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/MediaBar.qml`
- L1-200: Loader switches between YTM, MPRIS, and empty components.
- L31-73: YTM component shows title and pause/next controls.
- L75-120: MPRIS component shows scrolling ticker with title/artist/time and play/pause/next.
- L122-157: Empty component.
- L159-199: 1s ticker timer; `activePlayer`, `tickerText`, `formatTime`.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/SystemMonitor.qml`
- L1-78: CPU/memory/temperature text with tooltips; click spawns system monitor script.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/ToolsRow.qml`
- L1-113: Collapsible tools container with buttons for cliphist, idle, sunset, record, monitor-suspend, power-profile cycle. Toggle reveal via gear icon.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/ToolButton.qml`
- L1-28: Reusable icon button with optional active color.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/BatteryLevel.qml`
- L1-23: Shows UPower display device icon + percentage; visible only on laptop batteries; color changes for charging/low.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/SysTray.qml`
- L1-68: Repeats `SystemTray.items`; left-click activates, right-click shows DBus menu via simple `menuBridge`.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/QuickSettings.qml`
- L1-39: Shows DND and volume icons; click toggles control panel.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/PowerMenu.qml`
- L1-25: Power icon; click runs `wlogout.sh`.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/ControlButton.qml`
- L1-25: Simple icon button used in media bar.

---

## Panels / popups

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/PopupWindow.qml`
- L1-67: Reusable `PanelWindow` on `Overlay` layer, exclusive keyboard focus when open, `HyprlandFocusGrab` for click-outside-close, Escape closes.
- L52-57: Reparents `contentItem` into container.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/ControlPanel.qml`
- L1-40: `PopupWindow` bound to `Panels.controlPanelOpen`; width 400, height 800; Loader switches MainPage/NetworkPage/BluetoothPage/AudioPage.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/MainPage.qml`
- L1-206: Control panel root page.
- L16-44: Wi-Fi and Bluetooth toggle pills with detail navigation.
- L47-107: Brightness slider (visible if `Brightness.available`).
- L109-151: Audio device management navigation row.
- L153-186: Speaker/microphone `AudioEndpoint` summaries.
- L188-204: DND switch and notification list.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/NetworkPage.qml`
- L1-262: Wired toggle, Wi-Fi toggle + scan button, AP list sorted by signal strength, supports PSK connect (via `Network.connectAp`). Does not provide password input UI.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/BluetoothPage.qml`
- L1-234: Adapter toggle, discovery toggle with 15s auto-off timer, sorted device list, click to pair/connect/disconnect.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/AudioPage.qml`
- L1-96: Output and input device lists using `DeviceList`.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/TogglePill.qml`
- L1-87: Reusable two-part pill with icon/label click and detail arrow.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/AudioEndpoint.qml`
- L1-101: Mute toggle, volume slider, device description; `expanded` toggles but currently only changes chevron.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/DeviceList.qml`
- L1-71: Lists PipeWire nodes, filters by `AudioSink`/`AudioSource`, marks defaults, click sets preferred default.
- L13: Uses `Pipewire.nodes` for both input and output (the `model` condition uses the same expression regardless of `isInput`, though filtering occurs inside delegate).

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/NotificationList.qml`
- L1-34: Header + repeater over `NotificationStore.notifications`; shows "No notifications" placeholder.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/NotificationItem.qml`
- L1-145: Notification card with icon, summary, expandable body, timestamp, dismiss button, action buttons.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/DndSwitch.qml`
- L1-51: Toggle pill for `NotificationStore.dnd`.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/CenterPopup.qml`
- L1-71: `PopupWindow` 800x500 centered; two-column layout with `CalendarView` + `YouTubeSearch` on left, `MediaPlayer` on right.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/CalendarView.qml`
- L1-110: `MonthGrid` + `DayOfWeekRow` calendar with month navigation.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/MediaPlayer.qml`
- L1-38: Loader chooses `YouTubePlayerWidget` when `Ytm.isPlaying`, otherwise `MprisPlayerWidget`.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/MprisPlayerWidget.qml`
- L1-182: Album art, title/artist/album, position scrubber, prev/play/next controls.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/YouTubePlayerWidget.qml`
- L1-157: Cover art, title/artist, progress scrubber, prev/play/next controls using `Ytm` service.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/YouTubeSearch.qml`
- L1-209: Search input with placeholder, filter pills (Songs/Artists/Albums/Playlists), results list with thumbnails, radio button for songs, click handling for play vs. refine search.

---

## OSD and notification popups

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Osd/VolumeOsd.qml`
- L1-79: `PanelWindow` at bottom showing volume icon/bar/percentage; `show()` and 2s hide timer. No external trigger wires it; `visible` starts `false`.

`/home/sergiom/Code/hyprconfig/dotfiles/quickshell/NotificationPopups/NotificationPopups.qml`
- L1-44: `PanelWindow` top-right; visible when popups exist; column of `NotificationItem`s.

---

## Modified file

`/home/sergiom/Code/hyprconfig/pkglist-aur.txt`
- L1-26: `noctalia-qs` inserted between `nautilus-sendto-debug` and `reiserfsprogs` at line 21.

---

## Observed issues worth flagging

- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/Brightness.qml` lines 11 and 13 declare the same property `_brightnessPath` twice.
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/SystemStats.qml` has a hard-coded `_hwmonPath` default and `findHwmon` selects `temp1_input` of the first hwmon; may not match the intended sensor.
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Osd/VolumeOsd.qml` exposes `show()` but nothing in the reviewed files calls it (no keybinding integration).
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/NetworkPage.qml` connects to APs but provides no password-entry UI; PSK flow depends on stored/known networks.
- Error handling across QML services is generally silent (early returns or empty catches); failed commands do not surface user-visible errors.
- Runtime was not tested; static `qmllint`/`qmlformat`/shell-check passed per implementation report.
