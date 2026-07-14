# ferrite-check

Per-package **materializability gate** of the camelot image pipeline. For one
package (a flake image attr), verify it can be **materialized** — its attr
resolves to a derivation via a cheap `nix eval`, **not** a derive — *before*
the expensive build, content-address its **source**, and emit a **PoMS**
(**Proof-of-Materialization-Spec**) receipt, **cached by that source hash** so a
re-run over unchanged source is a pure cache hit (no re-eval, no derive).

Single-responsibility **sibling** of `build-matrix` (the `(svc, arch)` fan) and
`gen-build-spec` (the build-spec freshness gate): `ferrite-check` gates **one
fan cell's materializability** and emits its proof. It sits after them and
before the paid `super-cache-build` / `nix-image` derive.

```
build-matrix ──▶ ferrite-check (per (svc,arch) cell) ──▶ super-cache-build / nix-image
                    │  miss ⇒ derive
                    │  hit  ⇒ PoMS proves it — skip the derive
```

```yaml
jobs:
  build:
    needs: graph
    strategy:
      matrix: ${{ fromJSON(needs.graph.outputs.matrix) }}   # build-matrix rows
    runs-on: [self-hosted, camelot]   # a runner that bakes nix + jq + b3sum
    steps:
      - uses: actions/checkout@v4
      - id: ferrite
        uses: pleme-io/actions/ferrite-check@v1
        with:
          flake-ref: github:akeylesslabs/akeyless-nix-images
          image-attr: dockerImage
          attr-template: "dockerImage:{arch}:{svc}"   # akeyless colon-triple
          svc: ${{ matrix.image }}                    # e.g. auth / uam / gateway
          arch: ${{ matrix.arch }}                    # e.g. amd64
          poms-dir: .poms-cache                        # by-source-hash PoMS cache
          prev-receipt-hash: ${{ steps.spec.outputs.spec-hash }}  # chain to gen-build-spec
      # Skip the derive when ferrite already proved this exact source:
      - if: steps.ferrite.outputs.cached != 'true'
        uses: pleme-io/actions/nix-image@v1
        with:
          flake-ref: github:akeylesslabs/akeyless-nix-images
          attr-template: "dockerImage:{arch}:{svc}"
          svc: ${{ matrix.image }}
          arches: ${{ matrix.arch }}
```

## Inputs

| input | default | meaning |
|---|---|---|
| `flake-ref` | `.` | flake to eval |
| `image-attr` | `dockerImage` | attr base (`{base}`) substituted into `attr-template` |
| `attr-template` | `dockerImage:{arch}:{svc}` | typed template over `{base} {arch} {svc}` — same grammar as `nix-image` (`{base}-{arch}-{svc}`, `{base}-{arch}`, `dockerImage:{arch}`) |
| `svc` | `""` | substituted for `{svc}`; **required** when the template names `{svc}` (else an ambiguous attr → exit 1) |
| `arch` | `amd64` | substituted for `{arch}`; maps to a nix system double; an unknown arch → exit 1 |
| `poms-dir` | `""` | dir holding the `<source-hash>.poms.json` cache; empty = no lookup (always fresh); committed = the by-source-hash HIT skip (write-if-absent, content-addressed, no lock) |
| `prev-receipt-hash` | `""` | prior receipt to chain to (e.g. `gen-build-spec`'s), written into `chain.prev`; empty = a chain root |
| `poms-path` | `ferrite-poms.json` | where to write the emitted PoMS |
| `require` | `true` | a NOT-materializable verdict is a hard exit 1; set false for a clean typed exit 2 |
| `sign` | `false` | exercises the honest signing LiveTODO (DSSE/cosign not shipped) |
| `emit-outcome-chain` | `false` | exercises the honest OutcomeChain LiveTODO (kensa append not shipped) |

## Outputs

| output | meaning |
|---|---|
| `materializable` | `true` iff the attr resolves to a derivation |
| `cached` | `true` iff the verdict came from a cached PoMS for this source hash (derive skippable) |
| `source-hash` | the content-addressed source/cache key (the output store-path basename) |
| `drv-path` | the resolved `.drv` store path (empty when not materializable) |
| `attr` | the resolved flake attr (template rendered over base/arch/svc) |
| `poms-path` | path to the emitted PoMS JSON |
| `poms-hash` | the real BLAKE3 receipt hash of the PoMS (independently reproducible) |
| `poms-algo` | `blake3` |
| `signed` | `false` — DSSE/cosign signing is a LiveTODO |
| `outcome-chain` | `false` — kensa OutcomeChain append is a LiveTODO |
| `reason` | `ok` \| `cached` \| `not-materializable` \| `ambiguous-attr` \| `nix-absent` \| `jq-fail` \| `no-blake3-tool` |

## The PoMS — Proof-of-Materialization-Spec

A typed, content-addressed receipt (`schema: pleme-io.ferrite.materialization-spec/v1`)
binding `(package, arch, attr, source-hash) → materializable verdict + drv_path`,
whose `attestation.receipt_hash` is a **real BLAKE3** over the canonical
(sorted, compact) body. It is a **sibling** of `tameshi-attest`'s build receipt
and `cartorio-attest`'s delivery receipt on **one chain**: it carries
`chain.prev` (so PoMS → build → deliver chains) and shares the BLAKE3 core
(`_tlisp-stdlib` `hash:*`).

```json
{
  "schema": "pleme-io.ferrite.materialization-spec/v1",
  "subject": "auth:amd64",
  "package": { "svc": "auth", "arch": "amd64", "system": "x86_64-linux", "attr": "dockerImage:amd64:auth" },
  "source": { "hash": "7p5zhw…-akeyless-auth.tar.gz", "algorithm": "nix-store-path" },
  "materialization": { "materializable": true, "drv_path": "/nix/store/…-akeyless-auth.drv" },
  "chain": { "chain_algorithm": "blake3", "prev": "<gen-build-spec hash>" },
  "attestation": { "hash_algorithm": "blake3", "receipt_hash": "<real b3sum>", "signed": false, "signature": null, "outcome_chain": false }
}
```

## Cached by source hash

The cache key is the package's **source hash** — the basename of the attr's
`.outPath` (the output store path is a content-address over every input:
source, deps, build recipe). A committed PoMS at `<poms-dir>/<source-hash>.poms.json`
means we already proved this exact source materializable ⇒ a **HIT**: the cached
PoMS is re-emitted (byte-identical, so its receipt hash is stable and
verifiable), the eval is skipped, and `cached=true` tells the caller the derive
can be skipped too. Write-if-absent, content-addressed, **no lock** (the
eliminate-the-shared-cell property — two runners over the same source produce
identical PoMS content, so a race is benign; the same discipline as
`super-cache-save`'s local object tier).

## Exit codes (keyway three-code contract)

- **0** — materializable (PoMS emitted; fresh eval OR cached hit).
- **2** — eval OK but **not** materializable AND `require=false` — a clean typed
  "no" the caller branches on in YAML.
- **1** — a loud failure: not-materializable with `require=true`, an ambiguous
  attr (`{svc}` template + empty `svc`), an unknown arch, an absent `nix`, or a
  jq / no-BLAKE3-tool failure. Never a silent pass, never a faked PoMS.

## Tier-honesty

- **SHIPPABLE-NOW.** The materializability verdict is a real `nix eval` of the
  attr's `.outPath` (RAM, seconds — never a derive); the source hash is its
  content-addressed store-path basename; the PoMS is real jq-emitted JSON with a
  real, **independently reproducible** BLAKE3 receipt hash; the by-source-hash
  cache hit/skip is a real content-addressed file tier.
- **TYPED EMISSION.** The PoMS JSON is composed by `jq` (the typed serializer),
  never hand string-concatenated — the `tameshi-attest` / `cartorio-attest`
  rule. The jq program carries no double-quotes (every literal is a `--arg`).
  If no BLAKE3 tool (`b3sum` / `nix`) exists the action **fails** rather than
  emit a receipt that lies about its algorithm.
- **What it does NOT claim.** ferrite proves **realizability** (a derivation the
  daemon *can* realize), NOT that the realized output is bit-correct — that is
  `super-cache-build`'s job + `tameshi-attest`'s receipt.
- **LiveTODOs (never rounded up).** The tiered PoMS cache (sui Redis L1 →
  Postgres L2, behind sui's shipped `Store` / `StorageBackend` traits) is a
  named LiveTODO — the local file tier is the now-path, an honest miss when
  absent, never a faked hit. DSSE/cosign **signing** (`signed=false`) and kensa
  **OutcomeChain** append (`outcome-chain=false`) are honest LiveTODO warnings.

Pure decision helpers (`ferrite:render-attr`, `ferrite:arch->system`,
`ferrite:template-uses-svc?`, `ferrite:store-basename`,
`ferrite:poms-cache-path`, `ferrite:norm-bool`) are unit-tested as a 9-case
verification matrix in `run.test.tlisp` via `tatara-script --test`.
