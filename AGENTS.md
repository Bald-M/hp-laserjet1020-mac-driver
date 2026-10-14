# Agent instructions

This repository contains the MIT-licensed packaging layer for HP LaserJet 1020 Mac Driver. The four input driver assets live outside this repository; see `THIRD_PARTY.md` before changing asset handling.

For packaging changes, build and run the payload smoke test with the pinned local cache or a supplied checkout:

```sh
make test
# Or: make test SOURCE_DIR=/path/to/hp1020-driver-mac
```

Keep the package ID and filter/support paths under `LaserJet1020MacKit` for upgrades and existing print queues. The current PPD is `/Library/Printers/PPDs/Contents/Resources/HP LaserJet 1020 Mac Driver.gz`; the setup app is `/Applications/HP LaserJet 1020 Mac Driver.app`. The shell uninstaller stays at `/Library/Application Support/LaserJet1020MacKit/uninstall.sh`. A queue using this driver's filter is a dependency: never delete queues automatically during uninstall. Stop before changing files when any queue still depends on the driver. Keep the package upgrade script and uninstaller in sync when installed paths change. Inspect the package payload, app signature, upgrade script, and rewritten PPD before claiming a build works. Real printer compatibility requires hardware testing; report that separately from package validation. Do not commit `build/`, `dist/`, or third-party driver assets.
