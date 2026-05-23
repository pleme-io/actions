# pleme-io · gh-release-create

> Create a GitHub Release for a tag with optional auto-generated notes + asset uploads. Universal primitive — any language, any package shape.

**Category**: `gh` — 🐙 GitHub API
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/gh-release-create@v1
    with:
      assets: ""
      draft: "false"
      if-exists: "skip"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `assets` | no | `` | Space-separated paths to upload as release assets |
| `draft` | no | `false` | Create as draft |
| `if-exists` | no | `skip` | skip | update | fail when the release already exists |
| `notes` | no | `` | Release notes body (markdown). When empty, gh's --generate-notes is used. |
| `prerelease` | no | `false` | Mark as prerelease |
| `tag` | no | `` | Tag name to release (e.g. v0.1.4). Defaults to the current ref. |
| `title` | no | `` | Release title. Defaults to the tag name. |

## Outputs

| Name | Description |
|---|---|
| `created` | 'true' if a new release was created, 'false' if skipped/updated |
| `release-url` | URL of the created (or existing) release |

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

## Related primitives — `gh` category

[`derive-version-from-tag`](../derive-version-from-tag/)

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
