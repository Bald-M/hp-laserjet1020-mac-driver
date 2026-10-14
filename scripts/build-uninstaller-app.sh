#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
app="${1:-}"
if [[ $# -ne 1 || "$app" != *.app ]]; then
  echo "Usage: $0 /path/to/Uninstall.app" >&2
  exit 2
fi
version="$(cat "$project_dir/VERSION")"
for tool in osacompile plutil codesign; do
  command -v "$tool" >/dev/null || { echo "Missing macOS tool: $tool" >&2; exit 1; }
done

mkdir -p "$(dirname "$app")"
osacompile -o "$app" "$project_dir/app/Uninstaller.applescript"
install -m 755 "$project_dir/Uninstall.command" "$app/Contents/Resources/Uninstall.command"
install -m 644 "$project_dir/LICENSE" "$app/Contents/Resources/LICENSE"
plutil -replace CFBundleIdentifier -string com.laserjet1020mackit.uninstaller "$app/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$version" "$app/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$version" "$app/Contents/Info.plist"
codesign --force --sign - "$app"
