#!/usr/bin/env python3
"""Self-heal ntfs-3g IntxLNK pseudo-symlinks in the Steam library.

The NTFS game drive must be mounted with the kernel ntfs3 driver (pinned in
/etc/fstab). Symlinks created while it was mounted with ntfs-3g instead use
that driver's private Interix format (b"IntxLNK\\x01" + UTF-16LE target) and
appear under ntfs3 as opaque regular files. A Proton prefix link in that
state kills a game within a second of launch (NotADirectoryError on
pfx.lock), which over a stream just looks like the game refusing to start.

Run at seat1 session start (init.sh). Only scans the top level of compatdata
so it stays instant; it is not a substitute for the one-time bulk conversion
of the whole drive.
"""
import os
import sys

LIBRARY = "/run/media/sergiom/92A816A5A81687BD/Games/steamapps"
MAGIC = b"IntxLNK\x01"


def convert(path: str) -> str | None:
    """Return the decoded target if path was an IntxLNK file (now converted)."""
    if os.path.islink(path) or not os.path.isfile(path):
        return None
    if os.path.getsize(path) > 4096:
        return None
    with open(path, "rb") as f:
        data = f.read()
    if not data.startswith(MAGIC):
        return None
    target = data[len(MAGIC):].decode("utf-16-le", errors="strict")
    if not target or "\x00" in target:
        return None
    os.unlink(path)
    os.symlink(target, path)
    return target


def main() -> int:
    compatdata = os.path.join(LIBRARY, "compatdata")
    if not os.path.isdir(compatdata):
        print(f"library not mounted, skipping: {compatdata}")
        return 0
    fixed = 0
    for name in os.listdir(compatdata):
        path = os.path.join(compatdata, name)
        try:
            target = convert(path)
        except OSError as e:
            print(f"ERROR {path}: {e}")
            continue
        if target is not None:
            print(f"fixed {name} -> {target}")
            fixed += 1
    print(f"checked compatdata, fixed {fixed} broken link(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
