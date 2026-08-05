#!/usr/bin/env bash

# -----------------------------------------------------
# Keybindings cheatsheet (SUPER+CTRL+K)
#
# Reads the LIVE compositor state via `hyprctl binds -j` instead of parsing
# config files, so it works with the Lua config and never goes stale.
# The shown text is each bind's `description` flag (set in
# conf/keybinding.lua); binds without one fall back to "dispatcher arg".
# -----------------------------------------------------

keybinds=$(hyprctl binds -j | jq -r '
    def mods($m):
        [ (if ($m / 64 | floor) % 2 == 1 then "SUPER" else empty end),
          (if ($m / 4  | floor) % 2 == 1 then "CTRL"  else empty end),
          (if ($m / 8  | floor) % 2 == 1 then "ALT"   else empty end),
          (if  ($m % 2)         == 1 then "SHIFT" else empty end) ];
    .[]
    | (mods(.modmask)
       + [ (if .key != "" then .key else "code:\(.keycode)" end) ]
       | join(" + ")) as $keys
    | (if .description != "" then .description
       else "\(.dispatcher) \(.arg)" end) as $desc
    | "\($keys)\r\($desc)"
')

sleep 0.2
rofi -dmenu -i -markup -eh 2 -replace -p "Keybinds" \
    -config ~/.config/rofi/config-compact.rasi <<<"$keybinds"
