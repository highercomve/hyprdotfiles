#!/bin/bash

# Rofi Bluetooth Manager
#
# Based on the structure of the rofi-network-manager.sh script.
# This script uses bluetoothctl to manage Bluetooth devices.
#
# Ensure you have a Rofi theme for it, for example, by creating
# ~/.config/rofi/config-bluetooth.rasi
# You can copy and adapt it from an existing theme.

# Rofi config file
ROFI_CONFIG="${HOME}/.config/rofi/config-nm.rasi"

# Main menu function
main_menu() {
    printf " Exit\n"

    # Check if bluetooth is powered on
    if bluetoothctl show | grep -q "Powered: yes"; then
        printf " Power Off\n"
        printf " Scan for new devices\n"

        echo "<b>Paired Devices</b>"
        paired_devices=$(bluetoothctl devices Paired)
        if [ -n "$paired_devices" ]; then
            echo "$paired_devices" | while read -r line; do
                device_mac=$(echo "$line" | awk '{print $2}')
                device_name=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^ *//')
                device_info=$(bluetoothctl info "$device_mac")

                if echo "$device_info" | grep -q "Connected: yes"; then
                    battery_percentage=""
                    if echo "$device_info" | grep -q "Battery Percentage"; then
                        battery_level=$(echo "$device_info" | grep "Battery Percentage" | grep -oP '\(\K[0-9]+')
                        if [ -n "$battery_level" ]; then
                            battery_percentage=" [🔋${battery_level}%]"
                        fi
                    fi
                    echo " $device_name ($device_mac)${battery_percentage}"
                else
                    echo " $device_name ($device_mac)"
                fi
            done
        else
            echo "No paired devices found."
        fi
    else
        printf " Power On\n"
    fi
}

# Device menu function
device_menu() {
    device_mac="$1"
    device_name=$(bluetoothctl info "$device_mac" | grep "Name:" | cut -d ' ' -f 2-)

    while true; do
        options=" Back\n"

        if bluetoothctl info "$device_mac" | grep -q "Connected: yes"; then
            options+=" Disconnect\n"
        else
            options+=" Connect\n"
        fi

        if bluetoothctl info "$device_mac" | grep -q "Paired: yes"; then
            options+=" Unpair\n"
        else
            # This case should ideally not be reached from the main menu for paired devices
            options+=" Pair\n"
        fi

        if bluetoothctl info "$device_mac" | grep -q "Trusted: yes"; then
            options+=" Distrust\n"
        else
            options+=" Trust\n"
        fi

        choice=$(echo -e "$options" | rofi -config "$ROFI_CONFIG" -dmenu -p "$device_name" -i -l 5)

        case "$choice" in
        " Connect")
            bluetoothctl connect "$device_mac"
            ;;
        " Disconnect")
            bluetoothctl disconnect "$device_mac"
            ;;
        " Pair")
            bluetoothctl pair "$device_mac"
            ;;
        " Unpair")
            bluetoothctl remove "$device_mac"
            return # Exit after unpairing
            ;;
        " Trust")
            bluetoothctl trust "$device_mac"
            ;;
        " Distrust")
            bluetoothctl untrust "$device_mac"
            ;;
        " Back")
            return
            ;;
        *) # Esc
            return
            ;;
        esac
    done
}

# Scan menu function
scan_menu() {
    while true; do
        (
            echo "Scanning for devices..."
            tail -f /dev/null
        ) | rofi -config "$ROFI_CONFIG" -dmenu -p "Bluetooth Scan" &
        rofi_pid=$!

        # Start scanning, wait, then get devices
        (
            bluetoothctl scan on >/dev/null &
            sleep 5
            bluetoothctl scan off >/dev/null
        )

        kill "$rofi_pid"
        wait "$rofi_pid" 2>/dev/null

        # Get non-paired devices
        devices_list=$(bluetoothctl devices | while read -r line; do
            device_mac=$(echo "$line" | awk '{print $2}')
            device_name=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^ *//')
            if ! bluetoothctl info "$device_mac" | grep -q "Paired: yes"; then
                echo " $device_name ($device_mac)"
            fi
        done)

        choice=$(echo -e " Back\n Rescan\n$devices_list" | rofi -config "$ROFI_CONFIG" -dmenu -p "Scan Results" -i -l 10)

        case "$choice" in
        " Back")
            return
            ;;
        " Rescan")
            continue
            ;;
        "") # Esc
            return
            ;;
        *)
            device_mac=$(echo "$choice" | awk -F'[()]' '{print $2}')
            if [ -n "$device_mac" ]; then
                # Attempt to pair and trust.
                # Note: Pairing might require user interaction on the command line
                # if a PIN is needed.
                if bluetoothctl pair "$device_mac"; then
                    bluetoothctl trust "$device_mac"
                    bluetoothctl connect "$device_mac"
                fi
            fi
            # After action, return to main menu
            return
            ;;
        esac
    done
}

# Main loop
while true; do
    choice=$(main_menu | rofi -config "$ROFI_CONFIG" -dmenu -p "Bluetooth" -markup-rows -i -l 10)

    case "$choice" in
    " Exit")
        exit 0
        ;;
    " Power On")
        bluetoothctl power on
        ;;
    " Power Off")
        bluetoothctl power off
        ;;
    " Scan for new devices")
        scan_menu
        ;;
    "") # Esc
        exit 0
        ;;
    *)
        if [ -n "$choice" ]; then
            # Extract MAC address from the choice string like "ICON Name (MAC)"
            device_mac=$(echo "$choice" | awk -F'[()]' '{print $2}')
            if [ -n "$device_mac" ]; then
                device_menu "$device_mac"
            fi
        else
            exit 0
        fi
        ;;
    esac
done
