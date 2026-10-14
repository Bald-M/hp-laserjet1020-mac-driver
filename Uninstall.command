#!/bin/bash
set -euo pipefail

package_id='com.laserjet1020mackit.driver'
bundle='/Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle'
ppd='/Library/Printers/PPDs/Contents/Resources/LaserJet 1020 Mac Kit.gz'
support='/Library/Application Support/LaserJet1020MacKit'
queue='HP_LaserJet_1020_MacKit'
queue_ppd="/etc/cups/ppd/$queue.ppd"
files=(
  "$ppd"
  "$bundle/Contents/MacOS/rasterToHPZJS"
  "$bundle/Contents/MacOS/commandToHPZJS"
  "$bundle/Contents/Resources/hp1020.acl"
  "$support/AddPrinter.command"
  "$support/Uninstall.command"
)

is_our_queue_ppd() {
  [[ -f "$1" ]] && /usr/bin/grep -Fq \
    '/Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle/Contents/MacOS/rasterToHPZJS' "$1"
}

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  return 0
fi

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
  echo "Would remove $queue if its PPD still identifies this kit."
  echo 'Other printer queues would remain.'
  exit 0
fi

if ! /usr/sbin/pkgutil --pkg-info "$package_id" >/dev/null 2>&1; then
  echo "Package receipt $package_id was not found; no files were removed." >&2
  exit 1
fi

if [[ "$assume_yes" != true ]]; then
  echo 'Remove LaserJet 1020 Mac Kit driver files and package receipt?'
  echo "The $queue queue will also be removed if it still uses this kit's PPD."
  echo 'Other printer queues will remain.'
  read -r -p 'Type REMOVE to continue: ' answer
  [[ "$answer" == REMOVE ]] || { echo 'Cancelled.'; exit 1; }
fi

if [[ $EUID -ne 0 ]]; then
  exec /usr/bin/sudo /bin/bash "$0" --yes
fi

if is_our_queue_ppd "$queue_ppd"; then
  if ! /usr/bin/lpstat -p "$queue" >/dev/null 2>&1; then
    echo "Could not verify $queue with CUPS; driver files were left in place." >&2
    exit 1
  fi
  /usr/sbin/lpadmin -x "$queue"
  echo "Removed printer queue $queue."
elif /usr/bin/lpstat -p "$queue" >/dev/null 2>&1; then
  echo "Kept $queue because its PPD does not identify this kit." >&2
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
echo 'Driver files removed. Remove any other printer queue in System Settings if needed.'
