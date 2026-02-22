#!/usr/bin/env bash
set -euo pipefail

mode="${1:-check}"

ruby_files=()
while IFS= read -r file; do
  ruby_files+=("${file}")
done < <(find Formula -maxdepth 1 -name '*.rb' -type f | sort)
if [ "${#ruby_files[@]}" -eq 0 ]; then
  echo "No Ruby files found under Formula/."
  exit 1
fi

case "${mode}" in
  write)
    echo "Formatting Ruby files: ${ruby_files[*]}"
    for file in "${ruby_files[@]}"; do
      brew style --fix "${file}"
    done
    ;;
  check)
    echo "Checking Ruby formatting: ${ruby_files[*]}"
    for file in "${ruby_files[@]}"; do
      brew style --fix "${file}"
    done
    if ! git diff --quiet -- "${ruby_files[@]}"; then
      echo "Ruby formatting changes detected. Run: .github/scripts/ruby-fmt.sh write"
      git --no-pager diff -- "${ruby_files[@]}"
      exit 1
    fi
    ;;
  *)
    echo "Usage: $0 [check|write]"
    exit 1
    ;;
esac
