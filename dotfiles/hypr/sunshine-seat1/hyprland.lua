-- Minimal Hyprland Lua config for the headless seat1 streaming session.
-- This instance never touches the physical monitor — it only drives the
-- virtual display that Sunshine captures. Deliberately does NOT source the
-- main config (no bars, no listeners, no wallpaper daemons).

hl.monitor({
    output   = "HEADLESS-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1,
})

hl.config({
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        background_color         = 0x1e1e2e,
        -- never blank/lock the virtual display mid-stream
        mouse_move_enables_dpms  = true,
        key_press_enables_dpms   = true,
    },

    animations = {
        enabled = false,
    },

    decoration = {
        blur   = { enabled = false },
        shadow = { enabled = false },
    },

    input = {
        kb_layout    = "us",
        follow_mouse = 1,
    },
})

-- Games should just fill the virtual display.
hl.window_rule({
    name       = "steam-games-fullscreen",
    match      = { class = "(steam_app_.*)" },
    fullscreen = true,
})

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/sunshine-seat1/init.sh")
end)
