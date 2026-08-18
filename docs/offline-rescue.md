# Offline USB rescue bundles

A core project goal is to make common diagnostics and fixes possible **without working Wi-Fi or Internet access on the affected MacBook**.

The repository therefore contains an offline-bundle workflow rather than embedding binary packages directly in Git.

## Why bundles are generated, not committed

- Ubuntu packages receive security/point updates.
- Some packages depend on the exact kernel version.
- DKMS Wi-Fi drivers require matching kernel headers.
- `linux-firmware` is very large.
- A generated bundle can record exact package versions and SHA-256 hashes.
- The bundle can be rebuilt from official Ubuntu repositories without rewriting the toolkit code.

## Workflow

On an Ubuntu 24.04 amd64 machine with Internet access:

```bash
./scripts/offline/prepare-bundle.sh --profile rescue --output /media/$USER/USB/mbp-rescue
```

For the broadest recovery kit:

```bash
./scripts/offline/prepare-bundle.sh \
  --profile full \
  --kernel 7.0.0-29-generic \
  --output /media/$USER/USB/mbp-rescue-full
```

The exact kernel value matters for package sets that include `linux-headers-@KERNEL@`.

On the offline Mac:

```bash
./scripts/offline/verify-bundle.sh /path/to/mbp-rescue
./scripts/offline/install-bundle.sh /path/to/mbp-rescue
```

The installer creates a temporary **file:// APT repository** pointing only at the bundle, installs the selected safe package sets, then removes the temporary source configuration.

## Bundle layout

```text
mbp-rescue/
├── BUNDLE.json
├── SHA256SUMS
├── requested-packages.txt
├── package-sets.json
├── debs/
│   ├── Packages.gz
│   └── *.deb
├── firmware/
│   └── b43/              # only when explicitly captured
└── toolkit/
    ├── scripts/
    ├── docs/
    ├── knowledge/
    ├── profiles/
    └── packages/
```

## Profiles

### `minimal`

Smallest diagnostic kit. Intended to answer *what is wrong?* without changing drivers or firmware policy.

### `rescue`

Adds stable runtime/core packages such as the firmware baseline and dual-GPU service.

### `full`

Downloads all non-experimental package sets, including conditional Wi-Fi driver packages. **Presence in the USB bundle does not mean automatic installation.** Conditional drivers remain gated by hardware classification.

## Broadcom Wi-Fi

The full bundle may contain both the Broadcom STA packages and b43 tooling so the correct path is available even when the Mac has no network.

The offline installer must still choose only the classified driver path.

### STA / `wl`

The set includes:

- `broadcom-sta-dkms`
- `dkms`
- matching `linux-headers-<kernel>`

A kernel mismatch is a reason to stop, not to force DKMS installation.

### b43

`firmware-b43-installer` normally downloads firmware from the network during its installation process. Merely caching its `.deb` is **not sufficient for a guaranteed offline repair**.

The builder can mark a bundle `b43_firmware_captured=true` only when a pre-existing usable `/lib/firmware/b43/` tree is copied into the bundle. The target installer can then install that payload without contacting the network.

The project does not commit or redistribute proprietary b43 firmware directly.

## Safe installation policy

Offline installation follows the same safety contract as online actions:

1. verify bundle checksums;
2. verify Ubuntu codename and architecture;
3. inspect DMI model and hardware topology;
4. install stable diagnostic/runtime sets first;
5. never install conditional driver sets merely because they are present;
6. checkpoint relevant configuration before driver/policy changes;
7. postcheck the affected subsystem.

## Future release artifacts

Once the package/action framework is stable, GitHub Releases may publish prebuilt rescue bundles for specific supported Ubuntu/model combinations.

Those artifacts must still include:

- build date;
- suite and architecture;
- exact package versions;
- target kernel for DKMS/header payloads;
- SHA-256 manifest;
- toolkit commit SHA;
- maturity/support label.
