# pleme-io · nix-build

> Build a flake output (universal). With cache-push, pushes what it built to the fleet sui cache when a short probe finds the cache up; a cache that is down, slow or failing is a notice or a warning, never a held or failed build.

**Category**: `nix` — ❄️ Nix — build / cache push
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/nix-build@v1
    with:
      cache: ""
      cache-probe-timeout: ""
      cache-push: ""
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `cache` | no | `` | auto (default), on or off: whether the fleet cache is probed and used at all (see sui-cache-probe). off also stops the push. Empty takes the workflow environment SUI_CACHE, then auto. |
| `cache-probe-timeout` | no | `` | Whole seconds the cache probe may take. Empty takes SUI_CACHE_PROBE_TIMEOUT, then 2. |
| `cache-push` | no | `` | auto (default): when the runner exports SUI_CACHE_URL and SUI_CACHE_SIGNING_KEY_FILE (the fleet runner pools with an uploader key, nix lib/sui-cache.nix uploaders), probe that sui origin first (pleme-io/actions/sui-cache-probe, about 2 s) and, when it answers, push the outputs of every derivation this run built to it, so the next run on any fleet runner substitutes them. A cache that does not answer is a one-line notice and no push, never a held step. On a runner without them (GitHub-hosted) nothing is pushed. on: push without the probe gating it. off or false: no push. true: the older local-store push, `sui cache push --recursive` into `cache-store-path`. Empty takes the workflow environment SUI_CACHE_PUSH, then auto. |
| `cache-push-timeout` | no | `` | Whole seconds a push may run before it is stopped and reported as a warning. Empty takes SUI_CACHE_PUSH_TIMEOUT, then 1200. |
| `cache-signing-key` | no | `` | >- |
| `cache-store-path` | no | `` | >- |
| `eval-first` | no | `false` | >- |
| `eval-only` | no | `false` | >- |
| `eval-stack-kib` | no | `` | >- |
| `extra-conf` | no | `` | >- |
| `flake-ref` | no | `.#default` |  |
| `github-token` | no | `` | >- |
| `max-silent-time` | no | `` | >- |
| `plan` | no | `true` | >- |
| `system` | no | `` |  |

## Outputs

| Name | Description |
|---|---|
| `cache-push-reason` | Why cache-pushed is "false": disabled, the cache gate (down, off), sui not on PATH, no output paths, build failed, a timeout, or the push exit status and stderr. |
| `cache-pushed` | "true" when the sui cache push succeeded, otherwise "false". |
| `cache-state` | The sui-cache-probe state when the fleet push was considered: up, down, off, on, absent or unprobed; empty when no probe step ran. |
| `drv` | The evaluated derivation installable (`<drv>^*`), set by eval-only. |
| `out-path` |  |
| `will-build` | Derivations the dry-run plan said this runner must build. Empty when plan is "false" or the dry run failed. |
| `will-fetch` | Store paths the dry-run plan said this runner substitutes. Empty when plan is "false" or the dry run failed. |

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

[`nix-attic-push`](../nix-attic-push/) · [`nix-cachix-push`](../nix-cachix-push/) · [`nix-image`](../nix-image/) · [`nix-node-matrix`](../nix-node-matrix/) · [`nix-setup`](../nix-setup/) · [`nix-tool`](../nix-tool/)

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
