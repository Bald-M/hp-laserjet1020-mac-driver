#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
source_dir="${1:-}"
if [[ -z "$source_dir" || $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/hp1020-driver-mac" >&2
  exit 2
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp/}laserjet1020-test.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
DIST_DIR="$work_dir/dist" "$project_dir/scripts/build-package.sh" "$source_dir"
package="$work_dir/dist/LaserJet1020MacKit-$(cat "$project_dir/VERSION").pkg"
pkgutil --expand "$package" "$work_dir/expanded"
mkdir -p "$work_dir/payload"
(cd "$work_dir/payload" && gzip -dc "$work_dir/expanded/Payload" | cpio -id --quiet)

payload="$work_dir/payload/Library"
bundle="$payload/Printers/LaserJet1020MacKit/LaserJet1020.bundle"
ppd="$payload/Printers/PPDs/Contents/Resources/LaserJet 1020 Mac Kit.gz"
uninstaller="$payload/Application Support/LaserJet1020MacKit/uninstall.sh"
add_printer="$payload/Application Support/LaserJet1020MacKit/AddPrinter.command"
app="$work_dir/payload/Applications/LaserJet 1020 Mac Kit.app"
legacy_uninstall_app="$work_dir/payload/Applications/Uninstall LaserJet 1020 Mac Kit.app"
[[ -x "$bundle/Contents/MacOS/rasterToHPZJS" ]]
[[ -x "$bundle/Contents/MacOS/commandToHPZJS" ]]
[[ -s "$bundle/Contents/Resources/hp1020.acl" ]]
[[ -x "$uninstaller" ]]
[[ -x "$add_printer" ]]
[[ -x "$app/Contents/MacOS/applet" ]]
[[ "$(plutil -extract CFBundleIdentifier raw -o - "$app/Contents/Info.plist")" == 'com.laserjet1020mackit.manager' ]]
[[ "$(plutil -extract CFBundleShortVersionString raw -o - "$app/Contents/Info.plist")" == "$(cat "$project_dir/VERSION")" ]]
codesign --verify --deep --strict "$app"
osadecompile "$app/Contents/Resources/Scripts/main.scpt" > "$work_dir/manager.applescript"
grep -Fq 'AddPrinter.command' "$work_dir/manager.applescript"
if grep -Eiq 'uninstall(\.sh|\.command)' "$work_dir/manager.applescript"; then
  echo 'The setup app must not contain the uninstall action.' >&2
  exit 1
fi
[[ ! -e "$legacy_uninstall_app" ]]
[[ ! -e "$payload/Application Support/LaserJet1020MacKit/Uninstall.command" ]]
cmp "$project_dir/uninstall.sh" "$uninstaller"
cmp "$project_dir/package-scripts/postinstall" "$work_dir/expanded/Scripts/postinstall"
[[ -s "$ppd" ]]
gzip -dc "$ppd" > "$work_dir/driver.ppd"
grep -Fq '*NickName: "HP LaserJet 1020 (Mac Kit)"' "$work_dir/driver.ppd"
grep -Fq '/Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle/Contents/MacOS/rasterToHPZJS' "$work_dir/driver.ppd"
grep -Fq '/Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle/Contents/MacOS/commandToHPZJS' "$work_dir/driver.ppd"
grep -Fq '/Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle/Contents/Resources/hp1020.acl' "$work_dir/driver.ppd"
if grep -Fq '/Library/Printers/hp/laserjet/hplaserjetzjs.bundle' "$work_dir/driver.ppd"; then
  echo 'PPD still refers to the shared HP driver directory' >&2
  exit 1
fi
grep -Fq 'identifier="com.laserjet1020mackit.driver"' "$work_dir/expanded/PackageInfo"
if grep -Fq '<relocate>' "$work_dir/expanded/PackageInfo"; then
  echo 'The setup app must stay at its installed path.' >&2
  exit 1
fi
"$uninstaller" --dry-run > "$work_dir/uninstall-preview"
grep -Fq '/Applications/LaserJet 1020 Mac Kit.app' "$work_dir/uninstall-preview"
grep -Fq '/Applications/Uninstall LaserJet 1020 Mac Kit.app' "$work_dir/uninstall-preview"
grep -Fq 'com.laserjet1020mackit.uninstaller' "$work_dir/uninstall-preview"
echo 'Package smoke test passed.'
