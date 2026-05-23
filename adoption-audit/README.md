# pleme-io · adoption-audit

> Scan a GH org for AUTO-RELEASE directive adoption — counts repos with/without the canonical 3-workflow surface. Emits a markdown report + sets typed outputs. Runs cheap on free public CI.

**Category**: `meta` — 🪞 Meta — directive enforcement + audit + renderer
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/adoption-audit@v1
    with:
      exclude-archived: "true"
      open-issue: "false"
      org: "pleme-io"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `exclude-archived` | no | `true` |  |
| `open-issue` | no | `false` | Open a tracking issue listing gap repos |
| `org` | no | `pleme-io` | GH organization to audit (default: pleme-io) |
| `visibility` | no | `public` | public | private | both |

## Outputs

| Name | Description |
|---|---|
| `adopted-count` |  |
| `adoption-pct` |  |
| `gap-count` |  |
| `report-path` |  |
| `total-repos` |  |

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

## Related primitives — `meta` category

[`action-shell-lint`](../action-shell-lint/) · [`defaction-render`](../defaction-render/)

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
