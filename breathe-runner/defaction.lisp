;; breathe-runner/defaction.lisp — the typed catalog entry for the
;; super-cache-ci PREFLIGHT verb. Field vocabulary mirrors
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

(defaction "breathe-runner"
  :description "Preflight posture gate for camelot breathable spot runners: assert the job landed on a 100%-spot, scale-to-zero, taint-isolated in-cluster GHA runner (never rio) via config-driven CAMELOT_* signals, and arm the retirada drain->checkpoint hook. Never claims drain-armed without the handler present; enforce=false makes every requirement advisory."
  :inputs  ((:name "require-spot"          :type :string :required nil :default "true")
            (:name "require-camelot-taint" :type :string :required nil :default "true")
            (:name "require-scale-to-zero" :type :string :required nil :default "false")
            (:name "drain-handler"         :type :string :required nil :default "true")
            (:name "enforce"               :type :string :required nil :default "true")
            (:name "capacity-type-env"     :type :string :required nil :default "CAMELOT_CAPACITY_TYPE")
            (:name "node-group-env"        :type :string :required nil :default "CAMELOT_NODE_GROUP")
            (:name "min-runners-env"       :type :string :required nil :default "CAMELOT_MIN_RUNNERS"))
  :outputs ((:name "runner-ok") (:name "capacity-type") (:name "node-group")
            (:name "scale-to-zero") (:name "drain-armed"))
  :behavior      (:runtime :tatara-script :run-tlisp "breathe-runner/run.tlisp")
  :semver-compat :minor
  :attestation   :none)
