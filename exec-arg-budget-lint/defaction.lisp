;; exec-arg-budget-lint/defaction.lisp — the typed catalog entry for the
;; exec-arg-budget-lint verb, co-located next to the action it describes
;; (build-matrix/hardened-image-plan precedent).
;;
;; NAMED LiveTODO shared with the suite: folding this into
;; repo-forge/pleme-actions-catalog.lisp + arch-synthesizer's `Action` domain
;; needs a `TataraScript` `ActionBehavior` variant; until then `:behavior` names
;; the runtime explicitly and is NOT claimed to parse into the shipped struct.

(defaction
  "exec-arg-budget-lint"
  :description
  "Fail when a composite action inlines more tlisp than the kernel can exec, and report how close every other action is. Inlining sends the script step-output -> action-input -> environment-variable -> exec arg space, where Linux caps ONE argv/env string at MAX_ARG_STRLEN = 131072 bytes; over that bash never starts, nothing tlisp-related is logged, and the run dies with `Argument list too long` attributed to the action rather than to its size. The ceiling is SHARED and SHRINKING — every byte added to the stdlib comes out of every inlining action's budget at once — so this emits min-headroom alongside violations. TIER: CI-caught, not unrepresentable; the destination is converting every action to script-file (a path has no size) and `inlining` counts that sweep down to zero."
  :inputs
  ((
     :name "stdlib-path"
     :type :string
     :required nil
     :default "_tlisp-stdlib/stdlib.tlisp")
    (
      :name "limit"
      :type :string
      :required nil
      :default "131072")
    (
      :name "warn-margin"
      :type :string
      :required nil
      :default "8000")
    (
      :name "fail-on-violation"
      :type :string
      :required nil
      :default "true"))
  :outputs
  ((:name "scanned")
    (:name "inlining")
    (:name "violations")
    (:name "near-limit")
    (:name "min-headroom")
    (:name "reason"))
  :behavior
  (:runtime :tatara-script :run-tlisp "exec-arg-budget-lint/run.tlisp")
  :semver-compat
  :minor
  :attestation
  :optional)
