-- Window behavior settings (migrated from conf/window.conf).

local colors = require("colors")

-- "rgb(RRGGBB)" -> "rgba(RRGGBBAA)"
local function with_alpha(color, alpha)
    return (color:gsub("^rgb%(", "rgba("):gsub("%)$", alpha .. ")"))
end

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 5,
        border_size = 0,
        col = {
            active_border   = with_alpha(colors.color4, "FF"),
            inactive_border = with_alpha(colors.color0, "FF"),
        },
        layout           = "dwindle",
        resize_on_border = true,
    },
    -- Window groups (SUPER+G): make the tab bar actually visible.
    group = {
        col = {
            border_active   = colors.color4,
            border_inactive = colors.color0,
        },
        groupbar = {
            enabled       = true,
            height        = 26,
            render_titles = true,
            font_family   = "Fira Sans",
            font_size     = 12,
            gradients     = true,
            rounding      = 6,
            gaps_in       = 3,
            gaps_out      = 4,
            col = {
                active   = colors.color4,                    -- focused tab: light blue
                inactive = with_alpha(colors.color0, "E6"),  -- other tabs: dim gray, slightly translucent
            },
            text_color          = colors.background, -- dark text on the light blue tab
            text_color_inactive = colors.foreground,
        },
    },
})
