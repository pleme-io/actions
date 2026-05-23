# pleme-io · aws-assume-role

> Assume an AWS IAM role via OIDC (no long-lived creds). Exports AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY + AWS_SESSION_TOKEN to subsequent steps.

**Category**: `cloud` — ☁️ Cloud providers (AWS/GCP/Cloudflare/Azure/Vercel/Netlify/Render/Railway/Heroku/DigitalOcean/Fly)
**Backend**: tatara-lisp (run.tlisp) wrapping CLI tools via `exec-capture`
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/aws-assume-role@v1
    with:
      role-arn: <required>
      aws-region: "us-east-1"
      role-session-name: ""
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `role-arn` | yes | — | IAM role ARN to assume |
| `aws-region` | no | `us-east-1` | Default AWS region |
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
`tatara-script` invocation. Shared helpers from
[`_tlisp-stdlib`](../_tlisp-stdlib/).

Per the ★★ NO-SHELL prime directive
([pleme-io-pattern-core skill](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-pattern-core/SKILL.md)):
this action's primary logic is typed Lisp, not bash. The substrate's
[`action-shell-lint`](../action-shell-lint/) enforces this fleet-wide on every PR.

## Related primitives — `cloud` category

[`aws-s3-upload`](../aws-s3-upload/) · [`azure-deploy`](../azure-deploy/) · [`cloudflare-pages-deploy`](../cloudflare-pages-deploy/) · [`cloudflare-r2-upload`](../cloudflare-r2-upload/) · [`cloudflare-worker-deploy`](../cloudflare-worker-deploy/) · [`doctl-deploy`](../doctl-deploy/) · [`fly-deploy`](../fly-deploy/) · [`gcp-auth`](../gcp-auth/)


## Sources

- **Action source**: [`action.yml`](./action.yml) + [`run.tlisp`](./run.tlisp)
- **Catalog entry**: `substrate.lib.release.patterns.cloud.aws-assume-role` —
  [patterns-full.nix](https://github.com/pleme-io/substrate/blob/main/lib/release/patterns-full.nix)
- **Future typed source**: `(defaction aws-assume-role ...)` per
  [ACTION-AS-CAIXA.md](https://github.com/pleme-io/substrate/blob/main/docs/ACTION-AS-CAIXA.md) (M1+ migration)

## Operator-facing CLI

Same logic locally via `cargo install pleme-io-releaser`:

```bash
pleme-release plan      # preview what an auto-release would do
pleme-release onboard   # scaffold the 3-workflow surface to a fresh repo
pleme-release detect    # emit detected repo type
```

## Auto-published on free public CI

Every push to `main` on `pleme-io/actions`:
1. `auto-bump.yml` fires (~10s) → tags `v0.13.{next}`
2. `release.yml` cuts the Docker image (if applicable) + fast-forwards `v1`
3. Consumers using `@v1` or `@v0.13.{x}` see the new revision automatically

**$0/month cost** — GitHub-hosted runners + public-repo free tier.

## Discovery

Browse the [full catalog](../README.md) or query via Nix:

```bash
nix eval --raw github:pleme-io/substrate#lib.aarch64-darwin.release.patterns.cloud.aws-assume-role
```

## License

MIT.

---
*Auto-generated from `action.yml` by [`_gen-docs.py`](../_gen-docs.py).
Do not hand-edit; modify the source files or regenerate.*
