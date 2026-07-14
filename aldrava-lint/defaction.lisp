;; aldrava-lint/defaction.lisp — the typed catalog entry for the
;; catalog-validation verb. See aldrava-dispatch/defaction.lisp for the
;; tier-honest placement note (same LiveTODO applies here).

(defaction "aldrava-lint"
  :description "Validate a (defcommentcommand ...) catalog file — catches a typo'd keyword or malformed command definition at PR time instead of at the next real knock. Fails the step with the offending form named when the catalog does not parse."
  :inputs  ((:name "catalog-path" :type :string :required nil :default ".github/aldrava.lisp"))
  :outputs ((:name "ok") (:name "commands") (:name "error"))
  :behavior      (:runtime :tatara-script :run-tlisp "aldrava-lint/run.tlisp")
  :semver-compat :minor
  :attestation   :none)
