#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

MODEL_EXPECTED="MacBookPro6,2"
CODEX="$HOME/Codex"
TS="$(date +%Y%m%d-%H%M%S)"
CHECKPOINT="$CODEX/stable-checkpoint-mbp62-$TS"
REPORT="$CODEX/freeze-stable-mbp62-$TS.txt"

mkdir -p "$CODEX" "$CHECKPOINT"

exec > >(tee "$REPORT") 2>&1

section() {
  printf '\n================================================================\n %s\n================================================================\n' "$1"
}

section "PRECHECK"
date
uname -a
MODEL="$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || true)"
echo "DMI: $MODEL"
echo "Sessione: ${XDG_SESSION_TYPE:-unknown}"

if [ "$MODEL" != "$MODEL_EXPECTED" ]; then
  echo "ERRORE: questo script e destinato a $MODEL_EXPECTED."
  exit 1
fi

section "RIMUOVE SOLO RESIDUI DEI TEST DI QUESTA PROCEDURA"

# Questi file sono stati usati soltanto per test one-shot e non fanno parte
# della configurazione stabile.
sudo systemctl disable mbp-gpu-power-prefs-autorevert.service >/dev/null 2>&1 || true
sudo rm -f \
  /etc/mbp-gpu-power-prefs-igd-once \
  /usr/local/sbin/mbp-gpu-power-prefs-autorevert \
  /etc/systemd/system/mbp-gpu-power-prefs-autorevert.service
sudo systemctl daemon-reload >/dev/null 2>&1 || true
sudo systemctl reset-failed mbp-gpu-power-prefs-autorevert.service >/dev/null 2>&1 || true

echo "Residui gpu-power-prefs test: rimossi/non presenti."

section "GPU-POWER-PREFS"

VAR="/sys/firmware/efi/efivars/gpu-power-prefs-fa4ce28d-b62f-4c99-9cc3-6815686e30f9"
if sudo test -e "$VAR"; then
  echo "ATTENZIONE: gpu-power-prefs ESISTE. Non la modifico."
  sudo stat -c 'size=%s bytes' "$VAR" 2>/dev/null || true
  sudo xxd -g1 "$VAR" 2>/dev/null || true
  echo "STOP: stato EFI inatteso. Non procedo con altre modifiche."
  exit 10
else
  echo "gpu-power-prefs assente: OK."
fi

section "RIMUOVE EVENTUALI XORG TEST CONFIG"

TEST_XORG=(
  /etc/X11/xorg.conf.d/99-mbp-intel-primary-test.conf
  /etc/X11/xorg.conf.d/99-mbp-intel-primary-offload-test.conf
  /etc/X11/xorg.conf.d/99-mbp-intel-only-test.conf
)

mkdir -p "$CHECKPOINT/xorg-test-backup"

for f in "${TEST_XORG[@]}"; do
  if sudo test -f "$f"; then
    echo "Backup e rimozione residuo test: $f"
    sudo cp "$f" "$CHECKPOINT/xorg-test-backup/"
    sudo rm -f "$f"
  else
    echo "OK assente: $f"
  fi
done

sudo chown -R "$USER":"$(id -g)" "$CHECKPOINT/xorg-test-backup" 2>/dev/null || true

section "CHECKPOINT CONFIGURAZIONE STABILE"

for f in /etc/gdm3/custom.conf /etc/default/grub; do
  if sudo test -f "$f"; then
    sudo cp "$f" "$CHECKPOINT/$(basename "$f")"
    sudo chown "$USER":"$(id -g)" "$CHECKPOINT/$(basename "$f")" 2>/dev/null || true
  fi
done

if sudo test -d /boot/efi/EFI; then
  mkdir -p "$CHECKPOINT/EFI"
  sudo cp -a /boot/efi/EFI/. "$CHECKPOINT/EFI/"
  sudo chown -R "$USER":"$(id -g)" "$CHECKPOINT/EFI" 2>/dev/null || true
  echo "Snapshot EFI corrente salvato."
fi

section "VERIFICA BASELINE"

echo "--- GDM ---"
grep -nE 'WaylandEnable|AutomaticLogin' /etc/gdm3/custom.conf 2>/dev/null || true

if grep -Eq '^[[:space:]]*WaylandEnable=false' /etc/gdm3/custom.conf 2>/dev/null; then
  echo "Wayland disabilitato: OK."
else
  echo "ATTENZIONE: WaylandEnable=false non trovato."
fi

echo
echo "--- GRUB ---"
grep -nE 'GRUB_CMDLINE_LINUX' /etc/default/grub 2>/dev/null || true

CMDLINE="$(cat /proc/cmdline 2>/dev/null || true)"
if grep -qw nomodeset <<<"$CMDLINE"; then
  echo "ATTENZIONE: nomodeset e attivo."
else
  echo "nomodeset assente: OK."
fi

echo
echo "--- OpenCore ---"
OCVAR="$(find /sys/firmware/efi/efivars -maxdepth 1 -type f -iname 'opencore-version-*' -print 2>/dev/null | head -1 || true)"
if [ -n "$OCVAR" ]; then
  printf 'versione: '
  sudo dd if="$OCVAR" bs=1 skip=4 status=none 2>/dev/null | tr -d '\000' || true
  echo
else
  echo "opencore-version non esposta."
fi

echo
echo "--- GPU ---"
for dev in 0000:00:02.0 0000:01:00.0; do
  echo "$dev"
  lspci -nnk -s "${dev#0000:}" 2>/dev/null || true
  if [ -r "/sys/bus/pci/devices/$dev/boot_vga" ]; then
    printf 'boot_vga='
    cat "/sys/bus/pci/devices/$dev/boot_vga"
  fi
done

echo
echo "--- vga_switcheroo ---"
sudo cat /sys/kernel/debug/vgaswitcheroo/switch 2>/dev/null || true

section "CORREGGE SOLO IL DOPPIO PANNELLO NELLA SESSIONE CORRENTE"

# Non e persistente e non cambia gmux. Evita il desktop fantasma 2880x900
# quando entrambe le uscite LVDS dello stesso pannello risultano attive.
if [ "${XDG_SESSION_TYPE:-}" = "x11" ] && command -v xrandr >/dev/null 2>&1; then
  if xrandr --query 2>/dev/null | grep -q '^LVDS-1-2 connected'; then
    echo "Disabilito LVDS-1-2 SOLO per questa sessione X11."
    xrandr --output LVDS-1-2 --off || true
  else
    echo "LVDS-1-2 non risulta connesso: nessuna azione."
  fi

  echo
  xrandr --listactivemonitors 2>/dev/null || true
  xrandr --query 2>/dev/null | grep -E 'Screen 0:| connected| disconnected' || true
else
  echo "Sessione non X11 o xrandr assente: nessuna azione display."
fi

section "STATO SERVIZI"

systemctl is-enabled switcheroo-control.service 2>&1 || true
systemctl is-active switcheroo-control.service 2>&1 || true

echo
echo "Eventuali residui autorevert:"
systemctl is-enabled mbp-gpu-power-prefs-autorevert.service 2>&1 || true
ls -l \
  /etc/mbp-gpu-power-prefs-igd-once \
  /usr/local/sbin/mbp-gpu-power-prefs-autorevert \
  /etc/systemd/system/mbp-gpu-power-prefs-autorevert.service 2>&1 || true

section "RISULTATO"

sync

echo "CHECKPOINT STABILE CREATO."
echo "Nessuno switch gmux, nessuna write NVRAM, nessun reboot."
echo
echo "Checkpoint:"
echo "  $CHECKPOINT"
echo
echo "Report:"
echo "  $REPORT"
echo
echo "Per la massima stabilita fino alla prossima sessione:"
echo "  - resta su X11;"
echo "  - evita nuovi test GPU/NVRAM;"
echo "  - se Chromium provoca artefatti o rallentamenti, chiudilo e riaprilo domani dopo la nuova configurazione."
