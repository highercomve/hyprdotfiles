#!/bin/bash

# Configuration
ROFI_CONFIG="${HOME}/.config/rofi/config-compact.rasi"
IMPL_SCRIPT="${HOME}/.config/hypr/scripts/flash_impl.sh"

# Function to send notification
notify() {
    if command -v notify-send &>/dev/null; then
        notify-send "Flash USB" "$1"
    fi
}

# Check dependencies
for cmd in rofi fd lsblk awk; do
    if ! command -v "$cmd" &>/dev/null; then
        notify "Error: '$cmd' is not installed."
        exit 1
    fi
done

# 1. Select Image
# Use fd to find .img and .img.gz files in /home
# -t f: files only
# --regex: match extension
# --exclude: ignore specified directories to avoid irrelevant files from development/cache folders

# Define exclude patterns as an array
declare -a EXCLUDE_PATTERNS=(
    'go'
    '.cache'
    '.local/share'
    '.npm'
    '.cargo'
    '.rustup'
    '.vscode'
    'node_modules'
)

# Build the fd command arguments dynamically
# Add '--exclude' before each pattern
declare -a FD_EXCLUDE_ARGS=()
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    FD_EXCLUDE_ARGS+=('--exclude' "$pattern")
done

IMAGES=$(fd --type f --regex '(\.img(\.(gz|xz|bz2))?|\.wic(\.(gz|xz|bz2))?|-(?i)(wrynose|whinlatter|scarthgap|kirkstone)\.zip)$' "${HOME}" "${FD_EXCLUDE_ARGS[@]}" 2>/dev/null)

if [ -z "$IMAGES" ]; then
    notify "No .img, .img.gz or .wic files found in /home"
    exit 0
fi

SELECTED_IMAGE=$(echo "$IMAGES" | rofi -config "$ROFI_CONFIG" -dmenu -i -p "Select Image")

if [ -z "$SELECTED_IMAGE" ]; then
    exit 0
fi

# 2. Select Target Device
if [ -n "$1" ]; then
    DEVICE="$1"
else
    # Get all available disk devices (type "disk", not partitions or loop devices).
    # Exclude loop devices (7) and RAM disks (11).
    # Format: MODEL (SIZE) - /dev/NAME
    DEVICES=$(lsblk -o NAME,SIZE,TYPE,VENDOR,MODEL -d -e 7,11 --noheadings |
        awk '
            $3 == "disk" {
                name = $1;
                size = $2;
                type = $3;
                vendor = $4; # Get the vendor from the 4th field
                model = "";
                # Reconstruct model name in case it contains spaces.
                # lsblk outputs model as the 5th field onwards now (after NAME, SIZE, TYPE, VENDOR).
                for (i = 5; i <= NF; i++) {
                    model = model (i == 5 ? "" : " ") $i;
                }

                # Build the display name, combining vendor and model with a space if both exist
                display_name = "";
                if (vendor != "") {
                    display_name = vendor;
                }
                if (model != "") {
                    if (display_name != "") {
                        display_name = display_name " " model;
                    } else {
                        display_name = model;
                    }
                }

                # Print the final formatted string: VENDOR MODEL (SIZE) - /dev/NAME
                print display_name " (" size ") - /dev/" name;
            }
        ')

    if [ -z "$DEVICES" ]; then
        notify "No storage devices found."
        exit 0
    fi

    SELECTED_DEVICE_LINE=$(echo "$DEVICES" | rofi -config "$ROFI_CONFIG" -dmenu -i -p "Select Drive")

    if [ -z "$SELECTED_DEVICE_LINE" ]; then
        exit 0
    fi

    # Extract device path (last column)
    DEVICE=$(echo "$SELECTED_DEVICE_LINE" | awk '{print $NF}')
fi

# 3. Launch Terminal for Flashing
if [ ! -f "$IMPL_SCRIPT" ]; then
    notify "Error: Helper script not found at $IMPL_SCRIPT"
    exit 1
fi

# Ensure executable
chmod +x "$IMPL_SCRIPT" 2>/dev/null

# Get terminal command from user settings or default to ghostty
TERMINAL_CMD="alacritty"
# if [ -f "${HOME}/.config/hypr/user_settings/terminal.sh" ]; then
#     TERMINAL_CMD=$(cat "${HOME}/.config/hypr/user_settings/terminal.sh")
# fi

# Execute in terminal
# We use 'sudo' to run the implementation script as root.
# The terminal window title is set to "Flash USB".
$TERMINAL_CMD --title "Flash USB" --class dotfiles-floating-sm -e sudo "$IMPL_SCRIPT" "$SELECTED_IMAGE" "$DEVICE"
