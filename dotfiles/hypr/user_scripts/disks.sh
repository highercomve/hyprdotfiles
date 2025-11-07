#!/bin/bash

# Ensure rofi and wl-copy are available
if ! command -v rofi &>/dev/null; then
    echo "Error: rofi is not installed. Please install it to use this script."
    exit 1
fi

if ! command -v wl-copy &>/dev/null; then
    echo "Error: wl-copy is not installed. Please install it to use this script."
    exit 1
fi

# Get all available disk devices (type "disk", not partitions or loop devices).
# Exclude loop devices (7) and RAM disks (11) as they are typically not physical disks.
# Format: MODEL (SIZE) - /dev/NAME
# This formatted output is then piped to rofi for user selection.
selected_disk_info=$(lsblk -o NAME,SIZE,TYPE,VENDOR,MODEL -d -e 7,11 --noheadings |
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
    ' | rofi -dmenu -p "Select a disk to copy /dev path:")

# Check if a disk was selected by the user (i.e., rofi was not closed without selection)
if [ -n "$selected_disk_info" ]; then
    # Extract the /dev/NAME part, which is consistently the last field in our formatted string.
    dev_path=$(echo "$selected_disk_info" | awk '{print $NF}')

    # Copy the /dev path to the Wayland clipboard using wl-copy.
    if wl-copy "$dev_path"; then
        # Optional: Send a desktop notification for user feedback.
        if command -v notify-send &>/dev/null; then
            notify-send "Disk /dev path copied" "Copied: $dev_path"
        fi
    else
        echo "Error: Failed to copy '$dev_path' to clipboard. wl-copy might have failed."
        # Optional: Send an error notification.
        if command -v notify-send &>/dev/null; then
            notify-send -u critical "Clipboard Error" "Failed to copy '$dev_path' to clipboard."
        fi
    fi
else
    # User closed rofi or did not make a selection.
    echo "No disk selected. Operation cancelled."
fi
