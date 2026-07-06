# pleme-io · sui-warm-hydrate

**GRAPH-job warm verb.** Pre-load the sui daemon's tiered super-cache
(Redis L1 → Postgres L2 → object L3) with the fan-out's content keys
**before** the build matrix explodes, so every parallel build job starts
warm. Part of the default CI-authoring vocabulary for the sui-service
super-cache stack — canonical doctrine:
[`theory/SUPER-CACHE-CI.md`](https://github.com/pleme-io/theory/blob/main/SUPER-CACHE-CI.md).

## Where it sits in the pipeline

```
gen-build-spec      → SPEC_PATHS (typed *.build-spec.json, one per service)
  → build-matrix    → the image × arch fan-out
    → sui-warm-hydrate  ← YOU ARE HERE (warm the daemon for every fan-out key)
      → [build job fan-out] → super-cache-restore hits warm
```

## Usage

```yaml
- id: warm
  uses: pleme-io/actions/sui-warm-hydrate@v1
  with:
    endpoint:   ${{ steps.sui.outputs.endpoint }}
    spec-paths: Cargo.build-spec.json,uam.build-spec.json,gator.build-spec.json
    store-backend: ${{ steps.sui.outputs.store-backend }}
    cache-backend: ${{ steps.sui.outputs.cache-backend }}
    sandbox:       ${{ steps.sui.outputs.sandbox }}
```

## Inputs

| Input | Default | Meaning |
|---|---|---|
| `endpoint` | `""` | sui daemon endpoint (from sui-service-up); resolved when empty |
| `spec-paths` | `""` | Comma-separated typed build-spec paths; each is sha256-content-keyed |
| `keys` | `""` | Comma-separated explicit content keys; wins over `spec-paths` |
| `tiers` | `redis,pg,object` | Which tiers to warm (reported honestly) |
| `store-backend` | `graphstore` | `postgres`\|`graphstore`\|`local` — feeds `never-touch-disk` |
| `cache-backend` | `local` | `redis`\|`local`\|`s3` — feeds `never-touch-disk` |
| `sandbox` | `tmpfs` | `tmpfs`\|`disk` — feeds `never-touch-disk` |
| `require-warm` | `false` | `true` makes a store-absent degrade a hard failure (exit 1) instead of an honest exit-2 no-op |

## Outputs

`warmed` · `warm-count` · `hit-tier` · `never-touch-disk` · `reason`
(`no-keys`\|`store-absent-degraded`\|`endpoint-unreachable-degraded`\|`warmed`).

## Exit codes (the keyway three-code contract)

- **0** — warmed, OR nothing to warm (`no-keys`).
- **2** — a clean typed **"no"**: the store-absent / endpoint-unreachable
  degrade under `require-warm=false`. Distinct from a crash — branch on it
  in YAML (`continue-on-error` / `if:`).
- **1** — the same degrade under `require-warm=true` (a loud, honest
  failure — never a faked warm).

## Tier-honesty · DEGRADED-UNTIL-STORE

- **Shipped + unit-tested** (`run.test.tlisp`): the whole pure decision
  surface — key resolution/counting, `swh:can-warm?`, the `swh:reason`
  discriminant, and the `swh:exit-code` contract, exercised across the
  full `(tiered-shipped? × endpoint-alive? × requested-count ×
  require-warm)` matrix (including the destination `warmed` branch, so a
  keystone flip is already proven green).
- **LiveTODO at the action layer** — the actual warm: a daemon *warm-set
  RPC* pre-loading Redis L1 / Postgres L2 for the requested keys. There is
  **no shipped warm-set RPC** (`sui-daemon-client` is a *library*, not a
  binary) and the tiered backend (`TieredBackend =
  RedisBackend(L1)→PgStore(L2)→S3Storage(L3)` behind sui's **shipped**
  `Store`/`StorageBackend` traits) is unwritten. The keystone is the
  single constant `swh:tiered-warm-shipped? = #f`; flip it to `#t` when
  both ship and this verb lights up with **zero** other change. Default
  (`require-warm=false`) reports the honest degrade — `warmed=false`,
  `warm-count=0`, a `pending-super-cache-ci` log — and **never a faked
  warm**; `require-warm=true` fails loud.
- **Coordination LiveTODO** — this action's `warmed`/`warm-count` outputs
  are added to the shared `pleme-io/actions/tatara-script@v1`
  output-forward set (a composite forwards only declared keys); and its
  `defaction.lisp` folds into the suite catalog + arch-synthesizer's
  `Action` domain (which needs a `TataraScript` behavior variant — the
  suite-wide shared LiveTODO).

## Idiom

`run.tlisp` (tatara-lisp over `_tlisp-stdlib/stdlib.tlisp`) → the
`pleme-io/actions/tatara-script@v1` runner. No bash beyond the stdlib
loader. `defaction.lisp` is the typed authoring surface. `run.test.tlisp`
is the gated matrix (repo `tlisp-tests` job); `tests/test.yml` is a
co-located reference smoke.
