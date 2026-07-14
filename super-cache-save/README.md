# pleme-io · super-cache-save

> Persist a build's outputs to the durable super-cache tiers — write-if-absent, content-addressed, no lock.

**Category**: `super-cache-ci`
**Backend**: tatara-lisp (`run.tlisp` + `_tlisp-stdlib`)
**Doctrine**: [`theory/SUPER-CACHE-CI.md`](https://github.com/pleme-io/theory/blob/main/SUPER-CACHE-CI.md) §II.3

## 30-second quickstart

```yaml
steps:
  - id: save
    if: ${{ steps.build.outputs.built == 'true' }}
    uses: pleme-io/actions/super-cache-save@v1
    with:
      endpoint: ${{ steps.sui.outputs.endpoint }}
      key:      ${{ steps.restore.outputs.key }}
      outputs:  ${{ steps.build.outputs.outputs }}
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `endpoint` | no | `""` | The sui service endpoint (for the durable Pg/object write — LiveTODO). |
| `key` | no | `""` | Content-addressed key. Empty ⇒ computed as sha256 over `spec-path`. |
| `spec-path` | no | `""` | Typed build-spec used to compute the key. |
| `outputs` | no | `""` | Space-separated output list (store paths / files) to persist. |
| `cache-dir` | no | `""` | Directory backing the local content-addressed object tier (the now-path). |

## Outputs

| Name | Description |
|---|---|
| `saved` | `true` if the outputs were newly persisted. |
| `skipped` | `true` if the key was already present (idempotent write-if-absent skip). |
| `key` | The content-addressed key that was persisted (or skipped). |
| `tier` | `object` \| `none`. |
| `reason` | `written` \| `already-present` \| `no-key` \| `no-durable-tier` \| `write-failed`. |

## Why no lock

The write is keyed by the content address, so two runners saving the same key produce identical content — a race is benign. This is the [eliminate-the-shared-cell](https://github.com/pleme-io/theory/blob/main/UNREPRESENTABILITY.md) pattern: concurrent-runner cache coherence is free, with no lock and no coherence protocol.

## Status — tier-honest

- **now**: write-if-absent to a local content-addressed object tier (`<cache-dir>/<key>.entry`). When no cache-dir is configured, the save is an **honest no-op** (`reason=no-durable-tier`), never a faked persist.
- **LiveTODO** (rows 4/5/6): the durable Postgres L2 (index + pointer) + object L3 (NAR bytes) + warm Redis L1, behind sui's shipped `Store` / `StorageBackend` traits.

## Architecture

Composite action; typed Lisp in [`run.tlisp`](./run.tlisp), one `tatara-script` invocation, `_tlisp-stdlib` `supercache:` helpers. No bash beyond the loader glue (★★ NO-SHELL).

## License

MIT.
