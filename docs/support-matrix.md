# Support matrix

The toolkit must distinguish **fully investigated**, **partially compatible**, and **unknown** hardware. Similar product names do not imply identical gmux, GPU routing or firmware behaviour.

## Hardware

| Model | Status | Intel GPU | NVIDIA GPU | gmux | Notes |
|---|---|---|---|---|---|
| MacBookPro6,2 (15-inch Mid 2010) | reference / fully investigated | Ironlake/Arrandale `8086:0046`, i915/Crocus | GT216M / GeForce GT 330M `10de:0a29`, Nouveau | classic Apple gmux | Primary target of current scripts and evidence |
| Other 2010 dual-GPU MacBook Pro models | unknown / future | verify | verify | verify | Use diagnostics only until topology is matched |
| 2011 AMD-gmux MacBook Pro models | not supported by current fix scripts | different | AMD dGPU | different failure modes | Do not reuse MacBookPro6,2 experimental scripts blindly |

## Software baseline on reference machine

| Component | Reference state | Maturity |
|---|---|---|
| Ubuntu | 24.04.4 LTS | proven reference |
| Kernel | 7.0.0-29-generic Ubuntu build | proven reference |
| Session | X11 | stable baseline |
| Wayland multi-GPU | known freeze path | rejected as stable baseline |
| OpenCore | 1.0.7 | proven |
| Intel kernel driver | i915 | proven |
| Intel Mesa driver | Crocus | proven |
| NVIDIA kernel driver | Nouveau | proven with known Chromium limitations |
| NVIDIA 340 | unsupported strategy | rejected |
| `apple_gmux` | 1.9.33 classic on reference kernel | proven |
| `vga_switcheroo` | available | proven |
| `switcheroo-control` | 2.6 on reference Ubuntu | proven, default-policy mismatch remains |

## Capability matrix

| Capability | Reference result | Status |
|---|---|---|
| Boot Ubuntu with NVIDIA firmware-default | works | stable reference |
| Both GPUs initialized under X11 | works | proven |
| Intel direct Mesa acceleration | works | proven |
| Physical panel route to Intel via gmux | works | proven |
| Intel-primary Xorg desktop | works and is fluid | proven |
| NVIDIA PRIME render offload from Intel-primary | works | proven |
| Persistent boot-safe Intel-primary policy | not finalized | planned / experimental next step |
| GNOME dedicated-GPU UX matching intended policy | not finalized | planned |
| NVIDIA automatic runtime suspend/resume | not yet validated | planned |
| Wayland hybrid graphics | severe failure on reference machine | rejected for stable path |
| EFI `gpu-power-prefs` runtime creation | rejected with `EINVAL` | rejected |

## Script policy by model

Stable scripts should either:

- be read-only and safe across unknown models, or
- positively identify the supported model/topology before making changes.

Experimental MacBookPro6,2 scripts must fail closed when the model or expected PCI devices do not match.

## Expanding support

Before declaring another model supported:

1. collect a full diagnostic report;
2. document PCI GPU IDs and gmux topology;
3. verify internal/external display routing;
4. verify actual driver stack;
5. rerun safe capability tests independently;
6. add a dedicated support-matrix row;
7. only then generalize scripts.
