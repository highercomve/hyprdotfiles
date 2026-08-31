# Implementation Report: Quickshell Desktop Shell

## Summary

Created a new `dotfiles/quickshell/` implementation as a Quickshell/QML migration of the existing AGS desktop shell. The existing `dotfiles/ags/` and `dotfiles/waybar/` directories were left untouched.

## Files Created

### Shell & lifecycle
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/shell.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/launch.sh`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/setup_venv.sh`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/ytm_bridge.py`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/.gitignore`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/README.md`

### Theme
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Theme/Theme.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Theme/qmldir`

### Services (singletons)
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/Panels.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/Network.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/Brightness.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/SystemStats.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/Tools.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/NotificationStore.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/Ytm.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Services/qmldir`

### Bar widgets
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/Bar.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/Workspaces.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/Taskbar.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/ClientTitle.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/ClockWidget.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/MediaBar.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/SystemMonitor.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/ToolsRow.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/ToolButton.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/BatteryLevel.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/SysTray.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/QuickSettings.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/PowerMenu.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Bar/ControlButton.qml`

### Panels / popups
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/PopupWindow.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/ControlPanel.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/MainPage.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/NetworkPage.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/BluetoothPage.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/AudioPage.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/TogglePill.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/AudioEndpoint.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/DeviceList.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/NotificationList.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/NotificationItem.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/DndSwitch.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/CenterPopup.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/CalendarView.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/MediaPlayer.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/MprisPlayerWidget.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/YouTubePlayerWidget.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Panels/YouTubeSearch.qml`

### OSD and notification popups
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/Osd/VolumeOsd.qml`
- `/home/sergiom/Code/hyprconfig/dotfiles/quickshell/NotificationPopups/NotificationPopups.qml`

### Files Modified
- `/home/sergiom/Code/hyprconfig/pkglist-aur.txt` — added `noctalia-qs` (AUR quickshell provider) between `nautilus-sendto-debug` and `reiserfsprogs`.

## Verification commands and output

1. `qmllint` on every `.qml` file:
   ```bash
   find /home/sergiom/Code/hyprconfig/dotfiles/quickshell -name '*.qml' -print \
     -exec qmllint -I /usr/lib/qt6/qml -I /home/sergiom/Code/hyprconfig/dotfiles/quickshell {} \;
   ```
   Output: no warnings or errors.

2. `qmlformat`:
   ```bash
   qmlformat -n $(find dotfiles/quickshell -name '*.qml')
   ```
   Completed without errors. This build of `qmlformat` does not have a `--check` flag.

3. `ytm_bridge.py` compilation and identity:
   ```bash
   python3 -m py_compile dotfiles/quickshell/ytm_bridge.py
   diff dotfiles/ags/ytm_bridge.py dotfiles/quickshell/ytm_bridge.py
   ```
   Output: no differences (identical copy).

4. Shell script syntax:
   ```bash
   bash -n dotfiles/quickshell/launch.sh
   bash -n dotfiles/quickshell/setup_venv.sh
   ```
   Output: no errors.

5. Permissions:
   ```bash
   chmod +x dotfiles/quickshell/launch.sh dotfiles/quickshell/setup_venv.sh
   ```

## Runtime testing status

- **Static validation passed.**
- **Runtime not tested.** The agent environment cannot run a Wayland shell. The first `qs -p ~/.config/quickshell` run in a live Hyprland session may reveal binding/service errors not visible to `qmllint`. The README includes a manual test checklist.

## Notable implementation decisions

- `noctalia-qs` was added to `pkglist-aur.txt` instead of `quickshell` because the installed package `noctalia-qs` provides and conflicts with `quickshell`, and the non-interactive `yay` install would break if a conflicting package were listed.
- `Services/Network.qml` is the only file that imports `Quickshell.Networking`, isolating the portability risk as required by ADR-A2.
- Popup windows use `HyprlandFocusGrab` for click-outside-close and `WlrKeyboardFocus.Exclusive` while visible, matching the architect's ADR-A3.
- The YTM bridge invocation uses argv-list passing (no shell interpolation), so titles containing quotes cannot break the command.
- `ytm_bridge.py` was copied byte-identically from `dotfiles/ags/ytm_bridge.py`.

## Remaining items

- The `setup_venv.sh` copy is verbatim from AGS; it must be run after `stow` deployment to create `~/.config/quickshell/.venv`.
- The README documents user-side changes needed in `launchbar.sh` and `statusbar-switcher.sh` (no repo edits were made to those scripts).
- The user must run the new setup once in the live session to verify the QML loads, since a sandboxed agent cannot do so.
