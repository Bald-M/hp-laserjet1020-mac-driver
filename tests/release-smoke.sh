#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
work_dir="$(mktemp -d "${TMPDIR:-/tmp/}laserjet1020-release-test.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
DIST_DIR="$work_dir/dist" "$project_dir/scripts/build-release.sh"
package="$work_dir/dist/LaserJet1020MacKit-Uninstaller-$(cat "$project_dir/VERSION").pkg"
pkgutil --expand "$package" "$work_dir/expanded"
mkdir -p "$work_dir/payload"
(cd "$work_dir/payload" && gzip -dc "$work_dir/expanded/Payload" | cpio -id --quiet)
app="$work_dir/payload/Applications/Uninstall LaserJet 1020 Mac Kit.app"
[[ -x "$app/Contents/MacOS/applet" ]]
[[ "$(plutil -extract CFBundleIdentifier raw -o - "$app/Contents/Info.plist")" == 'com.laserjet1020mackit.uninstaller' ]]
codesign --verify --deep --strict "$app"
cmp "$project_dir/Uninstall.command" "$app/Contents/Resources/Uninstall.command"
grep -Fq 'identifier="com.laserjet1020mackit.uninstaller"' "$work_dir/expanded/PackageInfo"
if grep -Fq '<relocate>' "$work_dir/expanded/PackageInfo"; then
  echo 'The standalone uninstaller must install in Applications.' >&2
  exit 1
fi
[[ ! -e "$work_dir/payload/Library" ]]
echo 'Release uninstaller test passed.'
