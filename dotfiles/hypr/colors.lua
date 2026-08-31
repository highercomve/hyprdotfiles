-- Color scheme definitions (migrated from colors.conf).
-- Usage from any config file:
--   local colors = require("colors")
--   hl.config({ general = { col = { active_border = colors.color4 } } })
--
-- The static values below are the defaults. If the theme system has generated
-- ~/.cache/theme-colors/hyprland.lua (see themes/apply-palette.sh), its values
-- override them, so `hyprctl reload` follows the active theme.

local colors = {
    background = "rgb(242F41)",
    foreground = "rgb(D9E0EE)",
    color0     = "rgb(494D64)",
    color1     = "rgb(F28FAD)",
    color2     = "rgb(ABE9B3)",
    color3     = "rgb(FAE3B0)",
    color4     = "rgb(96CDFB)",
    color5     = "rgb(F5C2E7)",
    color6     = "rgb(89DCEB)",
    color7     = "rgb(CBA6F7)",
}

local home = os.getenv and os.getenv("HOME")
if home then
    local ok, override = pcall(dofile, home .. "/.cache/theme-colors/hyprland.lua")
    if ok and type(override) == "table" then
        for k, v in pairs(override) do
            colors[k] = v
        end
    end
end

return colors
