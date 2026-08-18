#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

MODEL="$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo unknown)"
SESSION="${XDG_SESSION_TYPE:-unknown}"
CMDLINE="$(cat /proc/cmdline 2>/dev/null || true)"

section(){ printf '\n================================================================\n %s\n================================================================\n' "$1"; }
flag(){ printf '  %-34s %s\n' "$1" "$2"; }

section "IDENTITY"
flag "model" "$MODEL"
flag "kernel" "$(uname -r)"
flag "session" "$SESSION"
flag "cmdline" "$CMDLINE"

section "GPU STATE"
for dev in 0000:00:02.0 0000:01:00.0; do
  if [ -e "/sys/bus/pci/devices/$dev" ]; then
    echo "--- $dev ---"
    lspci -nnk -s "${dev#0000:}" 2>/dev/null || true
    [ -r "/sys/bus/pci/devices/$dev/boot_vga" ] && {
      printf 'boot_vga='; cat "/sys/bus/pci/devices/$dev/boot_vga"
    }
  fi
done

echo
if command -v switcherooctl >/dev/null 2>&1; then
  switcherooctl list 2>/dev/null || true
fi

echo
if [ -r /sys/kernel/debug/vgaswitcheroo/switch ]; then
  cat /sys/kernel/debug/vgaswitcheroo/switch || true
elif command -v sudo >/dev/null 2>&1; then
  sudo -n cat /sys/kernel/debug/vgaswitcheroo/switch 2>/dev/null || echo "vga_switcheroo requires sudo to read"
fi

section "DISPLAY"
if [ "$SESSION" = "x11" ] && command -v xrandr >/dev/null 2>&1; then
  xrandr --listactivemonitors 2>/dev/null || true
  xrandr --query 2>/dev/null | grep -E 'Screen 0:| connected| disconnected' || true
else
  echo "xrandr display classification skipped (session=$SESSION)"
fi

section "KNOWN CASE CLASSIFICATION"

matched=0

if [ "$SESSION" = "wayland" ] && [ -d /sys/module/i915 ] && [ -d /sys/module/nouveau ]; then
  echo "MATCH: wayland-multigpu-freeze [risk=HIGH]"
  echo "  Both i915 and nouveau are loaded under Wayland."
  echo "  On the reference MacBookPro6,2 this combination led to catastrophic graphical freezes."
  echo "  Read: docs/quick-triage.md and knowledge/cases.json"
  matched=1
fi

if [ "$SESSION" = "x11" ] && command -v xrandr >/dev/null 2>&1; then
  connected_lvds="$(xrandr --query 2>/dev/null | awk '$1 ~ /^LVDS/ && $2=="connected" {print $1}' | wc -l)"
  if [ "$connected_lvds" -gt 1 ]; then
    echo "MATCH: duplicate-internal-lvds [risk=LOW]"
    echo "  More than one LVDS output is connected for the internal panel."
    echo "  Inspect output names before disabling the duplicate session-only output."
    matched=1
  fi
fi

if journalctl -b -k --no-pager 2>/dev/null | grep -Eq 'nouveau.*DATA_ERROR.*INVALID_VALUE'; then
  echo "MATCH: chromium-nouveau-invalid-value [risk=MEDIUM]"
  echo "  Current boot contains Nouveau DATA_ERROR/INVALID_VALUE entries."
  echo "  Correlate timestamps with Chromium/application launch before assigning cause."
  matched=1
fi

intel_boot="$(cat /sys/bus/pci/devices/0000:00:02.0/boot_vga 2>/dev/null || echo '?')"
nvidia_boot="$(cat /sys/bus/pci/devices/0000:01:00.0/boot_vga 2>/dev/null || echo '?')"
if [ "$intel_boot" = "0" ] && [ "$nvidia_boot" = "1" ]; then
  echo "MATCH: nvidia-default-because-boot-vga [risk=LOW]"
  echo "  Firmware marks NVIDIA boot_vga=1 and Intel boot_vga=0."
  echo "  switcheroo-control may therefore call NVIDIA the default GPU."
  matched=1
fi

if find /sys/firmware/efi/efivars -maxdepth 1 -type f -iname 'gpu-power-prefs-*' -print -quit 2>/dev/null | grep -q .; then
  echo "NOTICE: gpu-power-prefs EFI variable exists"
  echo "  This differs from the reference stable checkpoint. Do not overwrite it automatically."
  matched=1
fi

if grep -qw nomodeset <<<"$CMDLINE"; then
  echo "NOTICE: nomodeset is active"
  echo "  This is not the target stable configuration because it suppresses the Intel KMS path."
  matched=1
fi

if [ "$matched" -eq 0 ]; then
  echo "No current-state signature matched a known high-confidence case."
  echo "Run scripts/collect-diagnostics.sh and use docs/decision-tree.md."
fi

section "SAFETY"
echo "This script did not modify the system."
echo "Do not apply experimental GPU/EFI changes solely from this classifier."
