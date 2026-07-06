;; zot-push/defaction.lisp — the typed catalog entry for the
;; super-cache-ci PRIVATE-ZOT delivery verb. Field vocabulary mirrors
;; arch-synthesizer's typed `Action` domain
;; (arch-synthesizer/src/action_domain/mod.rs) and the sibling seed
;; catalog (super-cache-ci-catalog.lisp).
;;
;; ── TIER-HONEST placement note ──────────────────────────────────────
;; Co-located with the action (self-contained), matching the
;; tameshi-attest / super-cache-build / breathe-runner / gen-build-spec
;; precedent, rather than duplicating a row into the sibling
;; super-cache-ci-catalog.lisp (a duplicated defaction is the exact
;; drift CATALOG-REFLECTION forbids; the seed catalog carries a POINTER
;; to these co-located delivery/manifest/attest-leg entries instead).
;; Folding this entry into the canonical repo-forge/pleme-actions-catalog
;; + wiring it into arch-synthesizer's `Action` domain proofs is a NAMED
;; LiveTODO: these are tatara-script (run.tlisp) actions and the shipped
;; `ActionBehavior` models only Rust-crate actions (rust_crate / depends
;; / runtime_tools), so admitting a tatara-script action needs a
;; `TataraScript` `ActionBehavior` variant (a Rust change, out of this
;; coordination slice). The `:behavior` clause names the tatara-script
;; runtime + its run.tlisp explicitly and is NOT claimed to parse into
;; the shipped Rust struct.

(defaction "zot-push"
  :description "Push a nix OCI image tarball to the PRIVATE in-cluster Zot registry (zot.zot-system.svc.cluster.local:5000/akeyless-<svc>) under the ★ AUTOBUMP exact tag <arch>-r<run>-<sha>, and report the pushed repository DIGEST (the exact deploy coordinate). Sibling of ghcr-publish (which ships pleme-io OSS to public ghcr.io); zot-push ships FedRAMP-sensitive akeyless images to the cluster-internal Zot, NEVER ghcr.io. Insecure (http/self-signed) cluster-internal registry via INSECURE=true. Auth is a pre-condition."
  :inputs  ((:name "registry"      :type :string :required nil :default "zot.zot-system.svc.cluster.local:5000")
            (:name "repo"          :type :string :required nil :default "")
            (:name "image"         :type :string :required nil :default "")
            (:name "svc"           :type :string :required nil :default "")
            (:name "arch"          :type :string :required nil :default "amd64")
            (:name "run-number"    :type :string :required t)
            (:name "sha"           :type :string :required t)
            (:name "tarball"       :type :string :required nil :default "./result")
            (:name "moving-latest" :type :string :required nil :default "false")
            (:name "insecure"      :type :string :required nil :default "true"))
  :outputs ((:name "tag") (:name "ref") (:name "ref-amd64") (:name "ref-arm64")
            (:name "digest") (:name "pushed") (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "zot-push/run.tlisp")
  :semver-compat :minor
  :attestation   :required)
