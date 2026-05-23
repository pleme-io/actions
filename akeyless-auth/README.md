# pleme-io · akeyless-auth

> Akeyless login via access-id + (access-key | SAML | JWT). Exports AKEYLESS_TOKEN to subsequent steps so siblings (secret-fetch / rotate / etc) can reuse.

**Category**: `akeyless` — 🔑 Akeyless secret management
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/akeyless-auth@v1
    with:
      access-id: <required>
      access-key: ""
      api-url: "https://api.akeyless.io"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `access-id` | yes | — | Akeyless auth method access-id |
| `access-key` | no | `` | Static access-key (mutex with use-gh-jwt) |
| `api-url` | no | `https://api.akeyless.io` | Akeyless API URL |
| `use-gh-jwt` | no | `true` | Auth via GitHub OIDC JWT (recommended; no shared secret) |

## Outputs

| Name | Description |
|---|---|
| `token` | Akeyless session token (also exported as AKEYLESS_TOKEN env) |

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

[`akeyless-export-config`](../akeyless-export-config/) · [`akeyless-injector-validate`](../akeyless-injector-validate/) · [`akeyless-rotate`](../akeyless-rotate/) · [`akeyless-secret-fetch`](../akeyless-secret-fetch/)

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
