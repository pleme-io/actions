# pleme-io · pull-request-gate

Gate `pull_request_target` events: allow approved authors, label bots, and auto-close + lock external first-time-contributor PRs whose diff only touches documentation paths (README, LICENSE, `.github/`, `*.md`, `docs/`). Defends against vendor badge-trojan and SEO-spam pull requests (e.g. the SafeSkill / OyaAIProd campaign that hit ~100 GitHub repos in May 2026 with a fake "Verified Safe" README badge).

Companion to the typed `ExternalContributorPolicy` primitive reconciled by `pangea-operator` (Phase 2 — see [pleme-io/actions#2](https://github.com/pleme-io/actions/issues/2)).

## Behavior

Runs on `pull_request_target` and routes every PR through one of four branches:

| Branch | Trigger | Action |
|---|---|---|
| 1 — allowlist | PR author in `allowlist` input | no-op, pass through |
| 2 — bot | PR author matches `*[bot]` suffix or `bot-allowlist` | label `bot-pr`, pass through |
| 3 — drive-by | `FIRST_TIME_CONTRIBUTOR` **and** every file matches `restricted-paths-regex` | per `rejection-action` (default: comment + label `external-drive-by` + close + lock as `spam`) |
| 4 — substantive external | `FIRST_TIME_CONTRIBUTOR` with substantive diff | label `external-review-required` |

## Usage

```yaml
# .github/workflows/external-contributor-gate.yml
name: external-contributor-gate

on:
  pull_request_target:
    types: [opened, reopened, synchronize]

permissions:
  pull-requests: write
  issues: write          # required to lock conversations
  contents: read

jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: pleme-io/actions/pull-request-gate@v1
        with:
          allowlist: |
            drzln
```

## Inputs

| Input | Required | Default | Notes |
|---|---|---|---|
| `allowlist` | no | (empty) | Newline-separated GitHub logins exempt from gating. Org members and curated externals. |
| `bot-allowlist` | no | `dependabot[bot]`, `renovate[bot]`, `github-actions[bot]` | Newline-separated bot logins explicitly accepted. The `*[bot]` suffix also auto-detects bots, so this is for non-suffix bot accounts. |
| `restricted-paths-jq-predicate` | no | `. == "README.md" or . == "LICENSE" or startswith(".github/") or startswith("docs/") or endswith(".md")` | jq predicate expression evaluated per file path (the `.` variable). A drive-by candidate's every file must satisfy the predicate. Typed predicates beat regex through the shell+JSON+jq quoting chain. |
| `rejection-action` | no | `close_and_lock` | `close_and_lock` \| `label_only` \| `request_approval` |
| `github-token` | no | `${{ github.token }}` | Needs `pull-requests:write` + `issues:write`. |
| `tatara-version` | no | `latest` | tatara-lisp release tag. |

## Why `pull_request_target` (not `pull_request`)

`pull_request` from a fork runs with a read-only token — the gate cannot close, label, or lock. `pull_request_target` runs in the **base** repo context with the base repo's secrets and write permissions, but checks out the **base** commit (not the fork's HEAD), so it cannot accidentally execute attacker-controlled fork code. The gate makes only GitHub API calls — no fork code is executed.

### First-time-contributor workflow approval

GitHub's default `actions.first_time_contributors_approval` setting requires the maintainer to approve the first workflow run from a brand-new account. The OyaAIProd-shape PR will sit in "waiting for approval" until the maintainer clicks Approve and run, which then runs this gate, which then auto-rejects the PR. The gate removes the "what do I do with this?" cognitive load but does not bypass the approval click. A future Phase 3 controller (Rust webhook listener on rio) will close the loop without requiring the click.

## Required workflow permissions

```yaml
permissions:
  pull-requests: write   # close, label, comment
  issues: write          # lock conversation as spam
  contents: read         # CODEOWNERS lookup (future)
```

## Decision tree (for review)

```
pull_request_target.opened
  └── author in allowlist?
      ├── YES → exit 0
      └── NO  → author looks like bot (* [bot] suffix or in bot-allowlist)?
                ├── YES → label bot-pr, exit 0
                └── NO  → author_association == FIRST_TIME_CONTRIBUTOR
                          AND every file matches restricted-paths-regex?
                          ├── YES → rejection-action
                          │         ├── close_and_lock     → comment + label external-drive-by + close + lock(spam)
                          │         ├── label_only         → label external-drive-by
                          │         └── request_approval   → label external-review-required
                          └── NO  → label external-review-required, exit 0
```

## Status

- **v1** — initial release. Strict gate behavior, designed to be consumed via a `~~~~` pleme-io-github-posture reconcile loop in Phase 2.
- Tracking: pleme-io/actions#2.
- Dogfood: pleme-io/kotoba — the first repo to consume this action (the OyaAIProd PR target).

## References

- Skill: `pleme-io-action-vocabulary` (catalog conventions)
- Skill: `pleme-io-pattern-core` (canonical action shape)
- Skill: `pleme-io-github-posture` (fleet posture reconciler)
- Incident: SafeSkill / OyaAIProd drive-by — pleme-io/kotoba#1 (closed, locked, blocked 2026-05-28)
