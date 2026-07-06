# pleme-io · sui-remote-build

**BUILD-job remote-execution verb.** Dispatch a derivation to a REAPI
(Remote Execution API) spot worker over the sui daemon (RAM eval → tmpfs
sandbox → DB store), keyed by the gen build-spec; on no worker, **fall
back to the correct local daemon-node build**. Part of the default
CI-authoring vocabulary for the sui-service super-cache stack — canonical
doctrine:
[`theory/SUPER-CACHE-CI.md`](https://github.com/pleme-io/theory/blob/main/SUPER-CACHE-CI.md).

## Where it sits in the pipeline

```
sui-service-up          → ENDPOINT + store/cache/sandbox profile
  → gen-build-spec      → SPEC_PATH (typed *.build-spec.json)
    → super-cache-restore → KEY + cache-hit
      → sui-remote-build   ← YOU ARE HERE (remote-derive on a spot worker;
      │                       local fallback on none)
        → super-cache-save → persist the outputs
          → zot-push       → private-Zot delivery
```

`sui-remote-build` vs `super-cache-build`: `super-cache-build` is the
**local** derive core (daemon-node, in-process). `sui-remote-build` is the
**remote** variant that dispatches the derive to a REAPI worker and, on no
worker, delegates to exactly that local core. Both report `built=false`
today (the derive itself is a shared LiveTODO — no sui-graph build CLI);
`sui-remote-build` additionally reports `worker` (`reapi`|`local`) so the
caller sees which execution plane ran.

## Usage

```yaml
- id: build
  uses: pleme-io/actions/sui-remote-build@v1
  with:
    endpoint:  ${{ steps.sui.outputs.endpoint }}
    spec-path: ${{ steps.spec.outputs.spec-path }}
    key:       ${{ steps.restore.outputs.key }}
    arch:      amd64
    sandbox:   ${{ steps.sui.outputs.sandbox }}
    store-backend: ${{ steps.sui.outputs.store-backend }}
    cache-backend: ${{ steps.sui.outputs.cache-backend }}
```

## Inputs

| Input | Default | Meaning |
|---|---|---|
| `endpoint` | `""` | sui daemon endpoint (from sui-service-up); resolved when empty |
| `spec-path` | `""` | Typed gen build-spec; derives the key when `key` is empty |
| `key` | `""` | Content-addressed cache key (from super-cache-restore) |
| `arch` | `amd64` | Target arch (`amd64`\|`arm64`); feeds the REAPI worker pool |
| `sandbox` | `tmpfs` | `tmpfs`\|`disk` — the never-touch-disk path is `tmpfs` |
| `store-backend` | `graphstore` | `postgres`\|`graphstore`\|`local` |
| `cache-backend` | `local` | `redis`\|`local`\|`s3` |
| `require-build` | `false` | `true` makes a local-fallback derive-LiveTODO a hard failure (exit 1) instead of an honest exit-2 `built=false` |

## Outputs

`built` · `from-cache` · `outputs` · `output-hashes` · `eval-ms` ·
`build-ms` · `worker` (`reapi`\|`local`) · `never-touch-disk` · `reason`
(`remote-built`\|`local-fallback-derive-livetodo`).

## Exit codes (the keyway three-code contract)

- **0** — remote-built on a REAPI worker (`worker=reapi`).
- **2** — a clean typed **"no"**: the local-fallback derive-LiveTODO under
  `require-build=false`. Distinct from a crash — branch on it in YAML.
- **1** — the same fallback LiveTODO under `require-build=true` (a loud,
  honest failure — never a faked build).

## Tier-honesty · DEGRADED-UNTIL-STORE

- **Shipped + unit-tested** (`run.test.tlisp`): the whole pure decision
  surface — worker selection (`srb:select-worker`), the reason
  discriminant (`srb:reason`), `srb:built?`, and the `srb:exit-code`
  contract, exercised across the full `(reapi-shipped? × endpoint-alive? ×
  require-build)` matrix (including the destination `reapi` branch, so a
  keystone flip is already proven green) plus an end-to-end pure
  composition of today's cell.
- **LiveTODO at the action layer — doubly gated**: (a) the **REAPI worker
  binary is UNWIRED** (no remote-exec worker to dispatch to); (b) the
  remote plane rides the keystone `TieredBackend =
  RedisBackend(L1)→PgStore(L2)→S3Storage(L3)` behind sui's **shipped**
  `Store`/`StorageBackend` traits, and the local fallback core's derive
  (the sui-graph build RPC/CLI) is itself a LiveTODO (`sui-daemon-client`
  is a *library*, not a binary). The keystone is the single constant
  `srb:reapi-worker-shipped? = #f`; flip it to `#t` when both ship and the
  remote branch lights up. Default (`require-build=false`) gracefully
  falls back to the local build and reports `built=false` +
  `worker=local` + a `pending-super-cache-ci` log — **never a faked
  build**; `require-build=true` fails loud.
- **Coordination LiveTODO** — this action's `worker` output is added to
  the shared `pleme-io/actions/tatara-script@v1` output-forward set (a
  composite forwards only declared keys); and its `defaction.lisp` folds
  into the suite catalog + arch-synthesizer's `Action` domain (which needs
  a `TataraScript` behavior variant — the suite-wide shared LiveTODO).

## Idiom

`run.tlisp` (tatara-lisp over `_tlisp-stdlib/stdlib.tlisp`) → the
`pleme-io/actions/tatara-script@v1` runner. No bash beyond the stdlib
loader. `defaction.lisp` is the typed authoring surface. `run.test.tlisp`
is the gated matrix (repo `tlisp-tests` job); `tests/test.yml` is a
co-located reference smoke.
