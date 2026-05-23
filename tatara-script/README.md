# pleme-io · tatara-script

> Execute an embedded .tlisp source string with tatara-script (binary-first, cargo-install fallback)

**Category**: `runtime` — ⚙️ Runtime — tatara-script
**Backend**: shell
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/tatara-script@v1
    with:
      args: ""
      script: <required>
      version: "latest"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `args` | no | `` | Positional arguments passed to the script (forwarded as $@ after the script file) |
| `script` | yes | — | Multi-line .tlisp source executed by tatara-script (the entire body of a .tlisp file) |
| `version` | no | `latest` | tatara-lisp release tag (e.g. v0.1.0) or 'latest' |

## Outputs

| Name | Description |
|---|---|
| `bumped` | Forwarded from the script's GITHUB_OUTPUT (key: bumped) |
| `new-version` | Forwarded from the script's GITHUB_OUTPUT (key: new-version) |
| `result` | Forwarded from the script's GITHUB_OUTPUT (key: result) — generic catch-all |
| `version` | Forwarded from the script's GITHUB_OUTPUT (key: version) |

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

## Related primitives — `runtime` category

(this is the only primitive in this category)

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
