# Third-party driver assets

The package builder accepts these files from [anxkhn/hp1020-driver-mac](https://github.com/anxkhn/hp1020-driver-mac):

| Input | Purpose |
| --- | --- |
| `HP LaserJet 1022.gz` | HP PPD used as the basis for the rewritten PPD |
| `rasterToHPZJS` | CUPS raster filter |
| `commandToHPZJS` | CUPS command filter |
| `hp1020.acl` | Printer firmware initialization data |

The build was validated with upstream commit `f9d2f7e2a22b7bfb80d4cb51e42de61c88f7dfdc`. The upstream README says these assets were extracted from Apple's HP Printer Drivers package and identifies HP and other owners' rights. The upstream repository does not provide a license granting redistribution of these assets. This project's MIT license applies only to its original scripts and documentation, not to the input assets or the resulting package payload. A locally built `.pkg` contains the four inputs; assess rights before distributing it.

The upstream README describes the filters as universal, but `lipo -info` on this commit reports only `x86_64` for both executables. Apple silicon operation therefore depends on Rosetta and has not been verified with a physical printer in this project.
