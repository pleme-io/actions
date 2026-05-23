# pleme-io · aws-assume-role

> Assume an AWS IAM role via OIDC (no long-lived creds). Exports AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY + AWS_SESSION_TOKEN to subsequent steps.

**Category**: `cloud` — ☁️ Cloud providers
**Backend**: shell
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/aws-assume-role@v1
    with:
      aws-region: "us-east-1"
      role-arn: <required>
      role-session-name: ""
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `aws-region` | no | `us-east-1` | Default AWS region |
| `role-arn` | yes | — | IAM role ARN to assume |
| `role-session-name` | no | `` | Session name (default: gh-actions-${run-id}) |

## Outputs

| Name | Description |
|---|---|
| `account-id` |  |

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

[`aws-s3-upload`](../aws-s3-upload/) · [`azure-deploy`](../azure-deploy/) · [`cloudflare-pages-deploy`](../cloudflare-pages-deploy/) · [`cloudflare-r2-upload`](../cloudflare-r2-upload/) · [`cloudflare-worker-deploy`](../cloudflare-worker-deploy/) · [`doctl-deploy`](../doctl-deploy/) · [`fly-deploy`](../fly-deploy/) · [`gcp-auth`](../gcp-auth/)

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
