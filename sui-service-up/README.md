# pleme-io · sui-service-up

> Resolve, health-check, and export the sui service (`sui-daemon-graph`) endpoint + selected store/cache/sandbox tiers for a super-cache-ci build.

**Category**: `super-cache-ci` — the default CI-authoring vocabulary for the sui-service stack
**Backend**: tatara-lisp (`run.tlisp` + `_tlisp-stdlib`)
**Doctrine**: [`theory/SUPER-CACHE-CI.md`](https://github.com/pleme-io/theory/blob/main/SUPER-CACHE-CI.md)

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - id: sui
    uses: pleme-io/actions/sui-service-up@v1
    with:
      mode: connect            # postgres/redis/tmpfs profile (never-touch-disk)
      require-up: "true"
  # thread steps.sui.outputs.endpoint into super-cache-restore/build/save
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `mode` | no | `ephemeral` | `connect` \| `ephemeral` — picks the default backend profile. `ephemeral` ⇒ graphstore/local/disk (now(disk)); `connect` ⇒ postgres/redis/tmpfs (never-touch-disk destination). |
| `endpoint` | no | `""` | UDS path (default `$XDG_RUNTIME_DIR/sui-graph.sock`) or a `host:port` `.svc`. |
| `store-backend` | no | `""` | Override the durable store tier (postgres \| graphstore \| local). |
| `cache-backend` | no | `""` | Override the hot cache tier (redis \| local \| s3). |
| `sandbox` | no | `""` | Override the build sandbox (tmpfs \| disk). |
| `require-up` | no | `"false"` | Fail the step when the endpoint can't be confirmed reachable. |

## Outputs

| Name | Description |
|---|---|
| `endpoint` | The resolved service endpoint. |
| `store-backend` / `cache-backend` / `sandbox` | The selected tiers. |
| `never-touch-disk` | Computed predicate: `true` only when postgres ∧ redis ∧ tmpfs. |
| `up` | `true` if the endpoint was confirmed reachable. |
| `reason` | `ok` \| `endpoint-not-reachable` \| `tcp-liveness-livetodo`. |

## Status — tier-honest

This verb does **not** own daemon lifecycle; the daemon is an external service (a rio cluster app or a job-scoped sidecar). It resolves config, health-checks the endpoint, and exports the backend profile.

- **now**: config resolution, the `never-touch-disk` structural predicate, endpoint export, and UDS-existence health-check.
- **LiveTODO** (SUPER-CACHE-CI.md rows 4/5/7): a live `connect` to a Postgres/Redis daemon and TCP `.svc:port` liveness — `PgStore`/`RedisBackend` are unwritten and `sui-daemon-client` is a library, not a ping CLI. `mode: connect` logs a `pending-super-cache-ci` note; `require-up: true` against an unconfirmable endpoint fails loud rather than faking green.

## Architecture

Composite action; logic is typed Lisp in [`run.tlisp`](./run.tlisp), one `tatara-script` invocation. No bash beyond the loader glue (★★ NO-SHELL). `_tlisp-stdlib`'s `supercache:` helpers back the resolution + health-check.

## License

MIT.
