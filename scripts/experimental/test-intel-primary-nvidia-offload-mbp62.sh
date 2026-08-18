#!/usr/bin/env bash
# EXPERIMENTAL — MacBookPro6,2 only.
# Read docs/safety.md before running. This file came from a successful
# reference-machine experiment but is NOT part of the automatic quickstart.
set -Eeuo pipefail
export LC_ALL=C

USER_NAME="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
USER_UID="$(id -u "$USER_NAME")"
USER_GID="$(id -g "$USER_NAME")"
CODEX="$USER_HOME/Codex"
mkdir -p "$CODEX"

TS="$(date +%Y%m%d-%H%M%S)"
REPORT="$CODEX/test-intel-primary-nvidia-offload-mbp62-$TS.txt"
WORKER="$CODEX/intel-primary-nvidia-offload-worker-$TS.sh"

XORG_LINK="/etc/X11/xorg.conf.d/99-mbp-intel-primary-offload-test.conf"
XORG_RUN="/run/99-mbp-intel-primary-offload-test.conf"
MARKER="/etc/mbp-intel-primary-offload-test-active"

RESCUE_SCRIPT="/usr/local/sbin/mbp-intel-primary-offload-rescue"
RESCUE_UNIT="/etc/systemd/system/mbp-intel-primary-offload-rescue.service"
TRANSIENT="mbp-intel-primary-offload-$TS"
SW="/sys/kernel/debug/vgaswitcheroo/switch"

section() {
  printf '\n================================================================\n %s\n================================================================\n' "$1"
}

section "PRECHECK"
date
uname -a
printf 'DMI: '; cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || true
printf 'Sessione: %s\n' "${XDG_SESSION_TYPE:-unknown}"
printf 'Cmdline: '; cat /proc/cmdline 2>/dev/null || true

MODEL="$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || true)"
if [ "$MODEL" != "MacBookPro6,2" ]; then
  echo "ERRORE: script esclusivo per MacBookPro6,2."
  exit 1
fi

if [ "${XDG_SESSION_TYPE:-}" != "x11" ]; then
  echo "ERRORE: il test richiede X11."
  exit 1
fi

if [ ! -d /sys/module/i915 ] || [ ! -d /sys/module/nouveau ] || [ ! -d /sys/module/apple_gmux ]; then
  echo "ERRORE: i915, nouveau e apple_gmux devono essere caricati."
  exit 1
fi

if ! sudo test -e "$SW"; then
  echo "ERRORE: vga_switcheroo non disponibile."
  exit 1
fi

if [ -e "$XORG_LINK" ] || [ -L "$XORG_LINK" ]; then
  echo "ERRORE: esiste gia $XORG_LINK"
  exit 1
fi

if sudo test -e "$MARKER"; then
  echo "ERRORE: marker di un test precedente presente: $MARKER"
  exit 1
fi

echo
echo "--- switcheroo iniziale ---"
sudo cat "$SW"

section "BINARI MESA / GLXINFO"

GLXINFO=""
GLXGEARS=""

# 1) Preferisci eventuali binari gia installati nel sistema.
if command -v glxinfo >/dev/null 2>&1; then
  GLXINFO="$(command -v glxinfo)"
fi
if command -v glxgears >/dev/null 2>&1; then
  GLXGEARS="$(command -v glxgears)"
fi

# 2) Cerca qualsiasi estrazione portabile precedente sotto ~/Codex.
if [ -z "$GLXINFO" ]; then
  GLXINFO="$(
    find "$CODEX" -type f \
      \( -name 'glxinfo' -o -name 'glxinfo.*-linux-gnu' \) \
      -perm /111 -print 2>/dev/null | sort -r | head -1 || true
  )"
fi

if [ -z "$GLXGEARS" ]; then
  GLXGEARS="$(
    find "$CODEX" -type f \
      \( -name 'glxgears' -o -name 'glxgears.*-linux-gnu' \) \
      -perm /111 -print 2>/dev/null | sort -r | head -1 || true
  )"
fi

# 3) Se ancora assenti, scarica ed estrai i pacchetti Ubuntu senza installarli.
if [ -z "$GLXINFO" ]; then
  MESA_TMP="$CODEX/mesa-utils-offload-$TS"
  mkdir -p "$MESA_TMP/root"

  echo "glxinfo non trovato: preparo una copia portabile in $MESA_TMP"
  (
    cd "$MESA_TMP"
    apt download mesa-utils mesa-utils-bin
    for deb in ./*.deb; do
      [ -f "$deb" ] || continue
      dpkg-deb -x "$deb" "$MESA_TMP/root"
    done
  )

  GLXINFO="$(
    find "$MESA_TMP/root" -type f \
      \( -name 'glxinfo' -o -name 'glxinfo.*-linux-gnu' \) \
      -perm /111 -print 2>/dev/null | head -1 || true
  )"

  GLXGEARS="$(
    find "$MESA_TMP/root" -type f \
      \( -name 'glxgears' -o -name 'glxgears.*-linux-gnu' \) \
      -perm /111 -print 2>/dev/null | head -1 || true
  )"
fi

if [ -z "$GLXINFO" ] || [ ! -x "$GLXINFO" ]; then
  echo "ERRORE: impossibile ottenere glxinfo anche dopo l'estrazione portabile."
  exit 2
fi

echo "glxinfo:  $GLXINFO"
echo "glxgears: ${GLXGEARS:-NON TROVATO — il test continuera senza stress GL}"

section "INSTALLA RESCUE ONE-SHOT"

sudo tee "$RESCUE_SCRIPT" >/dev/null <<EOF
#!/usr/bin/env bash
set -u
SW="$SW"
MARKER="$MARKER"
XORG_LINK="$XORG_LINK"
XORG_RUN="$XORG_RUN"

rm -f "\$XORG_LINK" "\$XORG_RUN"

for _ in \$(seq 1 50); do
  if [ -e "\$SW" ]; then
    printf '%s\n' MDIS > "\$SW" 2>/dev/null || true
    break
  fi
  sleep 0.5
done

rm -f "\$MARKER"
exit 0
EOF
sudo chmod 0755 "$RESCUE_SCRIPT"

sudo tee "$RESCUE_UNIT" >/dev/null <<EOF
[Unit]
Description=MacBookPro6,2 rescue after interrupted Intel-primary NVIDIA-offload test
ConditionPathExists=$MARKER
Before=display-manager.service
After=systemd-modules-load.service

[Service]
Type=oneshot
ExecStart=$RESCUE_SCRIPT

[Install]
WantedBy=graphical.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mbp-intel-primary-offload-rescue.service >/dev/null

section "CREA WORKER"

cat > "$WORKER" <<EOF
#!/usr/bin/env bash
set -u
export LC_ALL=C

USER_NAME="$USER_NAME"
USER_HOME="$USER_HOME"
USER_UID="$USER_UID"
USER_GID="$USER_GID"
REPORT="$REPORT"
XORG_LINK="$XORG_LINK"
XORG_RUN="$XORG_RUN"
MARKER="$MARKER"
RESCUE_SCRIPT="$RESCUE_SCRIPT"
RESCUE_UNIT="$RESCUE_UNIT"
SW="$SW"
GLXINFO="$GLXINFO"
GLXGEARS="$GLXGEARS"

exec >>"\$REPORT" 2>&1

section() {
  printf '\\n================================================================\\n %s\\n================================================================\\n' "\$1"
}

run_user_x() {
  local auth="/run/user/\$USER_UID/gdm/Xauthority"
  if [ ! -r "\$auth" ]; then
    echo "Xauthority non disponibile: \$auth"
    return 1
  fi
  runuser -u "\$USER_NAME" -- env DISPLAY=:0 XAUTHORITY="\$auth" "\$@"
}

cleanup_rescue() {
  rm -f "\$MARKER"
  systemctl disable mbp-intel-primary-offload-rescue.service >/dev/null 2>&1 || true
  rm -f "\$RESCUE_UNIT" "\$RESCUE_SCRIPT"
  systemctl daemon-reload >/dev/null 2>&1 || true
}

rollback() {
  section "ROLLBACK NVIDIA PRIMARY"
  date
  systemctl stop display-manager.service >/dev/null 2>&1 || true
  sleep 3

  rm -f "\$XORG_LINK" "\$XORG_RUN"

  if [ -e "\$SW" ]; then
    printf '%s\n' MDIS > "\$SW" 2>/dev/null || true
  fi

  systemctl start display-manager.service >/dev/null 2>&1 || true
  sleep 12

  echo "--- switcheroo finale ---"
  cat "\$SW" 2>/dev/null || true
}

touch "\$MARKER"
START_ISO="\$(date --iso-8601=seconds)"

section "WORKER AVVIATO"
date
echo "Boot ID: \$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || true)"

section "CONFIGURA INTEL COME PRIMARYGPU"

mkdir -p /etc/X11/xorg.conf.d

cat > "\$XORG_RUN" <<'XORG'
Section "OutputClass"
    Identifier "MBP Intel Primary Offload Test"
    MatchDriver "i915"
    Driver "modesetting"
    Option "PrimaryGPU" "yes"
EndSection
XORG

ln -sfn "\$XORG_RUN" "\$XORG_LINK"
cat "\$XORG_RUN"

section "FERMA GDM E COMMUTA MUX SU INTEL"

systemctl stop display-manager.service >/dev/null 2>&1 || true
sleep 4

echo "--- prima MIGD ---"
cat "\$SW" || true
printf '%s\n' MIGD > "\$SW" 2>/dev/null
echo "MIGD rc=\$?"
echo "--- dopo MIGD ---"
cat "\$SW" || true

section "AVVIA DESKTOP INTEL PRIMARY"

systemctl start display-manager.service >/dev/null 2>&1 || true
sleep 20

echo "--- mapping Xorg ---"
journalctl -b --since "\$START_ISO" --no-pager 2>/dev/null \
  | grep -E 'PrimaryGPU|using drv /dev/dri/card|glamor X acceleration enabled|AIGLX|crocus|NVA5' \
  | tail -250 || true

section "NORMALIZZA PANNELLO: SOLO INTEL ATTIVO"

XR="\$(run_user_x xrandr --query 2>&1 || true)"
echo "\$XR" | grep -E 'Screen 0:| connected' || true

# Nella configurazione Intel-primary osservata finora:
# Intel = LVDS-2, NVIDIA secondaria = LVDS-1-1.
if grep -q '^LVDS-1-1 connected' <<<"\$XR"; then
  run_user_x xrandr --output LVDS-1-1 --off || true
fi

if grep -q '^LVDS-2 connected' <<<"\$XR"; then
  run_user_x xrandr --output LVDS-2 --primary --mode 1440x900 --pos 0x0 || true
fi

sleep 2
run_user_x xrandr --listactivemonitors 2>&1 || true
run_user_x xrandr --query 2>&1 | grep -E 'Screen 0:| connected' || true

section "SWITCHEROO-CONTROL DURANTE INTEL PRIMARY"

systemctl status switcheroo-control.service --no-pager 2>&1 || true
echo
busctl introspect net.hadess.SwitcherooControl /net/hadess/SwitcherooControl 2>&1 || true
echo
echo "--- proprieta GPUs raw ---"
busctl get-property \
  net.hadess.SwitcherooControl \
  /net/hadess/SwitcherooControl \
  net.hadess.SwitcherooControl \
  GPUs 2>&1 || true

section "TEST OPENGL DEFAULT: DEVE ESSERE INTEL"

DEFAULT_LOG="\$USER_HOME/Codex/glxinfo-intel-primary-default-$TS.txt"
run_user_x env LIBGL_DEBUG=verbose "\$GLXINFO" -B >"\$DEFAULT_LOG" 2>&1 || true
cat "\$DEFAULT_LOG"

section "TEST PRIME OFFLOAD: NVIDIA"

NV_LOG="\$USER_HOME/Codex/glxinfo-nvidia-offload-$TS.txt"
run_user_x env \
  DRI_PRIME=pci-0000_01_00_0 \
  DRI_PRIME_DEBUG=1 \
  LIBGL_DEBUG=verbose \
  "\$GLXINFO" -B >"\$NV_LOG" 2>&1 || true
cat "\$NV_LOG"

section "SINTESI RENDERER"

echo "--- DEFAULT ---"
grep -Ei 'direct rendering:|Accelerated:|OpenGL vendor string:|OpenGL renderer string:|driver crocus|driver nouveau|DRI_PRIME' \
  "\$DEFAULT_LOG" || true

echo
echo "--- NVIDIA OFFLOAD ---"
grep -Ei 'direct rendering:|Accelerated:|OpenGL vendor string:|OpenGL renderer string:|driver crocus|driver nouveau|DRI_PRIME' \
  "\$NV_LOG" || true

DEFAULT_OK=0
NV_OK=0

if grep -qi 'OpenGL renderer string:.*Intel' "\$DEFAULT_LOG" \
   && grep -qi 'Accelerated:[[:space:]]*yes' "\$DEFAULT_LOG"; then
  DEFAULT_OK=1
fi

if grep -qiE 'OpenGL renderer string:.*(NVA5|Nouveau|NVIDIA)' "\$NV_LOG" \
   && grep -qi 'Accelerated:[[:space:]]*yes' "\$NV_LOG"; then
  NV_OK=1
fi

echo
echo "Default Intel accelerata: \$DEFAULT_OK"
echo "NVIDIA PRIME accelerata : \$NV_OK"

section "STRESS LEGGERO NVIDIA 12s"

if [ -n "\$GLXGEARS" ] && [ -x "\$GLXGEARS" ]; then
  GEARS_LOG="\$USER_HOME/Codex/glxgears-nvidia-offload-$TS.txt"
  echo "Avvio glxgears su NVIDIA per 12 secondi..."
  set +e
  runuser -u "\$USER_NAME" -- env \
    DISPLAY=:0 \
    XAUTHORITY="/run/user/\$USER_UID/gdm/Xauthority" \
    DRI_PRIME=pci-0000_01_00_0 \
    DRI_PRIME_DEBUG=1 \
    LIBGL_DEBUG=verbose \
    timeout 12s "\$GLXGEARS" -info \
    >"\$GEARS_LOG" 2>&1
  GEARS_RC=\$?
  set -e
  cat "\$GEARS_LOG"
  echo "glxgears rc=\$GEARS_RC (124 e normale con timeout)"
else
  echo "glxgears non disponibile: salto."
fi

section "STATO DRM DURANTE OFFLOAD"

fuser -v /dev/dri/card* /dev/dri/renderD* 2>&1 || true
echo
cat "\$SW" 2>/dev/null || true

section "ERRORI GPU DEL TEST"

journalctl -k -b --since "\$START_ISO" --no-pager 2>/dev/null \
  | grep -Ei 'i915.*(error|hang|hung|reset|timeout)|nouveau.*(DATA_ERROR|INVALID_VALUE|RT_LINEAR_WITH_ZETA)|drm.*(hang|reset|timeout)|vga_switcheroo|apple.?gmux' \
  | tail -400 || true

section "CHECKPOINT GUI GNOME"

echo "Per circa 35 secondi il desktop resta Intel-primary."
echo "Puoi controllare in Panoramica applicazioni se col clic destro su un'icona"
echo "compare una voce tipo 'Avvia usando la scheda grafica dedicata'."
echo "Non e necessario avviare nulla: ci interessa sapere se la voce esiste."
sleep 35

rollback

section "RIEPILOGO FINALE"

echo "Default Intel accelerata: \$DEFAULT_OK"
echo "NVIDIA PRIME accelerata : \$NV_OK"

echo
echo "--- switcheroo-control GPUs osservate durante Intel-primary ---"
busctl get-property \
  net.hadess.SwitcherooControl \
  /net/hadess/SwitcherooControl \
  net.hadess.SwitcherooControl \
  GPUs 2>&1 || true

echo
echo "--- errori GPU finali ---"
journalctl -k -b --since "\$START_ISO" --no-pager 2>/dev/null \
  | grep -Ei 'i915.*(error|hang|hung|reset|timeout)|nouveau.*(DATA_ERROR|INVALID_VALUE|RT_LINEAR_WITH_ZETA)|drm.*(hang|reset|timeout)' \
  | tail -300 || true

cleanup_rescue
chown "\$USER_UID:\$USER_GID" "\$REPORT" "\$DEFAULT_LOG" "\$NV_LOG" 2>/dev/null || true

echo
echo "TEST TERMINATO E ROLLBACK COMPLETATO."
echo "REPORT: \$REPORT"
EOF

chmod +x "$WORKER"

section "TEST ARMATO"

echo "Tra 5 secondi:"
echo "  1. Xorg ripartira Intel-primary;"
echo "  2. NVIDIA restera accesa come GPU secondaria;"
echo "  3. verra testato PRIME offload verso NVIDIA;"
echo "  4. verranno lette le proprieta switcheroo-control;"
echo "  5. dopo la finestra GUI verra fatto rollback automatico."
echo
echo "Non viene eseguito IGD/OFF: NVIDIA NON verra spenta."
echo
echo "Report:"
echo "  $REPORT"

sudo systemd-run \
  --quiet \
  --collect \
  --unit="$TRANSIENT" \
  --on-active=5s \
  /bin/bash "$WORKER"

echo
echo "TEST AVVIATO."
