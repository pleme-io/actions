;; super-cache-build/defaction.lisp — the typed catalog entry for the
;; CORE super-cache-ci verb. Field vocabulary mirrors arch-synthesizer's
;; typed `Action` domain (arch-synthesizer/src/action_domain/mod.rs) and
;; the sibling seed catalog (super-cache-ci-catalog.lisp).
;;
;; ── TIER-HONEST placement note ──────────────────────────────────────
;; Co-located with the action (self-contained) rather than folded into
;; the sibling super-cache-ci-catalog.lisp, because that file is being
;; authored concurrently — a git-least-disturbance choice, not a
;; permanent home. Folding this entry into the suite seed catalog +
;; wiring it into arch-synthesizer's `Action` domain proofs is a NAMED
;; LiveTODO: these are tatara-script (run.tlisp) actions and the shipped
;; `ActionBehavior` models only Rust-crate actions, so admitting a
;; tatara-script action needs a `TataraScript` `ActionBehavior` variant
;; (a Rust change, out of this coordination slice). The `:behavior`
;; clause names the tatara-script runtime + its run.tlisp explicitly and
;; is NOT claimed to parse into the shipped Rust struct.

(defaction "super-cache-build"
  :description "THE CORE super-cache-ci verb: build a derivation via the sui service against the tiered super-cache, keyed by the gen build-spec (RAM eval, tmpfs sandbox, DB store). Skips the derive on a restore cache hit; the live derive (sui-graph build RPC/CLI) is a named LiveTODO reported honestly, never a faked green."
  :inputs  ((:name "spec-path"        :type :string :required nil :default "")
            (:name "key"              :type :string :required nil :default "")
            (:name "cache-hit"        :type :string :required nil :default "false")
            (:name "restored-outputs" :type :string :required nil :default "")
            (:name "force"            :type :string :required nil :default "false")
            (:name "endpoint"         :type :string :required nil :default "")
            (:name "sandbox"          :type :string :required nil :default "tmpfs")
            (:name "store-backend"    :type :string :required nil :default "graphstore")
            (:name "cache-backend"    :type :string :required nil :default "local")
            (:name "require-build"    :type :string :required nil :default "false"))
  :outputs ((:name "built") (:name "from-cache") (:name "outputs")
            (:name "output-hashes") (:name "eval-ms") (:name "build-ms")
            (:name "key") (:name "never-touch-disk") (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "super-cache-build/run.tlisp")
  :semver-compat :minor
  :attestation   :required)
