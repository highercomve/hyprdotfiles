#!/bin/bash

IMAGE="$1"
DEVICE="$2"

# Check if bmaptool is available
if command -v bmaptool &>/dev/null; then
    USE_BMAPTOOL=true
    echo "Using bmaptool for flashing."
else
    USE_BMAPTOOL=false
    echo "bmaptool not found, falling back to dd."
fi

# Basic validation
if [ -z "$IMAGE" ] || [ -z "$DEVICE" ]; then
    echo "Usage: $0 <image_path> <device_path>"
    echo "Press Enter to exit."
    read
    exit 1
fi

# Verify device availability
if [ ! -b "$DEVICE" ]; then
    echo "Error: Device $DEVICE is not a block device or not found."
    echo "Press Enter to exit."
    read
    exit 1
fi

# Display Information
clear
echo "========================================================"
echo "           USB FLASHING UTILITY                         "
echo "========================================================"
echo "Image : $IMAGE"
echo "Device: $DEVICE"
echo "--------------------------------------------------------"
lsblk -d -o NAME,MODEL,SIZE,TRAN,TYPE "$DEVICE"
echo "--------------------------------------------------------"
echo "WARNING: ALL DATA ON $DEVICE WILL BE PERMANENTLY LOST."
echo "========================================================"
echo ""
echo "Press [Enter] to CONFIRM and START flashing."
echo "Press [Ctrl+C] to CANCEL."
read

# Unmount partitions
echo "Step 1: Unmounting partitions on $DEVICE..."
# List partitions (excluding the device itself) and unmount them
for part in $(lsblk -ln -o NAME "$DEVICE" | grep -v "^$(basename "$DEVICE")$"); do
    echo "  - Unmounting /dev/$part"
    umount "/dev/$part" 2>/dev/null
done

# Determine flash method
echo "Step 2: Flashing image..."
START_TIME=$(date +%s)

if [ "$USE_BMAPTOOL" = true ]; then
    echo "  - Using bmaptool to copy image."

    bmaptool copy "$IMAGE" "$DEVICE" --nobmap
else
    if [[ "$IMAGE" == *.gz ]]; then
        echo "  - Detected gzip compressed image. Using dd."
        gunzip -c "$IMAGE" | dd of="$DEVICE" bs=4M status=progress conv=fsync
    else
        echo "  - Using dd to copy image."
        dd if="$IMAGE" of="$DEVICE" bs=4M status=progress conv=fsync
    fi
fi

# Sync
echo "Step 3: Syncing buffers (do not remove device yet)..."
sync

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "========================================================"
echo "SUCCESS! Flashing completed in ${DURATION}s."
echo "You may now safely remove the device."
echo "========================================================"
echo "Press [Enter] to close this window."
read
