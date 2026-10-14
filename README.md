# LaserJet 1020 Mac Kit

English | [简体中文](README.zh-CN.md)

LaserJet 1020 Mac Kit builds a local macOS installer for the HP LaserJet 1020. The `.pkg` installs existing CUPS filters, firmware, a PPD, a printer setup app, and a graphical uninstaller, so users do not have to copy driver files manually.

This project does not reimplement the printer protocol. Its build inputs come from [anxkhn/hp1020-driver-mac](https://github.com/anxkhn/hp1020-driver-mac). That repository's filters contain **x86_64** code, not universal binaries. They run directly on Intel Macs; Apple silicon Macs need Rosetta. The package also relies on the legacy CUPS PPD driver mechanism, which future macOS versions may change. The reference repository reports that its driver works on macOS 26 Tahoe. This project's automated checks cover the package contents and PPD; printing still needs to be tested with a connected HP LaserJet 1020.

## Build local release files

You need macOS, Xcode Command Line Tools (for `pkgbuild` and `lipo`), and network access. From the project directory, run:

```sh
cd "$HOME/Code/laserjet1020-mac-kit"
make release
```

`make package` builds only the installer. `make release` builds both release assets: `dist/LaserJet1020MacKit-0.4.0.pkg` and `dist/LaserJet1020MacKit-Uninstaller-0.4.0.zip`. Upload both assets to the same release after checking the rights for the third-party driver files. The pinned reference files are downloaded into the ignored `build/upstream/` directory. If you already have a local copy of the reference repository, you can build offline with `make release SOURCE_DIR=/path/to/hp1020-driver-mac`. Open the `.pkg` in Finder to install, or use:

```sh
sudo installer -pkg dist/LaserJet1020MacKit-0.4.0.pkg -target /
```

These locally built release files are not Developer ID signed or notarized. This project does not publish packages containing the third-party driver assets. Check the rights for those assets before publishing or redistributing a package; see [THIRD_PARTY.md](THIRD_PARTY.md).

### Apple silicon Macs

Install Rosetta before installing the driver, following [Apple's instructions](https://support.apple.com/en-hk/102527):

```sh
softwareupdate --install-rosetta
```

## Add the printer

The installer places **LaserJet 1020 Mac Kit.app** in Applications. Open it to launch the printer setup tool in Terminal. The installer does not create a print queue automatically.

Connect and turn on the HP LaserJet 1020, then open the app and choose **Add Printer**. Select the detected USB device and enter an administrator password to create a dedicated print queue. You can also open `/Library/Application Support/LaserJet1020MacKit/AddPrinter.command` in Finder, or add the printer through **System Settings → Printers & Scanners** using **HP LaserJet 1020 (Mac Kit)** as its driver. If the driver is not listed, find the device URI and add the queue with CUPS:

```sh
lpinfo -v | grep -i usb
sudo lpadmin -p HP_LaserJet_1020 -E \
  -v 'usb://Hewlett-Packard/HP%20LaserJet%201020?serial=YOUR_SERIAL' \
  -P '/Library/Printers/PPDs/Contents/Resources/LaserJet 1020 Mac Kit.gz' \
  -D 'HP LaserJet 1020 (Mac Kit)'
```

Replace the example URI with the actual value from `lpinfo -v`. `lpadmin` may warn that PPD drivers are deprecated; this is a CUPS warning about legacy drivers. The setup tool creates a queue named `HP_LaserJet_1020_MacKit`; the manual command above creates `HP_LaserJet_1020`. After printing a test page or PDF, check the queue with `lpstat -p <queue-name>`.

## Uninstall

Open **Uninstall LaserJet 1020 Mac Kit.app** in Applications, click **Uninstall**, and approve the standard macOS administrator prompt. The graphical app handles the cleanup without Terminal. A standalone copy is also available in `dist/LaserJet1020MacKit-Uninstaller-0.4.0.zip`, so it can be used even if the printer setup app has already been deleted.

Deleting the printer setup app through **System Settings → General → Storage → Applications** does not run the uninstaller. Run the standalone uninstaller for complete cleanup.

You can also open `/Library/Application Support/LaserJet1020MacKit/Uninstall.command` in Finder, or preview and run it in Terminal:

```sh
'/Library/Application Support/LaserJet1020MacKit/Uninstall.command' --dry-run
'/Library/Application Support/LaserJet1020MacKit/Uninstall.command'
```

The uninstaller removes both installed apps, the driver directory, the PPD, the support directory, and the package receipt. It removes every local print queue whose active PPD still points to this project's filter, including queues added manually. Queues using a different driver remain. Downloaded `.pkg` and `.zip` files are not installed files and remain wherever you saved them. The package uses its own directory and does not overwrite files manually installed from the reference repository under `/Library/Printers/hp/laserjet/`.

## Development and verification

```sh
make test
```

The tests build and extract a temporary package and standalone uninstaller archive. They check the filters, firmware, PPD, both apps, queue identification, app signatures, and rewritten PPD paths. They do not install anything system-wide or prove that printing works with real hardware.

### Verified build environment (October 14, 2026)

The local release files were built and checked on this machine with:

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
