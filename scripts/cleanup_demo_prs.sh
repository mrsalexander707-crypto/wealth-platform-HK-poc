#!/usr/bin/env bash
# Demo cleanup — close any open refactor PRs and delete the branches,
# leaving main on the original Hong Kong baseline.
#
# Usage:
#   export GH_PAT='github_pat_...'
#   bash scripts/cleanup_demo_prs.sh
#
# Idempotent: safe to run any number of times. Only touches branches
# matching the pattern `refactor/*-entity-context-*` — your other
# branches are untouched.

set -euo pipefail

OWNER="Supriyomaity98"
REPO="wealth-platform-HK-poc"
BRANCH_PATTERN='^refactor/.*-entity-context-.*$'

if [[ -z "${GH_PAT:-}" ]]; then
  echo "ERROR: GH_PAT environment variable not set"
  echo "  export GH_PAT='github_pat_...'"
  exit 1
fi

API="https://api.github.com/repos/${OWNER}/${REPO}"
H_AUTH=(-H "Authorization: Bearer ${GH_PAT}" -H "Accept: application/vnd.github+json")

echo "==> Listing open PRs on ${OWNER}/${REPO}"
open_prs=$(curl -s "${H_AUTH[@]}" "${API}/pulls?state=open&per_page=100")
matching_prs=$(echo "${open_prs}" | python3 -c "
import sys, json, re
prs = json.load(sys.stdin)
pat = re.compile(r'$BRANCH_PATTERN')
for pr in prs:
    if pat.match(pr['head']['ref']):
        print(f\"{pr['number']}|{pr['head']['ref']}\")
")

if [[ -z "${matching_prs}" ]]; then
  echo "  No matching open PRs."
else
  echo "  Matching PRs:"
  echo "${matching_prs}" | sed 's/^/    #/'
fi

echo
echo "==> Closing PRs + posting cleanup comment"
while IFS='|' read -r pr_num branch; do
  [[ -z "${pr_num}" ]] && continue
  echo "  PR #${pr_num} (branch ${branch})"
  curl -s -X POST "${H_AUTH[@]}" \
    "${API}/issues/${pr_num}/comments" \
    -d '{"body":"Auto-cleanup: closing this demo PR to keep the repo fresh for the next run. No changes were merged."}' \
    >/dev/null
  curl -s -X PATCH "${H_AUTH[@]}" \
    "${API}/pulls/${pr_num}" \
    -d '{"state":"closed"}' >/dev/null
  echo "    closed."
done <<< "${matching_prs}"

echo
echo "==> Listing all branches and deleting matching ones"
branches=$(curl -s "${H_AUTH[@]}" "${API}/branches?per_page=100" \
  | python3 -c "
import sys, json, re
bs = json.load(sys.stdin)
pat = re.compile(r'$BRANCH_PATTERN')
for b in bs:
    if pat.match(b['name']):
        print(b['name'])
")

if [[ -z "${branches}" ]]; then
  echo "  No matching branches to delete."
else
  while IFS= read -r branch; do
    [[ -z "${branch}" ]] && continue
    echo -n "  ${branch}: "
    code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${H_AUTH[@]}" \
      "${API}/git/refs/heads/${branch}")
    if [[ "${code}" == "204" ]]; then
      echo "deleted"
    else
      echo "WARN HTTP ${code}"
    fi
  done <<< "${branches}"
fi

echo
echo "==> Final state"
remaining_prs=$(curl -s "${H_AUTH[@]}" "${API}/pulls?state=open" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")
remaining_branches=$(curl -s "${H_AUTH[@]}" "${API}/branches" | python3 -c "import sys,json; print(','.join(b['name'] for b in json.load(sys.stdin)))")
echo "  Open PRs: ${remaining_prs}"
echo "  Branches: ${remaining_branches}"
echo
echo "Done. Repo ready for next demo run."
