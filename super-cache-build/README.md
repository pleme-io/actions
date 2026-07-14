# pleme-io · super-cache-build

**THE CORE super-cache-ci verb.** Build a derivation via the sui service
against the tiered super-cache (RAM eval → tmpfs sandbox → DB store),
keyed by the gen build-spec. Skips the derive entirely on a restore cache
hit. Part of the default CI-authoring vocabulary for the sui-service
super-cache stack — canonical doctrine:
[`theory/SUPER-CACHE-CI.md`](https://github.com/pleme-io/theory/blob/main/SUPER-CACHE-CI.md).

## Where it sits in the pipeline

```
sui-service-up        → ENDPOINT + store/cache/sandbox profile
  → gen-build-spec    → SPEC_PATH (typed *.build-spec.json)
    → super-cache-restore → KEY + cache-hit + restored-outputs
      → super-cache-build  ← YOU ARE HERE (derive on a miss; skip on a hit)
        → super-cache-save → persist the outputs to the durable tiers
```

## Usage

```yaml
- id: build
  uses: pleme-io/actions/super-cache-build@v1
  with:
    endpoint:  ${{ steps.sui.outputs.endpoint }}
    spec-path: ${{ steps.spec.outputs.spec-path }}
    key:       ${{ steps.restore.outputs.key }}
    cache-hit: ${{ steps.restore.outputs.cache-hit }}
    restored-outputs: ${{ steps.restore.outputs.outputs }}
    sandbox:   ${{ steps.sui.outputs.sandbox }}
    store-backend: ${{ steps.sui.outputs.store-backend }}
    cache-backend: ${{ steps.sui.outputs.cache-backend }}
```

## Inputs

| Input | Default | Meaning |
|---|---|---|
| `spec-path` | `""` | Typed gen build-spec; derives the key when `key` is empty |
| `key` | `""` | Content-addressed cache key (from super-cache-restore) |
| `cache-hit` | `false` | `true` short-circuits the derive |
| `restored-outputs` | `""` | Store paths restore already warmed (echoed on a hit) |
| `force` | `false` | Re-derive even on a hit |
| `endpoint` | `""` | sui daemon endpoint (from sui-service-up) |
| `sandbox` | `tmpfs` | `tmpfs`\|`disk` — the never-touch-disk path is `tmpfs` |
| `store-backend` | `graphstore` | `postgres`\|`graphstore`\|`local` |
| `cache-backend` | `local` | `redis`\|`local`\|`s3` |
| `require-build` | `false` | `true` makes a derive-LiveTODO a hard failure instead of an honest `built=false` |

## Outputs

`built` · `from-cache` · `outputs` · `output-hashes` · `eval-ms` · `build-ms`
· `key` · `never-touch-disk` · `reason` (`cache-hit`\|`derive-livetodo`).

## Tier-honesty

- **Shipped + unit-tested** (`run.test.tlisp`): the pure derive decision
  (`scb:outcome` — a restore HIT short-circuits, `force` overrides, a miss
  derives) and the cache-hit short-circuit path (emit `from-cache`, touch
  nothing).
- **LiveTODO at the action layer**: the actual derive (feed the build-spec
  to the daemon → RAM eval → sandbox → store). There is **no shipped
  sui-graph build CLI/RPC** — `sui-daemon-client` is a *library*, not a
  binary — matching `sui-service-up`'s honesty. Default
  (`require-build=false`) reports `built=false` + a
  `pending-super-cache-ci` log; `require-build=true` fails loud. **Never a
  faked green.** The never-touch-disk destination (tmpfs + Pg + Redis) is
  ledger rows 4/5/7.
- **Coordination LiveTODO**: this action's non-`built` outputs must be
  added to the shared `pleme-io/actions/tatara-script@v1` output-forward
  set before a consumer can read them; and its `defaction.lisp` folds into
  the suite catalog + arch-synthesizer's `Action` domain (which needs a
  `TataraScript` behavior variant).

## Idiom

`run.tlisp` (tatara-lisp over `_tlisp-stdlib/stdlib.tlisp`) → the
`pleme-io/actions/tatara-script@v1` runner. No bash beyond the stdlib
loader. `defaction.lisp` is the typed authoring surface. `run.test.tlisp`
is the gated smoke (repo `tlisp-tests` job); `tests/test.yml` is a
co-located reference smoke.
