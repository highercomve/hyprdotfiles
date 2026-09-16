#!/usr/bin/env bash

# Update the Sunshine AppImage in ~/.local/bin to the latest GitHub release
# (or a given tag). Sunshine is not packaged here: it is the official
# LizardByte AppImage, which is what init.sh's libva preload assumes.
#
#   update-sunshine.sh               # install latest (keeps .prev), restart service
#   update-sunshine.sh --check       # only report installed vs latest
#   update-sunshine.sh --no-restart  # swap the binary but leave the service running
#   update-sunshine.sh v2026.906.222525   # pin a specific release tag
#
# The running service keeps the old binary mapped until restarted, so the
# swap itself never interrupts an active stream; the restart (sudo) does.
# If a Moonlight client is connected it asks before restarting.

set -euo pipefail

BIN="$HOME/.local/bin/sunshine"
REPO="LizardByte/Sunshine"
ARCH="x86_64"
LOG="$HOME/.config/sunshine-seat1/sunshine.log"

check_only=0 restart=1 tag=""
for arg in "$@"; do
    case "$arg" in
        --check)   check_only=1 ;;
        --no-restart) restart=0 ;;
        -h|--help) sed -n '3,14p' "$0"; exit 0 ;;
        v*)        tag="$arg" ;;
        *) echo "unknown argument: $arg" >&2; exit 2 ;;
    esac
done

die() { echo "error: $*" >&2; exit 1; }

installed_version() {
    [ -x "$BIN" ] || { echo "none"; return; }
    "$BIN" --version 2>/dev/null | sed -n 's/.*Sunshine version: \([0-9.]*\).*/\1/p' | head -1
}

if [ -n "$tag" ]; then
    api="https://api.github.com/repos/$REPO/releases/tags/$tag"
else
    api="https://api.github.com/repos/$REPO/releases/latest"
fi

release_json=$(mktemp)
trap 'rm -f "$release_json"' EXIT
curl -fsSL -H 'Accept: application/vnd.github+json' -o "$release_json" "$api" \
    || die "could not query $api"

read -r tag url size digest < <(python3 - "$ARCH" "$release_json" <<'PY'
import json, sys
arch, path = sys.argv[1:3]
r = json.load(open(path))
for a in r["assets"]:
    if a["name"].endswith(f"_{arch}.AppImage"):
        print(r["tag_name"], a["browser_download_url"], a["size"], a.get("digest") or "-")
        break
else:
    sys.exit(f"no {arch} AppImage in release {r['tag_name']}")
PY
)

latest="${tag#v}"
current=$(installed_version)
echo "installed: $current"
echo "latest:    $latest"

if [ "$current" = "$latest" ]; then
    echo "already up to date"
    exit 0
fi
[ "$check_only" = 1 ] && exit 0

tmp=$(mktemp "${BIN}.download.XXXXXX")
trap 'rm -f "$tmp" "$release_json"' EXIT

echo "downloading $url"
curl -fL --progress-bar -o "$tmp" "$url"

actual_size=$(stat -c %s "$tmp")
[ "$actual_size" = "$size" ] || die "size mismatch: got $actual_size, expected $size"

if [ "$digest" != "-" ]; then
    want="${digest#sha256:}"
    got=$(sha256sum "$tmp" | cut -d' ' -f1)
    [ "$got" = "$want" ] || die "sha256 mismatch: got $got, expected $want"
    echo "sha256 ok"
else
    echo "warning: release has no digest, verified size only" >&2
fi

chmod 755 "$tmp"
new_version=$("$tmp" --version 2>/dev/null | sed -n 's/.*Sunshine version: \([0-9.]*\).*/\1/p' | head -1)
[ "$new_version" = "$latest" ] || die "downloaded binary reports '$new_version', expected $latest"

[ -x "$BIN" ] && cp -p "$BIN" "$BIN.prev"
mv -f "$tmp" "$BIN"
trap 'rm -f "$release_json"' EXIT
echo "installed $latest -> $BIN (previous kept as $BIN.prev)"

if systemctl is-active --quiet sunshine-seat1.service; then
    if [ "$restart" = 1 ]; then
        if [ -f "$LOG" ] && [ "$(grep -E 'CLIENT (CONNECTED|DISCONNECTED)' "$LOG" | tail -1 | grep -c CONNECTED)" = 1 ] \
           && ! grep -E 'CLIENT (CONNECTED|DISCONNECTED)' "$LOG" | tail -1 | grep -q DISCONNECTED; then
            echo "a Moonlight client is connected; restarting will drop the stream." >&2
            read -r -p "restart anyway? [y/N] " ans
            [ "$ans" = y ] || { echo "not restarted"; exit 0; }
        fi
        systemctl restart sunshine-seat1.service 2>/dev/null || sudo systemctl restart sunshine-seat1.service
        echo "sunshine-seat1.service restarted"
        # Input isolation depends on udev moving Sunshine's virtual input
        # devices to seat1 (72-sunshine-virtual-seat.rules matches them by
        # name: "(seat1)" for <= v2026.516, "libvirtualhid ..." / "Sunshine ..."
        # for >= v2026.906). A release that renames them again would silently
        # send remote input to the local seat0 desktop, so verify the devices
        # exist AND carry ID_SEAT=seat1 before trusting it.
        echo -n "checking Sunshine virtual input devices are on seat1"
        ok=0
        for _ in $(seq 1 30); do
            found=0 wrong=""
            for d in /sys/class/input/event*; do
                n=$(cat "$d/device/name" 2>/dev/null) || continue
                case "$n" in *"(seat1)"*|*libvirtualhid*|"Sunshine "*) ;; *) continue ;; esac
                found=1
                udevadm info -q property -p "$d" 2>/dev/null | grep -qx 'ID_SEAT=seat1' || wrong="$wrong\n  $n"
            done
            if [ "$found" = 1 ] && [ -z "$wrong" ]; then ok=1; break; fi
            echo -n .; sleep 1
        done
        echo
        if [ "$ok" = 1 ]; then
            echo "ok: Sunshine virtual input devices are assigned to seat1"
        else
            if [ "$found" = 0 ]; then
                echo "WARNING: no Sunshine virtual input devices found after restart — this release" >&2
                echo "         renamed them; update 72-sunshine-virtual-seat.rules to match." >&2
            else
                printf "WARNING: these Sunshine input devices are NOT on seat1 (remote input would hit the LOCAL desktop):%b\n" "$wrong" >&2
                echo "         Check 72-sunshine-virtual-seat.rules is installed and reloaded." >&2
            fi
            echo "         Roll back: mv $BIN.prev $BIN && systemctl restart sunshine-seat1.service" >&2
            exit 3
        fi
    else
        echo "sunshine-seat1.service still runs the old binary (--no-restart); restart with:"
        echo "  sudo systemctl restart sunshine-seat1.service"
    fi
fi
