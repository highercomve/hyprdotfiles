# TODO — quickshell migration

## Pending
- [ ] Step 1: Scaffold dotfiles/quickshell + Theme singleton (style.scss port)
- [ ] Step 2: Bar skeleton + Workspaces/Taskbar/ClientTitle/Clock/PowerMenu
- [ ] Step 3: SystemMonitor, ToolsRow, Battery, SysTray, QuickSettings
- [ ] Step 4: PopupWindow framework + ControlPanel main/audio pages + Brightness service
- [ ] Step 5: Services/Network.qml facade (sole Quickshell.Networking importer — ADR-A2), then Network + Bluetooth pages
- [ ] Step 6: NotificationServer store, popups, list, DND
- [ ] Step 7: MPRIS media player, MediaBar ticker, volume OSD
- [ ] Step 8: Ytm service (bridge + yt-dlp + QtMultimedia) + YouTubeSearch
- [ ] Step 9: CenterPopup with QML calendar
- [ ] Step 10: launch.sh, README.md, pkglist-aur.txt (+noctalia-qs per ADR-A1, NOT quickshell), .gitignore (must cover oauth.json/credentials.json/bridge.log too)
- [ ] Step 11: qmllint (-I /usr/lib/qt6/qml -I dotfiles/quickshell, errors-only gate) + runtime smoke attempt + document untested areas
- [ ] PopupWindow: HyprlandFocusGrab + WlrKeyboardFocus.Exclusive-while-visible (ADR-A3, not OnDemand)

## Review fixes required (see review-fable.md, 2026-07-27 — config fails to load)
- [ ] Fix: Theme.qml missing `import QtQuick` — `color` type unresolved, whole shell fails to load (Theme/Theme.qml:2)
- [ ] Fix: syntax errors `({}}`  (Services/NotificationStore.qml:79,99) and `_prevCpu: { … }` block-vs-object (Services/SystemStats.qml:11)
- [ ] Fix: duplicate `_brightnessPath` property (Services/Brightness.qml:11,13)
- [ ] Fix: replace nonexistent `Quickshell.createProcess()` with declared Process + StdioCollector / Quickshell.execDetached (Brightness, SystemStats, Tools, Network, Ytm)
- [ ] Fix: `property var onClick/onClicked/onDetail` callbacks evaluate eagerly at creation — convert to `signal clicked()` (ToolButton, ControlButton, TogglePill + call sites)
- [ ] Fix: add `id: root` to 6 services + TogglePill
- [ ] Fix: PanelWindow `anchor.*` → `anchors.*`; remove nonexistent `anchors.horizontalCenter` (Bar.qml, VolumeOsd.qml, NotificationPopups.qml, PopupWindow.qml:36)
- [ ] Fix: `Quickshell.desktopEntries` → `DesktopEntries`; `Quickshell.configPath()` no-arg → `Quickshell.shellDir` (NotificationStore:70, Taskbar:66, Ytm:29)
- [ ] Fix: Network facade — ObjectModel `.values` not `.count/.get`; WifiNetwork `name` not `ssid`; writable wifiEnabled path; loopback-as-wired risk
- [ ] Fix: popup `open` binding destroyed by imperative close; Keys.onEscapePressed on non-Item (PopupWindow.qml)
- [ ] Fix: add PwObjectTracker for default sink/source; wire VolumeOsd show() to volume/mute changes; fix `osd` id
- [ ] Fix: SystemStats `\\s`/`\\d` regexes + hwmon discovery order; frozen ClockWidget (no SystemClock)
- [ ] Fix: Taskbar `clazz`/read-only `activated`; ToolTip without QtQuick.Controls import (Taskbar, SysTray, SystemMonitor)
- [ ] Fix: SysTray menus via QsMenuAnchor; `Process.spawnDetached` → Quickshell.execDetached (SystemMonitor:76, PowerMenu:23)
- [ ] Fix: ToolsRow reveal binding; YouTubeSearch play missing resetQueue=true; MediaBar/MediaPlayer keyed on isPlaying instead of current-track
- [ ] Fix: Theme alpha hex order (#AARRGGBB) for barBackground/borderColor; missing Theme imports (ControlPanel, NotificationList, ToolButton, ControlButton)
- [ ] Fix: Variants modelData not declared (shell.qml/Bar.qml); MonthGrid has no previousMonth/nextMonth (CalendarView)
- [ ] Add: NetworkPage PSK password entry + forget/saved-networks flow (plan step 5); WifiSecurityType leak past facade
- [ ] Re-run step 11 for real: qmllint gate + `qs -p` smoke test (previous "no warnings or errors" claim was false — see scratchpad lint.txt, 492 diagnostics)

## In Progress
(review complete — changes requested)

## Completed
- [x] Read full AGS source, style.scss, launch/build scripts, ytm bridge protocol
- [x] Verified installed quickshell module surface (noctalia-qs provider)
- [x] Plan written to plan.md
- [x] Architect review complete — corrections merged in architecture.md (authoritative over plan.md)
