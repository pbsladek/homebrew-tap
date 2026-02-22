#!/usr/bin/env bash
set -euo pipefail

tap_name="${TAP_NAME:-pbsladek/tap}"
workspace="${GITHUB_WORKSPACE:-$PWD}"
event_name="${EVENT_NAME:-}"
changed="false"
run_brew_checks="${RUN_BREW_CHECKS:-true}"
apply_formula_changes="${APPLY_FORMULA_CHANGES:-false}"

if [ "${event_name}" = "workflow_dispatch" ]; then
  formula="${INPUT_FORMULA:-}"
  version="${INPUT_VERSION:-}"
  src_url="${INPUT_URL:-}"
  src_sha256="${INPUT_SHA256:-}"
else
  formula="${PAYLOAD_FORMULA:-ai-mr-comment}"
  version="${PAYLOAD_VERSION:-}"
  src_url="${PAYLOAD_URL:-}"
  src_sha256="${PAYLOAD_SHA256:-}"
fi

if [ -z "${formula}" ] || [ -z "${version}" ] || [ -z "${src_url}" ] || [ -z "${src_sha256}" ]; then
  echo "Missing required payload values."
  echo "formula=${formula}"
  echo "version=${version}"
  echo "url=${src_url}"
  echo "sha256=${src_sha256}"
  exit 1
fi

if ! [[ "${tap_name}" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
  echo "Invalid TAP_NAME: ${tap_name}"
  exit 1
fi

if ! [[ "${formula}" =~ ^[a-z0-9][a-z0-9+_.-]*$ ]]; then
  echo "Invalid formula name: ${formula}"
  exit 1
fi

if [ "${formula}" != "ai-mr-comment" ]; then
  echo "Formula is not in the allowed release-dispatch list: ${formula}"
  exit 1
fi

if ! [[ "${version}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.]+)*$ ]]; then
  echo "Invalid version format: ${version}"
  exit 1
fi

if ! [[ "${src_sha256}" =~ ^[A-Fa-f0-9]{64}$ ]]; then
  echo "Invalid sha256 format."
  exit 1
fi

url_regex='^https://github\.com/pbsladek/ai-mr-comment/archive/refs/tags/v[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.]+)*\.tar\.gz$'
if ! [[ "${src_url}" =~ ${url_regex} ]]; then
  echo "URL is not in the allowed source list: ${src_url}"
  exit 1
fi

expected_url="https://github.com/pbsladek/ai-mr-comment/archive/refs/tags/${version}.tar.gz"
if [ "${src_url}" != "${expected_url}" ]; then
  echo "URL/version mismatch."
  echo "Expected URL: ${expected_url}"
  echo "Provided URL: ${src_url}"
  exit 1
fi

actual_sha256="$(curl -fsSL "${src_url}" | shasum -a 256 | awk '{print $1}')"
if [ "${actual_sha256}" != "${src_sha256}" ]; then
  echo "SHA mismatch for upstream source tarball."
  echo "Expected: ${src_sha256}"
  echo "Actual:   ${actual_sha256}"
  exit 1
fi
echo "Upstream source checksum validated."

formula_file="Formula/${formula}.rb"
[ -f "${formula_file}" ] || {
  echo "Missing ${formula_file}"
  exit 1
}

current_url="$(sed -n 's/^[[:space:]]*url[[:space:]]*"\(.*\)"/\1/p' "${formula_file}" | head -n1)"
current_sha="$(sed -n 's/^[[:space:]]*sha256[[:space:]]*"\(.*\)"/\1/p' "${formula_file}" | head -n1)"
current_version="$(echo "${current_url}" | sed -n 's#.*refs/tags/\(v[^/"]*\)\.tar\.gz#\1#p')"

[ -n "${current_url}" ] || {
  echo "Could not parse url from ${formula_file}"
  exit 1
}
[ -n "${current_sha}" ] || {
  echo "Could not parse sha256 from ${formula_file}"
  exit 1
}
[ -n "${current_version}" ] || {
  echo "Could not parse version from formula URL"
  exit 1
}

if [ "${current_url}" != "${src_url}" ] || [ "${current_sha}" != "${src_sha256}" ]; then
  if [ "${apply_formula_changes}" = "true" ]; then
    echo "Updating ${formula_file} to ${version}"
    sed -i.bak \
      -e "s#^\([[:space:]]*url[[:space:]]*\"\).*\(\"[[:space:]]*\)$#\1${src_url}\2#" \
      -e "s#^\([[:space:]]*sha256[[:space:]]*\"\).*\(\"[[:space:]]*\)$#\1${src_sha256}\2#" \
      "${formula_file}"
    rm -f "${formula_file}.bak"
  fi
  changed="true"
else
  echo "Formula already up to date for ${version}."
fi

if [ "${run_brew_checks}" = "true" ]; then
  if brew tap | grep -qx "${tap_name}"; then
    brew untap --force "${tap_name}"
  fi
  brew tap --custom-remote "${tap_name}" "${workspace}"
  brew style "Formula/${formula}.rb"
  brew audit --strict --online "${tap_name}/${formula}"
  brew install --build-from-source "${tap_name}/${formula}"
  brew test "${tap_name}/${formula}"
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "formula=${formula}"
    echo "version=${version}"
    echo "src_url=${src_url}"
    echo "src_sha256=${src_sha256}"
    echo "formula_file=${formula_file}"
    echo "changed=${changed}"
  } >> "${GITHUB_OUTPUT}"
fi
