# pleme-io · caixa-publish

> Publish caixa-rendered Helm chart to an OCI registry. Wraps helm-publish but consumes the caixa-render output dir.

**Category**: `caixa` — 📦 caixa — canonical SDLC primitive
**Backend**: shell
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/caixa-publish@v1
    with:
      chart-subdir: "helm"
      registry: "ghcr.io/pleme-io/helm"
      rendered-dir: "rendered/"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `chart-subdir` | no | `helm` | Subdirectory under rendered-dir that contains the Helm chart |
| `registry` | no | `ghcr.io/pleme-io/helm` |  |
| `rendered-dir` | no | `rendered/` | Directory caixa-render wrote to (default: rendered/) |

## Outputs

| Name | Description |
|---|---|
| `shipped` |  |

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

## Related primitives — `caixa` category

[`caixa-bump`](../caixa-bump/) · [`caixa-render`](../caixa-render/) · [`caixa-render-pr`](../caixa-render-pr/)

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
