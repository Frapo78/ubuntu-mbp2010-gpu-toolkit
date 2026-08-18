#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

OUT="${1:-$HOME/Codex/mbp62-diagnostics-$(date +%Y%m%d-%H%M%S).txt}"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

section(){ printf '\n==== %s ====\n' "$1"; }

section "SYSTEM"
date
uname -a
cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || true
echo "session=${XDG_SESSION_TYPE:-unknown}"
cat /proc/cmdline 2>/dev/null || true

section "PCI GPU"
lspci -nnk | grep -A4 -Ei 'VGA|3D|Display' || true

section "GPU SYSFS"
for dev in 0000:00:02.0 0000:01:00.0 0000:01:00.1; do
  echo "--- $dev ---"
  base="/sys/bus/pci/devices/$dev"
  for f in boot_vga power/control power/runtime_status; do
    if [ -r "$base/$f" ]; then
      printf '%s=' "$f"; cat "$base/$f"
    fi
  done
done

section "GMUX / SWITCHEROO"
lsmod | grep -E 'apple_gmux|i915|nouveau' || true
sudo cat /sys/kernel/debug/vgaswitcheroo/switch 2>/dev/null || true

section "SWITCHEROO-CONTROL"
switcherooctl list 2>/dev/null || true
systemctl status switcheroo-control.service --no-pager 2>/dev/null || true

section "XORG"
xrandr --listproviders 2>/dev/null || true
xrandr --listactivemonitors 2>/dev/null || true
xrandr --query 2>/dev/null | grep -E 'Screen 0:| connected| disconnected' || true

section "OPENCORE"
var="$(find /sys/firmware/efi/efivars -maxdepth 1 -type f -iname 'opencore-version-*' -print 2>/dev/null | head -1 || true)"
if [ -n "$var" ]; then
  sudo dd if="$var" bs=1 skip=4 status=none 2>/dev/null | tr -d '\000' || true
  echo
fi
find /sys/firmware/efi/efivars -maxdepth 1 -type f -iname 'gpu-power-prefs-*' -print 2>/dev/null || true

section "GDM / GRUB"
grep -nE 'WaylandEnable|AutomaticLogin' /etc/gdm3/custom.conf 2>/dev/null || true
grep -nE 'GRUB_CMDLINE_LINUX' /etc/default/grub 2>/dev/null || true

section "CURRENT BOOT GPU ERRORS"
journalctl -k -b --no-pager 2>/dev/null \
 | grep -Ei 'nouveau.*(DATA_ERROR|INVALID_VALUE|RT_LINEAR_WITH_ZETA|firmware)|i915.*(hang|hung|reset)|apple.?gmux|vga_switcheroo' \
 | tail -300 || true

echo
echo "REPORT: $OUT"
