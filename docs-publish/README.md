# pleme-io · docs-publish

> Polymorphic doc generation + deploy to GitHub Pages. Detects repo type + routes to cargo doc / mkdocs / typedoc. The third compounding leg of the publish-side primitives (release + sbom + docs).

**Category**: `docs` — 📚 Documentation generation + publishing
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/docs-publish@v1
    with:
      force-tool: ""
      target-branch: "gh-pages"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `force-tool` | no | `` | Override auto-detect: cargo-doc | mkdocs | typedoc | none |
| `target-branch` | no | `gh-pages` | Branch to deploy to (gh-pages by default) |

## Outputs

| Name | Description |
|---|---|
| `deployed` | 'true' when docs landed on the target branch, 'false' otherwise |
| `tool` | Which doc tool ran (cargo-doc / mkdocs / typedoc / none) |

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

## Related primitives — `docs` category

[`api-spec-diff`](../api-spec-diff/) · [`changelog-generate`](../changelog-generate/) · [`docusaurus-build`](../docusaurus-build/) · [`hugo-build`](../hugo-build/) · [`mdbook-build`](../mdbook-build/) · [`mkdocs-build`](../mkdocs-build/) · [`toc-update`](../toc-update/) · [`vitepress-build`](../vitepress-build/)

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
