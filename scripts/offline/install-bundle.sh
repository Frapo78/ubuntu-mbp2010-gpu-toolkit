#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

BUNDLE=""
EXTRA_SETS=()
DRY_RUN=0
ALLOW_EXPERIMENTAL=0

usage(){
  cat <<'EOF'
Usage: install-bundle.sh /path/to/bundle [options]

Default behavior installs only package sets marked auto_install=true.
Conditional driver sets require BOTH explicit --set and --allow-experimental
until that driver path has been promoted by model-specific evidence.

Options:
  --set NAME             Explicitly install an additional package set (repeatable)
  --allow-experimental   Allow reviewed experimental conditional-driver sets
  --dry-run              Show selected sets/packages without installing
  -h, --help             Show help

Examples:
  install-bundle.sh /media/USB/mbp-rescue
  install-bundle.sh /media/USB/mbp-full --dry-run

After hardware classification only:
  install-bundle.sh /media/USB/mbp-full \
    --set wifi_broadcom_sta --allow-experimental

  install-bundle.sh /media/USB/mbp-full \
    --set wifi_b43_tools --allow-experimental
EOF
}

[ $# -gt 0 ] || { usage >&2; exit 2; }
BUNDLE="$1"; shift
while [ $# -gt 0 ]; do
  case "$1" in
    --set) EXTRA_SETS+=("${2:?missing set name}"); shift 2 ;;
    --allow-experimental) ALLOW_EXPERIMENTAL=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

BUNDLE="$(cd "$BUNDLE" && pwd)"
VERIFY="$BUNDLE/toolkit/scripts/offline/verify-bundle.sh"
[ -x "$VERIFY" ] || VERIFY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/verify-bundle.sh"
"$VERIFY" "$BUNDLE"

. /etc/os-release
CODENAME="${VERSION_CODENAME:-}"
ARCH="$(dpkg --print-architecture)"
MODEL="$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo unknown)"
KERNEL="$(uname -r)"

readarray -t META < <(python3 - "$BUNDLE/BUNDLE.json" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
print(m['suite'])
print(m['architecture'])
print(m['target_kernel'])
print(str(m.get('b43_firmware_captured',False)).lower())
PY
)
BUNDLE_SUITE="${META[0]}"
BUNDLE_ARCH="${META[1]}"
BUNDLE_KERNEL="${META[2]}"
B43_CAPTURED="${META[3]}"

if [ "$CODENAME" != "$BUNDLE_SUITE" ] || [ "$ARCH" != "$BUNDLE_ARCH" ]; then
  echo "Bundle/target mismatch." >&2
  echo "Target: suite=$CODENAME arch=$ARCH" >&2
  echo "Bundle: suite=$BUNDLE_SUITE arch=$BUNDLE_ARCH" >&2
  exit 5
fi

MANIFEST="$BUNDLE/package-sets.json"

# Default sets are only those explicitly marked safe for auto install.
mapfile -t SETS < <(python3 - "$MANIFEST" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
for name,s in m['sets'].items():
    if s.get('auto_install') is True:
        print(name)
PY
)

for s in "${EXTRA_SETS[@]}"; do
  if ! python3 - "$MANIFEST" "$s" <<'PY' >/dev/null
import json,sys
m=json.load(open(sys.argv[1]))
raise SystemExit(0 if sys.argv[2] in m['sets'] else 1)
PY
  then
    echo "Unknown package set: $s" >&2
    exit 6
  fi
  SETS+=("$s")
done

# Deduplicate sets.
mapfile -t SETS < <(printf '%s\n' "${SETS[@]}" | sed '/^$/d' | sort -u)

CONDITIONAL_SELECTED=0
for s in "${SETS[@]}"; do
  readarray -t INFO < <(python3 - "$MANIFEST" "$s" <<'PY'
import json,sys
x=json.load(open(sys.argv[1]))['sets'][sys.argv[2]]
print(x.get('status','unknown'))
print(x.get('class','unknown'))
PY
)
  STATUS="${INFO[0]}"
  CLASS="${INFO[1]}"

  case "$STATUS" in
    rejected|planned)
      echo "Refusing package set with maturity '$STATUS': $s" >&2
      exit 7
      ;;
    experimental)
      if [ "$CLASS" = "conditional_driver" ] && [ "$ALLOW_EXPERIMENTAL" -eq 1 ]; then
        echo "WARNING: explicitly allowing experimental conditional driver set: $s" >&2
      else
        echo "Refusing experimental set: $s" >&2
        echo "Only reviewed class=conditional_driver sets can be enabled with --allow-experimental." >&2
        exit 7
      fi
      ;;
    stable|proven) ;;
    *)
      echo "Refusing package set with unknown maturity '$STATUS': $s" >&2
      exit 7
      ;;
  esac

  if [ "$CLASS" = "conditional_driver" ]; then
    CONDITIONAL_SELECTED=1
  fi
done

if printf '%s\n' "${SETS[@]}" | grep -qx wifi_broadcom_sta; then
  if [ "$KERNEL" != "$BUNDLE_KERNEL" ]; then
    echo "Broadcom STA DKMS set requires matching kernel headers." >&2
    echo "Running kernel: $KERNEL" >&2
    echo "Bundle kernel:  $BUNDLE_KERNEL" >&2
    exit 8
  fi
fi

if printf '%s\n' "${SETS[@]}" | grep -qx wifi_b43_tools; then
  if [ "$B43_CAPTURED" != true ] || [ ! -d "$BUNDLE/firmware/b43" ]; then
    echo "Refusing offline b43 install: no captured b43 firmware payload in bundle." >&2
    echo "Rebuild online with --capture-b43 on a system that already has usable b43 firmware." >&2
    exit 9
  fi
fi

mapfile -t PACKAGES < <(python3 - "$MANIFEST" "$KERNEL" "${SETS[@]}" <<'PY'
import json,sys
m=json.load(open(sys.argv[1])); kernel=sys.argv[2]; sets=sys.argv[3:]
out=[]
for name in sets:
    for p in m['sets'][name]['packages']:
        p=p.replace('@KERNEL@',kernel)
        # Never run firmware-b43-installer offline: its normal behavior is to
        # fetch proprietary firmware from the network. A captured firmware
        # tree is installed separately below.
        if name=='wifi_b43_tools' and p=='firmware-b43-installer':
            continue
        if p not in out: out.append(p)
for p in out: print(p)
PY
)

echo "Target model:   $MODEL"
echo "Ubuntu:        $CODENAME/$ARCH"
echo "Kernel:        $KERNEL"
echo "Selected sets:"
printf '  %s\n' "${SETS[@]}"
echo "Packages:"
printf '  %s\n' "${PACKAGES[@]}"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN: no changes made."
  exit 0
fi

TS="$(date +%Y%m%d-%H%M%S)"
STATE="$HOME/Codex/offline-install-$TS"
WORK="/var/tmp/mbp-offline-$TS"
mkdir -p "$STATE"

# Checkpoint before any conditional driver package can change module policy.
if [ "$CONDITIONAL_SELECTED" -eq 1 ]; then
  mkdir -p "$STATE/modprobe.d-before"
  sudo cp -a /etc/modprobe.d/. "$STATE/modprobe.d-before/" 2>/dev/null || true
  lsmod > "$STATE/lsmod-before.txt"
  lspci -nnk > "$STATE/lspci-before.txt" 2>/dev/null || true
  rfkill list > "$STATE/rfkill-before.txt" 2>/dev/null || true
fi

mkdir -p "$WORK"
cp -a "$BUNDLE/debs" "$WORK/"
cp -a "$BUNDLE/BUNDLE.json" "$BUNDLE/package-sets.json" "$WORK/"
if [ -d "$BUNDLE/firmware" ]; then cp -a "$BUNDLE/firmware" "$WORK/"; fi

LIST="$WORK/offline.list"
printf 'deb [trusted=yes] file:%s/debs ./\n' "$WORK" > "$LIST"

APT_OPTS=(
  -o "Dir::Etc::sourcelist=$LIST"
  -o "Dir::Etc::sourceparts=-"
  -o "APT::Get::List-Cleanup=0"
  -o "Acquire::Languages=none"
)

cleanup(){
  rm -rf "$WORK" 2>/dev/null || true
}
trap cleanup EXIT

sudo apt-get "${APT_OPTS[@]}" update
sudo apt-get "${APT_OPTS[@]}" install -y --no-install-recommends "${PACKAGES[@]}"

if printf '%s\n' "${SETS[@]}" | grep -qx wifi_b43_tools; then
  echo "Installing captured b43 firmware payload."
  sudo mkdir -p /lib/firmware/b43
  sudo cp -a "$WORK/firmware/b43/." /lib/firmware/b43/
  sudo depmod -a
fi

{
  echo "date=$(date --iso-8601=seconds)"
  echo "model=$MODEL"
  echo "suite=$CODENAME"
  echo "arch=$ARCH"
  echo "kernel=$KERNEL"
  printf 'sets=%s\n' "$(IFS=,; echo "${SETS[*]}")"
  echo "allow_experimental=$ALLOW_EXPERIMENTAL"
} > "$STATE/install.txt"

dpkg-query -W "${PACKAGES[@]}" 2>/dev/null > "$STATE/packages-after.txt" || true

# Non-destructive post-install service/package checks.
systemctl is-enabled switcheroo-control.service 2>/dev/null || true
systemctl is-active switcheroo-control.service 2>/dev/null || true
systemctl is-active bluetooth.service 2>/dev/null || true

sync

echo
echo "Offline package installation complete."
echo "State/checkpoint: $STATE"
echo "No reboot was performed automatically."
echo "Run integration and subsystem postchecks before rebooting or applying further fixes."
