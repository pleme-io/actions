# pleme-io · onboard-auto-release

> Scaffold the canonical 3-workflow pleme-io auto-release surface into a repo (auto-release.yml + pre-merge-gate.yml + security-gate.yml). Idempotent — skips files that already exist unless --force is set.

**Category**: `sdlc` — 🔄 SDLC automation
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/onboard-auto-release@v1
    with:
      default-bump-type: "patch"
      force: "false"
      include-auto-release: "true"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `default-bump-type` | no | `patch` | Default bump-type input in the auto-release.yml shim |
| `force` | no | `false` | Overwrite existing workflow files |
| `include-auto-release` | no | `true` | Scaffold auto-release.yml (merge-time publish) |
| `include-pre-merge-gate` | no | `true` | Scaffold pre-merge-gate.yml (PR-time quality gate) |
| `include-security-gate` | no | `true` | Scaffold security-gate.yml (vuln/SBOM/SPDX) |
| `open-pr` | no | `false` | Commit + open a PR with the new workflows |
| `pr-branch` | no | `chore/onboard-auto-release` | Branch name for the onboarding PR |

## Outputs

| Name | Description |
|---|---|
| `files-skipped` | Space-separated list of files already present (skipped) |
| `files-written` | Space-separated list of workflow files created |
| `pr-url` | URL of the opened PR (empty when open-pr=false) |

## Configuration via `.pleme-io-release.toml`

Per-repo defaults follow 3-tier precedence:
**env var (workflow input) > `.pleme-io-release.toml` > hardcoded default**.

See the [full config schema](https://github.com/pleme-io/substrate/blob/main/lib/release/example-config.toml).

## Architecture

Composite GitHub Action. Logic lives in [`run.tlisp`](./run.tlisp);
[`action.yml`](./action.yml) orchestrates install steps + one
`tatara-script` invocation.

Per the ★★ NO-SHELL prime directive
([pleme-io-pattern-core skill](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-pattern-core/SKILL.md)):
this action's primary logic is typed Lisp, not bash. The substrate's
[`action-shell-lint`](../action-shell-lint/) enforces this fleet-wide on every PR.

## Related primitives — `sdlc` category

[`dependabot-trigger`](../dependabot-trigger/) · [`dependency-update`](../dependency-update/) · [`issue-create`](../issue-create/) · [`nix-flake-update`](../nix-flake-update/) · [`pr-comment`](../pr-comment/) · [`status-badge`](../status-badge/)

## Auto-published on free public CI

Every push to `main` on `pleme-io/actions`:
1. `auto-bump.yml` fires (~10s) → tags `v0.13.{next}`
2. `release.yml` cuts the Docker image (if applicable) + fast-forwards `v1`
3. Consumers using `@v1` see the new revision automatically

**$0/month cost** — GitHub-hosted runners + public-repo free tier.

## License

MIT.

---
*Auto-generated from `action.yml` by [`pleme-doc-gen`](https://github.com/pleme-io/pleme-doc-gen). Do not hand-edit.*
