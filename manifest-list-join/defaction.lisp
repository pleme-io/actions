;; manifest-list-join/defaction.lisp — the typed catalog entry for the
;; super-cache-ci MANIFEST verb. Field vocabulary mirrors
;; arch-synthesizer's typed `Action` domain
;; (arch-synthesizer/src/action_domain/mod.rs) and the sibling seed
;; catalog (super-cache-ci-catalog.lisp).
;;
;; ── TIER-HONEST placement note ──────────────────────────────────────
;; Co-located with the action (self-contained), matching the
;; tameshi-attest / super-cache-build precedent. Folding this entry into
;; the canonical repo-forge/pleme-actions-catalog + wiring it into
;; arch-synthesizer's `Action` domain proofs is a NAMED LiveTODO: these
;; are tatara-script (run.tlisp) actions and the shipped `ActionBehavior`
;; models only Rust-crate actions (rust_crate / depends / runtime_tools),
;; so admitting a tatara-script action needs a `TataraScript`
;; `ActionBehavior` variant (a Rust change, out of this coordination
;; slice). The `:behavior` clause names the tatara-script runtime + its
;; run.tlisp explicitly and is NOT claimed to parse into the shipped Rust
;; struct.

(defaction "manifest-list-join"
  :description "Compose separately-pushed per-arch images (amd64=<ref>,arm64=<ref>) into ONE multi-arch OCI image index (manifest list) and push it under the multi-arch deploy coordinate r<run>-<sha>; report the index DIGEST — the single exact coordinate an environment pins. Drives an auto-detected manifest tool (buildah|podman manifest, docker manifest, or regctl index) since skopeo copies single images but does not compose an index. FAILS loudly when no tool is present (never fakes a digest). A 1-arch join is a degenerate-but-honest index (reason=single-arch) until arm64-native lands."
  :inputs  ((:name "registry"  :type :string :required nil :default "zot.zot-system.svc.cluster.local:5000")
            (:name "repo"      :type :string :required nil :default "")
            (:name "image"     :type :string :required nil :default "")
            (:name "svc"       :type :string :required nil :default "")
            (:name "arch-refs" :type :string :required t)
            (:name "tag"       :type :string :required nil :default "")
            (:name "run-number":type :string :required nil :default "")
            (:name "sha"       :type :string :required nil :default "")
            (:name "insecure"  :type :string :required nil :default "true")
            (:name "tool"      :type (:enum (:options ("auto" "buildah" "podman" "docker" "regctl"))) :required nil :default "auto"))
  :outputs ((:name "index-ref") (:name "index-digest") (:name "arches")
            (:name "joined") (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "manifest-list-join/run.tlisp")
  :semver-compat :minor
  :attestation   :required)
