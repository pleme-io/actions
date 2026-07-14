# gen-build-spec

Emit the typed `*.build-spec.json` for a repo via `gen build .` and enforce the
**GEN-TYPED-SPEC-CONTRACT** stale gate. Step 3 of the super-cache-ci reference
pipeline — it produces the `spec-path` + `spec-hash` that the tiered
`super-cache-{restore,build,save}` verbs key on.

```yaml
- id: spec
  uses: pleme-io/actions/gen-build-spec@v1
  with:
    lang: auto            # cargo | npm | pip | gomod (auto = manifest precedence)
    ci-stale-check: true  # a drifted committed spec FAILS the job
```

## Outputs

| output | meaning |
|---|---|
| `lang` | resolved language (`cargo` \| `npm` \| `pip` \| `gomod` \| `unknown`) |
| `spec-path` | typed build-spec path, e.g. `Cargo.build-spec.json` |
| `spec-hash` | sha256 content-address = the downstream super-cache `key` |
| `regenerated` | `true` iff a real `gen build .` ran |
| `stale` / `changed` | `true` \| `false` \| `unknown` — did the committed spec drift |
| `reason` | `ok` \| `stale-spec` \| `lang-livetodo` \| `gen-absent-livetodo` \| … |

## Tier-honesty

- **`lang=cargo` is the NOW path** — `gen-cargo` is conquered (SUPER-CACHE-CI.md
  ledger row 9), so a real `gen build .` runs and the stale gate is enforced.
- **`lang ∈ {npm,pip,gomod}` is a LiveTODO** (ledger row 10) — adapters
  scaffolded, interpreters designed. Reported `regenerated=false reason=lang-livetodo`,
  never faked.
- **`gen` must be on PATH.** This action does NOT install it — the camelot
  arc-runner bakes `gen`; a hosted-runner consumer adds a gen-install step first.
  `gen` absent ⇒ an honest `gen-absent-livetodo` report (`exec-capture` raises on
  an absent binary, so `gen` is probed via a no-shell PATH scan first), unless
  `require-gen=true` (then a hard exit 1 — no faked green).
- **`spec-hash` is sha256 today** (equals the client cache `key`); the daemon's
  BLAKE3 store address is authoritative for store-level dedup. A BLAKE3
  `spec-hash` is a LiveTODO once a b3sum client helper lands.

Pure decision helpers (`gbs:lang-from-flags`, `gbs:spec-path-for`, `gbs:stale?`,
`gbs:on-path?`) are unit-tested in `run.test.tlisp` via `tatara-script --test`.
