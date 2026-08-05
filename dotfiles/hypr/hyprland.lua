-- Hyprland Lua config (migrated from hyprland.conf; the .conf files are kept
-- as a fallback reference until 0.57 removes hyprlang support).
-- When this file exists, Hyprland prefers it over hyprland.conf.

require("monitors")            -- Monitor setups and resolutions
require("conf/cursor")         -- Cursor theme and behavior
require("conf/environment")    -- Env vars for Wayland compatibility (NVIDIA)
require("colors")              -- Centralized color scheme definitions
require("conf/autostart")      -- Apps and services launched on startup
require("conf/window")         -- General window behavior and settings
require("conf/decoration")     -- Window decorations, shadows, and blurring
require("conf/layout")         -- Tiling layout behavior
require("workspaces")          -- Workspace specific settings and rules
require("conf/misc")           -- Miscellaneous settings and tweaks
require("conf/keybinding")     -- All keyboard shortcuts and keybinds
require("conf/keyboard")       -- Keyboard layout settings
require("conf/input")          -- Touchpad/input settings
require("conf/windowrule")     -- Rules for specific windows
require("conf/animation")      -- Animations for windows and workspaces
require("conf/user_config")    -- User-specific overrides
require("conf/custom")         -- Highly personalized, non-standard config
