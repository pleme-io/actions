;; release-promote/defaction.lisp — the typed catalog entry for the
;; two-mode promotion verb. Field vocabulary mirrors arch-synthesizer's
;; typed `Action` domain (arch-synthesizer/src/action_domain/mod.rs).
;;
;; ── TIER-HONEST placement note ──────────────────────────────────────
;; Co-located with the action (self-contained), matching the
;; tameshi-attest / cartorio-attest / attestation-gate defaction.lisp
;; precedent. This is a tatara-script (run.tlisp) action and the shipped
;; `ActionBehavior` models only Rust-crate actions, so folding this entry
;; into arch-synthesizer's `Action` domain needs a `TataraScript`
;; `ActionBehavior` variant (a Rust change, out of this coordination
;; slice). The `:behavior` clause names the tatara-script runtime + its
;; run.tlisp explicitly and is NOT claimed to parse into the shipped Rust
;; struct — a NAMED LiveTODO.
;;
;; The `helm-chart-version` mode is a MINOR (backward-compatible)
;; enhancement: `image-retag` remains the default and its guaranteed
;; inputs (image / source-tag / target-tag) are unchanged; the new mode
;; adds only optional inputs.

(defaction "release-promote"
  :description "Promote a built artifact between environments (dev → staging → prod) without rebuilding. kind=image-retag re-tags an existing OCI image (bit-identical per stage, docker buildx imagetools). kind=helm-chart-version writes the EXACT chart/image version into the next environment's committed values file as a GitOps commit (typed yq set, fail-loud git-bot commit) — the AUTOBUMP/eclusa FedRAMP chart-version-promotion leg; environments subscribe to the committed exact version, never a moving tag. Push defaults OFF (chain git-push-with-token for the rebase-safe token-rearmed path)."
  :inputs  ((:name "kind"        :type (:enum (:options ("image-retag" "helm-chart-version"))) :required nil :default "image-retag")
            (:name "image"       :type :string :required nil :default "")
            (:name "source-tag"  :type :string :required nil :default "")
            (:name "target-tag"  :type :string :required nil :default "")
            (:name "values-file" :type :string :required nil :default "")
            (:name "yaml-path"   :type :string :required nil :default ".version")
            (:name "version"     :type :string :required nil :default "")
            (:name "target-env"  :type :string :required nil :default "")
            (:name "commit"      :type :string :required nil :default "true")
            (:name "push"        :type :string :required nil :default "false")
            (:name "branch"      :type :string :required nil :default "main"))
  :outputs ((:name "promoted") (:name "kind") (:name "committed")
            (:name "pushed") (:name "version") (:name "values-file") (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "release-promote/run.tlisp")
  :semver-compat :minor
  :attestation   :optional)
