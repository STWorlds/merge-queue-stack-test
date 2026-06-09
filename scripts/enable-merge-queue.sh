#!/usr/bin/env bash
# Merge queue requires a repo owned by a GitHub Organization (not a personal account).
# See: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue
set -euo pipefail

OWNER="${1:?Usage: $0 ORG_NAME [REPO_NAME]}"
REPO="${2:-merge-queue-stack-test}"

gh api "repos/${OWNER}/${REPO}/rulesets" -X POST --input - <<'EOF'
{
  "name": "develop-merge-queue",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/develop"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [
          {"context": "check"}
        ]
      }
    },
    {
      "type": "merge_queue",
      "parameters": {
        "check_response_timeout_minutes": 60,
        "grouping_strategy": "ALLGREEN",
        "max_entries_to_build": 1,
        "max_entries_to_merge": 2,
        "min_entries_to_merge": 1,
        "min_entries_to_merge_wait_minutes": 0,
        "merge_method": "SQUASH"
      }
    }
  ]
}
EOF

echo "Merge queue ruleset created for ${OWNER}/${REPO}"
