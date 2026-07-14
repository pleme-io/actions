;; gen-build-spec/defaction.lisp — the typed catalog entry for the
;; gen-build-spec verb (arch-synthesizer Action-domain field vocabulary).
;; Co-located next to the action it describes, matching the
;; super-cache-build/defaction.lisp precedent (git-least-disturbance:
;; NOT hand-merged into super-cache-ci-catalog.lisp here).
;;
;; NAMED LiveTODO (shared with the whole suite): folding this into the
;; canonical repo-forge/pleme-actions-catalog.lisp + arch-synthesizer's
;; `Action` domain needs a `TataraScript` `ActionBehavior` variant (the
;; domain models only rust_crate actions today) — a Rust change outside
;; the pleme-io/actions slice. Until then `:behavior` names the
;; tatara-script runtime + run.tlisp explicitly and is NOT claimed to
;; parse into the shipped Rust struct.

(defaction "gen-build-spec"
  :description "Emit the typed *.build-spec.json via `gen build .` and enforce the GEN-TYPED-SPEC-CONTRACT stale gate (a committed spec that drifts from the regen is a CI failure). Step 3 of the super-cache-ci pipeline — the spec producer the tiered cache verbs key on."
  :inputs  ((:name "lang"           :type (:enum (:options ("auto" "cargo" "npm" "pip" "gomod"))) :required nil :default "auto")
            (:name "spec-path"      :type :string :required nil :default "")
            (:name "ci-stale-check" :type :string :required nil :default "true")
            (:name "require-gen"    :type :string :required nil :default "false"))
  :outputs ((:name "lang") (:name "spec-path") (:name "spec-hash")
            (:name "regenerated") (:name "stale") (:name "changed") (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "gen-build-spec/run.tlisp")
  :semver-compat :minor
  :attestation   :optional)
