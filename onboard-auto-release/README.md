# pleme-io · onboard-auto-release

Scaffold the canonical 3-workflow pleme-io auto-release surface
into a repo:

- `.github/workflows/pre-merge-gate.yml` — PR quality gate (fmt + lint + test + tlisp-lint + publish dry-run)
- `.github/workflows/security-gate.yml` — Vuln audit + SBOM + SPDX headers
- `.github/workflows/auto-release.yml` — Merge-time bump + tag + publish

Per the ★★ AUTO-RELEASE prime directive
([`pleme-io/CLAUDE.md`](https://github.com/pleme-io/blackmatter-pleme/blob/main/docs/pleme-io-CLAUDE.md)
and
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill), every adopting repo MUST land these three files. This
action automates the scaffold + optional PR open.

## Inputs

| Name | Default | Description |
|---|---|---|
| `include-pre-merge-gate` | `true` | Scaffold pre-merge-gate.yml |
| `include-security-gate` | `true` | Scaffold security-gate.yml |
| `include-auto-release` | `true` | Scaffold auto-release.yml |
| `force` | `false` | Overwrite existing files |
| `open-pr` | `false` | Commit + open a PR with the new workflows |
| `pr-branch` | `chore/onboard-auto-release` | Branch name for the PR |
| `default-bump-type` | `patch` | Default bump-type input |

## Outputs

| Name | Description |
|---|---|
| `files-written` | Space-separated list of created workflow files |
| `files-skipped` | Space-separated list of files already present (skipped) |
| `pr-url` | URL of the opened PR (empty when `open-pr=false`) |

## Idempotency

Existing workflow files are SKIPPED unless `force=true`. Running
the action twice in a row produces zero new commits.

## Example: ad-hoc onboarding via workflow_dispatch

```yaml
# .github/workflows/onboard.yml — temporary; delete after first run
name: onboard
on: workflow_dispatch
jobs:
  onboard:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: pleme-io/actions/onboard-auto-release@main
        with:
          open-pr: "true"
```

Run via:

```bash
gh workflow run onboard.yml --repo pleme-io/<repo>
```

## Example: fleet-wide bulk onboarding

```bash
# For each pleme-io repo without auto-release.yml:
gh repo list pleme-io --limit 200 --json name --jq '.[].name' \
  | while read repo; do
      if ! gh api "repos/pleme-io/$repo/contents/.github/workflows/auto-release.yml" \
           --silent 2>/dev/null; then
        gh workflow run onboard.yml --repo "pleme-io/$repo" -f open-pr=true || true
      fi
    done
```
