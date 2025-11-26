#!/bin/bash

# Rofi Bluetooth Manager using bluetoothctl
#
# This script uses bluetoothctl to interact with BlueZ.
# It's a rewrite to be more robust and reliable.
#
# Requires: bluetoothctl, rofi

# Rofi config file
ROFI_CONFIG="${HOME}/.config/rofi/config-nm.rasi"

# Check if bluetooth is powered on
is_powered() {
    bluetoothctl show | grep -q "Powered: yes"
}

# Check if a bluetooth agent is running
check_agent() {
    # We check for common agents. 
    # If using bluez, 'bluetoothctl' itself can be an agent if run interactively, 
    # but for a GUI script, we usually rely on a background agent like 'bt-agent' 
    # or a desktop environment's agent (e.g. blueman-applet, gnome-bluetooth).
    # However, checking for a specific process is brittle.
    # Instead, we can try to register a default agent with bluetoothctl and see if it fails,
    # or just warn the user if they experience pairing issues.
    
    # A better approach for this script might be to just rely on the user having one,
    # but adding a visual hint if we can detect it's missing would be nice.
    # For now, we'll skip a complex check and focus on making the pairing command robust.
    :
}

# Get device info
get_device_info() {
    mac="$1"
    info=$(bluetoothctl info "$mac")
    name=$(echo "$info" | grep "Name:" | cut -d ' ' -f 2-)
    alias=$(echo "$info" | grep "Alias:" | cut -d ' ' -f 2-)
    connected=$(echo "$info" | grep -q "Connected: yes" && echo "true" || echo "false")
    paired=$(echo "$info" | grep -q "Paired: yes" && echo "true" || echo "false")
    trusted=$(echo "$info" | grep -q "Trusted: yes" && echo "true" || echo "false")
    battery=$(echo "$info" | grep "Battery Percentage:" | awk -F'[()]' '{print $2}')

    # Use Alias if available, else Name
    if [ -n "$alias" ]; then
        display_name="$alias"
    else
        display_name="$name"
    fi
    
    echo "$display_name|$connected|$paired|$trusted|$battery"
}

# Main menu function
main_menu() {
    printf " Exit\n"

    if is_powered; then
        printf " Power Off\n"
        printf " Scan for new devices\n"

        echo "<b>Paired Devices</b>"

        # Get all known devices
        # Format: Device <MAC> <Name>
        # Note: 'paired-devices' command is not available on some versions, so we use 'devices' and filter.
        all_devices=$(bluetoothctl devices | grep "^Device")

        if [ -n "$all_devices" ]; then
            while read -r line; do
                mac=$(echo "$line" | awk '{print $2}')
                name=$(echo "$line" | cut -d ' ' -f 3-)
                
                # Get device info to check if paired
                info=$(bluetoothctl info "$mac")
                
                # Check if paired
                if echo "$info" | grep -q "Paired: yes"; then
                    if echo "$info" | grep -q "Connected: yes"; then
                        battery=$(echo "$info" | grep "Battery Percentage:" | awk -F'[()]' '{print $2}')
                        battery_str=""
                        if [ -n "$battery" ]; then
                            battery_str=" [🔋${battery}%]"
                        fi
                        echo " $name ($mac)${battery_str}"
                    else
                        echo " $name ($mac)"
                    fi
                fi
            done <<< "$all_devices"
        else
            echo "No devices found."
        fi
    else
        printf " Power On\n"
    fi
}

# Device menu function
device_menu() {
    device_mac="$1"
    device_name="$2"

    # Get fresh info
    info=$(bluetoothctl info "$device_mac")
    connected=$(echo "$info" | grep -q "Connected: yes" && echo "true" || echo "false")
    paired=$(echo "$info" | grep -q "Paired: yes" && echo "true" || echo "false")
    trusted=$(echo "$info" | grep -q "Trusted: yes" && echo "true" || echo "false")

    while true; do
        options=" Back\n"

        if [ "$connected" = "true" ]; then
            options+=" Disconnect\n"
        else
            options+=" Connect\n"
        fi

        if [ "$paired" = "true" ]; then
            options+=" Unpair\n"
        else
            options+=" Pair\n"
        fi

        if [ "$trusted" = "true" ]; then
            options+=" Distrust\n"
        else
            options+=" Trust\n"
        fi

        choice=$(echo -e "$options" | rofi -config "$ROFI_CONFIG" -dmenu -p "$device_name" -i -l 5)


        if ! pgrep -x "blueman-applet" > /dev/null; then
            echo "Starting blueman-applet..."
            blueman-applet &
            APPLET_PID=$!
            APPLET_STARTED_BY_SCRIPT=true
            # Give it a moment to start
            sleep 1
        fi

        case "$choice" in
        " Connect")
            bluetoothctl connect "$device_mac" >/dev/null

            ;;
        " Disconnect")
            bluetoothctl disconnect "$device_mac" >/dev/null
            ;;
        " Pair")
            # Pairing often requires an agent. 
            # We try to pair. If it fails, it might be due to missing agent or auth.
            # For a simple script, we can't easily handle interactive agent prompts in Rofi.
            # We rely on an external agent (like blueman-applet) being present.
            bluetoothctl pair "$device_mac" >/dev/null
            ;;
        " Unpair")
            bluetoothctl remove "$device_mac" >/dev/null
            return # Exit after unpairing
            ;;
        " Trust")
            bluetoothctl trust "$device_mac" >/dev/null
            ;;
        " Distrust")
            bluetoothctl untrust "$device_mac" >/dev/null
            ;;
        " Back")
            return
            ;;
        *) # Esc
            return
            ;;
        esac
        sleep 1

        if [ "$APPLET_STARTED_BY_SCRIPT" = "true" ]; then
            echo "Stopping blueman-applet..."
            kill $APPLET_PID 2>/dev/null
        fi

        # Refresh device info
        info=$(bluetoothctl info "$device_mac")
        connected=$(echo "$info" | grep -q "Connected: yes" && echo "true" || echo "false")
        paired=$(echo "$info" | grep -q "Paired: yes" && echo "true" || echo "false")
        trusted=$(echo "$info" | grep -q "Trusted: yes" && echo "true" || echo "false")
    done
}

# Ensure scanning stops when we exit this function
# Also stop blueman-applet if we started it
cleanup() {
    kill $BTCTL_PID 2>/dev/null
    bluetoothctl scan off > /dev/null 2>&1
    pkill -f "blueman-applet" 2>/dev/null
}


# Scan menu function
scan_menu() {
    # Check if blueman-applet is running
    APPLET_STARTED_BY_SCRIPT=false
    if ! pgrep -x "blueman-applet" > /dev/null; then
        echo "Starting blueman-applet..."
        blueman-applet &
        APPLET_PID=$!
        APPLET_STARTED_BY_SCRIPT=true
        # Give it a moment to start
        sleep 1
    fi

    # Start scanning in background using bluetoothctl
    # We use a subshell to keep bluetoothctl running with "scan on"
    (
        echo "scan on"
        while true; do sleep 10; done
    ) | bluetoothctl > /dev/null 2>&1 &
    BTCTL_PID=$!


    trap 'cleanup' RETURN

    while true; do
        # Get all devices from bluetoothctl
        # Output format: Device <MAC> <Name>
        all_devices=$(echo "devices" | bluetoothctl | grep "^Device")

        devices_list=""
        # Process each device
        while read -r line; do
            if [ -z "$line" ]; then continue; fi
            
            mac=$(echo "$line" | awk '{print $2}')
            name=$(echo "$line" | cut -d ' ' -f 3-)
            
            # Check if device is paired
            info=$(bluetoothctl info "$mac")
            if ! echo "$info" | grep -q "Paired: yes"; then
                 devices_list+=" $name ($mac)\n"
            fi
        done <<< "$all_devices"
        
        # Remove trailing newline
        devices_list=$(echo -e "$devices_list" | sed '/^$/d')

        # Show scanning indicator in the prompt
        choice=$(echo -e " Back\n Refresh\n$devices_list" | rofi -config "$ROFI_CONFIG" -dmenu -p "Scanning..." -i -l 10)

        case "$choice" in
        " Back")
            return
            ;;
        " Refresh")
            continue
            ;;
        "") # Esc
            return
            ;;
        *)
            # Extract MAC address from the choice string like "ICON Name (MAC)"
            # We use the content of the last set of parentheses to handle names with parens
            device_mac=$(echo "$choice" | awk -F'[()]' '{print $(NF-1)}')
            device_name=$(echo "$choice" | sed -E 's/^. (.*) \(.*\)$/\1/')
            
            if [ -n "$device_mac" ]; then
                if bluetoothctl pair "$device_mac" >/dev/null; then
                    bluetoothctl trust "$device_mac" >/dev/null
                    bluetoothctl connect "$device_mac" >/dev/null
                else
                     # If pairing fails, it might be because we need an agent or it timed out.
                     # We can try to trust and connect anyway, sometimes works for simple devices.
                     bluetoothctl trust "$device_mac" >/dev/null
                     bluetoothctl connect "$device_mac" >/dev/null
                fi
                cleanup
            fi
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
            device_mac=$(echo "$choice" | awk -F'[()]' '{print $(NF-1)}')
            device_name=$(echo "$choice" | sed -E 's/^. (.*) \(.*\).*$/\1/')
            
            if [ -n "$device_mac" ]; then
                device_menu "$device_mac" "$device_name"
            fi
        else
            exit 0
        fi
        ;;
    esac
done
