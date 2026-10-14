#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
work_dir="$(mktemp -d "${TMPDIR:-/tmp/}laserjet1020-release-test.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
DIST_DIR="$work_dir/dist" "$project_dir/scripts/build-release.sh"
archive="$work_dir/dist/LaserJet1020MacKit-Uninstaller-$(cat "$project_dir/VERSION").zip"
mkdir -p "$work_dir/extracted"
/usr/bin/ditto -x -k "$archive" "$work_dir/extracted"
app="$work_dir/extracted/Uninstall LaserJet 1020 Mac Kit.app"
[[ -x "$app/Contents/MacOS/applet" ]]
[[ "$(plutil -extract CFBundleIdentifier raw -o - "$app/Contents/Info.plist")" == 'com.laserjet1020mackit.uninstaller' ]]
codesign --verify --deep --strict "$app"
cmp "$project_dir/Uninstall.command" "$app/Contents/Resources/Uninstall.command"
echo 'Release uninstaller test passed.'
