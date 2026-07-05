# pleme-io · super-cache-restore

> Probe the tiered super-cache (Redis L1 → Postgres L2 → object L3) for a build's outputs and report the hit + tier — the warm path.

**Category**: `super-cache-ci`
**Backend**: tatara-lisp (`run.tlisp` + `_tlisp-stdlib`)
**Doctrine**: [`theory/SUPER-CACHE-CI.md`](https://github.com/pleme-io/theory/blob/main/SUPER-CACHE-CI.md) §II.3

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - id: spec
    uses: pleme-io/actions/gen-build-spec@v1
  - id: restore
    uses: pleme-io/actions/super-cache-restore@v1
    with:
      endpoint:  ${{ steps.sui.outputs.endpoint }}
      spec-path: ${{ steps.spec.outputs.spec-path }}
  # steps.restore.outputs.cache-hit gates the derive in super-cache-build
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `endpoint` | no | `""` | The sui service endpoint (for the Redis/Pg tier query — LiveTODO). |
| `key` | no | `""` | Content-addressed key. Empty ⇒ computed as sha256 over `spec-path`. |
| `spec-path` | no | `""` | Typed build-spec used to compute the key. |
| `tiers` | no | `redis,pg,object` | Tiers to consult (informational today). |
| `cache-dir` | no | `""` | Directory backing the local content-addressed object tier (the now-path). |

## Outputs

| Name | Description |
|---|---|
| `cache-hit` | `true` if a tier resolved the key. A cold-cache miss is not a failure. |
| `hit-tier` | `redis` \| `pg` \| `object` \| `miss`. |
| `key` | The resolved content-addressed key (thread into build/save). |
| `outputs` | The restored output list on a hit (empty on a miss). |

## Status — tier-honest

- **now**: content-key computation + a local content-addressed object tier (`<cache-dir>/<key>.entry`, the same shape `super-cache-save` writes) + an honest miss for everything else.
- **LiveTODO** (rows 4/5/6): the Redis L1 / Postgres L2 tiers queried via the sui service, behind sui's shipped `StorageBackend` / `Store` traits. A local miss with an endpoint set logs a `pending-super-cache-ci` note — never a faked hit.

## Architecture

Composite action; typed Lisp in [`run.tlisp`](./run.tlisp), one `tatara-script` invocation, `_tlisp-stdlib` `supercache:` helpers. No bash beyond the loader glue (★★ NO-SHELL).

## License

MIT.
