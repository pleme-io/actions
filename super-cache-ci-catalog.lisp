;; super-cache-ci-catalog.lisp — the typed catalog SEED for the
;; super-cache-ci action vocabulary (theory/SUPER-CACHE-CI.md).
;;
;; Each (defaction …) is the operator authoring surface for one verb in
;; the default CI-authoring language for the sui-service stack. The field
;; vocabulary (name / description / inputs / outputs / behavior /
;; semver-compat / attestation) mirrors arch-synthesizer's typed `Action`
;; domain 1:1 (arch-synthesizer/src/action_domain/mod.rs).
;;
;; ── TIER-HONEST placement note ──────────────────────────────────────
;; The CANONICAL catalog home is `repo-forge/pleme-actions-catalog.lisp`
;; feeding arch-synthesizer's `Action` domain (CONSTRUCTIVE-ACTIONS.md).
;; This file is the SUITE SEED committed alongside the actions it
;; describes; folding it into the canonical catalog + the Action-domain
;; proofs is a NAMED LiveTODO, because these are tatara-script (run.tlisp)
;; actions and the current `ActionBehavior` models only Rust-crate
;; actions (rust_crate / depends / runtime_tools). Admitting a
;; tatara-script action requires a `TataraScript` `ActionBehavior`
;; variant in arch-synthesizer — a Rust change + build, out of the
;; pleme-io/actions coordination slice. Until then the `:behavior`
;; clause names the tatara-script runtime + its run.tlisp explicitly and
;; is NOT claimed to parse into the shipped Rust struct.

(defaction "sui-service-up"
  :description "Resolve, health-check, and export the sui service (sui-daemon-graph) endpoint + selected store/cache/sandbox tiers for a super-cache-ci build. Does not own daemon lifecycle."
  :inputs  ((:name "mode"          :type (:enum (:options ("connect" "ephemeral"))) :required nil :default "ephemeral")
            (:name "endpoint"      :type :string :required nil :default "")
            (:name "store-backend" :type :string :required nil :default "")
            (:name "cache-backend" :type :string :required nil :default "")
            (:name "sandbox"       :type :string :required nil :default "")
            (:name "require-up"    :type :string :required nil :default "false"))
  :outputs ((:name "endpoint")     (:name "store-backend") (:name "cache-backend")
            (:name "sandbox")      (:name "never-touch-disk") (:name "up")
            (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "sui-service-up/run.tlisp")
  :semver-compat :minor
  :attestation   :optional)

(defaction "super-cache-restore"
  :description "Probe the tiered super-cache (Redis L1 -> Postgres L2 -> object L3) for a build's outputs and report the hit + tier (the warm path)."
  :inputs  ((:name "endpoint"  :type :string :required nil :default "")
            (:name "key"       :type :string :required nil :default "")
            (:name "spec-path" :type :string :required nil :default "")
            (:name "tiers"     :type :string :required nil :default "redis,pg,object")
            (:name "cache-dir" :type :string :required nil :default ""))
  :outputs ((:name "cache-hit") (:name "hit-tier") (:name "key") (:name "outputs"))
  :behavior      (:runtime :tatara-script :run-tlisp "super-cache-restore/run.tlisp")
  :semver-compat :minor
  :attestation   :optional)

(defaction "super-cache-save"
  :description "Persist a build's outputs to the durable super-cache tiers, write-if-absent, content-addressed, no lock (the eliminate-the-shared-cell pattern)."
  :inputs  ((:name "endpoint"  :type :string :required nil :default "")
            (:name "key"       :type :string :required nil :default "")
            (:name "spec-path" :type :string :required nil :default "")
            (:name "outputs"   :type :string :required nil :default "")
            (:name "cache-dir" :type :string :required nil :default ""))
  :outputs ((:name "saved") (:name "skipped") (:name "key") (:name "tier") (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "super-cache-save/run.tlisp")
  :semver-compat :minor
  :attestation   :optional)

;; ── delivery leg (build a nix OCI image -> private ghcr -> zot faucet) ──

(defaction "nix-image"
  :description "Build multi-arch nix OCI image tarballs via dockerTools (NO Dockerfile), one per arch, from the substrate dockerImage-<arch> convention. Routes through the sui super-cache when SUI_ENDPOINT is set (LiveTODO:super-cache-build); correct local nix build otherwise."
  :inputs  ((:name "image-attr" :type :string :required nil :default "dockerImage")
            (:name "arches"     :type :string :required nil :default "amd64")
            (:name "flake-ref"  :type :string :required nil :default ".")
            (:name "endpoint"   :type :string :required nil :default ""))
  :outputs ((:name "tarball-amd64") (:name "tarball-arm64") (:name "tarballs")
            (:name "via-service")   (:name "built")         (:name "result"))
  :behavior      (:runtime :tatara-script :run-tlisp "nix-image/run.tlisp")
  :semver-compat :minor
  :attestation   :optional)

(defaction "ghcr-publish"
  :description "Push a nix OCI image tarball to a private registry (ghcr.io/pleme-io/<svc>) under the AUTOBUMP exact tag <arch>-r<run>-<sha>, plus an optional moving <arch>-latest human pointer (never a deploy source). Auth is a pre-condition (docker/login-action first)."
  :inputs  ((:name "repo"          :type :string :required nil :default "")
            (:name "registry"      :type :string :required nil :default "ghcr.io")
            (:name "image"         :type :string :required nil :default "")
            (:name "arch"          :type :string :required nil :default "amd64")
            (:name "run-number"    :type :string :required t)
            (:name "sha"           :type :string :required t)
            (:name "tarball"       :type :string :required nil :default "./result")
            (:name "moving-latest" :type :string :required nil :default "true"))
  :outputs ((:name "tag") (:name "ref") (:name "ref-amd64") (:name "ref-arm64")
            (:name "pushed") (:name "result"))
  :behavior      (:runtime :tatara-script :run-tlisp "ghcr-publish/run.tlisp")
  :semver-compat :minor
  :attestation   :optional)

(defaction "zot-pull-scan"
  :description "The zot faucet gate: pull an image from a private zot registry, scan the PULLED bytes with Trivy, and admit it into the trusted zone ONLY when the scan clears the fail-on-severity gate. Nothing enters the trusted zone unscanned."
  :inputs  ((:name "ref"              :type :string :required t)
            (:name "fail-on-severity" :type (:enum (:options ("LOW" "MEDIUM" "HIGH" "CRITICAL" "none"))) :required nil :default "HIGH")
            (:name "ignore-unfixed"   :type :string :required nil :default "false")
            (:name "dest"             :type :string :required nil :default "zot-pull.tar"))
  :outputs ((:name "admitted") (:name "severity") (:name "vuln-count")
            (:name "local-archive") (:name "result"))
  :behavior      (:runtime :tatara-script :run-tlisp "zot-pull-scan/run.tlisp")
  :semver-compat :minor
  :attestation   :required)
