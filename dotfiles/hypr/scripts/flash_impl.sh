#!/bin/bash

IMAGE="$1"
DEVICE="$2"

# Check if pvflasher is available
if command -v pvflasher &>/dev/null || [ -x "/usr/local/bin/pvflasher" ] || [ -x "$HOME/.local/bin/pvflasher" ]; then
	USE_PVFLASHER=true
	echo "Using pvflasher for flashing."
elif command -v bmaptool &>/dev/null; then
	USE_BMAPTOOL=true
	echo "Using bmaptool for flashing."
else
	USE_PVFLASHER=false
	USE_BMAPTOOL=false
	echo "pvflasher/bmaptool not found, falling back to dd."
fi

# Basic validation
if [ -z "$IMAGE" ] || [ -z "$DEVICE" ]; then
	echo "Usage: $0 <image_path> <device_path>"
	echo "Press Enter to exit."
	read -r
	exit 1
fi

# Check validation
if [ ! -b "$DEVICE" ]; then
	echo "Error: Device $DEVICE is not a block device or not found."
	echo "Press Enter to exit."
	read -r
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
read -r

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

# Look for bmap file in the same directory as the image
BMAP_FILE=""
IMAGE_DIR=$(dirname "$IMAGE")
IMAGE_BASE=$(basename "$IMAGE" | sed 's/\.wic.*$//')
for ext in "" ".bz2" ".gz" ".xz"; do
	if [ -f "${IMAGE_DIR}/${IMAGE_BASE}.wic${ext}.bmap" ]; then
		BMAP_FILE="${IMAGE_DIR}/${IMAGE_BASE}.wic${ext}.bmap"
		break
	elif [ -f "${IMAGE_DIR}/${IMAGE_BASE}.bmap" ]; then
		BMAP_FILE="${IMAGE_DIR}/${IMAGE_BASE}.bmap"
		break
	fi
done

if [ "$USE_PVFLASHER" = true ]; then
	echo "  - Using pvflasher to copy image (supports compressed images)."
	if [ -n "$BMAP_FILE" ]; then
		echo "  - Found bmap file: $BMAP_FILE"
		pvflasher copy "$IMAGE" "$DEVICE" --bmap "$BMAP_FILE"
	else
		pvflasher copy "$IMAGE" "$DEVICE"
	fi
elif [ "$USE_BMAPTOOL" = true ]; then
	echo "  - Using bmaptool to copy image."
	if [ -n "$BMAP_FILE" ]; then
		echo "  - Found bmap file: $BMAP_FILE"
		bmaptool copy --bmap "$BMAP_FILE" "$IMAGE" "$DEVICE"
	else
		echo "  - No bmap file found, copying raw image."
		bmaptool copy --nobmap "$IMAGE" "$DEVICE"
	fi
else
	if [[ "$IMAGE" == *.gz ]]; then
		echo "  - Detected gzip compressed image. Using dd."
		gunzip -c "$IMAGE" | dd of="$DEVICE" bs=4M status=progress conv=fsync
	elif [[ "$IMAGE" == *.xz ]]; then
		echo "  - Detected xz compressed image. Using dd."
		xz -c -d "$IMAGE" | dd of="$DEVICE" bs=4M status=progress conv=fsync
	elif [[ "$IMAGE" == *.bz2 ]]; then
		echo "  - Detected bzip2 compressed image. Using dd."
		bzip2 -c -d "$IMAGE" | dd of="$DEVICE" bs=4M status=progress conv=fsync
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
read -r
