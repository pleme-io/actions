# pleme-io · git-commit-tag

> Configure github-actions bot identity, stage typed paths, commit with a typed message template, and create an annotated tag. Composes with git-push-with-token for the push half.

**Category**: `git` — 📝 Git operations
**Backend**: tatara-lisp (run.tlisp) wrapping CLI tools via `exec-capture`
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/git-commit-tag@v1
    with:
      version: <required>
      tag-prefix: "v"
      commit-message-template: "release: workspace v{version}"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `version` | yes | — | Version string used in the commit message + tag (e.g. '0.1.1') |
| `tag-prefix` | no | `v` | Prefix prepended to the tag name (default 'v' → tag 'v<version>') |
| `commit-message-template` | no | `release: workspace v{version}` | Commit message template; '{version}' is substituted with the version input |
| `add-paths` | no | `Cargo.toml Cargo.lock Cargo.nix` | Space-separated git pathspecs to stage. Default fits a Rust workspace. |
| `identity-name` | no | `github-actions[bot]` | git user.name to set for the commit |
| `identity-email` | no | `41898282+github-actions[bot]@users.noreply.github.com` | git user.email to set for the commit |

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
`tatara-script` invocation. Shared helpers from
[`_tlisp-stdlib`](../_tlisp-stdlib/).

Per the ★★ NO-SHELL prime directive
([pleme-io-pattern-core skill](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-pattern-core/SKILL.md)):
this action's primary logic is typed Lisp, not bash. The substrate's
[`action-shell-lint`](../action-shell-lint/) enforces this fleet-wide on every PR.

## Related primitives — `git` category

[`git-push-with-token`](../git-push-with-token/)


## Sources

- **Action source**: [`action.yml`](./action.yml) + [`run.tlisp`](./run.tlisp)
- **Catalog entry**: `substrate.lib.release.patterns.git.git-commit-tag` —
  [patterns-full.nix](https://github.com/pleme-io/substrate/blob/main/lib/release/patterns-full.nix)
- **Future typed source**: `(defaction git-commit-tag ...)` per
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
nix eval --raw github:pleme-io/substrate#lib.aarch64-darwin.release.patterns.git.git-commit-tag
```

## License

MIT.

---
*Auto-generated from `action.yml` by [`_gen-docs.py`](../_gen-docs.py).
Do not hand-edit; modify the source files or regenerate.*
