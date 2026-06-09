# Merge Queue + Manual Stacked PR — Observations

> **Superseded by [REPORT.md](REPORT.md)** — kept for Phase 1 detail and PR links.

**Repo:** https://github.com/adsteventir/merge-queue-stack-test  
**Date:** 2026-06-09  
**Branch:** `develop` (default)  
**Protection:** Ruleset `develop-protection` — PR required, `check` status, `strict_required_status_checks_policy: true`  
**Merge queue:** **Not enabled** — personal-account repo; API returns `Invalid rule 'merge_queue'`. See [ORG-SETUP.md](ORG-SETUP.md).

---

## Platform blocker

| Item | Result |
|------|--------|
| `merge_queue` ruleset via REST API | **Rejected** (`422 Invalid rule 'merge_queue'`) |
| `merge_group` workflow runs (entire repo) | **0 runs** — queue never triggered |
| "Merge when ready" / queue UI | **Not available** without org-owned repo |

Merge queue requires a **public repo owned by a GitHub Organization** ([GitHub blog](https://github.blog/news-insights/product-news/github-merge-queue-is-generally-available/)). After org transfer, run `./scripts/enable-merge-queue.sh YOUR_ORG`.

---

## Scenario A — Single PR + trunk drift (without merge queue)

| Observation | Result |
|-------------|--------|
| PR | [#2](https://github.com/adsteventir/merge-queue-stack-test/pull/2) `feat/a` → `develop` |
| Decoy merged first | [#3](https://github.com/adsteventir/merge-queue-stack-test/pull/3) advanced `develop` |
| `mergeStateStatus` after drift | **BEHIND** |
| Merge without Update branch | **Blocked** — `head branch is not up to date with the base branch` |
| Update branch clicks | **1 required** (or `gh pr update-branch`) to merge |
| `merge_group` CI | **N/A** — no queue |

**With strict branch protection and no merge queue:** the Update branch problem is real.

---

## Scenario B — Two parallel PRs (without merge queue)

| Observation | Result |
|-------------|--------|
| PRs | [#4](https://github.com/adsteventir/merge-queue-stack-test/pull/4) B1, [#5](https://github.com/adsteventir/merge-queue-stack-test/pull/5) B2 |
| B1 merged | Success (squash) |
| B2 after B1 landed | **BEHIND** — merge blocked without update |
| Queue both smoothly | **No** — manual update required on B2 |
| `merge_group` CI | **N/A** |

---

## Scenario C — Manual stacked PRs

### C2 — Queue whole stack

| PR | Base | Result |
|----|------|--------|
| [#6](https://github.com/adsteventir/merge-queue-stack-test/pull/6) layer-1 → `develop` | Merged (squash + **delete branch**) |
| [#7](https://github.com/adsteventir/merge-queue-stack-test/pull/7) layer-2 → `feat/layer-1` | **Closed automatically** when base branch deleted — `DIRTY` / `CONFLICTING` |

**Friction:** Deleting the bottom branch on merge breaks the top PR. Top PR cannot enter `develop` queue (targets intermediate branch anyway).

### C3 — Sequential landing (workable path)

| Step | PR | Result |
|------|-----|--------|
| Open stack | [#8](https://github.com/adsteventir/merge-queue-stack-test/pull/8), [#9](https://github.com/adsteventir/merge-queue-stack-test/pull/9) | PR-2 base = `feat/layer-1b` |
| Merge PR-1 | #8 squash, **keep** `feat/layer-1b` branch | OK |
| Change base PR-2 → `develop` | #9 | Diff showed **both** files until update-branch |
| `gh pr update-branch` | #9 | Diff narrowed to `layer2b.txt` only |
| Merge PR-2 | #9 | **Success** |

| Manual steps for smooth stack land | 1) merge bottom without deleting base, 2) change base to `develop`, 3) update branch, 4) wait CI, 5) merge |

**Mid-stack PR CI:** [#7](https://github.com/adsteventir/merge-queue-stack-test/pull/7) had **no `check` runs** while base was `feat/layer-1` — workflow only triggers on PRs targeting `develop`.

---

## Scenario E — `merge_group` failure guards

CI guards are in [`.github/workflows/ci.yml`](.github/workflows/ci.yml) (`merge_group` + `checks_requested`).

| Sub-scenario | PR | `pull_request` CI | `merge_group` CI | Outcome |
|--------------|-----|-------------------|------------------|---------|
| E1 solo fail marker | [#10](https://github.com/adsteventir/merge-queue-stack-test/pull/10) `.mg-fail-solo` | **Pass** | **Not run** | Merged via direct squash — guard never executed |
| E2 combined markers | [#11](https://github.com/adsteventir/merge-queue-stack-test/pull/11), [#12](https://github.com/adsteventir/merge-queue-stack-test/pull/12) | **Pass** each | **Not run** | B1 merged; B2 **BEHIND** (same as Scenario B) |

**E2 queue ejection behavior:** **Not tested** — requires merge queue on org repo.

---

## Scenario D — Baseline (this repo *is* the baseline)

With `strict_required_status_checks_policy: true` and **no** merge queue, every drifted PR shows **BEHIND** and blocks merge until Update branch.

---

## Verdict rubric

| Scenario | Update branch clicks | Queue worked | Manual steps | Smooth? |
|----------|---------------------|--------------|--------------|---------|
| A — single PR + drift | **1** (blocked without it) | N/A (no queue) | Update branch | No |
| B — two parallel PRs | **1** on survivor PR | N/A | Update branch on B2 | No |
| C — stacked PRs | **1** on PR-2 after retarget | N/A | Change base + update branch; avoid delete-base on PR-1 | Partial |
| E1 — solo `merge_group` fail | 0 | **Not tested** | — | — |
| E2 — combined `merge_group` fail | 1 on B2 (no queue) | **Not tested** | — | — |
| D — without queue | **1+** required | N/A | Update branch | No |

---

## Bottom line

### Without merge queue (what we ran)

1. **Update branch is required** whenever `develop` moves ahead and strict up-to-date checks are on — confirmed in A, B, C3.
2. **Manual stacking does not queue to `develop`** for the top PR; sequential landing needs **change base + update branch** (and do not delete the stack base branch on merge).
3. **Mid-stack PRs** targeting `feat/layer-*` do not run `develop`-targeted CI in this workflow setup.

### Expected with merge queue (after org transfer — not verified here)

Per [GitHub docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue):

- PRs targeting `develop` should queue without Update branch; `merge_group` + `checks_requested` runs the second CI pass.
- Failed `merge_group` ejects the PR; queue rebuilds for survivors.
- Manual stacks still need **native Stacked PRs (`gh-stack`)** for one-click multi-PR queue — or the C3 manual steps above.

### gh-stack preview worth pursuing?

**Yes, if** you routinely stack PRs and want org merge queue + stack-aware landing without change-base/update-branch choreography. **Next step:** transfer repo to a free org → `./scripts/enable-merge-queue.sh` → re-run A, B, E → join [Stacked PRs waitlist](https://github.github.com/gh-stack/) for C with native stack map.
