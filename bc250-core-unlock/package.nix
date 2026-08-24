{
  lib,
  writeShellApplication,
  coreutils,
  util-linux,
}:

writeShellApplication {
  name = "bc250-core-unlock";

  runtimeInputs = [
    coreutils
    util-linux
  ];

  text = ''
      C=/sys/bus/pci/devices/0000:00:00.0/config

      Q3_CMD='\x20\x0a\xb1\x03'
      Q3_RSP='\x80\x0a\xb1\x03'
      Q3_ARG='\x88\x0a\xb1\x03'
      Q3_ARG_HI='\x8c\x0a\xb1\x03'
      MASK='\x70\xa8\x05\x00'
      ZERO='\x00\x00\x00\x00'
      MSG98='\x98\x00\x00\x00'

      [ -r /proc/cmdline ] || mount -t proc proc /proc 2>/dev/null || true

      if ! cmdline=$(cat /proc/cmdline 2>/dev/null); then
        echo "bc250-core-unlock: cannot read kernel command line, refusing"
        exit 0
      fi

      case "$cmdline" in
        *bc250.nocoreunlock*)
          echo "bc250-core-unlock: disabled via kernel command line"
          exit 0
          ;;
      esac

      if [ ! -e "$C" ]; then
        echo "bc250-core-unlock: no PCI config space at $C"
        exit 0
      fi

      smn_addr() { printf "%b" "$1" | dd of="$C" bs=1 seek=184 conv=notrunc status=none; }

      smn_rd() {
        smn_addr "$1"
        dd if="$C" bs=1 skip=188 count=4 status=none | od -An -tx1 | tr -d ' '
      }

      smn_wr() {
        smn_addr "$1"
        printf "%b" "$2" | dd of="$C" bs=1 seek=188 conv=notrunc status=none
      }

      mailbox_wait() {
        i=0
        while [ "$i" -lt 250 ]; do
          case "$(smn_rd "$Q3_RSP")" in
            01000000|ff000000|fe000000|fd000000|fc000000) return 0 ;;
          esac
          sleep 0.02
          i=$((i + 1))
        done
        return 1
      }

      before=$(smn_rd "$MASK")
    echo "bc250-core-unlock: core presence mask is $before"

    case "$before" in
      ff000000)
        echo "bc250-core-unlock: already unlocked, continuing boot"
        exit 0
        ;;
      77000000) ;;
      *)
        echo "bc250-core-unlock: unexpected mask, refusing"
        echo "bc250-core-unlock: a mask other than 0x77 suggests a harvest that skipped defective cores"
        exit 0
        ;;
    esac

    if ! mailbox_wait; then
      echo "bc250-core-unlock: SMU mailbox busy, not writing"
      exit 0
    fi

    smn_wr "$Q3_RSP" "$ZERO"
    smn_wr "$Q3_ARG" "$MASK"
    smn_wr "$Q3_ARG_HI" "$ZERO"
    smn_wr "$Q3_CMD" "$MSG98"

    if ! mailbox_wait; then
      echo "bc250-core-unlock: SMU mailbox timeout, not resetting"
      exit 0
    fi

    status=$(smn_rd "$Q3_RSP")
    if [ "$status" != "01000000" ]; then
      echo "bc250-core-unlock: SMU returned $status, not resetting"
      exit 0
    fi

    sleep 0.2
    after=$(smn_rd "$MASK")
    if [ "$after" != "ff000000" ]; then
      echo "bc250-core-unlock: mask did not take ($after), not resetting"
      exit 0
    fi

    echo "bc250-core-unlock: mask written, resetting"
    sleep 1
    echo b > /proc/sysrq-trigger
  '';

  meta = {
    description = "Enable the two disabled CPU cores on the AMD BC-250 during early boot";
    longDescription = ''
      Shell reimplementation of bc250-core-unlock, adapted to run as a systemd
      unit in the initrd. Triggers a reboot on cold boot to apply the unlock.
      See the original script and documentation at
      https://github.com/rw-r-r-0644/bc250-core-unlock.
    '';
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "bc250-core-unlock";
  };
}
