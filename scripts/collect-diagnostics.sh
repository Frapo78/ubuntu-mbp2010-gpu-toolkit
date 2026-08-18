#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

OUT="${1:-$HOME/Codex/mbp-ubuntu-diagnostics-$(date +%Y%m%d-%H%M%S).txt}"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

section(){ printf '\n================================================================\n %s\n================================================================\n' "$1"; }

redact_cmdline() {
  sed -E \
    -e 's#root=PARTUUID=[^ ]+#root=PARTUUID=<REDACTED>#g' \
    -e 's#root=UUID=[^ ]+#root=UUID=<REDACTED>#g' \
    -e 's#resume=UUID=[^ ]+#resume=UUID=<REDACTED>#g'
}

section "SYSTEM"
date
uname -a
if [ -r /etc/os-release ]; then
  grep -E '^(NAME|VERSION|VERSION_ID|VERSION_CODENAME)=' /etc/os-release || true
fi
printf 'DMI model: '
cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo unknown
printf 'session: %s\n' "${XDG_SESSION_TYPE:-unknown}"
printf 'kernel cmdline: '
cat /proc/cmdline 2>/dev/null | redact_cmdline || true

section "PCI GPU"
lspci -nnk | grep -A4 -Ei 'VGA|3D|Display' || true

section "GPU SYSFS"
for dev in 0000:00:02.0 0000:01:00.0 0000:01:00.1; do
  [ -e "/sys/bus/pci/devices/$dev" ] || continue
  echo "--- $dev ---"
  base="/sys/bus/pci/devices/$dev"
  for f in boot_vga power/control power/runtime_status power/runtime_suspended_time power/runtime_active_time; do
    if [ -r "$base/$f" ]; then
      printf '%s=' "$f"; cat "$base/$f"
    fi
  done
done

section "GPU MODULES"
for mod in i915 nouveau apple_gmux; do
  if [ -d "/sys/module/$mod" ]; then
    echo "$mod=loaded"
  else
    echo "$mod=not-loaded"
  fi
done
lsmod | grep -E '^(apple_gmux|i915|nouveau)\b' || true

section "GMUX / VGA_SWITCHEROO"
if [ -r /sys/kernel/debug/vgaswitcheroo/switch ]; then
  cat /sys/kernel/debug/vgaswitcheroo/switch || true
else
  sudo -n cat /sys/kernel/debug/vgaswitcheroo/switch 2>/dev/null \
    || echo "vga_switcheroo state unavailable without interactive sudo"
fi

section "SWITCHEROO-CONTROL"
if command -v switcherooctl >/dev/null 2>&1; then
  switcherooctl list 2>/dev/null || true
else
  echo "switcherooctl not installed"
fi
systemctl show switcheroo-control.service \
  -p LoadState -p ActiveState -p SubState -p UnitFileState 2>/dev/null || true

section "DRM NODES AND HOLDERS"
ls -l /dev/dri 2>/dev/null || true
for f in /dev/dri/card* /dev/dri/renderD*; do
  [ -e "$f" ] || continue
  echo "--- $f ---"
  sudo -n fuser -v "$f" 2>/dev/null || fuser -v "$f" 2>/dev/null || true
done

section "DISPLAY / XORG"
if [ "${XDG_SESSION_TYPE:-}" = "x11" ] && command -v xrandr >/dev/null 2>&1; then
  xrandr --listproviders 2>/dev/null || true
  echo
  xrandr --listactivemonitors 2>/dev/null || true
  echo
  xrandr --query 2>/dev/null | grep -E 'Screen 0:| connected| disconnected' || true
else
  echo "Xorg/xrandr classification skipped: session=${XDG_SESSION_TYPE:-unknown}"
fi

XLOG="$HOME/.local/share/xorg/Xorg.0.log"
if [ -r "$XLOG" ]; then
  echo
  echo "--- selected Xorg GPU lines ---"
  grep -E 'PrimaryGPU|using drv /dev/dri/card|glamor X acceleration|DRI driver:|AIGLX:|Output LVDS' "$XLOG" \
    | tail -160 || true
fi

section "OPENCORE / EFI"
if [ -d /sys/firmware/efi/efivars ]; then
  printf 'efivarfs type: '
  stat -f -c %T /sys/firmware/efi/efivars 2>/dev/null || true
  findmnt -T /sys/firmware/efi/efivars -o FSTYPE,OPTIONS -n 2>/dev/null || true

  var="$(find /sys/firmware/efi/efivars -maxdepth 1 -type f -iname 'opencore-version-*' -print 2>/dev/null | head -1 || true)"
  if [ -n "$var" ]; then
    printf 'OpenCore version: '
    sudo -n dd if="$var" bs=1 skip=4 status=none 2>/dev/null \
      | tr -d '\000' || dd if="$var" bs=1 skip=4 status=none 2>/dev/null | tr -d '\000' || true
    echo
  else
    echo "OpenCore version EFI variable not found"
  fi

  if find /sys/firmware/efi/efivars -maxdepth 1 -type f -iname 'gpu-power-prefs-*' -print -quit 2>/dev/null | grep -q .; then
    echo "gpu-power-prefs=present"
  else
    echo "gpu-power-prefs=absent"
  fi
else
  echo "EFI runtime variables unavailable"
fi

section "GDM / GRUB"
grep -nE 'WaylandEnable' /etc/gdm3/custom.conf 2>/dev/null || true
# Do not print AutomaticLogin username in public diagnostics.
if grep -Eq '^[[:space:]]*AutomaticLoginEnable=true' /etc/gdm3/custom.conf 2>/dev/null; then
  echo "AutomaticLoginEnable=true"
fi

grep -E '^[[:space:]]*GRUB_CMDLINE_LINUX(_DEFAULT)?=' /etc/default/grub 2>/dev/null \
  | redact_cmdline || true

section "CURRENT BOOT GPU ERRORS"
journalctl -k -b --no-pager 2>/dev/null \
 | grep -Ei 'nouveau.*(DATA_ERROR|INVALID_VALUE|RT_LINEAR_WITH_ZETA|firmware|msvld|timeout|error)|i915.*(hang|hung|reset|timeout|error)|apple.?gmux|vga_switcheroo|drm.*(hang|reset|timeout)' \
 | tail -400 || true

section "THERMALS"
if command -v sensors >/dev/null 2>&1; then
  sensors 2>/dev/null || true
else
  echo "lm-sensors not installed"
fi

section "BATTERY SUMMARY"
if command -v upower >/dev/null 2>&1; then
  BAT="$(upower -e 2>/dev/null | grep -m1 BAT || true)"
  if [ -n "$BAT" ]; then
    upower -i "$BAT" 2>/dev/null \
      | grep -E '^[[:space:]]+(state|energy:|energy-full:|energy-full-design:|percentage:|capacity:|technology:|charge-cycles:)' || true
  else
    echo "battery device not found"
  fi
else
  echo "upower not installed"
fi

section "STORAGE SUMMARY"
lsblk -o NAME,MODEL,FSTYPE,SIZE,MOUNTPOINTS 2>/dev/null || true
systemctl is-enabled fstrim.timer 2>/dev/null || true
systemctl is-active fstrim.timer 2>/dev/null || true

section "REPORT NOTES"
echo "REPORT: $OUT"
echo "The collector intentionally omits IP/MAC data, serial numbers and full EFI variables."
echo "Kernel root UUID/PARTUUID values are redacted."
echo "Review the report before attaching it to a public issue."
