#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

OUT="${1:-$HOME/Codex/mbp-integration-$(date +%Y%m%d-%H%M%S).txt}"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

section(){ printf '\n==== %s ====\n' "$1"; }
cmd(){ printf '$ %s\n' "$*"; "$@" 2>&1 || true; }

section "SYSTEM"
date
uname -a
printf 'model='; cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || true
printf 'session=%s\n' "${XDG_SESSION_TYPE:-unknown}"
printf 'ubuntu='; . /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-unknown}" || true

section "APPLE / PLATFORM MODULES"
for m in bcm5974 hid_apple applesmc apple_gmux btusb uvcvideo; do
  if [ -d "/sys/module/$m" ]; then
    echo "$m=loaded"
  else
    echo "$m=not-loaded"
  fi
done

section "INPUT / TRACKPAD / KEYBOARD"
cmd grep -Ei 'Name=|Handlers=|Phys=|EV=' /proc/bus/input/devices
if command -v libinput >/dev/null 2>&1; then
  cmd libinput list-devices
else
  echo "libinput CLI unavailable (install libinput-tools)"
fi
if command -v xinput >/dev/null 2>&1 && [ "${XDG_SESSION_TYPE:-}" = x11 ]; then
  cmd xinput list
fi
if [ -d /sys/module/hid_apple/parameters ]; then
  echo "--- hid_apple parameters ---"
  for f in /sys/module/hid_apple/parameters/*; do
    [ -r "$f" ] || continue
    printf '%s=' "$(basename "$f")"
    cat "$f" || true
  done
fi

section "KEYBOARD LED / DISPLAY BACKLIGHT"
echo "--- LEDs ---"
for d in /sys/class/leds/*; do
  [ -e "$d" ] || continue
  echo "$(basename "$d")"
  for f in brightness max_brightness trigger; do
    [ -r "$d/$f" ] && { printf '  %s=' "$f"; cat "$d/$f"; }
  done
done

echo "--- display backlights ---"
for d in /sys/class/backlight/*; do
  [ -e "$d" ] || continue
  echo "$(basename "$d")"
  for f in brightness actual_brightness max_brightness type; do
    [ -r "$d/$f" ] && { printf '  %s=' "$f"; cat "$d/$f"; }
  done
done

section "WIFI"
cmd lspci -nnk
if command -v rfkill >/dev/null 2>&1; then cmd rfkill list; fi
if command -v iw >/dev/null 2>&1; then
  cmd iw dev
  cmd iw phy
fi
if command -v nmcli >/dev/null 2>&1; then
  cmd nmcli -f DEVICE,TYPE,STATE,CONNECTION device
fi
journalctl -k -b --no-pager 2>/dev/null \
  | grep -Ei 'b43|brcmsmac|brcmfmac|broadcom|\bwl\b|firmware.*(wifi|wlan|b43|brcm)' \
  | tail -150 || true

section "BLUETOOTH"
cmd lsusb
if command -v rfkill >/dev/null 2>&1; then cmd rfkill list bluetooth; fi
if command -v bluetoothctl >/dev/null 2>&1; then cmd bluetoothctl show; fi
cmd systemctl status bluetooth.service --no-pager
journalctl -k -b --no-pager 2>/dev/null \
  | grep -Ei 'bluetooth|btusb|btintel|btbcm|firmware.*bluetooth' \
  | tail -150 || true

section "AUDIO"
if command -v aplay >/dev/null 2>&1; then cmd aplay -l; fi
if command -v arecord >/dev/null 2>&1; then cmd arecord -l; fi
if command -v wpctl >/dev/null 2>&1; then cmd wpctl status; fi

section "CAMERA"
ls -l /dev/video* 2>/dev/null || true
if command -v v4l2-ctl >/dev/null 2>&1; then cmd v4l2-ctl --list-devices; fi

section "BATTERY / POWER"
if command -v upower >/dev/null 2>&1; then
  BATT="$(upower -e 2>/dev/null | grep -m1 battery || true)"
  [ -n "$BATT" ] && cmd upower -i "$BATT"
fi
if command -v acpi >/dev/null 2>&1; then cmd acpi -V; fi

section "SENSORS / APPLE SMC / FANS"
if command -v sensors >/dev/null 2>&1; then cmd sensors; fi
find /sys/devices/platform -maxdepth 4 \
  \( -iname '*applesmc*' -o -iname '*fan*' -o -iname '*temp*' \) \
  -print 2>/dev/null | head -250 || true

section "STORAGE / OPTICAL"
cmd lsblk -o NAME,TYPE,SIZE,FSTYPE,MOUNTPOINTS,MODEL
ls -l /dev/sr* 2>/dev/null || true
if command -v smartctl >/dev/null 2>&1; then
  for d in /dev/sd?; do
    [ -b "$d" ] || continue
    echo "--- smartctl $d ---"
    smartctl -H -A "$d" 2>&1 | grep -E 'SMART overall-health|SMART Health Status|Reallocated|Wear|Power_On_Hours|Temperature' || true
  done
fi

section "PACKAGE / SERVICE SNAPSHOT"
for p in linux-firmware switcheroo-control bluez blueman brightnessctl libinput-tools evtest xinput lm-sensors powertop smartmontools alsa-utils v4l-utils broadcom-sta-dkms b43-fwcutter firmware-b43-installer pommed mbpfan macfanctld; do
  if dpkg-query -W -f='${Status} ${Version}\n' "$p" 2>/dev/null | grep -q '^install ok installed '; then
    printf '%-28s ' "$p"
    dpkg-query -W -f='${Version}\n' "$p"
  fi
done

section "RESULT"
echo "Read-only integration report complete."
echo "REPORT: $OUT"
