#!/usr/bin/env bash
# Add a pull request to the merge queue (use when gh pr merge fails on ruleset-based queues).
set -euo pipefail
REPO="${1:?Usage: $0 OWNER/REPO PR_NUMBER}"
PR="${2:?Usage: $0 OWNER/REPO PR_NUMBER}"
ID=$(gh pr view "$PR" --repo "$REPO" --json id -q .id)
gh api graphql -f query='
  mutation($id: ID!) {
    enqueuePullRequest(input: {pullRequestId: $id}) {
      mergeQueueEntry { position state }
    }
  }' -f id="$ID"
