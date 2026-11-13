# pleme-io · sui-cache-push

> Push built store paths (and their closures) into a remote sui binary cache over HTTP, signed with the uploader key the origin trusts. The pleme-io cache plane is sui; this replaces nix-cachix-push and nix-attic-push. A failed push is a warning unless required is "true".

**Category**: `uncategorized` — 🔧 Uncategorized — needs a home
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/sui-cache-push@v1
    with:
      cache: ""
      cache-probe-timeout: ""
      cache-push: ""
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `cache` | no | `` | auto (default): probe the origin first and push only when it answers. on: no probe. off: no push. Workflow environment: SUI_CACHE. See sui-cache-probe. |
| `cache-probe-timeout` | no | `` | Whole seconds the probe may take. Default 2. Workflow environment: SUI_CACHE_PROBE_TIMEOUT. |
| `cache-push` | no | `` | auto (default): push when the cache is up. on: push whatever the probe says. off: never push. Workflow environment: SUI_CACHE_PUSH. |
| `cache-push-timeout` | no | `` | Whole seconds the push may run before it is stopped and reported. Default 1200. Workflow environment: SUI_CACHE_PUSH_TIMEOUT. |
| `cache-url` | no | `` | The sui origin, e.g. http://rio:5000. Empty falls back to the runner environment SUI_CACHE_URL, which the fleet runner pools export. |
| `paths` | yes | — | Store paths to push, separated by whitespace or newlines (e.g. the out-path output of nix-build). |
| `recursive` | no | `true` | Push each path''s whole closure ("true") or only the named paths. |
| `required` | no | `false` | The literal "true" fails the step when the push fails or cannot run; otherwise it is a warning. A cache that is down or switched off is a skip, never a failure. |
| `signing-key` | no | `` | The uploader secret key contents, from a secret. Written to a 0600 file under RUNNER_TEMP, removed after the push, never logged. |
| `signing-key-file` | no | `` | Path of the uploader ed25519 secret key the origin lists with --upload-key. Empty falls back to signing-key, then to the runner environment SUI_CACHE_SIGNING_KEY_FILE. |

## Outputs

| Name | Description |
|---|---|
| `cache-state` | The sui-cache-probe state: up, down, off, on, absent or unprobed. |
| `pushed` | "true" when sui cache push succeeded for every path. |
| `reason` | Why pushed is "false": no paths, no cache url, no signing key, the cache gate (down, off), sui not on PATH, a timeout, or the push exit status and stderr. |

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

## Related primitives — `uncategorized` category

[`action-pipeline`](../action-pipeline/) · [`advance-major-tag`](../advance-major-tag/) · [`airtable-record-create`](../airtable-record-create/) · [`aldrava-dispatch`](../aldrava-dispatch/) · [`aldrava-install`](../aldrava-install/) · [`aldrava-lint`](../aldrava-lint/) · [`aldrava-resolve`](../aldrava-resolve/) · [`algolia-index-push`](../algolia-index-push/)

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
