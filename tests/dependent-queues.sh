#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
# shellcheck source=uninstall.sh
source "$project_dir/uninstall.sh"
work_dir="$(mktemp -d "${TMPDIR:-/tmp/}laserjet1020-queue.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
ppd_file="$work_dir/HP_LaserJet_1020_MacKit.ppd"

printf '*NickName: "HP LaserJet 1020 (Mac Kit)"\n' > "$ppd_file"
if ppd_uses_kit_filter "$ppd_file"; then
  echo 'Matched a queue by NickName alone' >&2
  exit 1
fi
printf '*%% Former filter: /Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle/Contents/MacOS/rasterToHPZJS\n' >> "$ppd_file"
if ppd_uses_kit_filter "$ppd_file"; then
  echo 'Matched a filter path in a comment' >&2
  exit 1
fi
printf '*cupsFilter: "application/vnd.cups-raster 100 /Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle/Contents/MacOS/rasterToHPZJS"\n' >> "$ppd_file"
ppd_uses_kit_filter "$ppd_file"
cp "$ppd_file" "$work_dir/Manual_HP_1020.ppd"
printf '*NickName: "Other printer"\n' > "$work_dir/Unrelated.ppd"
actual="$(list_dependent_queues "$work_dir")"
expected="$(printf '%s\n' HP_LaserJet_1020_MacKit Manual_HP_1020)"
[[ "$actual" == "$expected" ]] || {
  printf 'Expected two queues using the kit filter, got:\n%s\n' "$actual" >&2
  exit 1
}
echo 'Dependent queue detection test passed.'
