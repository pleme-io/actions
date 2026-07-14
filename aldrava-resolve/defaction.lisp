;; aldrava-resolve/defaction.lisp — the typed catalog entry for the
;; uniform-run-context-resolution verb. See aldrava-dispatch/defaction.lisp
;; for the tier-honest placement note (same LiveTODO applies here).

(defaction "aldrava-resolve"
  :description "Resolve a uniform run context (checkout ref, branch ref, base ref, PR author, is-develop) from whatever event triggered this job — a label add, workflow_dispatch, schedule, or repository_dispatch — so a downstream pipeline behaves the same regardless of trigger source. Pure computation: no network call, no trust decision (that already happened upstream in aldrava-dispatch)."
  :inputs  ((:name "label-name" :type :string :required nil :default ""))
  :outputs ((:name "should-run") (:name "checkout-ref") (:name "branch-ref")
            (:name "base-ref") (:name "pr-author") (:name "is-develop") (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "aldrava-resolve/run.tlisp")
  :semver-compat :minor
  :attestation   :none)
