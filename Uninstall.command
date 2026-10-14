#!/bin/bash
set -euo pipefail

package_id='com.laserjet1020mackit.driver'
uninstaller_package_id='com.laserjet1020mackit.uninstaller'
driver_root='/Library/Printers/LaserJet1020MacKit'
ppd='/Library/Printers/PPDs/Contents/Resources/LaserJet 1020 Mac Kit.gz'
support='/Library/Application Support/LaserJet1020MacKit'
manager_app='/Applications/LaserJet 1020 Mac Kit.app'
uninstaller_app='/Applications/Uninstall LaserJet 1020 Mac Kit.app'

is_our_queue_ppd() {
  [[ -f "$1" ]] && /usr/bin/grep -Fxq \
    '*cupsFilter: "application/vnd.cups-raster 100 /Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle/Contents/MacOS/rasterToHPZJS"' "$1"
}

list_our_queues() {
  local ppd_directory="$1" ppd_file queue_name
  for ppd_file in "$ppd_directory"/*.ppd; do
    [[ -f "$ppd_file" && ! -L "$ppd_file" ]] || continue
    if is_our_queue_ppd "$ppd_file"; then
      queue_name="${ppd_file##*/}"
      printf '%s\n' "${queue_name%.ppd}"
    fi
  done
}

app_has_id() {
  [[ -d "$1" && ! -L "$1" ]] &&
    [[ "$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$1/Contents/Info.plist" 2>/dev/null)" == "$2" ]]
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

queues=()
while IFS= read -r queue_name; do
  queues+=("$queue_name")
done < <(list_our_queues '/etc/cups/ppd')

if [[ "$dry_run" == true ]]; then
  printf 'Would remove:\n  %s\n  %s\n  %s\n' "$ppd" "$driver_root" "$support"
  printf 'Would remove the installed applications if their bundle IDs match:\n  %s\n  %s\n' "$manager_app" "$uninstaller_app"
  printf 'Would forget package receipts: %s, %s\n' "$package_id" "$uninstaller_package_id"
  if [[ ${#queues[@]} -gt 0 ]]; then
    printf 'Would remove print queues using this driver:\n'
    printf '  %s\n' "${queues[@]}"
  fi
  exit 0
fi

if ! /usr/sbin/pkgutil --pkg-info "$package_id" >/dev/null 2>&1 &&
  ! /usr/sbin/pkgutil --pkg-info "$uninstaller_package_id" >/dev/null 2>&1 &&
  [[ ! -e "$driver_root" && ! -L "$driver_root" && ! -e "$ppd" && ! -L "$ppd" && ! -e "$support" && ! -L "$support" && ${#queues[@]} -eq 0 ]] &&
  ! app_has_id "$manager_app" 'com.laserjet1020mackit.manager' &&
  ! app_has_id "$uninstaller_app" 'com.laserjet1020mackit.uninstaller'; then
  echo 'LaserJet 1020 Mac Kit is already uninstalled.'
  exit 0
fi

if [[ "$assume_yes" != true ]]; then
  echo 'Remove LaserJet 1020 Mac Kit, its installed files, and print queues using this driver?'
  read -r -p 'Type REMOVE to continue: ' answer
  [[ "$answer" == REMOVE ]] || { echo 'Cancelled.'; exit 1; }
fi

if [[ $EUID -ne 0 ]]; then
  if [[ "$assume_yes" == true ]]; then
    echo 'Administrator privileges are required.' >&2
    exit 1
  fi
  exec /usr/bin/sudo /bin/bash "$0" --yes
fi

for queue_name in "${queues[@]}"; do
  if ! /usr/bin/lpstat -p "$queue_name" >/dev/null 2>&1; then
    echo "Could not verify print queue $queue_name with CUPS; no driver files were removed." >&2
    exit 1
  fi
done
for queue_name in "${queues[@]}"; do
  /usr/sbin/lpadmin -x "$queue_name"
  echo "Removed print queue: $queue_name"
done

/bin/rm -f "$ppd"
/bin/rm -rf "$driver_root" "$support"
if app_has_id "$manager_app" 'com.laserjet1020mackit.manager'; then
  /bin/rm -rf "$manager_app"
fi
if app_has_id "$uninstaller_app" 'com.laserjet1020mackit.uninstaller'; then
  /bin/rm -rf "$uninstaller_app"
fi
for path in "$ppd" "$driver_root" "$support"; do
  if [[ -e "$path" || -L "$path" ]]; then
    echo "Could not remove $path; package receipt was kept." >&2
    exit 1
  fi
done
for receipt in "$package_id" "$uninstaller_package_id"; do
  if /usr/sbin/pkgutil --pkg-info "$receipt" >/dev/null 2>&1; then
    /usr/sbin/pkgutil --forget "$receipt"
  fi
done
echo 'LaserJet 1020 Mac Kit and its installed files were removed.'
