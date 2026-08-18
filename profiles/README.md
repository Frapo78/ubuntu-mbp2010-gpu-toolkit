# Hardware profiles

Profiles describe **measured platform facts** used to gate diagnosis and future actions.

They are not fix scripts.

## Current reference profile

`MacBookPro6,2.json` is the fully investigated 15-inch Mid 2010 reference machine.

## What belongs in a profile

- DMI model identifier;
- GPU PCI addresses and IDs;
- expected kernel/userspace drivers;
- mux topology/control mechanism;
- reference software baseline;
- proven capabilities;
- known hard prohibitions;
- expected stable-state signals.

## What does not belong in a profile

- user/account data;
- serial numbers;
- raw logs;
- speculative fixes;
- mutation commands;
- assumptions copied from a different Mac generation.

## Adding another model

Before adding a model as supported:

1. collect a real-machine diagnostic report;
2. verify GPU PCI topology;
3. verify gmux / `vga_switcheroo` behaviour;
4. verify display routing;
5. verify driver/Mesa stack;
6. document which existing cases reproduce;
7. add the profile;
8. update `docs/support-matrix.md`;
9. ensure model-specific scripts fail closed outside their supported profiles.

A similar marketing name is not sufficient evidence of compatibility.
