#!/bin/bash

# Colors are baked into the bundle from _colors.scss, a symlink to
# ~/.cache/theme-colors/ags-colors.scss. Seed a default palette (Mocha)
# if the theme system hasn't generated one yet.
if [ ! -f "$HOME/.cache/theme-colors/ags-colors.scss" ]; then
    "$HOME/.config/themes/apply-palette.sh" \
        "$HOME/.config/themes/palettes/modern.json" --generate-only
fi

ags bundle --gtk 4 app.ts statusbar
