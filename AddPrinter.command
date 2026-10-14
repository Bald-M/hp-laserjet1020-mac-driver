#!/bin/bash
set -euo pipefail

ppd='/Library/Printers/PPDs/Contents/Resources/HP LaserJet 1020 Mac Driver.gz'
queue='HP_LaserJet_1020_MacDriver'
legacy_queue='HP_LaserJet_1020_MacKit'

is_target_uri() {
  local uri="$1" address vendor model
  [[ "$uri" == usb://*/* ]] || return 1
  address="${uri#usb://}"
  vendor="${address%%/*}"
  model="${address#*/}"
  model="${model%%\?*}"
  vendor="$(printf '%s' "$vendor" | /usr/bin/tr '[:upper:]' '[:lower:]')"
  model="$(printf '%s' "$model" | /usr/bin/tr '[:upper:]' '[:lower:]')"
  case "$vendor" in
    hp|hewlett-packard|hewlett%20packard) ;;
    *) return 1 ;;
  esac
  case "$model" in
    *laserjet*1020|*laserjet*1020%20*) return 0 ;;
    *) return 1 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  return 0
fi

if [[ $# -ne 0 ]]; then
  echo "Usage: $0" >&2
  exit 2
fi
if [[ ! -f "$ppd" ]]; then
  echo 'Driver PPD not found. Install HP LaserJet 1020 Mac Driver first.' >&2
  exit 1
fi
if /usr/bin/lpstat -p "$queue" >/dev/null 2>&1; then
  echo "The printer queue $queue already exists. Check it in System Settings." >&2
  exit 1
fi
if /usr/bin/lpstat -p "$legacy_queue" >/dev/null 2>&1; then
  echo "The printer queue $legacy_queue already exists. Check it in System Settings." >&2
  exit 1
fi

if ! devices="$(/usr/sbin/lpinfo -v)"; then
  echo 'CUPS could not list printer devices. Check the printing service and retry.' >&2
  exit 1
fi

uris=()
while IFS= read -r line; do
  [[ "$line" == 'direct usb://'* ]] || continue
  uri="${line#direct }"
  if is_target_uri "$uri"; then
    uris+=("$uri")
  fi
done <<< "$devices"

if [[ ${#uris[@]} -eq 0 ]]; then
  echo 'No USB LaserJet 1020 was found. Connect and power on the printer, then retry.' >&2
  exit 1
fi

echo 'Detected USB printer(s):'
for i in "${!uris[@]}"; do
  printf '%s) %s\n' "$((i + 1))" "${uris[i]}"
done
read -r -p 'Enter the number to add (or press Return to cancel): ' choice
selected=''
for i in "${!uris[@]}"; do
  if [[ "$choice" == "$((i + 1))" ]]; then
    selected="${uris[i]}"
    break
  fi
done
if [[ -z "$selected" ]]; then
  echo 'Cancelled.'
  exit 1
fi

echo "Adding $queue for $selected"
/usr/bin/sudo /usr/sbin/lpadmin -p "$queue" -E -v "$selected" -P "$ppd" -D 'HP LaserJet 1020 Mac Driver'
echo "Added $queue. Print a test page from System Settings."
