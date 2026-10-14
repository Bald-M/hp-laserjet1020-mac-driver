# Agent instructions

This repository contains the MIT-licensed packaging layer for LaserJet 1020 Mac Kit. The four input driver assets live outside this repository; see `THIRD_PARTY.md` before changing asset handling.

For packaging changes, build and run the payload smoke test with the pinned local cache or a supplied checkout:

```sh
make test
# Or: make test SOURCE_DIR=/path/to/hp1020-driver-mac
```

Keep driver files under `/Library/Printers/LaserJet1020MacKit` and the uniquely named PPD. The setup app belongs in `/Applications/LaserJet 1020 Mac Kit.app`; the shell uninstaller belongs in `/Library/Application Support/LaserJet1020MacKit/uninstall.sh`. A queue using this kit's filter is a dependency, not proof that the kit created the queue: never delete queues automatically during uninstall. Stop before changing files when any queue still depends on the driver. Keep the package upgrade script and uninstaller in sync when installed paths change. Inspect the package payload, app signature, upgrade script, and rewritten PPD before claiming a build works. Real printer compatibility requires hardware testing; report that separately from package validation. Do not commit `build/`, `dist/`, or third-party driver assets.
