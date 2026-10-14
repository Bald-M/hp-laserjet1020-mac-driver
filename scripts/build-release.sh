#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
version="$(cat "$project_dir/VERSION")"
dist_dir="${DIST_DIR:-$project_dir/dist}"
mkdir -p "$dist_dir"
dist_dir="$(cd "$dist_dir" && pwd -P)"
work_dir="$(mktemp -d "${TMPDIR:-/tmp/}laserjet1020-release.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

root="$work_dir/root"
mkdir -p "$root/Applications"
app="$root/Applications/Uninstall LaserJet 1020 Mac Kit.app"
"$project_dir/scripts/build-uninstaller-app.sh" "$app"
components="$work_dir/components.plist"
pkgbuild --analyze --root "$root" "$components"
/usr/libexec/PlistBuddy -c 'Set :0:BundleIsRelocatable false' "$components"
package="$dist_dir/LaserJet1020MacKit-Uninstaller-$version.pkg"
COPYFILE_DISABLE=1 pkgbuild \
  --root "$root" \
  --component-plist "$components" \
  --identifier com.laserjet1020mackit.uninstaller \
  --version "$version" \
  --install-location / \
  --ownership recommended \
  "$package"
echo "Built: $package"
