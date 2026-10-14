#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
source_dir="$project_dir/build/upstream"
commit='f9d2f7e2a22b7bfb80d4cb51e42de61c88f7dfdc'

if [[ ! -d "$source_dir/.git" ]]; then
  if [[ -e "$source_dir" ]]; then
    echo "Cannot use existing non-Git path: $source_dir" >&2
    exit 1
  fi
  mkdir -p "$project_dir/build"
  git clone https://github.com/anxkhn/hp1020-driver-mac.git "$source_dir"
  git -C "$source_dir" checkout --detach "$commit"
fi

actual="$(git -C "$source_dir" rev-parse HEAD)"
if [[ "$actual" != "$commit" ]]; then
  echo "Cached source is at $actual, expected $commit" >&2
  exit 1
fi
if [[ -n "$(git -C "$source_dir" status --porcelain --untracked-files=no -- \
  'HP LaserJet 1022.gz' rasterToHPZJS commandToHPZJS hp1020.acl)" ]]; then
  echo "Cached driver files have local modifications: $source_dir" >&2
  exit 1
fi
echo "Using reference driver files from $source_dir ($commit)"
