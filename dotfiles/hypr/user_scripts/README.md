# User Scripts

This directory contains a collection of utility scripts designed to be used with Hyprland.

## `disks.sh`

A utility to manage disk devices. It allows you to select a disk, and then choose to either copy its device path or format it.

**Video demonstration:** [https://youtu.be/jM4sE7jS1Xk](https://youtu.be/jM4sE7jS1Xk)

### Features

- Lists all available physical disk devices.
- Interactive selection using `rofi`.
- Actions available:
    - **Copy path**: Copies the device path (e.g., `/dev/sda`) to the clipboard.
    - **Format disk**: Opens a new terminal to format the selected disk. This action requires `sudo` privileges.

### Dependencies

- `rofi`
- `wl-copy` (from `wl-clipboard`)
- `lsblk` (from `util-linux`)
- `notify-send` (optional, for notifications)
- A terminal emulator configured in `~/.config/hypr/user_settings/terminal.sh`.

### Usage

Simply execute the script. It is intended to be bound to a hotkey in your Hyprland configuration.

```sh
./disks.sh
```

## `ttyusb.sh`

A utility for managing `ttyUSB` serial devices. It allows you to select a device and then choose to either copy its path or open a serial console.

**Video demonstration:** [https://youtu.be/SoM7voD3kRk](https://youtu.be/SoM7voD3kRk)

### Features

- Lists all connected `ttyUSB` devices with descriptive names (vendor, model, serial).
- Interactive selection using `rofi`.
- Actions available:
    - **Copy path**: Copies the device path (e.g., `/dev/ttyUSB0`) to the clipboard.
    - **Open console**: Opens a new terminal with a `picocom` serial console connected to the selected device.

### Dependencies

- `rofi`
- `wl-copy` (from `wl-clipboard`)
- `udevadm` (from `systemd`)
- `picocom`
- `notify-send` (optional, for notifications)
- A terminal emulator configured in `~/.config/hypr/user_settings/terminal.sh`.

### Usage

Execute the script. It is best used when bound to a hotkey.

```sh
./ttyusb.sh
```
