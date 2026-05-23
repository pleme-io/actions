# pleme-io · nix-flake-update

> Run `nix flake update` + open PR if flake.lock changed. Idempotent — exits 0 with no PR when lock is current. Specific case of dependency-update for nix-only repos.

**Category**: `sdlc` — 🔄 SDLC automation
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/nix-flake-update@v1
    with:
      inputs-to-update: ""
      open-pr: "true"
      pr-branch: "chore/flake-lock-update"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `inputs-to-update` | no | `` | Space-separated flake inputs to update (empty = all) |
| `open-pr` | no | `true` | Open a PR when flake.lock changed |
| `pr-branch` | no | `chore/flake-lock-update` | Branch name for the PR |

## Outputs

| Name | Description |
|---|---|
| `changed` |  |
| `pr-url` |  |

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

[`dependabot-trigger`](../dependabot-trigger/) · [`dependency-update`](../dependency-update/) · [`issue-create`](../issue-create/) · [`onboard-auto-release`](../onboard-auto-release/) · [`pr-comment`](../pr-comment/) · [`status-badge`](../status-badge/)

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
