# LaserJet 1020 Mac Kit

LaserJet 1020 Mac Kit builds a local macOS installer for the HP LaserJet 1020. The `.pkg` installs existing CUPS filters, firmware, a PPD, and a manager app, so users do not have to copy driver files manually.

This project does not reimplement the printer protocol. Its build inputs come from [anxkhn/hp1020-driver-mac](https://github.com/anxkhn/hp1020-driver-mac). That repository's filters contain **x86_64** code, not universal binaries. They run directly on Intel Macs; Apple silicon Macs need Rosetta. The package also relies on the legacy CUPS PPD driver mechanism, which future macOS versions may change. The reference repository reports that its driver works on macOS 26 Tahoe. This project's automated checks cover the package contents and PPD; printing still needs to be tested with a connected HP LaserJet 1020.

## Build the installer

You need macOS, Xcode Command Line Tools (for `pkgbuild` and `lipo`), and network access. From the project directory, run:

```sh
cd "$HOME/Code/laserjet1020-mac-kit"
make package
```

The pinned reference files are downloaded into the ignored `build/upstream/` directory. If you already have a local copy of the reference repository, you can build offline with `make package SOURCE_DIR=/path/to/hp1020-driver-mac`. The output is `dist/LaserJet1020MacKit-0.3.0.pkg`. Open it in Finder to install, or use:

```sh
sudo installer -pkg dist/LaserJet1020MacKit-0.3.0.pkg -target /
```

The locally built installer is not signed or notarized for distribution. This project does not publish packages containing the third-party driver assets. Check the rights for those assets before publishing or redistributing a package; see [THIRD_PARTY.md](THIRD_PARTY.md).

### Apple silicon Macs

Install Rosetta before installing the driver, following [Apple's instructions](https://support.apple.com/en-hk/102527):

```sh
softwareupdate --install-rosetta
```

## Add the printer

The installer places **LaserJet 1020 Mac Kit.app** in Applications. Open it to launch the printer setup or uninstall tool in Terminal. The installer does not create a print queue automatically.

Connect and turn on the HP LaserJet 1020, then open the app and choose **添加打印机** (Add Printer). Select the detected USB device and enter an administrator password to create a dedicated print queue. You can also open `/Library/Application Support/LaserJet1020MacKit/AddPrinter.command` in Finder, or add the printer through **System Settings → Printers & Scanners** using **HP LaserJet 1020 (Mac Kit)** as its driver. If the driver is not listed, find the device URI and add the queue with CUPS:

```sh
lpinfo -v | grep -i usb
sudo lpadmin -p HP_LaserJet_1020 -E \
  -v 'usb://Hewlett-Packard/HP%20LaserJet%201020?serial=YOUR_SERIAL' \
  -P '/Library/Printers/PPDs/Contents/Resources/LaserJet 1020 Mac Kit.gz' \
  -D 'HP LaserJet 1020 (Mac Kit)'
```

Replace the example URI with the actual value from `lpinfo -v`. `lpadmin` may warn that PPD drivers are deprecated; this is a CUPS warning about legacy drivers. The setup tool creates a queue named `HP_LaserJet_1020_MacKit`; the manual command above creates `HP_LaserJet_1020`. After printing a test page or PDF, check the queue with `lpstat -p <queue-name>`.

## Uninstall

Open **LaserJet 1020 Mac Kit.app** in Applications and choose **卸载驱动** (Uninstall Driver). In Terminal, type `REMOVE` and enter an administrator password when prompted. Deleting the app from **System Settings → General → Storage → Applications** removes only the app, not the printer driver.

You can also open `/Library/Application Support/LaserJet1020MacKit/Uninstall.command` in Finder, or preview and run it in Terminal:

```sh
'/Library/Application Support/LaserJet1020MacKit/Uninstall.command' --dry-run
'/Library/Application Support/LaserJet1020MacKit/Uninstall.command'
```

The uninstaller removes this project's app, driver files, and package receipt. It also removes the queue created by the setup tool if that queue still uses this project's PPD. Manually created queues and queues switched to a different PPD remain; remove them in **System Settings → Printers & Scanners** if needed. The package uses its own directory and does not overwrite files manually installed from the reference repository under `/Library/Printers/hp/laserjet/`.

## Development and verification

```sh
make test
```

The tests build and extract a temporary package, then check its filters, firmware, PPD, manager app, uninstaller, and rewritten PPD paths. They do not install anything system-wide or prove that printing works with real hardware.

## License and provenance

The scripts and documentation written for this project are licensed under the [MIT License](LICENSE). The reference repository's filters, firmware, and PPD are **not covered by this project's MIT license** and are not committed to this repository. See [THIRD_PARTY.md](THIRD_PARTY.md) for their provenance and rights. This project is not affiliated with HP or Apple.
