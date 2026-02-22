#!/usr/bin/env bash
set -euo pipefail

formula="${FORMULA:?FORMULA is required}"
version="${VERSION:?VERSION is required}"
formula_file="${FORMULA_FILE:?FORMULA_FILE is required}"
src_url="${SRC_URL:?SRC_URL is required}"
src_sha256="${SRC_SHA256:?SRC_SHA256 is required}"
base_branch="${BASE_BRANCH:?BASE_BRANCH is required}"
assignee="${ASSIGNEE:-}"

# Normalize potential CR/LF from workflow outputs before validation/use.
formula="${formula//$'\r'/}"
formula="${formula//$'\n'/}"
version="${version//$'\r'/}"
version="${version//$'\n'/}"
formula_file="${formula_file//$'\r'/}"
formula_file="${formula_file//$'\n'/}"
src_url="${src_url//$'\r'/}"
src_url="${src_url//$'\n'/}"
src_sha256="${src_sha256//$'\r'/}"
src_sha256="${src_sha256//$'\n'/}"
base_branch="${base_branch//$'\r'/}"
base_branch="${base_branch//$'\n'/}"
assignee="${assignee//$'\r'/}"
assignee="${assignee//$'\n'/}"

for tool in git gh sed; do
  if ! command -v "${tool}" > /dev/null 2>&1; then
    echo "Required tool not found: ${tool}"
    exit 1
  fi
done

if ! [[ "${formula}" =~ ^[a-z0-9][a-z0-9+_.-]*$ ]]; then
  echo "Invalid FORMULA: ${formula}"
  exit 1
fi

if [ "${formula_file}" != "Formula/${formula}.rb" ]; then
  echo "Unexpected FORMULA_FILE path: ${formula_file}"
  exit 1
fi

if ! [[ "${version}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.]+)*$ ]]; then
  echo "Invalid VERSION: ${version}"
  exit 1
fi

if ! [[ "${src_sha256}" =~ ^[A-Fa-f0-9]{64}$ ]]; then
  echo "Invalid SRC_SHA256 format."
  exit 1
fi

if ! [[ "${base_branch}" =~ ^[A-Za-z0-9._/-]+$ ]]; then
  echo "Invalid BASE_BRANCH: ${base_branch}"
  exit 1
fi

if [ -n "${assignee}" ] && ! [[ "${assignee}" =~ ^[A-Za-z0-9-]+$ ]]; then
  echo "Invalid ASSIGNEE: ${assignee}"
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

safe_version="$(printf '%s' "${version}" | tr -c '[:alnum:]._-' '-')"
branch="automation/bump-${formula}-${safe_version}"
title="chore(formula): bump ${formula} to ${version}"
run_url="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-pbsladek/homebrew-tap}/actions/runs/${GITHUB_RUN_ID:-unknown}"
body=$(
  cat << EOF
Automated formula update from upstream release metadata.

- Formula: \`${formula}\`
- Version: \`${version}\`
- File: \`${formula_file}\`
- Source URL: \`${src_url}\`
- SHA256: \`${src_sha256}\`
- Workflow run: ${run_url}
EOF
)

escape_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[&\\#]/\\&/g'
}

escaped_src_url="$(escape_sed_replacement "${src_url}")"
escaped_src_sha256="$(escape_sed_replacement "${src_sha256}")"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git fetch origin "${base_branch}"
git checkout -B "${branch}" "origin/${base_branch}"

sed -i.bak \
  -e "s#^\([[:space:]]*url[[:space:]]*\"\).*\(\"[[:space:]]*\)$#\1${escaped_src_url}\2#" \
  -e "s#^\([[:space:]]*sha256[[:space:]]*\"\).*\(\"[[:space:]]*\)$#\1${escaped_src_sha256}\2#" \
  "${formula_file}"
rm -f "${formula_file}.bak"

git add "${formula_file}"

if git diff --cached --quiet; then
  echo "No staged formula changes to commit; skipping PR update."
  exit 0
fi

git commit -m "${title}"
git push --force-with-lease --set-upstream origin "${branch}"

pr_number="$(gh pr list --head "${branch}" --base "${base_branch}" --json number --jq '.[0].number')"
if [ -n "${pr_number}" ]; then
  if [ -n "${assignee}" ]; then
    gh pr edit "${pr_number}" \
      --title "${title}" \
      --body "${body}" \
      --add-assignee "${assignee}"
  else
    gh pr edit "${pr_number}" \
      --title "${title}" \
      --body "${body}"
  fi
  echo "Updated PR #${pr_number}"
else
  if [ -n "${assignee}" ]; then
    gh pr create \
      --base "${base_branch}" \
      --head "${branch}" \
      --title "${title}" \
      --body "${body}" \
      --assignee "${assignee}"
  else
    gh pr create \
      --base "${base_branch}" \
      --head "${branch}" \
      --title "${title}" \
      --body "${body}"
  fi
  echo "Created PR for ${formula} ${version}"
fi
