#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

PROFILE="rescue"
OUTPUT=""
TARGET_KERNEL="$(uname -r)"
CAPTURE_B43=0
SKIP_UPDATE=0

usage(){
  cat <<'EOF'
Usage: prepare-bundle.sh [options]

Build an offline APT/diagnostic bundle from official Ubuntu repositories.

Options:
  --profile minimal|rescue|full   Bundle profile (default: rescue)
  --output PATH                   Output directory (required)
  --kernel VERSION                Target kernel for @KERNEL@ packages
  --capture-b43                   Copy existing /lib/firmware/b43 into bundle
  --skip-update                   Do not run apt-get update
  -h, --help                      Show help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="${2:?missing profile}"; shift 2 ;;
    --output) OUTPUT="${2:?missing output}"; shift 2 ;;
    --kernel) TARGET_KERNEL="${2:?missing kernel}"; shift 2 ;;
    --capture-b43) CAPTURE_B43=1; shift ;;
    --skip-update) SKIP_UPDATE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$OUTPUT" ] || { echo "--output is required" >&2; exit 2; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MANIFEST="$ROOT/packages/manifests/noble-amd64.json"

[ -f "$MANIFEST" ] || { echo "Manifest not found: $MANIFEST" >&2; exit 3; }

. /etc/os-release
CODENAME="${VERSION_CODENAME:-}"
ARCH="$(dpkg --print-architecture)"

if [ "$CODENAME" != "noble" ] || [ "$ARCH" != "amd64" ]; then
  echo "This reference builder currently supports Ubuntu noble amd64 only." >&2
  echo "Detected: codename=$CODENAME arch=$ARCH" >&2
  exit 4
fi

case "$PROFILE" in minimal|rescue|full) ;; *) echo "Invalid profile: $PROFILE" >&2; exit 2 ;; esac

mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"
DEBS="$OUTPUT/debs"
mkdir -p "$DEBS" "$OUTPUT/toolkit" "$OUTPUT/firmware"

if [ "$SKIP_UPDATE" -eq 0 ]; then
  sudo apt-get update
fi

if ! command -v dpkg-scanpackages >/dev/null 2>&1; then
  echo "Installing dpkg-dev on the online builder (needed only to build Packages.gz)."
  sudo apt-get install -y dpkg-dev
fi

mapfile -t SETS < <(python3 - "$MANIFEST" "$PROFILE" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
for x in m['bundle_profiles'][sys.argv[2]]:
    print(x)
PY
)

mapfile -t REQUESTED < <(python3 - "$MANIFEST" "$PROFILE" "$TARGET_KERNEL" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
profile=sys.argv[2]
kernel=sys.argv[3]
out=[]
for setname in m['bundle_profiles'][profile]:
    for p in m['sets'][setname]['packages']:
        p=p.replace('@KERNEL@',kernel)
        if p not in out: out.append(p)
for p in out: print(p)
PY
)

printf '%s\n' "${REQUESTED[@]}" > "$OUTPUT/requested-packages.txt"
cp "$MANIFEST" "$OUTPUT/package-sets.json"

# Resolve a practical dependency closure from APT metadata. The target is an
# already-installed Ubuntu system, but including recursive Depends/PreDepends
# makes the USB substantially more resilient to partially missing packages.
mapfile -t RESOLVED < <(
  apt-cache depends --recurse \
    --no-recommends --no-suggests --no-conflicts --no-breaks \
    --no-replaces --no-enhances \
    "${REQUESTED[@]}" 2>/dev/null \
  | awk '/^[A-Za-z0-9][A-Za-z0-9+.:~-]*$/ {print $1}' \
  | sort -u
)

# Ensure every explicitly requested package stays in the download list.
ALL_PKGS="$(printf '%s\n' "${REQUESTED[@]}" "${RESOLVED[@]}" | sed '/^$/d' | sort -u)"
printf '%s\n' "$ALL_PKGS" > "$OUTPUT/resolved-packages.txt"

pushd "$DEBS" >/dev/null
FAILED=()
while IFS= read -r pkg; do
  [ -n "$pkg" ] || continue
  echo "Downloading $pkg"
  if ! apt-get download "$pkg" >/dev/null 2>&1; then
    FAILED+=("$pkg")
  fi
done <<< "$ALL_PKGS"
popd >/dev/null

if [ "${#FAILED[@]}" -gt 0 ]; then
  printf 'WARNING: packages not downloaded:\n' >&2
  printf '  %s\n' "${FAILED[@]}" >&2
  printf '%s\n' "${FAILED[@]}" > "$OUTPUT/download-failures.txt"
fi

# Build a local flat APT repository index.
pushd "$DEBS" >/dev/null
dpkg-scanpackages . /dev/null > Packages 2>/dev/null
gzip -9c Packages > Packages.gz
popd >/dev/null

B43_CAPTURED=false
if [ "$CAPTURE_B43" -eq 1 ]; then
  if [ -d /lib/firmware/b43 ] && find /lib/firmware/b43 -type f -print -quit | grep -q .; then
    mkdir -p "$OUTPUT/firmware/b43"
    cp -a /lib/firmware/b43/. "$OUTPUT/firmware/b43/"
    B43_CAPTURED=true
  else
    echo "WARNING: --capture-b43 requested but /lib/firmware/b43 is unavailable." >&2
  fi
fi

# Copy the auditable toolkit alongside the packages.
for d in scripts docs knowledge profiles packages tests .github; do
  [ -e "$ROOT/$d" ] && cp -a "$ROOT/$d" "$OUTPUT/toolkit/"
done
for f in README.md AGENTS.md SECURITY.md CONTRIBUTING.md LICENSE CHANGELOG.md; do
  [ -f "$ROOT/$f" ] && cp -a "$ROOT/$f" "$OUTPUT/toolkit/"
done

(
  cd "$OUTPUT"
  find debs firmware toolkit -type f -print0 \
    | sort -z \
    | xargs -0 sha256sum > SHA256SUMS
)

COMMIT="unknown"
if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  COMMIT="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
fi

python3 - "$OUTPUT/BUNDLE.json" "$PROFILE" "$CODENAME" "$ARCH" "$TARGET_KERNEL" "$COMMIT" "$B43_CAPTURED" "${#REQUESTED[@]}" <<'PY'
import json,sys,datetime
path,profile,suite,arch,kernel,commit,b43,count=sys.argv[1:]
data={
  'schema_version':1,
  'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
  'profile':profile,
  'suite':suite,
  'architecture':arch,
  'target_kernel':kernel,
  'toolkit_commit':commit,
  'b43_firmware_captured': b43.lower()=='true',
  'requested_package_count':int(count),
  'install_policy':'stable-auto_conditional-manual'
}
json.dump(data,open(path,'w'),indent=2,sort_keys=True)
PY

echo
echo "Bundle created: $OUTPUT"
echo "Profile:        $PROFILE"
echo "Target kernel:  $TARGET_KERNEL"
echo "b43 captured:   $B43_CAPTURED"
echo "DEBs:           $(find "$DEBS" -maxdepth 1 -name '*.deb' | wc -l)"
echo
echo "Before using it offline, run:"
echo "  $OUTPUT/toolkit/scripts/offline/verify-bundle.sh '$OUTPUT'"
