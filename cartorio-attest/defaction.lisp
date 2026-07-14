;; cartorio-attest/defaction.lisp — the typed catalog entry for the
;; super-cache-ci FedRAMP COMPLIANCE-attestation verb. Field vocabulary
;; mirrors arch-synthesizer's typed `Action` domain
;; (arch-synthesizer/src/action_domain/mod.rs) and the sibling seed
;; catalog (super-cache-ci-catalog.lisp).
;;
;; ── SIBLING OF tameshi-attest, NOT a duplicate ──────────────────────
;; tameshi-attest = the BUILD receipt (spec-hash / output-hashes /
;; cache-tier / timings). cartorio-attest = the DELIVERY / COMPLIANCE
;; receipt (image digest → Nix-closure SBOM + SLSA v1.0 provenance + a
;; BLAKE3 chain link back to the build receipt via chain.prev). The
;; BLAKE3 content-addressing core is SHARED (promoted to _tlisp-stdlib
;; `hash:*`); cartorio ADDS the SBOM + SLSA pillars tameshi lacks —
;; Operating-Principle #1 (extend/compose the near-miss, never fork).
;; cartorio realizes the compliant-artifact-provability decomposition
;; (cartorio/lacre/provas/tabeliao) for the private-Zot akeyless images.
;;
;; ── TIER-HONEST placement note ──────────────────────────────────────
;; Co-located with the action (self-contained), matching the
;; tameshi-attest / super-cache-build precedent. Folding this entry into
;; the canonical repo-forge/pleme-actions-catalog + wiring it into
;; arch-synthesizer's `Action` domain proofs is a NAMED LiveTODO: these
;; are tatara-script (run.tlisp) actions and the shipped `ActionBehavior`
;; models only Rust-crate actions (rust_crate / depends / runtime_tools),
;; so admitting a tatara-script action needs a `TataraScript`
;; `ActionBehavior` variant (a Rust change, out of this coordination
;; slice). The `:behavior` clause names the tatara-script runtime + its
;; run.tlisp explicitly and is NOT claimed to parse into the shipped Rust
;; struct.

(defaction "cartorio-attest"
  :description "The FedRAMP THREE-PILLAR compliance receipt for a delivered image digest: (1) a BLAKE3 chain-linked receipt (chain.prev binds delivery to the tameshi build receipt); (2) an SBOM from Nix inputs — CycloneDX 1.5 derived from the built image's Nix runtime closure (nix path-info -r), the exact derivation inputs, NOT a filesystem re-scan; (3) SLSA v1.0 provenance (in-toto Statement) binding the digest to its build definition. Sibling of tameshi-attest (build receipt), sharing the BLAKE3 core, adding the SBOM+SLSA pillars. TYPED EMISSION: all JSON via jq; receipt_hash is a real b3sum (fails rather than lie about its algorithm). Nix-closure SBOM given a store path is SHIPPABLE-NOW; a digest-only SBOM, DSSE/cosign signing, and kensa OutcomeChain append are named LiveTODOs (honest empty SBOM / signed=false / outcome_chain=false, never faked)."
  :inputs  ((:name "subject"            :type :string :required nil :default "")
            (:name "image-ref"          :type :string :required nil :default "")
            (:name "image-digest"       :type :string :required nil :default "")
            (:name "nix-store-path"     :type :string :required nil :default "")
            (:name "prev-receipt-hash"  :type :string :required nil :default "")
            (:name "builder-id"         :type :string :required nil :default "")
            (:name "sbom-path"          :type :string :required nil :default "cartorio-sbom.cdx.json")
            (:name "slsa-path"          :type :string :required nil :default "cartorio-slsa.json")
            (:name "receipt-path"       :type :string :required nil :default "cartorio-receipt.json")
            (:name "sign"               :type :string :required nil :default "false")
            (:name "emit-outcome-chain" :type :string :required nil :default "false"))
  :outputs ((:name "attested") (:name "receipt-path") (:name "receipt-hash")
            (:name "receipt-algo") (:name "sbom-path") (:name "sbom-format")
            (:name "sbom-components") (:name "slsa-path") (:name "slsa-predicate-type")
            (:name "signed") (:name "outcome-chain") (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "cartorio-attest/run.tlisp")
  :semver-compat :minor
  :attestation   :required)
