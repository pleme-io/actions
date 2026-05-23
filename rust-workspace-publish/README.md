# pleme-io · rust-workspace-publish

> Ship every workspace member to the Rust registry in topological dependency order. Auto-renames any conflicting crate to pleme-io-<original> + commits the rename back to main + retries. Pure tlisp logic, no shell beyond install glue.

**Category**: `publish` — 📤 Registry publishing
**Backend**: tatara-lisp (run.tlisp) wrapping CLI tools via `exec-capture`
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/rust-workspace-publish@v1
    with:
      dry-run: "false"
      no-verify: "true"
      rename-prefix: "pleme-io-"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `dry-run` | no | `false` | Run the registry ship as --dry-run only (no upload) |
| `no-verify` | no | `true` | Skip the verification compile step. true keeps the ship loop fast + tolerant of edge cases the verify step trips on; false uses the registry's default verification. |
| `rename-prefix` | no | `pleme-io-` | Prefix used when auto-renaming a conflicting crate. Default 'pleme-io-' lands names under the org's namespace. |
| `max-rename-retries` | no | `20` | Maximum number of conflict-rename retry iterations. Default 20 covers a 15-crate workspace with safety margin. |

## Outputs

| Name | Description |
|---|---|
| `shipped-count` | Number of workspace members successfully shipped |
| `renamed-crates` | Comma-separated list of crates that got auto-renamed |

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

## Related primitives — `publish` category

(this is the only primitive in this category)


## Sources

- **Action source**: [`action.yml`](./action.yml) + [`run.tlisp`](./run.tlisp)
- **Catalog entry**: `substrate.lib.release.patterns.publish.rust-workspace-publish` —
  [patterns-full.nix](https://github.com/pleme-io/substrate/blob/main/lib/release/patterns-full.nix)
- **Future typed source**: `(defaction rust-workspace-publish ...)` per
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
nix eval --raw github:pleme-io/substrate#lib.aarch64-darwin.release.patterns.publish.rust-workspace-publish
```

## License

MIT.

---
*Auto-generated from `action.yml` by [`_gen-docs.py`](../_gen-docs.py).
Do not hand-edit; modify the source files or regenerate.*
