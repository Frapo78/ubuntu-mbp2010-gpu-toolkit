#!/usr/bin/env bash
# EXPERIMENTAL — MacBookPro6,2 only.
# Read docs/safety.md before running. This file came from a successful
# reference-machine experiment but is NOT part of the automatic quickstart.
set -Eeuo pipefail
export LC_ALL=C

mkdir -p "$HOME/Codex"
TS="$(date +%Y%m%d-%H%M%S)"
OUT="$HOME/Codex/test-gmux-migd-mbp62-$TS.txt"
UNIT="mbp-gmux-autorevert-$TS"

exec > >(tee "$OUT") 2>&1

section() {
  printf '\n================================================================\n %s\n================================================================\n' "$1"
}

SW="/sys/kernel/debug/vgaswitcheroo/switch"

cleanup_display() {
  # Dopo il ritorno a NVIDIA eliminiamo nuovamente il pannello duplicato Intel.
  if [ "${DISPLAY:-}" != "" ]; then
    xrandr --output LVDS-1-2 --off >/dev/null 2>&1 || true
    xrandr --output LVDS-1 --primary --mode 1440x900 --pos 0x0 >/dev/null 2>&1 || true
  fi
}

section "PRECHECK"
date
uname -a
printf 'DMI: '; cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || true
printf 'Sessione: %s\n' "${XDG_SESSION_TYPE:-unknown}"
printf 'Display: %s\n' "${DISPLAY:-unknown}"
printf 'Cmdline: '; cat /proc/cmdline 2>/dev/null || true

MODEL="$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || true)"
if [ "$MODEL" != "MacBookPro6,2" ]; then
  echo "ERRORE: script preparato esclusivamente per MacBookPro6,2."
  exit 1
fi

if [ "${XDG_SESSION_TYPE:-}" != "x11" ]; then
  echo "ERRORE: questo test richiede X11."
  exit 1
fi

if [ ! -d /sys/module/i915 ] || [ ! -d /sys/module/nouveau ] || [ ! -d /sys/module/apple_gmux ]; then
  echo "ERRORE: i915, nouveau e apple_gmux devono essere tutti caricati."
  exit 1
fi

if ! sudo test -e "$SW"; then
  echo "ERRORE: vga_switcheroo non disponibile."
  exit 1
fi

XR="$(xrandr --query 2>&1 || true)"
if ! grep -q '^LVDS-1 connected' <<<"$XR"; then
  echo "ERRORE: output NVIDIA LVDS-1 non trovato."
  exit 1
fi
if ! grep -q '^LVDS-1-2 connected' <<<"$XR"; then
  echo "ERRORE: output Intel LVDS-1-2 non trovato."
  exit 1
fi

section "STATO INIZIALE"
echo "--- switcheroo ---"
sudo cat "$SW"
echo
echo "--- xrandr ---"
xrandr --listactivemonitors || true
xrandr --query | grep -E 'Screen 0:|^LVDS-1 |^LVDS-1-2 ' || true

STATE="$(sudo cat "$SW")"
if ! grep -q 'DIS:+:Pwr:0000:01:00.0' <<<"$STATE"; then
  echo
  echo "ERRORE: NVIDIA non risulta client attivo DIS. Test annullato."
  exit 1
fi
if ! grep -q 'IGD: .*:Pwr:0000:00:02.0' <<<"$STATE"; then
  echo
  echo "ERRORE: Intel IGD non risulta alimentata. Test annullato."
  exit 1
fi

section "PREPARA SCANOUT INTEL IN MIRROR"
echo "Attivo LVDS-1-2 (Intel) a 1440x900 sovrapposto a LVDS-1 (NVIDIA)."
echo "Entrambe le GPU restano alimentate."

xrandr \
  --output LVDS-1 --primary --mode 1440x900 --pos 0x0 \
  --output LVDS-1-2 --mode 1440x900 --pos 0x0

sleep 2

echo
echo "--- xrandr mirror ---"
xrandr --listactivemonitors || true
xrandr --query | grep -E 'Screen 0:|^LVDS-1 |^LVDS-1-2 ' || true

# Verifica che entrambe abbiano realmente un CRTC attivo.
VERBOSE="$(xrandr --verbose 2>&1 || true)"
if ! awk '/^LVDS-1 connected/{f=1;next} /^[A-Za-z0-9-]+ (connected|disconnected)/{f=0} f && /CRTC:/{print; exit}' <<<"$VERBOSE" | grep -Eq 'CRTC:[[:space:]]+[0-9]+'; then
  echo "ERRORE: CRTC NVIDIA non attivo."
  cleanup_display
  exit 1
fi
if ! awk '/^LVDS-1-2 connected/{f=1;next} /^[A-Za-z0-9-]+ (connected|disconnected)/{f=0} f && /CRTC:/{print; exit}' <<<"$VERBOSE" | grep -Eq 'CRTC:[[:space:]]+[0-9]+'; then
  echo "ERRORE: CRTC Intel non attivo. Non commuto il mux."
  cleanup_display
  exit 1
fi

section "ARMA RITORNO AUTOMATICO A NVIDIA"
echo "Creo un timer root one-shot: MDIS tra 12 secondi."
echo "Se il pannello diventasse nero, NON fare nulla: il mux tornera automaticamente a NVIDIA."

sudo systemd-run \
  --quiet \
  --collect \
  --unit="$UNIT" \
  --on-active=12s \
  /bin/sh -c "printf '%s\n' MDIS > '$SW'"

echo "Timer armato: $UNIT"

section "TEST MUX-ONLY INTEL"
echo
echo "ATTENZIONE: ora il pannello puo lampeggiare o diventare nero temporaneamente."
echo "Commuto SOLO il mux verso Intel (MIGD)."
echo

printf '%s\n' MIGD | sudo tee "$SW" >/dev/null
MIGD_RC=$?

sleep 2

echo "--- switcheroo ~2s dopo MIGD ---"
sudo cat "$SW" || true
echo
echo "Se stai leggendo questo sul pannello interno durante questi secondi,"
echo "il mux fisico sta mostrando correttamente lo scanout Intel."

section "ATTESA AUTOREVERT"
echo "Attendo il ritorno automatico a NVIDIA..."
sleep 12

echo
echo "--- stato dopo autorevert ---"
sudo cat "$SW" || true

section "RIPRISTINA LAYOUT XORG"
cleanup_display
sleep 1

xrandr --listactivemonitors || true
xrandr --query | grep -E 'Screen 0:|^LVDS-1 |^LVDS-1-2 ' || true

section "ERRORI GPU DAL TEST"
journalctl -k -b --since '-1 min' --no-pager 2>/dev/null \
  | grep -Ei 'apple.?gmux|vga_switcheroo|i915.*(error|hang|hung|reset)|nouveau.*(DATA_ERROR|INVALID_VALUE|RT_LINEAR_WITH_ZETA)|drm.*(hang|reset)' \
  | tail -250 || true

section "RIEPILOGO"
FINAL="$(sudo cat "$SW" 2>/dev/null || true)"
echo "MIGD write rc: $MIGD_RC"

if grep -q 'DIS:+:' <<<"$FINAL"; then
  echo "Stato finale mux: NVIDIA/DIS"
else
  echo "Stato finale mux: da verificare"
fi

echo
echo "IMPORTANTE:"
echo "Il test MIGD non spegne NVIDIA e non rende Intel la GPU primaria di Xorg."
echo "Serve solo a dimostrare se il pannello fisico puo essere commutato sullo scanout Intel."
echo
echo "REPORT COMPLETO: $OUT"
echo "Nessuna configurazione persistente, GRUB o EFI e stata modificata."
