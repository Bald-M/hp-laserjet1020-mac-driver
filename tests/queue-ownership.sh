#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
# shellcheck source=Uninstall.command
source "$project_dir/Uninstall.command"
work_dir="$(mktemp -d "${TMPDIR:-/tmp/}laserjet1020-queue.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
ppd_file="$work_dir/HP_LaserJet_1020_MacKit.ppd"

printf '*NickName: "HP LaserJet 1020 (Mac Kit)"\n' > "$ppd_file"
if is_our_queue_ppd "$ppd_file"; then
  echo 'Matched a queue by NickName alone' >&2
  exit 1
fi
printf '*%% Former filter: /Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle/Contents/MacOS/rasterToHPZJS\n' >> "$ppd_file"
if is_our_queue_ppd "$ppd_file"; then
  echo 'Matched a filter path in a comment' >&2
  exit 1
fi
printf '*cupsFilter: "application/vnd.cups-raster 100 /Library/Printers/LaserJet1020MacKit/LaserJet1020.bundle/Contents/MacOS/rasterToHPZJS"\n' >> "$ppd_file"
is_our_queue_ppd "$ppd_file"
cp "$ppd_file" "$work_dir/Manual_HP_1020.ppd"
printf '*NickName: "Other printer"\n' > "$work_dir/Unrelated.ppd"
actual="$(list_our_queues "$work_dir")"
expected="$(printf '%s\n' HP_LaserJet_1020_MacKit Manual_HP_1020)"
[[ "$actual" == "$expected" ]] || {
  printf 'Expected two project queues, got:\n%s\n' "$actual" >&2
  exit 1
}
echo 'Queue ownership test passed.'
