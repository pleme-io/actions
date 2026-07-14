;; build-matrix/defaction.lisp — the typed catalog entry for the
;; build-matrix verb (arch-synthesizer Action-domain field vocabulary).
;; Co-located next to the action it describes, matching the
;; gen-build-spec/defaction.lisp + super-cache-build/defaction.lisp
;; precedent (git-least-disturbance: also registered in the suite seed
;; super-cache-ci-catalog.lisp, never hand-merged only-here).
;;
;; NAMED LiveTODO (shared with the whole suite): folding this into the
;; canonical repo-forge/pleme-actions-catalog.lisp + arch-synthesizer's
;; `Action` domain needs a `TataraScript` `ActionBehavior` variant (the
;; domain models only rust_crate actions today) — a Rust change outside
;; the pleme-io/actions slice. Until then `:behavior` names the
;; tatara-script runtime + run.tlisp explicitly and is NOT claimed to
;; parse into the shipped Rust struct.

(defaction "build-matrix"
  :description "Enumerate a flake's colon-triple image attrs (dockerImage:<arch>:<svc>) and emit the GitHub Actions image×arch build matrix. Step 2 of the super-cache-ci graph job — the single-responsibility sibling of gen-build-spec (spec freshness gate); this fans the fresh spec across every (service, arch) the flake actually exposes. Deterministic `nix eval` enumeration, honest per-service arch discovery (never a hard-coded arch pair); the matrix JSON is composed by jq (TYPED EMISSION), never hand-concatenated."
  :inputs  ((:name "flake-ref"        :type :string :required nil :default ".")
            (:name "eval-system"      :type :string :required nil :default "x86_64-linux")
            (:name "image-base"       :type :string :required nil :default "dockerImage")
            (:name "services"         :type :string :required nil :default "")
            (:name "arches"           :type :string :required nil :default "")
            (:name "exclude"          :type :string :required nil :default "")
            (:name "require-nonempty" :type :string :required nil :default "true"))
  :outputs ((:name "matrix") (:name "count") (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "build-matrix/run.tlisp")
  :semver-compat :minor
  :attestation   :optional)
