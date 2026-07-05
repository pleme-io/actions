# pleme-io · tameshi-attest

> Assemble + BLAKE3-hash a typed super-cache-ci build receipt (spec-hash +
> output-hashes + cache tier + timings + image digests) into a
> content-addressed, independently-verifiable JSON.

**Category**: `super-cache-ci` — 🛡️ camelot breathable CI
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.x` tags or floating `@v1` / `@main`

This is the **final verb** of the super-cache-ci action vocabulary. It takes the
typed outputs of the earlier verbs and emits one receipt whose
`attestation.receipt_hash` is a **real BLAKE3** over the canonicalized body — a
transferable proof that this build ran with these inputs, hit this cache tier,
and produced these outputs.

## 30-second quickstart

```yaml
steps:
  # ... super-cache-ci build steps produce these outputs ...
  - id: attest
    uses: pleme-io/actions/tameshi-attest@v1
    with:
      spec-hash:     ${{ steps.spec.outputs.spec-hash }}
      output-hashes: ${{ steps.build.outputs.output-hashes }}
      cache-hit:     ${{ steps.restore.outputs.cache-hit }}
      hit-tier:      ${{ steps.restore.outputs.hit-tier }}
      eval-ms:       ${{ steps.build.outputs.eval-ms }}
      build-ms:      ${{ steps.build.outputs.build-ms }}
```

## Requirement — a BLAKE3 provider

The receipt hash is a **real** BLAKE3, resolved as: `b3sum` on PATH (baked into
every super-cache-ci runner), else `nix run nixpkgs#b3sum` (the nix-native
fleet fallback). If neither exists the action **fails** rather than emit a
receipt that lies about its algorithm.

## The receipt (canonical, sorted keys)

```json
{
  "schema": "pleme-io.super-cache-ci.receipt/v1",
  "subject": "<repo-or-service>",
  "git": { "sha": "…", "ref": "…" },
  "run": { "id": "…", "number": "…", "workflow": "…" },
  "timestamp": "<UTC ISO-8601>",
  "build_spec": { "hash": "<blake3>" },
  "outputs": { "hashes": ["<blake3>", …] },
  "cache": { "hit": true, "tier": "redis" },
  "timings_ms": { "eval": 120, "build": null },
  "images": ["sha256:…"],
  "attestation": {
    "hash_algorithm": "blake3",
    "receipt_hash": "<blake3 over the body with receipt_hash=\"\">",
    "signed": false,
    "signature": null,
    "outcome_chain": false
  }
}
```

**Verify** a receipt independently:

```bash
printf '%s' "$(jq -S -c '.attestation.receipt_hash = ""' receipt.json)" \
  | b3sum   # -> must equal .attestation.receipt_hash
```

The JSON is built by `jq` (the typed serializer) — never string-concatenation
(★★ TYPED EMISSION).

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `subject` | no | `$GITHUB_REPOSITORY` | The artifact / service attested |
| `spec-hash` | no | `""` | Build-spec BLAKE3 (from gen-build-spec) |
| `output-hashes` | no | `""` | Space/comma BLAKE3 list (from super-cache-build) |
| `cache-hit` | no | `false` | Served from the super-cache (from super-cache-restore) |
| `hit-tier` | no | `miss` | `miss` \| `redis` \| `pg` \| `object` |
| `eval-ms` | no | `""` | Eval ms (empty ⇒ null) |
| `build-ms` | no | `""` | Build ms (empty ⇒ null) |
| `image-digests` | no | `""` | Space/comma OCI digests (from ghcr-publish) |
| `receipt-path` | no | `tameshi-receipt.json` | Where to write the receipt |
| `sign` | no | `false` | Request Ed25519 signing — **LiveTODO** |
| `emit-outcome-chain` | no | `false` | Request a kensa OutcomeChain append — **LiveTODO** |

## Outputs

| Name | Description |
|---|---|
| `attested` | true when the receipt was assembled + hashed |
| `receipt-path` | Path of the written receipt JSON |
| `receipt-hash` | The BLAKE3 receipt hash (content address) |
| `receipt-algo` | `blake3` |
| `signed` | Whether the receipt is Ed25519-signed (false until the LiveTODO ships) |
| `outcome-chain` | Whether appended to a kensa OutcomeChain (false until the LiveTODO ships) |

## Tier-honest status (never rounded up)

- **Shipped now**: assemble the typed receipt + a real, independently
  reproducible BLAKE3 hash. Proven green + re-verified by
  [`tests/test.yml`](./tests/test.yml).
- **LiveTODO — signing**: `sign=true` warns loudly and still emits an honest
  receipt with `attestation.signed=false`. Destination: a cofre `SecretRef` key
  + a detached Ed25519 signature.
- **LiveTODO — OutcomeChain**: `emit-outcome-chain=true` warns and sets
  `attestation.outcome_chain=false`. Destination: append the receipt hash to the
  kensa OutcomeChain (the continuously-attested-theorem half of the Viggy
  promessa).
- **LiveTODO — output forwarding**: the outputs are declared here + in
  `tatara-script/action.yml`, but a composite forwards only DECLARED keys and
  the published `tatara-script@v1` tag carries them only after its next
  re-release. The receipt **file** (written at `receipt-path`) is the durable,
  verifiable artifact and does not depend on the forward — that is what the
  smoke reads.

## Typed Action-domain catalog entry

```lisp
(defaction "tameshi-attest"
  :description "Assemble + BLAKE3-hash a typed super-cache-ci build receipt."
  :inputs  ((:name "subject"            :type :string :default "")
            (:name "spec-hash"          :type :string :default "")
            (:name "output-hashes"      :type :string :default "")
            (:name "cache-hit"          :type :bool   :default "false")
            (:name "hit-tier"           :type (:enum "miss" "redis" "pg" "object") :default "miss")
            (:name "eval-ms"            :type :string :default "")
            (:name "build-ms"           :type :string :default "")
            (:name "image-digests"      :type :string :default "")
            (:name "receipt-path"       :type :string :default "tameshi-receipt.json")
            (:name "sign"               :type :bool   :default "false")
            (:name "emit-outcome-chain" :type :bool   :default "false"))
  :outputs ((:name "attested") (:name "receipt-path") (:name "receipt-hash")
            (:name "receipt-algo") (:name "signed") (:name "outcome-chain"))
  :behavior      (:tatara-script "tameshi-attest/run.tlisp")
  :semver-compat :minor
  :attestation   :self)
```

## Architecture

Composite GitHub Action. Logic lives in [`run.tlisp`](./run.tlisp) (pure
normalization helpers + a BLAKE3 resolver + a gated `main` that drives jq);
[`action.yml`](./action.yml) loads the shared `_tlisp-stdlib` and runs one
`tatara-script` invocation. Per the ★★ NO-SHELL directive there is no bash
beyond the stdlib loader. Unit tests: [`run.test.tlisp`](./run.test.tlisp)
(4 `deftest` forms).
