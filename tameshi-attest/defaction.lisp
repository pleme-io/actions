;; tameshi-attest/defaction.lisp — the typed catalog entry for the
;; super-cache-ci ATTEST verb (the final verb). Field vocabulary mirrors
;; arch-synthesizer's typed `Action` domain
;; (arch-synthesizer/src/action_domain/mod.rs) and the sibling seed
;; catalog (super-cache-ci-catalog.lisp).
;;
;; ── TIER-HONEST placement note ──────────────────────────────────────
;; Co-located with the action (self-contained), matching the
;; super-cache-build/defaction.lisp precedent, rather than folded into
;; the sibling super-cache-ci-catalog.lisp — that file is being authored
;; by a concurrent workflow, so a co-located entry is a
;; git-least-disturbance choice, not a permanent home. Folding this entry
;; into the suite seed catalog + wiring it into arch-synthesizer's
;; `Action` domain proofs is a NAMED LiveTODO: these are tatara-script
;; (run.tlisp) actions and the shipped `ActionBehavior` models only
;; Rust-crate actions, so admitting a tatara-script action needs a
;; `TataraScript` `ActionBehavior` variant (a Rust change, out of this
;; coordination slice). The `:behavior` clause names the tatara-script
;; runtime + its run.tlisp explicitly and is NOT claimed to parse into
;; the shipped Rust struct.

(defaction "tameshi-attest"
  :description "Assemble + BLAKE3-hash a typed, independently verifiable super-cache-ci build receipt (schema, subject, spec-hash, output-hashes, cache tier, timings, image digests). JSON built by jq (typed serializer, never format!()); receipt_hash is a real b3sum (on-PATH b3sum, else nix run nixpkgs#b3sum) — the action FAILS rather than emit a receipt that lies about its algorithm. Ed25519 signing + kensa OutcomeChain append are named LiveTODOs (warn + emit signed=false / outcome_chain=false, never faked)."
  :inputs  ((:name "subject"            :type :string :required nil :default "")
            (:name "spec-hash"          :type :string :required nil :default "")
            (:name "output-hashes"      :type :string :required nil :default "")
            (:name "cache-hit"          :type :string :required nil :default "false")
            (:name "hit-tier"           :type (:enum (:options ("miss" "redis" "pg" "object"))) :required nil :default "miss")
            (:name "eval-ms"            :type :string :required nil :default "")
            (:name "build-ms"           :type :string :required nil :default "")
            (:name "image-digests"      :type :string :required nil :default "")
            (:name "receipt-path"       :type :string :required nil :default "tameshi-receipt.json")
            (:name "sign"               :type :string :required nil :default "false")
            (:name "emit-outcome-chain" :type :string :required nil :default "false"))
  :outputs ((:name "attested") (:name "receipt-path") (:name "receipt-hash")
            (:name "receipt-algo") (:name "signed") (:name "outcome-chain"))
  :behavior      (:runtime :tatara-script :run-tlisp "tameshi-attest/run.tlisp")
  :semver-compat :minor
  :attestation   :required)
