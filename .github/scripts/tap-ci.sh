#!/usr/bin/env bash
set -euo pipefail

tap_name="${TAP_NAME:-pbsladek/tap}"
workspace="${GITHUB_WORKSPACE:-$PWD}"

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

for f in ${formulae}; do
  echo "brew style Formula/${f}.rb"
  brew style "Formula/${f}.rb"

  echo "brew audit --strict --online ${tap_name}/${f}"
  brew audit --strict --online "${tap_name}/${f}"

  echo "brew install --build-from-source ${tap_name}/${f}"
  brew install --build-from-source "${tap_name}/${f}"

  echo "brew test ${tap_name}/${f}"
  brew test "${tap_name}/${f}"
done
