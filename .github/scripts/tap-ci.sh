#!/usr/bin/env bash
set -euo pipefail

tap_name="${TAP_NAME:-pbsladek/tap}"
workspace="${GITHUB_WORKSPACE:-$PWD}"

if ! [[ "${tap_name}" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
  echo "Invalid TAP_NAME: ${tap_name}"
  exit 1
fi

if brew tap | grep -qx "${tap_name}"; then
  brew untap --force "${tap_name}"
fi
brew tap --custom-remote "$tap_name" "$workspace"

formulae="$(find Formula -maxdepth 1 -name '*.rb' -type f -exec basename {} .rb \; | sort | xargs)"
if [ -z "${formulae}" ]; then
  echo "No formulae found in Formula/."
  exit 1
fi

echo "Found formulae: ${formulae}"

echo "Running Ruby format check"
.github/scripts/ruby-fmt.sh check

echo "Running Ruby lint"
.github/scripts/ruby-lint.sh

for f in ${formulae}; do
  echo "brew audit --strict --online ${tap_name}/${f}"
  brew audit --strict --online "${tap_name}/${f}"

  echo "brew install --build-from-source ${tap_name}/${f}"
  brew install --build-from-source "${tap_name}/${f}"

  echo "brew test ${tap_name}/${f}"
  brew test "${tap_name}/${f}"
done
