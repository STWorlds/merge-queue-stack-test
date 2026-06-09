# Merge queue results — STWorlds org (2026-06-09)

> **Superseded by [REPORT.md](REPORT.md)** — kept for Phase 2 detail and PR links.

**Repo:** https://github.com/STWorlds/merge-queue-stack-test  
**Org:** [STWorlds](https://github.com/STWorlds) (free org, public repo)  
**Merge queue:** Enabled via ruleset `develop-protection` (`merge_queue` + `strict` status checks)

## Setup notes

- `gh pr merge` needs `allow_auto_merge=true` on the repo, or use `enqueuePullRequest` GraphQL ([cli#13398](https://github.com/cli/cli/issues/13398)).
- Enqueue helper: `gh api graphql` with `enqueuePullRequest` mutation (see `scripts/enqueue-pr.sh`).
- CI guards were fixed to only fail on **newly added** marker files (`git diff base_sha..HEAD`), not markers already on `develop`.

---

## Scenario A — Drift without Update branch ✅

| Step | Result |
|------|--------|
| [#14 MQ-A](https://github.com/STWorlds/merge-queue-stack-test/pull/14) opened | `pull_request` CI pass |
| [#15 decoy](https://github.com/STWorlds/merge-queue-stack-test/pull/15) merged via queue | `develop` advanced |
| Queue #14 **without** `gh pr update-branch` | **Merged** |
| `merge_group` CI | **Pass** on `gh-readonly-queue/develop/pr-14-...` |

**Verdict:** Merge queue **eliminates Update branch** for PRs targeting `develop`.

---

## Scenario B — Two PRs in queue ✅

| PR | Result |
|----|--------|
| [#17 MQ-B1](https://github.com/STWorlds/merge-queue-stack-test/pull/17) | Queued first → `merge_group` pass → merged |
| [#18 MQ-B2](https://github.com/STWorlds/merge-queue-stack-test/pull/18) | Queued second → `merge_group` pass (included B1) → merged |
| Update branch clicks | **0** |

---

## Scenario E1 — Solo `merge_group` failure ✅

| PR | `pull_request` | `merge_group` | Queue outcome |
|----|----------------|---------------|---------------|
| [#20 MQ-E1](https://github.com/STWorlds/merge-queue-stack-test/pull/20) `.mq-e1-fail` | Pass | **Fail** | **Ejected** — PR stays **OPEN**, not merged |

---

## Scenario E2 — Combined batch failure (partial)

| PR | Result |
|----|--------|
| [#21 MQ-E2A](https://github.com/STWorlds/merge-queue-stack-test/pull/21) `.mq-e2-a` | Solo `merge_group` pass → **merged** |
| [#22 MQ-E2B](https://github.com/STWorlds/merge-queue-stack-test/pull/22) `.mq-e2-b` | Solo `merge_group` pass → **merged** |

**Note:** Combined guard (both markers in one `merge_group` diff) did **not** trigger because the queue validated and merged #21 before building the combined group for #22. To force combined failure, put both markers on **one PR** or increase `min_entries_to_merge` so both land in the same batch.

---

## Stacked PRs (manual — unchanged from personal-account run)

Merge queue still only accepts PRs whose **base is `develop`**. Manual stacks need bottom-first merge + change base + update branch (see [OBSERVATIONS.md](OBSERVATIONS.md) Scenario C). Native stack-aware queue requires [GitHub Stacked PRs](https://github.github.com/gh-stack/).

---

## Summary

| Question | Answer (org + merge queue) |
|----------|---------------------------|
| Free org + public repo works? | **Yes** |
| Update branch replaced? | **Yes** for `develop`-targeting PRs |
| Two PRs queue smoothly? | **Yes** — FIFO, `merge_group` per entry |
| `merge_group` failure ejects PR? | **Yes** (E1) |
| Manual stacked PRs one-click queue? | **No** — still need C3 manual steps |
