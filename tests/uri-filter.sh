#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
# shellcheck source=AddPrinter.command
source "$project_dir/AddPrinter.command"

is_target_uri 'usb://Hewlett-Packard/HP%20LaserJet%201020?serial=AB12'
is_target_uri 'usb://HP/LaserJet%201020?serial=AB12'
if is_target_uri 'usb://Other/Printer?serial=1020'; then
  echo 'Matched another printer by serial number' >&2
  exit 1
fi
if is_target_uri 'usb://Other/LaserJet%201020?serial=AB12'; then
  echo 'Matched another vendor with the same model name' >&2
  exit 1
fi
if is_target_uri 'usb://Hewlett-Packard/LaserJet%201022?serial=1020'; then
  echo 'Matched a different model by serial number' >&2
  exit 1
fi
if is_target_uri 'usb://Hewlett-Packard/LaserJet%2010200?serial=AB12'; then
  echo 'Matched a different model with a 1020 prefix' >&2
  exit 1
fi
echo 'USB URI filter test passed.'
