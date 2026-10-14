#!/bin/bash
set -euo pipefail

package_id='com.laserjet1020mackit.driver'
legacy_uninstaller_package_id='com.laserjet1020mackit.uninstaller'
driver_root='/Library/Printers/LaserJet1020MacKit'
ppd='/Library/Printers/PPDs/Contents/Resources/HP LaserJet 1020 Mac Driver.gz'
legacy_ppd='/Library/Printers/PPDs/Contents/Resources/LaserJet 1020 Mac Kit.gz'
support='/Library/Application Support/LaserJet1020MacKit'
manager_app='/Applications/HP LaserJet 1020 Mac Driver.app'
legacy_manager_app='/Applications/LaserJet 1020 Mac Kit.app'
legacy_uninstaller_app='/Applications/Uninstall LaserJet 1020 Mac Kit.app'

ppd_uses_kit_filter() {
  [[ -f "$1" ]] && /usr/bin/grep -Fxq \
    '*cupsFilter: "application/vnd.cups-raster 100 /Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle/Contents/MacOS/rasterToHPZJS"' "$1"
}

legacy_ppd_is_ours() {
  [[ -f "$legacy_ppd" && ! -L "$legacy_ppd" ]] &&
    /usr/bin/gzip -dc "$legacy_ppd" 2>/dev/null |
      /usr/bin/grep -Fx '*cupsFilter: "application/vnd.cups-raster 100 /Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle/Contents/MacOS/rasterToHPZJS"' >/dev/null
}

list_dependent_queues() {
  local ppd_directory="$1" ppd_file queue_name
  for ppd_file in "$ppd_directory"/*.ppd; do
    [[ -f "$ppd_file" && ! -L "$ppd_file" ]] || continue
    if ppd_uses_kit_filter "$ppd_file"; then
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
done < <(list_dependent_queues '/etc/cups/ppd')

if [[ ${#queues[@]} -gt 0 ]]; then
  printf 'Uninstall blocked: these print queues still use this driver:\n' >&2
  printf '  %s\n' "${queues[@]}" >&2
  echo 'No queues or driver files were removed. Change or remove these queues in Printers & Scanners, then retry.' >&2
  exit 1
fi

if [[ "$dry_run" == true ]]; then
  printf 'Would remove:\n  %s\n  %s\n  %s\n' "$ppd" "$driver_root" "$support"
  if legacy_ppd_is_ours; then
    printf '  %s\n' "$legacy_ppd"
  fi
  printf 'Would remove the installed applications if their bundle IDs match:\n  %s\n  %s\n  %s\n' "$manager_app" "$legacy_manager_app" "$legacy_uninstaller_app"
  printf 'Would forget package receipts: %s, %s\n' "$package_id" "$legacy_uninstaller_package_id"
  exit 0
fi

if ! /usr/sbin/pkgutil --pkg-info "$package_id" >/dev/null 2>&1 &&
  ! /usr/sbin/pkgutil --pkg-info "$legacy_uninstaller_package_id" >/dev/null 2>&1 &&
  [[ ! -e "$driver_root" && ! -L "$driver_root" && ! -e "$ppd" && ! -L "$ppd" && ! -e "$support" && ! -L "$support" ]] &&
  ! legacy_ppd_is_ours &&
  ! app_has_id "$manager_app" 'com.laserjet1020mackit.manager' &&
  ! app_has_id "$legacy_manager_app" 'com.laserjet1020mackit.manager' &&
  ! app_has_id "$legacy_uninstaller_app" 'com.laserjet1020mackit.uninstaller'; then
  echo 'HP LaserJet 1020 Mac Driver is already uninstalled.'
  exit 0
fi

if [[ "$assume_yes" != true ]]; then
  echo 'Remove HP LaserJet 1020 Mac Driver and its installed files?'
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

legacy_ppd_was_ours=false
if legacy_ppd_is_ours; then
  legacy_ppd_was_ours=true
  /bin/rm -f "$legacy_ppd"
fi
/bin/rm -f "$ppd"
/bin/rm -rf "$driver_root" "$support"
if app_has_id "$manager_app" 'com.laserjet1020mackit.manager'; then
  /bin/rm -rf "$manager_app"
fi
if app_has_id "$legacy_manager_app" 'com.laserjet1020mackit.manager'; then
  /bin/rm -rf "$legacy_manager_app"
fi
if app_has_id "$legacy_uninstaller_app" 'com.laserjet1020mackit.uninstaller'; then
  /bin/rm -rf "$legacy_uninstaller_app"
fi
for path in "$ppd" "$driver_root" "$support"; do
  if [[ -e "$path" || -L "$path" ]]; then
    echo "Could not remove $path; package receipt was kept." >&2
    exit 1
  fi
done
if [[ "$legacy_ppd_was_ours" == true && ( -e "$legacy_ppd" || -L "$legacy_ppd" ) ]]; then
  echo "Could not remove $legacy_ppd; package receipt was kept." >&2
  exit 1
fi
for receipt in "$package_id" "$legacy_uninstaller_package_id"; do
  if /usr/sbin/pkgutil --pkg-info "$receipt" >/dev/null 2>&1; then
    /usr/sbin/pkgutil --forget "$receipt"
  fi
done
echo 'HP LaserJet 1020 Mac Driver and its installed files were removed.'
