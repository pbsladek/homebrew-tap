#!/usr/bin/env bash
set -euo pipefail

ruby_files=()
while IFS= read -r file; do
  ruby_files+=("${file}")
done < <(find Formula -maxdepth 1 -name '*.rb' -type f | sort)
if [ "${#ruby_files[@]}" -eq 0 ]; then
  echo "No Ruby files found under Formula/."
  exit 1
fi

echo "Linting Ruby files: ${ruby_files[*]}"
for file in "${ruby_files[@]}"; do
  brew style "${file}"
done
