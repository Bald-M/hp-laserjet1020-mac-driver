#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
work_dir="$(mktemp -d "${TMPDIR:-/tmp/}laserjet1020-preserve.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/ppd"

# A manually added SMB queue can use this kit's PPD too.
printf '*cupsFilter: "application/vnd.cups-raster 100 /Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle/Contents/MacOS/rasterToHPZJS"\n' \
  > "$work_dir/ppd/SMB_Printer.ppd"
/usr/bin/sed "s|list_dependent_queues '/etc/cups/ppd'|list_dependent_queues '$work_dir/ppd'|" \
  "$project_dir/uninstall.sh" > "$work_dir/uninstall.sh"

if output="$(/bin/bash "$work_dir/uninstall.sh" --dry-run 2>&1)"; then
  printf 'The uninstaller would remove a manually added SMB printer:\n%s\n' "$output" >&2
  exit 1
fi
[[ "$output" == *'Uninstall blocked'* && "$output" == *'SMB_Printer'* ]] || {
  printf 'Expected a clear block for the SMB printer, got:\n%s\n' "$output" >&2
  exit 1
}

mkdir -p "$work_dir/empty"
/usr/bin/sed "s|list_dependent_queues '/etc/cups/ppd'|list_dependent_queues '$work_dir/empty'|" \
  "$project_dir/uninstall.sh" > "$work_dir/empty-uninstall.sh"
output="$(/bin/bash "$work_dir/empty-uninstall.sh" --dry-run)"
[[ "$output" == *'Would remove:'* && "$output" != *'Uninstall blocked'* ]]
echo 'Uninstall preserves manually added queues.'
