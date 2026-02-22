#!/usr/bin/env bash
set -euo pipefail

formula="${FORMULA:?FORMULA is required}"
version="${VERSION:?VERSION is required}"
formula_file="${FORMULA_FILE:?FORMULA_FILE is required}"
src_url="${SRC_URL:?SRC_URL is required}"
src_sha256="${SRC_SHA256:?SRC_SHA256 is required}"
base_branch="${BASE_BRANCH:?BASE_BRANCH is required}"
assignee="${ASSIGNEE:?ASSIGNEE is required}"

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

safe_version="$(echo "${version}" | tr -c '[:alnum:]._-' '-')"
branch="automation/bump-${formula}-${safe_version}"
title="chore(formula): bump ${formula} to ${version}"
body="Automated formula update from upstream release metadata."

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git checkout -B "${branch}"

sed -i.bak \
  -e "s#^\([[:space:]]*url[[:space:]]*\"\).*\(\"[[:space:]]*\)$#\1${src_url}\2#" \
  -e "s#^\([[:space:]]*sha256[[:space:]]*\"\).*\(\"[[:space:]]*\)$#\1${src_sha256}\2#" \
  "${formula_file}"
rm -f "${formula_file}.bak"

git add "${formula_file}"

if git diff --cached --quiet; then
  echo "No staged formula changes to commit; skipping PR update."
  exit 0
fi

git commit -m "${title}"
git push --force --set-upstream origin "${branch}"

pr_number="$(gh pr list --head "${branch}" --base "${base_branch}" --json number --jq '.[0].number')"
if [ -n "${pr_number}" ]; then
  gh pr edit "${pr_number}" \
    --title "${title}" \
    --body "${body}" \
    --add-assignee "${assignee}"
  echo "Updated PR #${pr_number}"
else
  gh pr create \
    --base "${base_branch}" \
    --head "${branch}" \
    --title "${title}" \
    --body "${body}" \
    --assignee "${assignee}"
  echo "Created PR for ${formula} ${version}"
fi
