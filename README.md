# HP LaserJet 1020 Mac Driver

English | [简体中文](README.zh-CN.md)

HP LaserJet 1020 Mac Driver builds a local macOS installer for the HP LaserJet 1020 printer. The `.pkg` installs existing CUPS filters, firmware, a PPD, a printer setup app, and a shell uninstaller, so users do not have to copy driver files manually.

This project does not reimplement the printer protocol. Its build inputs come from [anxkhn/hp1020-driver-mac](https://github.com/anxkhn/hp1020-driver-mac). That repository's filters contain **x86_64** code, not universal binaries. They run directly on Intel Macs; Apple silicon Macs need Rosetta. The package also relies on the legacy CUPS PPD driver mechanism, which future macOS versions may change. The reference repository reports that its driver works on macOS 26 Tahoe. This project's automated checks cover the package contents and PPD; printing still needs to be tested with a connected HP LaserJet 1020.

## Build local release files

You need macOS, Xcode Command Line Tools (for `pkgbuild` and `lipo`), and network access. From the project directory, run:

```sh
cd "$HOME/Code/hp-laserjet1020-mac-driver"
make release
```

`make package` or `make release` builds one release asset: `dist/HPLaserJet1020MacDriver-0.7.0.pkg`. Check the rights for the third-party driver files before publishing it. The pinned reference files are downloaded into the ignored `build/upstream/` directory. If you already have a local copy of the reference repository, you can build offline with `make release SOURCE_DIR=/path/to/hp1020-driver-mac`. Open the `.pkg` in Finder to install, or use:

```sh
sudo installer -pkg dist/HPLaserJet1020MacDriver-0.7.0.pkg -target /
```

This locally built package is not Developer ID signed or notarized. This project does not publish packages containing the third-party driver assets. Check the rights for those assets before publishing or redistributing a package; see [THIRD_PARTY.md](THIRD_PARTY.md).

### Apple silicon Macs

Install Rosetta before installing the driver, following [Apple's instructions](https://support.apple.com/en-hk/102527):

```sh
softwareupdate --install-rosetta
```

## Add the printer

The installer places **HP LaserJet 1020 Mac Driver.app** in Applications. Open it to launch the printer setup tool in Terminal. The installer does not create a print queue automatically.

Connect and turn on the HP LaserJet 1020, then open the app and choose **Add Printer**. Select the detected USB device and enter an administrator password to create a dedicated print queue. You can also open `/Library/Application Support/LaserJet1020MacKit/AddPrinter.command` in Finder, or add the printer through **System Settings → Printers & Scanners** using **HP LaserJet 1020 Mac Driver** as its driver. If the driver is not listed, find the device URI and add the queue with CUPS:

```sh
lpinfo -v | grep -i usb
sudo lpadmin -p HP_LaserJet_1020 -E \
  -v 'usb://Hewlett-Packard/HP%20LaserJet%201020?serial=YOUR_SERIAL' \
  -P '/Library/Printers/PPDs/Contents/Resources/HP LaserJet 1020 Mac Driver.gz' \
  -D 'HP LaserJet 1020 Mac Driver'
```

Replace the example URI with the actual value from `lpinfo -v`. `lpadmin` may warn that PPD drivers are deprecated; this is a CUPS warning about legacy drivers. The setup tool creates a queue named `HP_LaserJet_1020_MacDriver`; the manual command above creates `HP_LaserJet_1020`. An existing `HP_LaserJet_1020_MacKit` queue is left in place during upgrades. After printing a test page or PDF, check the queue with `lpstat -p <queue-name>`.

## Uninstall

Run the installed shell script in Terminal. It asks you to type `REMOVE` and then requests administrator privileges:

```sh
'/Library/Application Support/LaserJet1020MacKit/uninstall.sh'
```

Deleting the printer setup app through **System Settings → General → Storage → Applications** does not run the uninstaller. Run the shell script for complete cleanup.

If any print queue still uses this driver's filter, including a manually added SMB queue, the script stops before changing files or queues. Change that queue to another driver or remove it in **Printers & Scanners**, then run the script again. The script never deletes printer queues automatically.

When no queue depends on the driver, the script removes the setup app, driver directory, PPD, support directory, and package receipt. It also removes the former Mac Kit app and PPD, plus any leftover graphical uninstaller app or receipt from versions 0.4–0.5. Internal driver paths and package IDs retain `LaserJet1020MacKit` for upgrade compatibility. The downloaded `.pkg` is not an installed file and remains wherever you saved it. The package uses its own directory and does not overwrite files manually installed from the reference repository under `/Library/Printers/hp/laserjet/`.

## Development and verification

```sh
make test
```

The tests build and extract a temporary installer package. They check the filters, firmware, PPD, setup app, uninstaller script, upgrade cleanup script, queue dependency guard, app signature, and rewritten PPD paths. They do not install anything system-wide or prove that printing works with real hardware.

### Verified build environment (October 14, 2026)

The local release package was built and checked on this machine with:

| Component | Version |
| --- | --- |
| macOS | 15.2 (build 24C2101), Apple silicon (`arm64`) |
| Xcode Command Line Tools | 16.2.0.0.1.1733547573 (active developer directory: `/Library/Developer/CommandLineTools`) |
| Apple clang | 16.0.0 (`clang-1600.0.26.6`) |
| GNU Make | 3.81 |
| ShellCheck | 0.11.0 |
| Apple Git | 2.39.5 (`Apple Git-154`) |

Full Xcode is not installed in the active developer directory. These are the versions used for this build, not minimum supported versions.

## License and provenance

The scripts and documentation written for this project are licensed under the [MIT License](LICENSE). The reference repository's filters, firmware, and PPD are **not covered by this project's MIT license** and are not committed to this repository. See [THIRD_PARTY.md](THIRD_PARTY.md) for their provenance and rights. This project is not affiliated with HP or Apple.
