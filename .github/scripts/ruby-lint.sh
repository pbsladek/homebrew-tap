#!/usr/bin/env bash
set -euo pipefail

ruby_files="$(find Formula -maxdepth 1 -name '*.rb' -type f | sort | xargs)"
if [ -z "${ruby_files}" ]; then
  echo "No Ruby files found under Formula/."
  exit 1
fi

echo "Linting Ruby files: ${ruby_files}"
for file in ${ruby_files}; do
  brew style "${file}"
done
