;; aldrava-dispatch/defaction.lisp — the typed catalog entry for the
;; comment-command dispatch verb. Field vocabulary mirrors
;; arch-synthesizer's typed `Action` domain
;; (arch-synthesizer/src/action_domain/mod.rs) and the sibling seed
;; catalog (super-cache-ci-catalog.lisp).
;;
;; ── TIER-HONEST placement note ──────────────────────────────────────
;; Co-located with the action (breathe-runner/build-matrix precedent)
;; rather than folded into super-cache-ci-catalog.lisp — this is a
;; ChatOps primitive, not a super-cache-ci build verb, so it doesn't
;; belong in that catalog's namespace either way. Folding into a
;; fleet-wide action catalog + wiring into arch-synthesizer's `Action`
;; domain proofs is a NAMED LiveTODO: this is a tatara-script
;; (run.tlisp) action and the shipped `ActionBehavior` models only
;; Rust-crate actions, so admitting a tatara-script action needs a
;; `TataraScript` `ActionBehavior` variant (a Rust change, out of this
;; slice). The `:behavior` clause names the tatara-script runtime + its
;; run.tlisp explicitly and is NOT claimed to parse into the shipped
;; Rust struct.

(defaction "aldrava-dispatch"
  :description "The typed knock: match a PR comment against a registered (defcommentcommand ...) catalog (or an inline single-command config), resolve commenter trust (PR author / allowlist / minimum repo permission), and dispatch the target — an idempotent label relabel, a workflow_dispatch, or a repository_dispatch. Never mutates on an untrusted or unmatched knock."
  :inputs  ((:name "catalog-path"                       :type :string :required nil :default "")
            (:name "command"                             :type :string :required nil :default "")
            (:name "trigger"                             :type :string :required nil :default "")
            (:name "min-permission"                      :type :string :required nil :default "write")
            (:name "trust-pr-author"                     :type :string :required nil :default "true")
            (:name "allowlist"                            :type :string :required nil :default "")
            (:name "target-label"                        :type :string :required nil :default "")
            (:name "target-workflow"                     :type :string :required nil :default "")
            (:name "target-workflow-ref"                 :type :string :required nil :default "")
            (:name "target-repository-dispatch-event"    :type :string :required nil :default "")
            (:name "target-repository-dispatch-repo"     :type :string :required nil :default "")
            (:name "repo"                                :type :string :required nil :default "${{ github.repository }}")
            (:name "token"                               :type :string :required nil :default "${{ github.token }}"))
  :outputs ((:name "dispatched") (:name "outcome") (:name "command") (:name "args")
            (:name "commenter") (:name "checkout-ref") (:name "branch-ref") (:name "base-ref")
            (:name "pr-author") (:name "is-develop") (:name "target-kind") (:name "target-detail")
            (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "aldrava-dispatch/run.tlisp")
  :semver-compat :minor
  :attestation   :none)
