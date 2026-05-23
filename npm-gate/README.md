# pleme-io · npm-gate

> PR-time quality gate for an npm repo: prettier --check + eslint + npm test (each conditionally run based on script presence in package.json).

**Category**: `validation` — 🚦 Validation — per-language gates + universal lints
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/npm-gate@v1
    with:
      run-fmt: "true"
      run-lint: "true"
      run-test: "true"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `run-fmt` | no | `true` | Run prettier --check (when fmt script exists) |
| `run-lint` | no | `true` | Run npm run lint (when lint script exists) |
| `run-test` | no | `true` | Run npm test (when test script exists) |

## Outputs

| Name | Description |
|---|---|
| `fmt-passed` |  |
| `lint-passed` |  |
| `test-passed` |  |

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

## Related primitives — `validation` category

[`nix-flake-check`](../nix-flake-check/) · [`python-gate`](../python-gate/) · [`rust-gate`](../rust-gate/) · [`tlisp-lint`](../tlisp-lint/) · [`typecheck-gate`](../typecheck-gate/)

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
