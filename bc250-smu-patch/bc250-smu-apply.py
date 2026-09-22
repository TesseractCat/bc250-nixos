#!@PYTHON@
import os
import sys

sys.path.insert(0, "@SITE@")

from bc250_smu import Bc250Smu
from bc250_smu.errors import SmuError
from patcher import read_hex
from unlock import unlock

ESCAPE = "bc250.nosmupatch"
HEX_PATH = "@HEX@"


def _cmdline_has(token):
    try:
        with open("/proc/cmdline") as f:
            return token in f.read().split()
    except OSError:
        return False


def main():
    if os.geteuid() != 0:
        print("bc250-smu-apply: needs root", file=sys.stderr)
        return 1

    if _cmdline_has(ESCAPE):
        print(f"bc250-smu-apply: disabled via {ESCAPE}")
        return 0

    if not os.path.exists(HEX_PATH):
        print(f"bc250-smu-apply: patches.hex not found ({HEX_PATH})", file=sys.stderr)
        return 1

    patches = read_hex(HEX_PATH)
    if not patches:
        print("bc250-smu-apply: no patches parsed from hex", file=sys.stderr)
        return 1

    smu = Bc250Smu()
    try:
        if not smu.alive():
            print("bc250-smu-apply: SMU not alive - cold power cycle", file=sys.stderr)
            return 1

        if not smu.secure_access_enabled():
            print("bc250-smu-apply: unlocking secure access")
            try:
                unlock(smu)
            except SmuError as e:
                print(f"bc250-smu-apply: unlock failed: {e}", file=sys.stderr)
                return 1
        else:
            print("bc250-smu-apply: secure access already open")

        ok = True
        for addr, new in patches:
            cur = smu.smu_read_bytes(addr, len(new))
            if cur == new:
                print(f"bc250-smu-apply: {addr:05X} already patched")
                continue
            smu.smu_write_bytes(addr, new)
            got = smu.smu_read_bytes(addr, len(new))
            if got == new:
                print(f"bc250-smu-apply: {addr:05X} {cur.hex()} -> {got.hex()} OK")
            else:
                print(
                    f"bc250-smu-apply: {addr:05X} {cur.hex()} -> {got.hex()} "
                    f"VERIFY FAIL (want {new.hex()})",
                    file=sys.stderr,
                )
                ok = False

        return 0 if ok else 1
    finally:
        smu.close()


if __name__ == "__main__":
    sys.exit(main())
