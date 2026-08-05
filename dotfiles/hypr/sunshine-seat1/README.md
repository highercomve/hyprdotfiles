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
- `bin/systemctl` + `bin/dbus-update-activation-environment`: PATH shims
  (prepended in `session.sh`) that keep this session out of the **shared**
  activation environment — see below.

### Activation-environment isolation

`systemd --user` and the dbus activation environment are per-**user**, not
per-seat, but Hyprland unconditionally publishes its own session into them at
startup (`systemctl --user import-environment DISPLAY WAYLAND_DISPLAY
HYPRLAND_INSTANCE_SIGNATURE ... && dbus-update-activation-environment
--systemd ...`) and clears them again on exit. With two compositors that is a
race the seat1 session must lose, because `xdg-desktop-portal-hyprland` is a
single per-user service that binds to whatever
`HYPRLAND_INSTANCE_SIGNATURE` it was activated with and **never re-attaches**.

Left alone it broke both directions:

- At boot the unit starts ~14s before the GDM login finishes, so the first
  portal request (Chrome) activated xdph against seat1. When this session
  exited 13s later, xdph spent the rest of the uptime polling a hung-up
  wayland socket — two threads at ~150% CPU — and the local desktop's portal
  was dead too (screen sharing fell back to a cross-GPU shm copy path).
- Toggling the session off mid-session ran `unset-environment` and wiped
  seat0's `WAYLAND_DISPLAY`/signature, breaking later dbus activations.

The shims swallow exactly those calls; both are needed, because Hyprland runs
them as one `&&` chain and `dbus-update-activation-environment --systemd`
forwards to the systemd manager on its own. This session needs neither: it is
captured through wlr-screencopy (`capture = wlr`) and never uses a portal.

On the seat0 side, `hypr/scripts/portal-rebind.sh` (run from
`conf/autostart.lua`) is the safety net: at login it restarts xdph if it finds
it bound to a foreign or dead instance.

Verify: with the stream session running,
`systemctl --user show-environment | grep HYPRLAND` must still show the seat0
signature, and `journalctl -t sunshine-seat1 | grep shim` shows the swallowed
calls.

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

- **Black screen on stream** (`Couldn't initialize va display: unknown libva
  error` in `~/.config/sunshine-seat1/sunshine.log`, then nvenc fallback with
  per-frame `GL: ... 00000502` errors): the AppImage's bundled libva is older
  than 2.24 and can't bind Mesa's driver (`__vaDriverInit_1_24` only), so
  vaapi dies and the cross-GPU nvenc fallback captures black. init.sh
  preloads the host libva (`LD_PRELOAD=/usr/lib/libva.so.2:...libva-drm.so.2`).
  Verify: `grep 'Found H.264 encoder' ~/.config/sunshine-seat1/sunshine.log`
  → `h264_vaapi [vaapi]`. (AV1 is absent: the Raphael iGPU has no AV1
  encoder — use HEVC/H.264 on the client.)
- **Steam dies with "requires user namespaces" / `bwrap: Unexpected
  capabilities but not setuid`, and quitting the stream hangs on `steam
  -shutdown`**: systemd ≥ 261's pam_systemd gives login sessions an ambient
  CAP_WAKE_ALARM; bwrap refuses to run with unexpected caps. session.sh drops
  all ambient caps via `setpriv --ambient-caps=-all` before starting the
  compositor (the pam_systemd `default-capability-ambient-set=` option can't
  express an empty set). Verify: `grep CapAmb
  /proc/$(systemctl show -p MainPID --value sunshine-seat1)/status` → zeros.
  Note: the MAIN session gets the same ambient cap on its next relogin —
  Steam/Proton/Flatpak launched there may break the same way (upstream
  systemd 261 change, not specific to this setup).
- **vaapi fails in seat0 shells** (`vainfo`, ffmpeg): the main Hyprland
  config exports `env = LIBVA_DRIVER_NAME,nvidia`
  (`hypr/conf/environment.conf`) but no libva-nvidia-driver is installed —
  the var only breaks probing. Remove it or install libva-nvidia-driver.
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
sudo ~/.config/hypr/sunshine-seat1/uninstall.sh
```

Reverts everything install.sh set up (service, udev seat rules, polkit rule,
desktop launcher, and the wired-preferred NM dispatcher if installed), plus the
seat0 half of the activation-environment fix: it deletes
`hypr/scripts/portal-rebind.sh` and strips its `exec-once` from
`conf/autostart.{lua,conf}`. The `bin/` shims need no reverting — they only
apply to `session.sh`, so they go away with this folder. The AMD iGPU returns
to seat0; user state in `~/.config/sunshine-seat1/` and the Sunshine binary are
kept.
