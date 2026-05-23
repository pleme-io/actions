# pleme-io · cargo-bump

> Bump a single-crate Rust repo via cargo set-version --bump <type>, regenerate Cargo.nix, refresh Cargo.lock. Sibling of rust-workspace-bump for non-workspace Rust repos.

**Category**: `rust` — 🦀 Rust ecosystem
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/cargo-bump@v1
    with:
      bump-type: "patch"
      skip-when-no-source-changes: "true"
      source-paths: "src Cargo.toml Cargo.lock"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `bump-type` | no | `patch` | patch | minor | major |
| `skip-when-no-source-changes` | no | `true` | Skip the bump when no source path changed since the previous tag |
| `source-paths` | no | `src Cargo.toml Cargo.lock` | Space-separated globs the skip-detector inspects for changes since the last tag |

## Outputs

| Name | Description |
|---|---|
| `bumped` | true if a bump happened, false if skipped/no-op |
| `new-version` | New package.version after bump (empty when bumped=false) |
| `old-version` | Previous package.version (always populated) |

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

## Related primitives — `rust` category

[`cargo-publish-crate`](../cargo-publish-crate/)

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
