# OpenCore notes

## Reference state

The reference machine was upgraded successfully to OpenCore **1.0.7** and subsequently booted Ubuntu.

The configuration was first validated with the matching Linux build of `ocvalidate`.

A single validation issue was found:

```text
Misc -> BlessOverride -> \EFI\Microsoft\Boot\bootmgfw.efi
```

OpenCore 1.0.7 considers that path redundant. Removing only that entry allowed the existing configuration to validate.

## Safe update method

1. Back up the complete EFI directory.
2. Download an official OpenCore release.
3. Use the **matching** `ocvalidate.linux`.
4. Validate a copy of the current `config.plist`.
5. Stage the new OpenCore components outside the real ESP.
6. Validate again.
7. Update only after hashes and referenced files are coherent.
8. Keep a rollback script and an EFI backup.
9. Change only one boot variable at a time.

## Important warning

The machine's EFI also contains OCLP-related NVRAM/config markers. Do not blindly replace the entire EFI directory with a stock OpenCore package.

OpenCore upgrades and GPU-policy experiments should be separate operations so a failed boot has only one variable to diagnose.
