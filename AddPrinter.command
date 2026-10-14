#!/bin/bash
set -euo pipefail

ppd='/Library/Printers/PPDs/Contents/Resources/LaserJet 1020 Mac Kit.gz'
queue='HP_LaserJet_1020_MacKit'

if [[ $# -ne 0 ]]; then
  echo "Usage: $0" >&2
  exit 2
fi
if [[ ! -f "$ppd" ]]; then
  echo 'Driver PPD not found. Install LaserJet 1020 Mac Kit first.' >&2
  exit 1
fi
if /usr/bin/lpstat -p "$queue" >/dev/null 2>&1; then
  echo "The printer queue $queue already exists. Check it in System Settings." >&2
  exit 1
fi

uris=()
while IFS= read -r line; do
  [[ "$line" == 'direct usb://'* ]] || continue
  uri="${line#direct }"
  lower_uri="$(printf '%s' "$uri" | /usr/bin/tr '[:upper:]' '[:lower:]')"
  if [[ "$lower_uri" == *1020* ]]; then
    uris+=("$uri")
  fi
done < <(/usr/sbin/lpinfo -v)

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
/usr/bin/sudo /usr/sbin/lpadmin -p "$queue" -E -v "$selected" -P "$ppd" -D 'HP LaserJet 1020 (Mac Kit)'
echo "Added $queue. Print a test page from System Settings."
