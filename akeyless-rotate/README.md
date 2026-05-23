# pleme-io · akeyless-rotate

> Rotate a rotated-secret in Akeyless. Reads $AKEYLESS_TOKEN.

**Category**: `akeyless` — 🔑 Akeyless secret management
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/akeyless-rotate@v1
    with:
      api-url: "https://api.akeyless.io"
      secret-name: <required>
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `api-url` | no | `https://api.akeyless.io` |  |
| `secret-name` | yes | — |  |

## Outputs

| Name | Description |
|---|---|
| `rotated` |  |

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

## Related primitives — `akeyless` category

[`akeyless-auth`](../akeyless-auth/) · [`akeyless-export-config`](../akeyless-export-config/) · [`akeyless-injector-validate`](../akeyless-injector-validate/) · [`akeyless-secret-fetch`](../akeyless-secret-fetch/)

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
