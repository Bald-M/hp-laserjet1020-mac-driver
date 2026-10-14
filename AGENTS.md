# Agent instructions

This repository contains the MIT-licensed packaging layer for LaserJet 1020 Mac Kit. The four input driver assets live outside this repository; see `THIRD_PARTY.md` before changing asset handling.

For packaging changes, build and run the payload smoke test with a local checkout of the reference repository:

```sh
make test SOURCE_DIR=/path/to/hp1020-driver-mac
```

Keep installation paths under `/Library/Printers/LaserJet1020MacKit` and the uniquely named PPD. Update the uninstaller whenever installed paths change. Inspect both the package payload and the rewritten PPD before claiming a build works. Real printer compatibility requires hardware testing; report that separately from package validation. Do not commit `dist/` or third-party driver assets.
