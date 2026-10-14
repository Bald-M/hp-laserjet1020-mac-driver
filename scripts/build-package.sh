#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
source_dir="${1:-}"
if [[ -z "$source_dir" || $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/hp1020-driver-mac" >&2
  exit 2
fi
source_dir="$(cd "$source_dir" && pwd -P)"

for tool in pkgbuild lipo gzip sed grep; do
  command -v "$tool" >/dev/null || { echo "Missing macOS tool: $tool" >&2; exit 1; }
done

for name in 'HP LaserJet 1022.gz' rasterToHPZJS commandToHPZJS hp1020.acl; do
  path="$source_dir/$name"
  if [[ ! -f "$path" || -L "$path" || ! -s "$path" ]]; then
    echo "Missing, empty, or linked source file: $path" >&2
    exit 1
  fi
done

for name in rasterToHPZJS commandToHPZJS; do
  architectures="$(lipo -archs "$source_dir/$name")"
  if [[ " $architectures " != *' x86_64 '* ]]; then
    echo "$name must contain an x86_64 Mach-O slice (found: $architectures)" >&2
    exit 1
  fi
done

version="$(cat "$project_dir/VERSION")"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "VERSION must be a three-part numeric version" >&2
  exit 1
fi

old_bundle='/Library/Printers/hp/laserjet/hplaserjetzjs.bundle'
new_bundle='/Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle'
work_dir="$(mktemp -d "${TMPDIR:-/tmp/}laserjet1020-mac-kit.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
root="$work_dir/root"
bundle="$root$new_bundle"
ppd_dir="$root/Library/Printers/PPDs/Contents/Resources"
support_dir="$root/Library/Application Support/LaserJet1020MacKit"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources" "$ppd_dir" "$support_dir"

install -m 755 "$source_dir/rasterToHPZJS" "$bundle/Contents/MacOS/rasterToHPZJS"
install -m 755 "$source_dir/commandToHPZJS" "$bundle/Contents/MacOS/commandToHPZJS"
install -m 644 "$source_dir/hp1020.acl" "$bundle/Contents/Resources/hp1020.acl"
install -m 755 "$project_dir/Uninstall.command" "$support_dir/Uninstall.command"
install -m 755 "$project_dir/AddPrinter.command" "$support_dir/AddPrinter.command"

plain_ppd="$work_dir/LaserJet 1020 Mac Kit.ppd"
gzip -dc "$source_dir/HP LaserJet 1022.gz" |
  sed \
    -e "s|$old_bundle|$new_bundle|g" \
    -e '/^\*APPrinterIconPath:/d' \
    -e 's/^\*NickName: .*/\*NickName: "HP LaserJet 1020 (Mac Kit)"/' \
    -e 's/^\*ShortNickName: .*/\*ShortNickName: "HP LaserJet 1020 (Mac Kit)"/' \
    -e 's/^\*CloseUI: \*JamRecovery$/\*JCLCloseUI: \*JamRecovery/' \
    -e 's/^\*CloseUI: \*PrintDensity$/\*JCLCloseUI: \*PrintDensity/' \
    > "$plain_ppd"

for relative in 'Contents/MacOS/rasterToHPZJS' 'Contents/MacOS/commandToHPZJS' 'Contents/Resources/hp1020.acl'; do
  grep -Fq "$new_bundle/$relative" "$plain_ppd" || {
    echo "PPD is missing the expected driver reference: $relative" >&2
    exit 1
  }
done
if grep -Fq "$old_bundle" "$plain_ppd"; then
  echo 'PPD still refers to the shared HP driver directory' >&2
  exit 1
fi
if command -v cupstestppd >/dev/null; then
  # Staged files are owned by the builder; pkgbuild installs them as root.
  cupstestppd -q -I filters "$plain_ppd"
fi
gzip -c "$plain_ppd" > "$ppd_dir/LaserJet 1020 Mac Kit.gz"
chmod 644 "$ppd_dir/LaserJet 1020 Mac Kit.gz"
/usr/bin/xattr -cr "$root"

dist_dir="${DIST_DIR:-$project_dir/dist}"
mkdir -p "$dist_dir"
dist_dir="$(cd "$dist_dir" && pwd -P)"
package="$dist_dir/LaserJet1020MacKit-$version.pkg"
COPYFILE_DISABLE=1 pkgbuild \
  --root "$root" \
  --identifier com.laserjet1020mackit.driver \
  --version "$version" \
  --install-location / \
  --ownership recommended \
  "$package"
echo "Built: $package"
