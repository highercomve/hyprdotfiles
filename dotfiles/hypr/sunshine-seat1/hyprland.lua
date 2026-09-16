-- Minimal Hyprland Lua config for the headless seat1 streaming session.
-- This instance never touches the physical monitor — it only drives the
-- virtual display that Sunshine captures. Deliberately does NOT source the
-- main config (no bars, no listeners, no wallpaper daemons).

hl.monitor({
    output   = "HEADLESS-1",
    mode     = "1920x1200@120",
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

-- Sunshine is NOT started from here: Hyprland lowers its ambient
-- capabilities at startup, so anything it spawns can never hold the
-- CAP_SYS_NICE that Sunshine's high-priority encoder context needs.
-- session.sh starts init.sh as a sibling instead; this hook only publishes
-- the compositor's env (WAYLAND_DISPLAY etc.) to tell it we are ready.
hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/sunshine-seat1/ready.sh")
end)
