# pleme-io · tlisp-lint

> Validate every *.tlisp file under the repo: balanced parens, balanced strings, balanced comments, and (when tatara-script is installed) a parser-level dry-run. Catches the parse-error class of bug at PR time instead of after-tag.

**Category**: `validation` — 🚦 Validation — per-language gates + universal lints
**Backend**: tatara-lisp (run.tlisp) wrapping CLI tools via `exec-capture`
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/tlisp-lint@v1
    with:
      paths: "**/*.tlisp"
      fail-on-unbalanced: "true"
      run-parser-check: "true"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `paths` | no | `**/*.tlisp` | Space-separated globs to lint. Default scans every *.tlisp in the repo. |
| `fail-on-unbalanced` | no | `true` | Exit non-zero on any unbalanced paren/string/comment (default true). Set false to log warnings only. |
| `run-parser-check` | no | `true` | Also invoke tatara-script's parser via a no-op preamble to catch parser-level errors that pass a pure paren count. Default true. |

## Outputs

| Name | Description |
|---|---|
| `files-scanned` | Number of .tlisp files scanned |
| `errors-found` | Number of files with errors |

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

## Related primitives — `validation` category

[`nix-flake-check`](../nix-flake-check/) · [`npm-gate`](../npm-gate/) · [`python-gate`](../python-gate/) · [`rust-gate`](../rust-gate/) · [`typecheck-gate`](../typecheck-gate/)


## Sources

- **Action source**: [`action.yml`](./action.yml) + [`run.tlisp`](./run.tlisp)
- **Catalog entry**: `substrate.lib.release.patterns.validation.tlisp-lint` —
  [patterns-full.nix](https://github.com/pleme-io/substrate/blob/main/lib/release/patterns-full.nix)
- **Future typed source**: `(defaction tlisp-lint ...)` per
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
nix eval --raw github:pleme-io/substrate#lib.aarch64-darwin.release.patterns.validation.tlisp-lint
```

## License

MIT.

---
*Auto-generated from `action.yml` by [`_gen-docs.py`](../_gen-docs.py).
Do not hand-edit; modify the source files or regenerate.*
