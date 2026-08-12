;; hardened-image-plan/defaction.lisp — the typed catalog entry for the
;; hardened-image-plan verb (arch-synthesizer Action-domain field vocabulary).
;; Co-located next to the action it describes, matching the
;; build-matrix/defaction.lisp + gen-build-spec/defaction.lisp precedent.
;;
;; NAMED LiveTODO (shared with the whole suite): folding this into the
;; canonical repo-forge/pleme-actions-catalog.lisp + arch-synthesizer's
;; `Action` domain needs a `TataraScript` `ActionBehavior` variant (the domain
;; models only rust_crate actions today) — a Rust change outside the
;; pleme-io/actions slice. Until then `:behavior` names the tatara-script
;; runtime + run.tlisp explicitly and is NOT claimed to parse into the shipped
;; Rust struct.

(defaction
  "hardened-image-plan"
  :description
  "Read a hardened-image CATALOG attrset out of a flake and emit the resolved GitHub Actions delivery matrices. The single-responsibility sibling of build-matrix: build-matrix fans a flake's colon-triple image attrs across (service, arch) and knows nothing about a component beyond its name; this verb reads a RICH per-component catalog (zot / harbor / publishName / scan posture) and resolves the delivery conditions — lane, only, stage, event, and tracked mirror-debt — into plain booleans on each row, so the calling workflow carries no per-component `if:` expression at all. The matrix JSON is composed by jq (TYPED EMISSION), never hand-concatenated, and the pre-filter row count is emitted as `scanned` so an empty plan can never be mistaken for a clean one."
  :inputs
  ((
     :name "flake-ref"
     :type :string
     :required nil
     :default ".")
    (
      :name "catalog-attr"
      :type :string
      :required nil
      :default "hardenedImageCatalog")
    (
      :name "event"
      :type :string
      :required t
      :default "")
    (
      :name "only"
      :type :string
      :required nil
      :default "")
    (
      :name "lane"
      :type :string
      :required nil
      :default "")
    (
      :name "stage"
      :type :string
      :required nil
      :default "")
    (
      :name "max-stage"
      :type :string
      :required nil
      :default "all")
    (
      :name "held-file"
      :type :string
      :required nil
      :default "tools/pipeline-registration-baseline.txt")
    (
      :name "runner"
      :type :string
      :required nil
      :default "")
    (
      :name "require-nonempty"
      :type :string
      :required nil
      :default "true")
    (
      :name "strict"
      :type :string
      :required nil
      :default "true")
    (
      :name "summary"
      :type :string
      :required nil
      :default "true"))
  :outputs
  ((:name "pipeline-matrix")
    (:name "pipeline-count")
    (:name "rescan-matrix")
    (:name "rescan-count")
    (:name "promoting")
    (:name "scanned")
    (:name "reason"))
  :behavior
  (:runtime :tatara-script :run-tlisp "hardened-image-plan/run.tlisp")
  :semver-compat
  :minor
  :attestation
  :optional)
