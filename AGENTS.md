# Agent instructions

This repository contains the MIT-licensed packaging layer for LaserJet 1020 Mac Kit. The four input driver assets live outside this repository; see `THIRD_PARTY.md` before changing asset handling.

For packaging changes, build and run the payload smoke test with the pinned local cache or a supplied checkout:

```sh
make test
# Or: make test SOURCE_DIR=/path/to/hp1020-driver-mac
```

Keep driver files under `/Library/Printers/LaserJet1020MacKit` and the uniquely named PPD. The setup and uninstaller apps belong in `/Applications/LaserJet 1020 Mac Kit.app` and `/Applications/Uninstall LaserJet 1020 Mac Kit.app`. Update both copies of the uninstaller whenever installed paths change. Inspect the package payload, app signatures, standalone uninstaller archive, and rewritten PPD before claiming a build works. Real printer compatibility requires hardware testing; report that separately from package validation. Do not commit `build/`, `dist/`, or third-party driver assets.
