# pleme-io · cartorio-attest

> The FedRAMP **three-pillar** compliance receipt for a delivered image digest:
> (1) a **BLAKE3 chain-linked** receipt, (2) an **SBOM from Nix inputs** (CycloneDX
> derived from the Nix runtime closure), (3) **SLSA v1.0 provenance**.

Part of the **super-cache-ci** attest leg. Consumes the multi-arch index digest
from `manifest-list-join` (and, optionally, the built image's Nix store path for
the closure SBOM).

## Sibling of `tameshi-attest` — not a duplicate

| | `tameshi-attest` | `cartorio-attest` |
|---|---|---|
| Role | the **build** receipt | the **delivery / compliance** receipt |
| Subject | spec-hash · output-hashes · cache-tier · timings | image **digest** → SBOM + SLSA |
| Pillars | BLAKE3 receipt | BLAKE3 receipt **+ Nix-closure SBOM + SLSA provenance** |
| Chain | root of the build receipt | `chain.prev` links delivery → build |

The BLAKE3 content-addressing core is **shared** (promoted to `_tlisp-stdlib`
`hash:*`, consumed by both). cartorio **adds** the two pillars tameshi lacks —
Operating-Principle #1 (extend/compose the near-miss, never fork). It realizes the
compliant-artifact-provability decomposition (cartorio/lacre/provas/tabeliao) for
the private-Zot akeyless images.

- The SBOM is **Nix-closure-native** (`nix path-info -r` → the exact derivation
  inputs) — distinct from the syft-based `sbom-generate`/`image-scan` filesystem
  re-scan.
- The SLSA is a **deterministic typed predicate** (jq) — distinct from
  `slsa-attest`'s witness/OSS-binary flow.

```yaml
- uses: pleme-io/actions/cartorio-attest@v1
  id: cartorio
  with:
    subject: akeyless-auth
    image-ref: ${{ steps.index.outputs.index-ref }}
    image-digest: ${{ steps.index.outputs.index-digest }}
    nix-store-path: ${{ steps.image.outputs.tarball-amd64 }}   # the Nix-closure SBOM source
    prev-receipt-hash: ${{ steps.tameshi.outputs.receipt-hash }} # chain delivery → build
```

## Outputs

| Name | Meaning |
|---|---|
| `attested` | `true` iff the receipt assembled + hashed |
| `receipt-path` / `receipt-hash` / `receipt-algo` | the receipt JSON + its BLAKE3 content-address (`blake3`) |
| `sbom-path` / `sbom-format` / `sbom-components` | CycloneDX-1.5 SBOM + component count |
| `slsa-path` / `slsa-predicate-type` | SLSA provenance predicate + type |
| `signed` / `outcome-chain` | LiveTODO flags (false today) |
| `reason` | `attested` \| `jq-*-fail` \| `no-blake3-tool` |

## Tier-honesty

- **SHIPPABLE-NOW** — the BLAKE3 receipt + chain link, the SLSA v1.0 provenance
  predicate, and the Nix-closure SBOM **given a `nix-store-path`** are real today.
  All JSON is emitted by jq (TYPED EMISSION); `receipt_hash` is a real b3sum
  (on-PATH, else `nix run nixpkgs#b3sum`) — the action **fails rather than lie**
  about its algorithm.
- **LiveTODOs (honest, never faked):**
  - SBOM from a registry **digest alone** (no store path) → an honest **empty**
    SBOM (`sbom-components=0`, a loud warning). *[registry-attached SBOM / OCI
    referrers API]*
  - **DSSE/cosign signing** → `signed=false`. *[cofre SecretRef + cosign attach]*
  - **kensa OutcomeChain append** → `outcome-chain=false`. *[kensa append]*

## Verification

`tests/test.yml` builds a real Nix store path, derives the three pillars over its
closure, asserts each pillar's shape + the chain link, and independently
reproduces the receipt's BLAKE3 hash.
