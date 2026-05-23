# pleme-io · iac-forge

> Run iac-forge codegen against a spec + provider TOML

**Category**: `iac` — 🏗️ IaC — Terraform / Pulumi
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/iac-forge@v1
    with:
      backend: <required>
      data-sources: ""
      output: <required>
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `backend` | yes | — | ansible | terraform | pulumi | crossplane | steampipe | helm |
| `data-sources` | no | `` | Path to data-source TOML directory (optional) |
| `output` | yes | — | Output directory for generated artifacts |
| `provider` | yes | — | Path to provider.toml |
| `resources` | yes | — | Path to resource TOML directory |
| `spec` | yes | — | Path to OpenAPI spec (yaml/json) |
| `version` | no | `latest` | iac-forge-cli version to use (e.g. v0.2.0 or 'latest') |

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

## Related primitives — `iac` category

[`pulumi-up`](../pulumi-up/) · [`terraform-apply`](../terraform-apply/) · [`terraform-plan`](../terraform-plan/)

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
