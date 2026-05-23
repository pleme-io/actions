# pleme-io · changelog-generate

> Generate a CHANGELOG.md (or fragment) from git log since a base ref. Universal primitive — language-agnostic, used by every release flow that wants typed changelogs.

**Category**: `docs` — 📚 Documentation generation + publishing
**Backend**: tatara-lisp (run.tlisp) wrapping CLI tools via `exec-capture`
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/changelog-generate@v1
    with:
      base-ref: ""
      format: "markdown"
      output-file: ""
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `base-ref` | no | `` | Base ref to diff from (e.g. previous tag). Empty means: use git describe --tags --abbrev=0 to auto-detect. |
| `format` | no | `markdown` | markdown | keepachangelog | conventional |
| `output-file` | no | `` | Path to write the generated changelog. Empty means: only emit to outputs (no file write). |
| `fragment` | no | `false` | If true, emit only the new section (don't prepend to an existing file) |

## Outputs

| Name | Description |
|---|---|
| `changelog` | Generated changelog content (as a multi-line string) |
| `commit-count` | Number of commits between base-ref and HEAD |

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

## Related primitives — `docs` category

[`api-spec-diff`](../api-spec-diff/) · [`docs-publish`](../docs-publish/) · [`docusaurus-build`](../docusaurus-build/) · [`hugo-build`](../hugo-build/) · [`mdbook-build`](../mdbook-build/) · [`mkdocs-build`](../mkdocs-build/) · [`toc-update`](../toc-update/) · [`vitepress-build`](../vitepress-build/)


## Sources

- **Action source**: [`action.yml`](./action.yml) + [`run.tlisp`](./run.tlisp)
- **Catalog entry**: `substrate.lib.release.patterns.docs.changelog-generate` —
  [patterns-full.nix](https://github.com/pleme-io/substrate/blob/main/lib/release/patterns-full.nix)
- **Future typed source**: `(defaction changelog-generate ...)` per
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
nix eval --raw github:pleme-io/substrate#lib.aarch64-darwin.release.patterns.docs.changelog-generate
```

## License

MIT.

---
*Auto-generated from `action.yml` by [`_gen-docs.py`](../_gen-docs.py).
Do not hand-edit; modify the source files or regenerate.*
