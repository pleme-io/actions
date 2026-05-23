# pleme-io · aws-s3-upload

> Upload a file or directory to S3. Pairs with aws-assume-role for IAM. Useful for build-artifact ship, backup, SBOM archive, etc.

**Category**: `cloud` — ☁️ Cloud providers
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/aws-s3-upload@v1
    with:
      acl: "private"
      bucket: <required>
      key: <required>
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `acl` | no | `private` |  |
| `bucket` | yes | — |  |
| `key` | yes | — | Destination key prefix (e.g. releases/v0.1.0/) |
| `recursive` | no | `false` |  |
| `source` | yes | — | Local file or directory |

## Outputs

| Name | Description |
|---|---|
| `s3-uri` |  |

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

## Related primitives — `cloud` category

[`aws-assume-role`](../aws-assume-role/) · [`azure-deploy`](../azure-deploy/) · [`cloudflare-pages-deploy`](../cloudflare-pages-deploy/) · [`cloudflare-r2-upload`](../cloudflare-r2-upload/) · [`cloudflare-worker-deploy`](../cloudflare-worker-deploy/) · [`doctl-deploy`](../doctl-deploy/) · [`fly-deploy`](../fly-deploy/) · [`gcp-auth`](../gcp-auth/)

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
