-- -----------------------------------------------------
-- Key bindings (migrated from conf/keybinding.conf)
--
-- Every bind carries a `description` flag: that's what
-- scripts/keybindings.sh (SUPER+CTRL+K cheatsheet) shows, via
-- `hyprctl binds -j`. Keep them short and human-readable.
-- -----------------------------------------------------

local mainMod       = "SUPER"
local secondMod     = "CTRL"
local thirdMod      = "ALT"
local HYPRSCRIPTS   = "~/.config/hypr/scripts"
local USERSETTINGS  = "~/.config/hypr/user_settings"

-- Applications
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(USERSETTINGS .. "/terminal.sh"), { description = "Open the terminal" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(USERSETTINGS .. "/browser.sh"), { description = "Open the browser" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(USERSETTINGS .. "/filemanager.sh"), { description = "Open the filemanager" })
hl.bind(mainMod .. " + " .. secondMod .. " + C", hl.dsp.exec_cmd(USERSETTINGS .. "/calculator.sh"), { description = "Open the calculator" })
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(USERSETTINGS .. "/hyprpicker.sh"), { description = "Open the color picker" })
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/disks.sh"), { description = "Open disks selector" })
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/ttyusb.sh"), { description = "USBTTY connector selector" })
hl.bind(mainMod .. " + " .. secondMod .. " + D", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/flash-usb.sh"), { description = "Flash image into USB device" })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/rofi-network-manager.sh"), { description = "Open network manager" })
hl.bind(mainMod .. " + " .. thirdMod .. " + N", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/rofi-bluetooth.sh"), { description = "Open Bluetooth configuration" })
hl.bind(secondMod .. " + SHIFT + A", hl.dsp.exec_cmd("~/.local/bin/ghostpen --trigger"), { description = "GhostPen — AI text editing overlay" })
hl.bind(secondMod .. " + SHIFT + D", hl.dsp.exec_cmd("~/.local/bin/ghostpen --voice-input"), { description = "GhostPen — voice dictation" })
hl.bind(secondMod .. " + SHIFT + L", hl.dsp.exec_cmd("~/.local/bin/ghostpen --captions"), { description = "GhostPen — live captions toggle" })

-- Display zoom
hl.bind(mainMod .. " + SHIFT + mouse_down", hl.dsp.exec_cmd([[hyprctl keyword cursor:zoom_factor $(awk "BEGIN {print $(hyprctl getoption cursor:zoom_factor | grep 'float:' | awk '{print $2}') + 0.5}")]]), { description = "Increase display zoom" })
hl.bind(mainMod .. " + SHIFT + mouse_up", hl.dsp.exec_cmd([[hyprctl keyword cursor:zoom_factor $(awk "BEGIN {print $(hyprctl getoption cursor:zoom_factor | grep 'float:' | awk '{print $2}') - 0.5}")]]), { description = "Decrease display zoom" })
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd("hyprctl keyword cursor:zoom_factor 1"), { description = "Reset display zoom" })

-- Windows
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Kill active window" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("hyprctl activewindow | grep pid | tr -d 'pid:' | xargs kill"), { description = "Quit active window and all open instances" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Set active window to fullscreen" })
hl.bind(mainMod .. " + S", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Maximize window" })
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle active window floating" })
-- workspaceopt/allfloat was removed upstream (0.55+): the old
-- "SUPER+SHIFT+T -> all windows float" bind has no replacement dispatcher.
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "Toggle split" })
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }), { description = "Move focus left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }), { description = "Move focus right" })
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }), { description = "Move focus up" })
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }), { description = "Move focus down" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Move window with the mouse" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window with the mouse" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 100,  y = 0,    relative = true }), { description = "Increase window width with keyboard" })
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -100, y = 0,    relative = true }), { description = "Reduce window width with keyboard" })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,    y = 100,  relative = true }), { description = "Increase window height with keyboard" })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,    y = -100, relative = true }), { description = "Reduce window height with keyboard" })
hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { description = "Toggle window group" })
hl.bind(mainMod .. " + K", hl.dsp.layout("swapsplit"), { description = "Swapsplit" })
hl.bind(mainMod .. " + " .. thirdMod .. " + left",  hl.dsp.window.swap({ direction = "l" }), { description = "Swap tiled window left" })
hl.bind(mainMod .. " + " .. thirdMod .. " + right", hl.dsp.window.swap({ direction = "r" }), { description = "Swap tiled window right" })
hl.bind(mainMod .. " + " .. thirdMod .. " + up",    hl.dsp.window.swap({ direction = "u" }), { description = "Swap tiled window up" })
hl.bind(mainMod .. " + " .. thirdMod .. " + down",  hl.dsp.window.swap({ direction = "d" }), { description = "Swap tiled window down" })
hl.bind(thirdMod .. " + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end, { repeating = true, description = "Cycle between windows and raise" })

-- Actions
hl.bind(mainMod .. " + " .. secondMod .. " + R", hl.dsp.exec_cmd("hyprctl reload"), { description = "Reload Hyprland configuration" })
hl.bind(mainMod .. " + " .. secondMod .. " + S", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/statusbar-switcher.sh"), { description = "Open status bar switcher" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/record.sh toggle"), { description = "Record whole screen" })
hl.bind(mainMod .. " + " .. thirdMod .. " + R", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/record.sh area"), { description = "Record screen area" })
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/toggle-animations.sh"), { description = "Toggle animations" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/screenshot.sh"), { description = "Take a screenshot" })
hl.bind(mainMod .. " + " .. thirdMod .. " + F", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/screenshot.sh --instant"), { description = "Instant full-screen screenshot" })
hl.bind(mainMod .. " + " .. thirdMod .. " + S", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/screenshot.sh --instant-area"), { description = "Instant area screenshot" })
hl.bind(mainMod .. " + " .. secondMod .. " + Q", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/wlogout.sh"), { description = "Start logout view" })
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/waypaper.sh --random"), { description = "Change the wallpaper" })
hl.bind(mainMod .. " + " .. secondMod .. " + W", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/waypaper.sh"), { description = "Open wallpaper selector" })
hl.bind(mainMod .. " + " .. thirdMod .. " + W", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/wallpaper-automation.sh"), { description = "Start random wallpaper script" })
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("pkill rofi || rofi -show drun -replace -i"), { description = "Open application launcher" })
hl.bind(mainMod .. " + " .. secondMod .. " + RETURN", hl.dsp.exec_cmd("pkill rofi || rofi -show drun -replace -i"), { description = "Open application launcher" })
hl.bind(mainMod .. " + " .. secondMod .. " + K", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/keybindings.sh"), { description = "Show keybindings" })
hl.bind(mainMod .. " + " .. secondMod .. " + B", hl.dsp.exec_cmd("~/.config/waybar/toggle.sh"), { description = "Toggle waybar" })
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/cliphist.sh"), { description = "Open clipboard manager" })
hl.bind(mainMod .. " + " .. secondMod .. " + T", hl.dsp.exec_cmd("~/.config/themes/themeswitcher.sh"), { description = "Open theme switcher" })
hl.bind(mainMod .. " + " .. thirdMod .. " + G", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/gamemode.sh"), { description = "Toggle game mode" })
hl.bind(mainMod .. " + " .. secondMod .. " + L", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/power.sh lock"), { description = "Lock desktop" })
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/hyprshade.sh"), { description = "Change hyprshade" })
hl.bind(secondMod .. " + Tab", hl.dsp.exec_cmd(HYPRSCRIPTS .. "/focus.sh"), { description = "Open select window menu" })

-- Workspaces: SUPER+[0-9] focus, SUPER+SHIFT+[0-9] move window,
-- SUPER+CTRL+[0-9] move all windows.
hl.config({
    binds = {
        -- The Surface Arc emits several scroll events for one swipe.
        scroll_event_delay = 1500,
    },
})

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Open workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Move active window to workspace " .. i })
    hl.bind(mainMod .. " + " .. secondMod .. " + " .. key, hl.dsp.exec_cmd(HYPRSCRIPTS .. "/moveTo.sh " .. i), { description = "Move all windows to workspace " .. i })
end

hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "m+1" }), { description = "Open next workspace" })
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }), { description = "Open previous workspace" })
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Open next workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Open previous workspace" })
hl.bind(mainMod .. " + " .. secondMod .. " + down", hl.dsp.focus({ workspace = "empty" }), { description = "Open the next empty workspace" })

-- Fn keys
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -q s +10%"), { description = "Increase brightness by 10%" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q s 10%-"), { description = "Reduce brightness by 10%" })
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+"), { locked = true, repeating = true, description = "Increase volume by 2%" })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),      { locked = true, repeating = true, description = "Reduce volume by 2%" })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), { description = "Toggle mute" })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), { description = "Audio play/pause" })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl pause"), { description = "Audio pause" })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"), { description = "Audio next" })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"), { description = "Audio previous" })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { description = "Toggle microphone" })
hl.bind("XF86Calculator",        hl.dsp.exec_cmd(USERSETTINGS .. "/calculator.sh"), { description = "Open calculator" })
hl.bind("XF86ScreenSaver",       hl.dsp.exec_cmd("hyprlock"), { description = "Open screenlock" }) -- "XF86Lock" in the old conf was not a real keysym

hl.bind("code:238", hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight s +10"), { description = "Keyboard backlight up" })
hl.bind("code:237", hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight s 10-"), { description = "Keyboard backlight down" })
