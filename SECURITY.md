# Security and recovery

This project touches boot configuration and GPU multiplexer state. A mistake can produce a black screen or an unbootable configuration.

Before running experimental scripts:

- keep a known-good EFI backup
- have a recovery boot route
- keep X11 available
- understand the rollback procedure
- never batch several boot-critical changes together

Please report scripts that fail to clean up after themselves as bugs.
