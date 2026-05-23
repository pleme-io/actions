# pleme-io · pr-comment

> Post or update a comment on a pull request. Idempotent via a magic marker — re-running updates the existing comment instead of spamming.

**Category**: `sdlc` — 🔄 SDLC automation
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/pr-comment@v1
    with:
      body: <required>
      marker: ""
      pr-number: ""
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `body` | yes | — | Markdown body of the comment |
| `marker` | no | `` | Hidden HTML comment that identifies this comment for upsert (default: ${{ github.workflow }}) |
| `pr-number` | no | `` | PR number (defaults to current PR if event is pull_request) |

## Outputs

| Name | Description |
|---|---|
| `action-taken` | 'created' | 'updated' |
| `comment-id` |  |

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

[`dependabot-trigger`](../dependabot-trigger/) · [`dependency-update`](../dependency-update/) · [`issue-create`](../issue-create/) · [`nix-flake-update`](../nix-flake-update/) · [`onboard-auto-release`](../onboard-auto-release/) · [`status-badge`](../status-badge/)

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
