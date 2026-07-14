# pleme-io · git-commit-tag

> Configure github-actions bot identity, stage typed paths, commit with a typed message template, and create an annotated tag. Composes with git-push-with-token for the push half.

**Category**: `git` — 📝 Git operations
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/git-commit-tag@v1
    with:
      add-paths: "Cargo.toml Cargo.lock Cargo.nix Cargo.gen.lock"
      commit-message-template: "release: workspace v{version}"
      identity-email: "41898282+github-actions[bot]@users.noreply.github.com"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `add-paths` | no | `Cargo.toml Cargo.lock Cargo.nix Cargo.gen.lock` | Space-separated git pathspecs to stage. Default fits a Rust workspace. |
| `commit-message-template` | no | `release: workspace v{version}` | Commit message template; '{version}' is substituted with the version input |
| `identity-email` | no | `41898282+github-actions[bot]@users.noreply.github.com` | git user.email to set for the commit |
| `identity-name` | no | `github-actions[bot]` | git user.name to set for the commit |
| `tag-prefix` | no | `v` | Prefix prepended to the tag name (default 'v' → tag 'v<version>') |
| `version` | yes | — | Version string used in the commit message + tag (e.g. '0.1.1') |

## Outputs

| Name | Description |
|---|---|
| `tag` | The created tag name |

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

## Related primitives — `git` category

[`git-push-with-token`](../git-push-with-token/)

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
