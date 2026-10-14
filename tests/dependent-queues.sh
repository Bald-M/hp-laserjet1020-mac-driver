#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
# shellcheck source=uninstall.sh
source "$project_dir/uninstall.sh"
work_dir="$(mktemp -d "${TMPDIR:-/tmp/}laserjet1020-queue.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
ppd_file="$work_dir/HP_LaserJet_1020_MacDriver.ppd"

printf '*NickName: "HP LaserJet 1020 Mac Driver"\n' > "$ppd_file"
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
legacy_ppd="$work_dir/legacy.ppd.gz"
gzip -c "$ppd_file" > "$legacy_ppd"
legacy_ppd_is_ours
printf '*NickName: "Other printer"\n' | gzip -c > "$legacy_ppd"
if legacy_ppd_is_ours; then
  echo 'Matched an unrelated legacy PPD' >&2
  exit 1
fi
gzip -c "$ppd_file" > "$work_dir/owned.ppd.gz"
rm "$legacy_ppd"
ln -s "$work_dir/owned.ppd.gz" "$legacy_ppd"
if legacy_ppd_is_ours; then
  echo 'Matched a linked legacy PPD' >&2
  exit 1
fi
cp "$ppd_file" "$work_dir/Manual_HP_1020.ppd"
cp "$ppd_file" "$work_dir/HP_LaserJet_1020_MacKit.ppd"
printf '*NickName: "Other printer"\n' > "$work_dir/Unrelated.ppd"
actual="$(list_dependent_queues "$work_dir")"
expected="$(printf '%s\n' HP_LaserJet_1020_MacDriver HP_LaserJet_1020_MacKit Manual_HP_1020)"
[[ "$actual" == "$expected" ]] || {
  printf 'Expected three queues using the driver filter, got:\n%s\n' "$actual" >&2
  exit 1
}
echo 'Dependent queue detection test passed.'
