#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
# shellcheck source=Uninstall.command
source "$project_dir/Uninstall.command"
ppd_file="$(mktemp "${TMPDIR:-/tmp/}laserjet1020-queue.XXXXXX")"
trap 'rm -f "$ppd_file"' EXIT

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
echo 'Queue ownership test passed.'
