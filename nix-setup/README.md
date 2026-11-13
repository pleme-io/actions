# pleme-io · nix-setup

> >-

**Category**: `nix` — ❄️ Nix — build / cache push
**Backend**: shell
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/nix-setup@v1
    with:
      cache: ""
      cache-probe-timeout: ""
      extra-conf: ""
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `cache` | no | `` | auto (default): add the fleet sui cache (SUI_CACHE_URL, or `substituters`) as an extra substituter only when its /nix-cache-info answers within cache-probe-timeout; a cache that does not answer is a one-line notice. on: add it without a probe. off: leave nix.conf on cache.nixos.org alone. true and false read as auto and off. Empty takes the workflow environment SUI_CACHE, then auto. |
| `cache-probe-timeout` | no | `` | Whole seconds the cache probe may take. Empty takes the workflow environment SUI_CACHE_PROBE_TIMEOUT, then 2. |
| `extra-conf` | no | `` | >- |
| `github-token` | no | `` | >- |
| `nextest` | no | `false` | >- |
| `substituters` | no | `` | >- |
| `trusted-public-keys` | no | `` | Keys the cache signs with. Empty means the fleet sui origin and the CI uploader. |

## Outputs

| Name | Description |
|---|---|
| `cache` | The cache URL added as a substituter, or empty when none was (off, unset, or it did not answer). |
| `nextest-bin` | >- |

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

## Related primitives — `nix` category

[`nix-attic-push`](../nix-attic-push/) · [`nix-build`](../nix-build/) · [`nix-cachix-push`](../nix-cachix-push/) · [`nix-image`](../nix-image/) · [`nix-node-matrix`](../nix-node-matrix/) · [`nix-tool`](../nix-tool/)

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
