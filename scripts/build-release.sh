#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
version="$(cat "$project_dir/VERSION")"
dist_dir="${DIST_DIR:-$project_dir/dist}"
mkdir -p "$dist_dir"
dist_dir="$(cd "$dist_dir" && pwd -P)"
work_dir="$(mktemp -d "${TMPDIR:-/tmp/}laserjet1020-release.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

app="$work_dir/Uninstall LaserJet 1020 Mac Kit.app"
"$project_dir/scripts/build-uninstaller-app.sh" "$app"
archive="$dist_dir/LaserJet1020MacKit-Uninstaller-$version.zip"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$app" "$archive"
echo "Built: $archive"
