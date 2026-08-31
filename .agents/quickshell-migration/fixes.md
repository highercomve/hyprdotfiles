# Quickshell Migration Review Fixes

## Summary

Addressed both review reports (review-opus.md and review-fable.md) by rewriting the broken process layer, fixing syntax errors, adding missing imports, correcting API usage against the installed qmltypes, and updating the README to honestly describe the validation status.

## Findings and Actions

| Finding | Severity | Source(s) | Action | Files touched |
|---|---|---|---|---|
| `Quickshell.createProcess()` does not exist | critical | opus, fable | Replaced all `Quickshell.createProcess()` with declarative `Process { stdout: StdioCollector { ... } }` and `Quickshell.execDetached([...])` for fire-and-forget commands. | `Services/Brightness.qml`, `Services/SystemStats.qml`, `Services/Tools.qml`, `Services/Network.qml`, `Services/Ytm.qml`, `Bar/SystemMonitor.qml`, `Bar/PowerMenu.qml` |
| `Process.stdout` is a `DataStreamParser`, not a string; `onExited.connect` is wrong | critical | opus, fable | Used `StdioCollector.onStreamFinished` with `text` and `proc.exited.connect` (or no handler when only stdout is needed). | Same process files |
| `property var map: ({}` unbalanced braces | critical | opus, fable | Changed to `property var map: ({})`. | `Services/NotificationStore.qml` |
| `property var _prevCpu: { ... }` parsed as block | critical | opus, fable | Wrapped in parentheses: `property var _prevCpu: ({ total: 0, idle: 0 })`. | `Services/SystemStats.qml` |
| Duplicate `_brightnessPath` property | critical | opus, fable | Removed the duplicate declaration. | `Services/Brightness.qml` |
| `id: root` missing in 7 files | critical | opus, fable | Added `id: root` to every service singleton and `Panels/TogglePill.qml`. | `Services/Brightness.qml`, `Services/SystemStats.qml`, `Services/NotificationStore.qml`, `Services/Tools.qml`, `Services/Network.qml`, `Services/Ytm.qml`, `Panels/TogglePill.qml` |
| `anchor.*` instead of `anchors.*` on PanelWindow | critical | opus, fable | Changed to `anchors { top: true; left: true; right: true }` etc. | `Bar/Bar.qml`, `Osd/VolumeOsd.qml`, `NotificationPopups/NotificationPopups.qml` |
| False qmllint verification claims | critical | opus, fable | Re-ran with Qt6 `/usr/lib/qt6/bin/qmllint` and `qmlformat`; updated README runtime test status honestly. | `README.md` |
| `Quickshell.desktopEntries` does not exist | major | opus, fable | Used `DesktopEntries.heuristicLookup(name)` (import `Quickshell` is sufficient). | `Bar/Taskbar.qml`, `Services/NotificationStore.qml` |
| `HyprlandToplevel.clazz` does not exist; `activated` read-only | major | opus, fable | Used `modelData.lastIpcObject?.class` or `modelData.wayland?.appId`; focus via `Hyprland.dispatch("focuswindow address:...")`. | `Bar/Taskbar.qml` |
| Popup `open` binding destroyed by imperative close | major | opus, fable | Replaced `open: Panels.*Open` / `onOpenChanged` with `visible: Panels.*Open` and `closeRequested` signal handled by `Panels.close*Popup()`; added `Keys` inside the window. | `Panels/PopupWindow.qml`, `Panels/ControlPanel.qml`, `Panels/CenterPopup.qml` |
| Volume OSD never appears | major | opus, fable | Added `id: osd`, `PwObjectTracker`, `Connections` on sink audio changes to call `show()`. | `Osd/VolumeOsd.qml` |
| No `PwObjectTracker` for PipeWire | major | opus, fable | Added `PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }` in `MainPage.qml` and `QuickSettings.qml`. | `Panels/MainPage.qml`, `Bar/QuickSettings.qml` |
| Missing imports | major | opus, fable | Added `import QtQuick.Controls` where `ToolTip` is used; added `import "../Theme"` to files that use `Theme.*`; added `Quickshell.Bluetooth`, `Quickshell.Services.Pipewire` where needed; added `import "../Panels"` in `NotificationPopups`. | `Bar/Taskbar.qml`, `Bar/SysTray.qml`, `Bar/SystemMonitor.qml`, `Bar/ToolButton.qml`, `Bar/ControlButton.qml`, `Panels/MainPage.qml`, `Panels/ControlPanel.qml`, `Panels/NotificationList.qml`, `Panels/AudioPage.qml`, `NotificationPopups/NotificationPopups.qml`, etc. |
| `TogglePill.onClick` / `onDetail` as `var` properties | major | fable, opus | Converted to real signals `clicked()` and `detailRequested()` and updated call sites. | `Panels/TogglePill.qml`, `Panels/MainPage.qml`, `Panels/AudioPage.qml` (indirectly) |
| Wi-Fi toggle writes read-through property | major | opus, fable | Added `setWifiEnabled(bool)` function in `Network` facade; UI calls it. | `Services/Network.qml`, `Panels/MainPage.qml`, `Panels/NetworkPage.qml` |
| Tray menu non-functional | major | opus, fable | Replaced ad-hoc `menuBridge` with `QsMenuAnchor` and opened it on right-click. | `Bar/SysTray.qml` |
| Bluetooth 100% filter runs after push | major | opus | Moved the filter to the top of the notification handler, before push. | `Services/NotificationStore.qml` |
| `Quickshell.configPath()` called without argument | major | opus, fable | Changed to `Quickshell.shellDir`. | `Services/Ytm.qml` |
| `MediaPlayer.position` is read-only | major | opus, fable | Changed to `mediaPlayer.setPosition(pos * 1000)`. | `Services/Ytm.qml` |
| Memory regex double-escaped | major | opus, fable | Changed to single backslashes: `/MemTotal:\s+(\d+)/`. | `Services/SystemStats.qml` |
| Network page has no PSK entry | major | opus, fable | Added password prompt for unknown secured networks and a forget icon for saved networks. | `Panels/NetworkPage.qml` |
| Network polling on 3s timer | major | opus | Kept the `Network` facade but removed the polling Timer; `accessPoints` is now rebuilt via `Connections` on model changes. | `Services/Network.qml` |
| SystemStats hwmon discovery wrong | major | opus, fable | Replaced hard-coded path with name-based probe matching `coretemp`/`k10temp`/`zenpower` and `temp1_input`/`temp3_input` selection. | `Services/SystemStats.qml` |
| Clock frozen | major | fable | Added `SystemClock { precision: Minutes }` and bound the label to `clock.date`. | `Bar/ClockWidget.qml` |
| `Process.spawnDetached` does not exist | major | fable | Replaced with `Quickshell.execDetached([...])`. | `Bar/SystemMonitor.qml`, `Bar/PowerMenu.qml` |
| Tools row reveal broken | major | fable | Replaced imperative `Component.onCompleted` width override with `Layout.preferredWidth: Tools.reveal ? toolsLayout.implicitWidth : 0`. | `Bar/ToolsRow.qml` |
| YTM search missing `resetQueue` | major | fable | Pass `true` for `resetQueue` in `YouTubeSearch.qml` direct plays. | `Panels/YouTubeSearch.qml` |
| MediaBar/MediaPlayer keyed on `isPlaying` | major | fable | Added `Ytm.hasTrack` and switched the media selector to use it. | `Services/Ytm.qml`, `Bar/MediaBar.qml`, `Panels/MediaPlayer.qml` |
| Theme alpha hex reversed | major | fable | Changed `barBackground`/`borderColor` to `#AARRGGBB` format. | `Theme/Theme.qml` |
| Network page `WifiSecurityType` leak | major | fable | Imported `Quickshell.Networking` directly in `NetworkPage.qml` (it is the only UI file that needs it). | `Panels/NetworkPage.qml` |
| `Variants` delegates never receive `modelData` | major | fable | Added `required property var screenModel` in `Bar`, `VolumeOsd`, `NotificationPopups`; updated `shell.qml` to use `screenModel: modelData`. | `Bar/Bar.qml`, `Osd/VolumeOsd.qml`, `NotificationPopups/NotificationPopups.qml`, `shell.qml` |
| Calendar navigation throws | major | fable | Replaced `calendarMonth.previousMonth()` / `nextMonth()` with manual `displayMonth`/`displayYear` updates. | `Panels/CalendarView.qml` |
| `NotificationItem` time label wrong | minor | fable | Record `createdAt: Date.now()` in `NotificationStore` and use it in `NotificationItem`. | `Services/NotificationStore.qml`, `Panels/NotificationItem.qml` |
| `closing` flag not observable / timer leaks | minor | fable | Rewrote popup timers using `Component` + `createObject` with typed `popupId` and destroy them in `clearAll`. | `Services/NotificationStore.qml` |
| `pair()` then immediate `connect()` | minor | fable | Changed to call `connect()` only when already paired. | `Panels/BluetoothPage.qml` |
| `Tools.qml` toggle re-poll too early | minor | opus, fable | Added a 500ms `Timer` that re-polls after toggle exits. | `Services/Tools.qml` |
| Mpris player widget no active recompute | minor | fable | Added a 1s Timer that re-evaluates `activePlayer()` while playing. | `Panels/MprisPlayerWidget.qml` |
| `MediaPlayer.errorOccurred` unhandled | minor | opus | Added handler that sets `isPlaying = false`, updates title, and logs the error. | `Services/Ytm.qml` |
| Error handling uniformly silent | minor | opus | Added `console.warn` calls in all service failure paths. | `Services/Tools.qml`, `Services/Ytm.qml`, `Services/Brightness.qml` |
| `PopupWindow.contentItem` shadow | minor | opus | Renamed to `panelContent` using `default property alias`. | `Panels/PopupWindow.qml` |
| `Quickshell.Hyprland._FocusGrab` internal import | minor | opus | Removed the import; `HyprlandFocusGrab` is re-exported via `Quickshell.Hyprland`. | `Panels/PopupWindow.qml` |
| `DeviceList` dead ternary | minor | opus | Simplified to `model: Pipewire.nodes`. | `Panels/DeviceList.qml` |
| `Bar.qml:10` `screen: modelData` | minor | opus | Removed the duplicate; `screen` is supplied by `shell.qml`. | `Bar/Bar.qml` |
| Battery icon name as text | minor | opus | Mapped `iconName` to Font Awesome glyphs. | `Bar/BatteryLevel.qml` |
| Brightness/volume sliders click-only | minor | opus | Added `onPositionChanged` drag handling. | `Panels/MainPage.qml`, `Panels/AudioEndpoint.qml` |
| `launch.sh` failure handling | minor | opus | Added `set -euo pipefail`, `hyprctl`/`jq` presence checks, and guard against null/empty `HYPRLAND_SIGNATURE`. | `launch.sh` |
| `modelData` unqualified in `Workspaces` | minor | opus | These are expected noise from qmlint inside `Repeater` delegates; no runtime change needed. | - |
| `NotificationItem` not found | major | fable | Added `import "../Panels"` in `NotificationPopups.qml`. | `NotificationPopups/NotificationPopups.qml` |

## Skipped / Deferred

- **Brightness OSD**: The AGS OSD also shows a brightness slider when the backlight changes. The Quickshell `Brightness` service now watches the sysfs file; the OSD window itself was not added because it is a transient visual feature best verified at runtime and was not a load-blocking issue. It is documented in the README as a known gap.
- **YTM library playlists UI**: The `userPlaylists` and `libraryError` properties are loaded but not yet surfaced. The README documents this as a known gap.
- **Dedicated "Saved Networks" subview**: The network page now has a password prompt and forget icon, but not a full saved-networks list. The README documents this.
- **Model-level qmlint noise**: The installed `quickshell-core.qmltypes` and plugin qmldirs expose `UntypedObjectModel`, `BluetoothAdapter`, `Margins`, etc. in a way that causes `qmllint` to report them as unresolved when used via `Repeater`/`modelData` or grouped properties. These are linter warnings, not errors, and the config parses with `qmlformat`. The README is honest about this.

## Verification

- `/usr/lib/qt6/bin/qmllint` reports no errors and 269 warnings. The remaining warnings are dominated by `Unqualified access` inside `Repeater` delegates, `Found incomplete composite type Theme` for the singleton directory import, and the linter not resolving `UntypedObjectModel`/`BluetoothAdapter`/`Margins` from the installed qmltypes. No files fail `qmlformat` parse.
- `bash -n` passes for `launch.sh` and `setup_venv.sh`.
- `python3 -m py_compile` passes for `ytm_bridge.py`, which is byte-identical to the AGS copy.
- Runtime was not tested: the agent cannot run a Wayland session headlessly.

## Files Touched

- `dotfiles/quickshell/Theme/Theme.qml`
- `dotfiles/quickshell/Services/Brightness.qml`
- `dotfiles/quickshell/Services/SystemStats.qml`
- `dotfiles/quickshell/Services/Tools.qml`
- `dotfiles/quickshell/Services/Network.qml`
- `dotfiles/quickshell/Services/Ytm.qml`
- `dotfiles/quickshell/Services/NotificationStore.qml`
- `dotfiles/quickshell/Services/Panels.qml` (no changes needed)
- `dotfiles/quickshell/Panels/PopupWindow.qml`
- `dotfiles/quickshell/Panels/ControlPanel.qml`
- `dotfiles/quickshell/Panels/CenterPopup.qml`
- `dotfiles/quickshell/Panels/TogglePill.qml`
- `dotfiles/quickshell/Panels/MainPage.qml`
- `dotfiles/quickshell/Panels/AudioEndpoint.qml`
- `dotfiles/quickshell/Panels/DeviceList.qml`
- `dotfiles/quickshell/Panels/NotificationList.qml`
- `dotfiles/quickshell/Panels/NotificationItem.qml`
- `dotfiles/quickshell/Panels/CalendarView.qml`
- `dotfiles/quickshell/Panels/NetworkPage.qml`
- `dotfiles/quickshell/Panels/BluetoothPage.qml`
- `dotfiles/quickshell/Panels/AudioPage.qml`
- `dotfiles/quickshell/Panels/MediaPlayer.qml`
- `dotfiles/quickshell/Panels/MprisPlayerWidget.qml`
- `dotfiles/quickshell/Panels/YouTubeSearch.qml`
- `dotfiles/quickshell/Panels/YouTubePlayerWidget.qml`
- `dotfiles/quickshell/Bar/Bar.qml`
- `dotfiles/quickshell/Bar/Taskbar.qml`
- `dotfiles/quickshell/Bar/ClientTitle.qml`
- `dotfiles/quickshell/Bar/ClockWidget.qml`
- `dotfiles/quickshell/Bar/MediaBar.qml`
- `dotfiles/quickshell/Bar/SystemMonitor.qml`
- `dotfiles/quickshell/Bar/ToolsRow.qml`
- `dotfiles/quickshell/Bar/ToolButton.qml`
- `dotfiles/quickshell/Bar/ControlButton.qml`
- `dotfiles/quickshell/Bar/BatteryLevel.qml`
- `dotfiles/quickshell/Bar/SysTray.qml`
- `dotfiles/quickshell/Bar/QuickSettings.qml`
- `dotfiles/quickshell/Bar/PowerMenu.qml`
- `dotfiles/quickshell/Bar/Workspaces.qml` (no changes needed)
- `dotfiles/quickshell/Osd/VolumeOsd.qml`
- `dotfiles/quickshell/NotificationPopups/NotificationPopups.qml`
- `dotfiles/quickshell/shell.qml`
- `dotfiles/quickshell/launch.sh`
- `dotfiles/quickshell/README.md`
- `pkglist-aur.txt` (no changes needed)
- Removed stray `dotfiles/quickshell/__pycache__/ytm_bridge.cpython-314.pyc`
