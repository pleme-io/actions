# pleme-io · issue-create

> Create (or reuse) a GitHub issue for a typed event. Useful for workflow auto-reporting (test failures, broken deps, drift, etc.). Idempotent via title-match deduplication.

**Category**: `sdlc` — 🔄 SDLC automation
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/issue-create@v1
    with:
      assignees: ""
      body: <required>
      labels: "automation"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `assignees` | no | `` | Comma-separated assignees |
| `body` | yes | — | Issue body (markdown) |
| `labels` | no | `automation` | Comma-separated labels |
| `reuse-open` | no | `true` | Reuse an existing open issue with the same title (idempotent) |
| `title` | yes | — | Issue title (used for dedup match) |

## Outputs

| Name | Description |
|---|---|
| `action-taken` | 'created' | 'reused' |
| `issue-url` |  |

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

[`dependabot-trigger`](../dependabot-trigger/) · [`dependency-update`](../dependency-update/) · [`nix-flake-update`](../nix-flake-update/) · [`onboard-auto-release`](../onboard-auto-release/) · [`pr-comment`](../pr-comment/) · [`status-badge`](../status-badge/)

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
