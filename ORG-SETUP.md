# Organization required for merge queue

GitHub merge queue is **not available on personal-account repos**. The REST API returns `Invalid rule 'merge_queue'` when creating rulesets on `adsteventir/merge-queue-stack-test`.

Per [GitHub's merge queue docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue), merge queue is available for:

- **Public** repositories owned by an **organization**
- All repositories on **GitHub Enterprise Cloud**

## To enable merge queue for this experiment

1. Create a free GitHub organization (or use an existing one where you have repo-create permission).
2. Transfer this repository: **Settings → General → Transfer ownership** → your org.
3. Delete the existing `develop-protection` ruleset (no merge queue).
4. Run:

```bash
./scripts/enable-merge-queue.sh YOUR_ORG_NAME
```

5. Re-run scenarios A–E from the experiment plan.

Until then, scenarios run with PR-required ruleset + `check` status only (direct squash merge, no queue).
