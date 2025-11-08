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

# Get all available ttyUSB devices and their properties.
# Format: VENDOR PRODUCT (SERIAL) - /dev/ttyUSBX
# This formatted output is then piped to rofi for user selection.
ttyusb_list=""
for device in /dev/ttyUSB*; do
    # Check if the device file actually exists and is a character device
    if [ -c "$device" ]; then
        # Get udev properties. Using -q property for 'property' query, -n for 'name'.
        # We look for vendor, model, and serial identifiers.
        vendor=$(udevadm info -q property -n "$device" | grep '^ID_VENDOR=' | cut -d'=' -f2)
        model=$(udevadm info -q property -n "$device" | grep '^ID_MODEL=' | cut -d'=' -f2)

        serial=$(udevadm info -q property -n "$device" | grep '^ID_SERIAL_SHORT=' | cut -d'=' -f2)
        # Fallback for serial if ID_SERIAL_SHORT is not available
        if [ -z "$serial" ]; then
            serial=$(udevadm info -q property -n "$device" | grep '^ID_SERIAL=' | cut -d'=' -f2)
            # If ID_SERIAL is in VENDOR_PRODUCT_SERIAL format, try to extract just the serial part
            if echo "$serial" | grep -q '_'; then
                serial="${serial##*_}" # Optimized: use shell parameter expansion instead of sed
            fi
        fi

        display_name=""
        if [ -n "$vendor" ]; then
            display_name="$vendor"
        fi
        if [ -n "$model" ]; then
            if [ -n "$display_name" ]; then
                display_name="$display_name $model"
            else
                display_name="$model"
            fi
        fi

        formatted_line="$display_name"
        if [ -n "$serial" ]; then
            # If there's already a display name, add serial in parentheses
            if [ -n "$formatted_line" ]; then
                formatted_line="$formatted_line ($serial)"
            else # Otherwise, just the serial
                formatted_line="$serial"
            fi
        fi

        # If no descriptive info (vendor, model, serial) was found, just use the device name
        if [ -z "$formatted_line" ]; then
            formatted_line="$(basename "$device")"
        fi

        # Changed order to /dev/ttyUSBX - DESCRIPTION
        ttyusb_list="${ttyusb_list}$device - ${formatted_line}\n"
    fi
done

# Check if any ttyUSB devices were found
if [ -z "$ttyusb_list" ]; then
    echo "No ttyUSB devices found."
    # Optional: Send a notification if no devices are found
    if command -v notify-send &>/dev/null; then
        notify-send "No ttyUSB Devices" "No /dev/ttyUSB* devices were detected."
    fi
    exit 0
fi

# Use rofi to let the user select a ttyUSB device
selected_ttyusb_info=$(echo -e "$ttyusb_list" | rofi -config ~/.config/rofi/config-compact.rasi -dmenu -p "Select a ttyUSB device to copy /dev path:")

# Check if a device was selected by the user (i.e., rofi was not closed without selection)
if [ -n "$selected_ttyusb_info" ]; then
    # Extract the /dev/ttyUSBX part, which is consistently the last field in our formatted string.
    dev_path=$(echo "$selected_ttyusb_info" | awk '{print $NF}')

    # Copy the /dev path to the Wayland clipboard using wl-copy.
    if wl-copy "$dev_path"; then
        # Optional: Send a desktop notification for user feedback.
        if command -v notify-send &>/dev/null; then
            notify-send "ttyUSB /dev path copied" "Copied: $dev_path"
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
    echo "No ttyUSB device selected. Operation cancelled."
fi
