;; ferrite-check/defaction.lisp — the typed catalog entry for the
;; ferrite-check verb (arch-synthesizer Action-domain field vocabulary).
;; Co-located next to the action it describes, matching the
;; build-matrix/defaction.lisp + cartorio-attest/defaction.lisp +
;; super-cache-build/defaction.lisp precedent (git-least-disturbance: also
;; registered in the suite seed super-cache-ci-catalog.lisp, never
;; hand-merged only-here).
;;
;; NAMED LiveTODO (shared with the whole suite): folding this into the
;; canonical repo-forge/pleme-actions-catalog.lisp + arch-synthesizer's
;; `Action` domain needs a `TataraScript` `ActionBehavior` variant (the
;; domain models only rust_crate actions today) — a Rust change outside
;; the pleme-io/actions slice. Until then `:behavior` names the
;; tatara-script runtime + run.tlisp explicitly and is NOT claimed to
;; parse into the shipped Rust struct.

(defaction "ferrite-check"
  :description "Per-package MATERIALIZABILITY gate of the camelot image pipeline. For ONE package (a flake image attr) verify it can be materialized (its attr resolves to a derivation via a cheap `nix eval`, NOT a derive) BEFORE the expensive build, content-address its SOURCE (the output store-path), and emit a PoMS — a Proof-of-Materialization-Spec receipt (schema pleme-io.ferrite.materialization-spec/v1) whose attestation.receipt_hash is a real BLAKE3 over the canonical body — cached by that source hash so a re-run over unchanged source is a pure cache HIT (skip re-eval + derive). Single-responsibility sibling of build-matrix (the (svc,arch) fan) + gen-build-spec (the build-spec freshness gate); gates one fan cell's materializability. Sibling of tameshi-attest (build receipt) + cartorio-attest (delivery receipt) on ONE chain — carries chain.prev, shares the BLAKE3 core (stdlib hash:*). TYPED EMISSION: the PoMS JSON is composed by jq, never hand-concatenated. Keyway three-code exit: 0 materializable (fresh or cached), 2 clean typed not-materializable under require=false, 1 not-materializable under require=true / config / tooling failure."
  :inputs  ((:name "flake-ref"          :type :string :required nil :default ".")
            (:name "image-attr"         :type :string :required nil :default "dockerImage")
            (:name "attr-template"      :type :string :required nil :default "dockerImage:{arch}:{svc}")
            (:name "svc"                :type :string :required nil :default "")
            (:name "arch"               :type :string :required nil :default "amd64")
            (:name "poms-dir"           :type :string :required nil :default "")
            (:name "prev-receipt-hash"  :type :string :required nil :default "")
            (:name "poms-path"          :type :string :required nil :default "ferrite-poms.json")
            (:name "require"            :type :string :required nil :default "true")
            (:name "sign"               :type :string :required nil :default "false")
            (:name "emit-outcome-chain" :type :string :required nil :default "false"))
  :outputs ((:name "materializable") (:name "cached") (:name "source-hash")
            (:name "drv-path")       (:name "attr")   (:name "poms-path")
            (:name "poms-hash")      (:name "poms-algo")
            (:name "signed")         (:name "outcome-chain") (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "ferrite-check/run.tlisp")
  :semver-compat :minor
  :attestation   :required)
