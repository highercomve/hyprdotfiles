# sunshine-seat1 — isolated remote game streaming

Streams games via Sunshine/Moonlight on a **fully isolated second session**, so a
remote player and the local desktop can be used **at the same time** without
sharing keyboard, mouse, cursor, or display.

## Architecture

```
seat0 (local, untouched)              seat1 (remote stream)
├─ Hyprland on RTX 4070 → DP-1        ├─ headless Hyprland on AMD iGPU
├─ physical keyboard/mouse            ├─ virtual display HEADLESS-1
└─ your normal workflow               ├─ Sunshine (port 48989, capture=wlr,
                                      │            encoder=vaapi on iGPU VCN)
                                      └─ input: Sunshine's uinput devices,
                                         named "(seat1)", moved to seat1 by
                                         udev — invisible to seat0
```

- `sunshine-seat1.service` (system unit): `PAMName=login` + `XDG_SEAT=seat1`
  creates a logind session on seat1 (no VT — always active, never competes
  with the local session) and runs `session.sh` → headless Hyprland.
- `init.sh` (exec-once inside that Hyprland): creates the `HEADLESS-1` virtual
  display, disables the FALLBACK output, starts Sunshine with `sunshine.conf`.
- `72-sunshine-virtual-seat.rules`: moves Sunshine's virtual input devices
  (named `... (seat1)`, requires Sunshine ≥ v2026.516) and the AMD iGPU's DRM
  device to seat1.
- `resize.sh` (global_prep_cmd): resizes `HEADLESS-1` to the Moonlight
  client's resolution/FPS on connect.
- Games render on the RTX 4070 via its render node (render nodes are not
  seat-gated); the iGPU handles compositing + VAAPI encoding (zero-copy).

## Install

```bash
sudo ~/.config/hypr/sunshine-seat1/install.sh
```

Then pair Moonlight: web UI at `https://<host>:48990`, add host `<host>:48989`.
This instance is fully separate from any Sunshine you run manually in the main
session (different ports, state in `~/.config/sunshine-seat1/`).

## Operate

```bash
systemctl status  sunshine-seat1    # health
journalctl -u sunshine-seat1 -f     # logs (compositor + sunshine)
systemctl stop    sunshine-seat1    # kill the remote session
systemctl disable sunshine-seat1    # don't start at boot
```

## Verify isolation

- `loginctl list-sessions` → a session for sergiom on **seat1**.
- While a Moonlight client is connected and moving the mouse, the local seat0
  cursor must not move.
- `libinput list-devices` in the seat1 session shows only `... (seat1)` devices.

## Troubleshooting

- **Service crashes with "CBackend::create() failed! / no allocator"**: the
  iGPU didn't land on seat1. Check `loginctl seat-status seat1` lists the DRM
  device; re-run `sudo udevadm trigger -s drm`.
- **Session lands on seat0 instead of seat1** (`loginctl list-sessions`):
  pam_systemd didn't pick up `XDG_SEAT` — check the unit's `Environment=`
  lines survived and `/etc/pam.d/login` includes `pam_systemd.so` (Arch:
  via `system-login`).
- **Remote input does nothing**: Sunshine's devices weren't renamed/moved.
  `cat /proc/bus/input/devices | grep seat1` should list them while a client
  is connected; confirm `XDG_SEAT=seat1` is in the sunshine process env
  (`cat /proc/$(pgrep -f sunshine-seat1)/environ | tr '\0' '\n' | grep SEAT`).
- **Game renders on the iGPU (bad FPS)**: force the dGPU per game, e.g. Steam
  launch options `DXVK_FILTER_DEVICE_NAME="NVIDIA" %command%` or
  `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia %command%`.
- **Machine asleep when remote**: suspend-on-monitor-off was removed for
  exactly this reason; if you ever re-add suspend, you'll need Wake-on-LAN
  (Moonlight has a built-in "Wake PC" button).

## Network: prefer ethernet over WiFi

The stream uses whichever IP the Moonlight client targets. With both NICs up
(ethernet `192.168.68.128`, WiFi `192.168.68.127`, same subnet) mDNS discovery
may hand Moonlight the WiFi address — add the host manually by the ethernet IP.

Optional (not part of install.sh, since it changes networking globally):
`99-wired-preferred` is a NetworkManager dispatcher that turns WiFi off while
the ethernet cable is connected and back on when unplugged:

```bash
sudo install -m 755 ~/.config/hypr/sunshine-seat1/99-wired-preferred \
    /etc/NetworkManager/dispatcher.d/
```

## Uninstall

```bash
sudo systemctl disable --now sunshine-seat1
sudo rm /etc/systemd/system/sunshine-seat1.service \
        /etc/udev/rules.d/72-sunshine-virtual-seat.rules
sudo systemctl daemon-reload
sudo udevadm control --reload-rules && sudo udevadm trigger
```
