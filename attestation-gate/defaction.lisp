;; attestation-gate/defaction.lisp — the typed catalog entry for the
;; FedRAMP provenance GATE verb (the verify/gate dual of tameshi-attest +
;; cartorio-attest). Field vocabulary mirrors arch-synthesizer's typed
;; `Action` domain (arch-synthesizer/src/action_domain/mod.rs) and the
;; sibling attest verbs' co-located entries.
;;
;; ── TIER-HONEST placement note ──────────────────────────────────────
;; Co-located with the action (self-contained), matching the
;; tameshi-attest / cartorio-attest defaction.lisp precedent, rather than
;; folded into arch-synthesizer's `Action` domain: these are
;; tatara-script (run.tlisp) actions and the shipped `ActionBehavior`
;; models only Rust-crate actions, so admitting a tatara-script action
;; needs a `TataraScript` `ActionBehavior` variant (a Rust change, out of
;; this coordination slice). The `:behavior` clause names the
;; tatara-script runtime + its run.tlisp explicitly and is NOT claimed to
;; parse into the shipped Rust struct — a NAMED LiveTODO.

(defaction "attestation-gate"
  :description "FedRAMP provenance GATE: verify a tameshi/cartorio attestation receipt (presence + blake3 algorithm + content-address tamper-evidence via re-canonicalize+re-hash + optional chain/digest/SBOM/SLSA pillar checks) and REFUSE to promote an unattested/tampered artifact version. Cryptographic signature verification (cosign/DSSE/Ed25519) is a named LiveTODO — require-signed=true FAILS honestly, never passes a signature it cannot verify. Emits a typed jq-serialized gate-decision receipt."
  :inputs  ((:name "receipt-path"      :type :string :required nil :default "cartorio-receipt.json")
            (:name "subject"           :type :string :required nil :default "")
            (:name "expected-prev"     :type :string :required nil :default "")
            (:name "expected-digest"   :type :string :required nil :default "")
            (:name "sbom-path"         :type :string :required nil :default "")
            (:name "slsa-path"         :type :string :required nil :default "")
            (:name "require-chain"     :type :string :required nil :default "false")
            (:name "require-signed"    :type :string :required nil :default "false")
            (:name "fail-on-gate"      :type :string :required nil :default "true")
            (:name "gate-receipt-path" :type :string :required nil :default "attestation-gate-receipt.json"))
  :outputs ((:name "passed") (:name "decision") (:name "reason")
            (:name "receipt-hash") (:name "verified-algo")
            (:name "gate-receipt-path") (:name "signed-verified"))
  :behavior      (:runtime :tatara-script :run-tlisp "attestation-gate/run.tlisp")
  :semver-compat :minor
  :attestation   :required)
