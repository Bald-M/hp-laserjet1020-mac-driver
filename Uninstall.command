#!/bin/bash
set -euo pipefail

package_id='com.laserjet1020mackit.driver'
bundle='/Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle'
ppd='/Library/Printers/PPDs/Contents/Resources/LaserJet 1020 Mac Kit.gz'
support='/Library/Application Support/LaserJet1020MacKit'
files=(
  "$ppd"
  "$bundle/Contents/MacOS/rasterToHPZJS"
  "$bundle/Contents/MacOS/commandToHPZJS"
  "$bundle/Contents/Resources/hp1020.acl"
  "$support/Uninstall.command"
)

usage() {
  echo "Usage: $0 [--dry-run | --yes]"
}

dry_run=false
assume_yes=false
case "${1:-}" in
  '') ;;
  --dry-run) dry_run=true ;;
  --yes) assume_yes=true ;;
  --help|-h) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
if [[ $# -gt 1 ]]; then
  usage >&2
  exit 2
fi

if [[ "$dry_run" == true ]]; then
  printf 'Would remove:\n'
  printf '  %s\n' "${files[@]}"
  echo "Would forget receipt: $package_id"
  echo 'Printer queues are left for you to remove in System Settings.'
  exit 0
fi

if ! /usr/sbin/pkgutil --pkg-info "$package_id" >/dev/null 2>&1; then
  echo "Package receipt $package_id was not found; no files were removed." >&2
  exit 1
fi

if [[ "$assume_yes" != true ]]; then
  echo 'Remove LaserJet 1020 Mac Kit driver files and package receipt?'
  echo 'Printer queues will remain and can be removed in System Settings.'
  read -r -p 'Type REMOVE to continue: ' answer
  [[ "$answer" == REMOVE ]] || { echo 'Cancelled.'; exit 1; }
fi

if [[ $EUID -ne 0 ]]; then
  exec /usr/bin/sudo /bin/bash "$0" --yes
fi

for path in "${files[@]}"; do
  if [[ -e "$path" || -L "$path" ]]; then
    /bin/rm -f "$path"
  fi
done
for path in \
  "$bundle/Contents/MacOS" \
  "$bundle/Contents/Resources" \
  "$bundle/Contents" \
  "$bundle" \
  '/Library/Printers/LaserJet1020MacKit' \
  "$support"; do
  /bin/rmdir "$path" 2>/dev/null || true
done
/usr/sbin/pkgutil --forget "$package_id"
echo 'Driver files removed. Remove any remaining printer queue in System Settings.'
