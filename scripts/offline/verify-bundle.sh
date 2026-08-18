#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

BUNDLE="${1:-}"
[ -n "$BUNDLE" ] || { echo "Usage: verify-bundle.sh /path/to/bundle" >&2; exit 2; }
BUNDLE="$(cd "$BUNDLE" && pwd)"

for f in BUNDLE.json SHA256SUMS requested-packages.txt package-sets.json debs/Packages.gz; do
  [ -e "$BUNDLE/$f" ] || { echo "Missing bundle component: $f" >&2; exit 3; }
done

python3 - "$BUNDLE/BUNDLE.json" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
need=['schema_version','profile','suite','architecture','target_kernel']
missing=[x for x in need if x not in m]
if missing:
    raise SystemExit('Missing metadata keys: '+', '.join(missing))
print('profile='+str(m['profile']))
print('suite='+str(m['suite']))
print('architecture='+str(m['architecture']))
print('target_kernel='+str(m['target_kernel']))
print('b43_firmware_captured='+str(m.get('b43_firmware_captured',False)).lower())
PY

(
  cd "$BUNDLE"
  sha256sum -c SHA256SUMS
)

DEB_COUNT="$(find "$BUNDLE/debs" -maxdepth 1 -type f -name '*.deb' | wc -l)"
[ "$DEB_COUNT" -gt 0 ] || { echo "No .deb packages found" >&2; exit 4; }

echo
echo "Bundle verification PASSED ($DEB_COUNT deb files)."
