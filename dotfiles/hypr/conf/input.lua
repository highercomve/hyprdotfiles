-- Touchpad/input settings (migrated from conf/input.conf).

hl.config({
    input = {
        touchpad = {
            -- Natural scrolling; disable trackpad while typing
            natural_scroll       = true,
            disable_while_typing = true,
        },
    },
})

-- Two-finger movement is reported as scroll by libinput. Hyprland's native
-- workspace swipe gesture therefore uses three fingers.
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
