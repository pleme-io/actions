# pleme-io · helm-publish

> Publish a Helm chart to an OCI registry (default ghcr.io/pleme-io/helm); skip if (name, version) already exists.

**Category**: `helm` — ⛵ Helm — chart packaging + deployment
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/helm-publish@v1
    with:
      dry-run: "false"
      registry: "ghcr.io/pleme-io/helm"
      registry-username: ""
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `dry-run` | no | `false` | Package the chart but don't push |
| `registry` | no | `ghcr.io/pleme-io/helm` | OCI registry to push to |
| `registry-username` | no | `` | Registry login username (default github.actor) |

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

## Related primitives — `helm` category

[`helm-bump`](../helm-bump/) · [`helm-oci-publish`](../helm-oci-publish/)

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
