# Changelog

## 0.3.0 — 2026-10-14

- Added a manager app in Applications to open the printer setup and driver uninstaller tools.
- Made the uninstaller remove the manager app when it belongs to this project.

## 0.2.0 — 2026-10-14

- Added a guided USB printer queue setup tool with vendor and model matching.
- Made uninstall remove the tool-created queue when it still uses this kit's PPD.

## 0.1.0 — 2026-10-14

- Added a macOS `.pkg` builder with a pinned local download of the reference driver assets or an offline source directory.
- Rewrote PPD references into a project-owned directory and corrected two malformed JCL UI terminators.
- Added an interactive uninstaller, package smoke test, documentation, and MIT licensing for original project files.
