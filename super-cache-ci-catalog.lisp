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

;; ── warm + remote-execution leg (DEGRADED-UNTIL-STORE) ──────────────
;; Both verbs' fast behavior is gated on the keystone
;; `TieredBackend = RedisBackend(L1)→PgStore(L2)→S3Storage(L3)` behind
;; sui's SHIPPED Store/StorageBackend traits (+ a daemon warm-set RPC for
;; sui-warm-hydrate, + the REAPI worker binary for sui-remote-build).
;; Until then each is an HONEST degrade — a no-op warm / a correct local
;; fallback build — reported truthfully (warmed=false / worker=local),
;; NEVER a faked warm/build. The single `*-shipped?` keystone constant in
;; each run.tlisp promotes it to fleet-wide-fast with zero other change.
;; These NET-NEW verbs formalize the keyway's third exit code (exit 2 = a
;; clean typed "no", the degrade under require-*=false; exit 1 under
;; require-*=true; exit 0 on the real path) per the design's A2.

(defaction "sui-warm-hydrate"
  :description "GRAPH-job warm verb: pre-load the sui daemon's tiered super-cache (Redis L1 -> Postgres L2 -> object L3) with the fan-out's content keys BEFORE the build matrix explodes, so every parallel job starts warm. DEGRADED-UNTIL-STORE: the warm-set RPC + TieredBackend are a named LiveTODO; today an honest no-op (warmed=false, never a faked warm)."
  :inputs  ((:name "endpoint"      :type :string :required nil :default "")
            (:name "spec-paths"    :type :string :required nil :default "")
            (:name "keys"          :type :string :required nil :default "")
            (:name "tiers"         :type :string :required nil :default "redis,pg,object")
            (:name "store-backend" :type :string :required nil :default "graphstore")
            (:name "cache-backend" :type :string :required nil :default "local")
            (:name "sandbox"       :type :string :required nil :default "tmpfs")
            (:name "require-warm"  :type :string :required nil :default "false"))
  :outputs ((:name "warmed") (:name "warm-count") (:name "hit-tier")
            (:name "never-touch-disk") (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "sui-warm-hydrate/run.tlisp")
  :semver-compat :minor
  :attestation   :optional)

(defaction "sui-remote-build"
  :description "BUILD-job remote-execution verb: dispatch a derivation to a REAPI spot worker over the sui daemon, keyed by the gen build-spec. DEGRADED-UNTIL-STORE: the REAPI worker binary + TieredBackend are a named LiveTODO; gracefully falls back to the correct local daemon-node build (worker=local, built=false honest — super-cache-build's derive core is itself unshipped), never a faked build."
  :inputs  ((:name "endpoint"      :type :string :required nil :default "")
            (:name "spec-path"     :type :string :required nil :default "")
            (:name "key"           :type :string :required nil :default "")
            (:name "arch"          :type :string :required nil :default "amd64")
            (:name "sandbox"       :type :string :required nil :default "tmpfs")
            (:name "store-backend" :type :string :required nil :default "graphstore")
            (:name "cache-backend" :type :string :required nil :default "local")
            (:name "require-build" :type :string :required nil :default "false"))
  :outputs ((:name "built") (:name "from-cache") (:name "outputs")
            (:name "output-hashes") (:name "eval-ms") (:name "build-ms")
            (:name "worker") (:name "never-touch-disk") (:name "reason"))
  :behavior      (:runtime :tatara-script :run-tlisp "sui-remote-build/run.tlisp")
  :semver-compat :minor
  :attestation   :required)

;; ── delivery leg (build a nix OCI image -> private ghcr -> zot faucet) ──

(defaction "nix-image"
  :description "Build native-arch nix OCI image tarballs via dockerTools (NO Dockerfile, NO QEMU), one per arch, resolving the flake attr from a typed {base}/{arch}/{svc} template — covers substrate mkImageReleaseApp (dockerImage-<arch>), mkGoDockerImage multi-service (dockerImage-<arch>-<svc>), and akeyless-nix-images (dockerImage:<arch>:<svc>). Fan out over runs-on:[camelot,<arch>] for a native build. Routes through the sui super-cache when SUI_ENDPOINT is set (LiveTODO:super-cache-build); correct local nix build otherwise."
  :inputs  ((:name "image-attr"    :type :string :required nil :default "dockerImage")
            (:name "attr-template" :type :string :required nil :default "{base}-{arch}")
            (:name "svc"           :type :string :required nil :default "")
            (:name "arches"        :type :string :required nil :default "amd64")
            (:name "flake-ref"     :type :string :required nil :default ".")
            (:name "endpoint"      :type :string :required nil :default "")
            ;; ADAPTIVE CORE-PARTITION: discover V=nproc, partition across N
            ;; targets so planned concurrency (max-jobs*cores) <= V and ~= V.
            (:name "targets"       :type :string :required nil :default "1")
            (:name "dag-shape"     :type (:enum (:options ("narrow" "wide"))) :required nil :default "narrow")
            (:name "auto-tune"     :type :string :required nil :default "true")
            ;; explicit CAPS (quota bounds) that WIN over the tuner; the
            ;; sentinels "auto"/"0" hand control to the tuner.
            (:name "max-jobs"      :type :string :required nil :default "auto")
            (:name "cores"         :type :string :required nil :default "0"))
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
  :attestation   :optional)

;; ── node-local daemon-aware cache leg (Phase 3b GHA integration) ──────
;; Unlike every other verb above, this one is NOT tatara-script — it is
;; a cargo-installed Rust binary (`gha-entrypoint`, published as a bin of
;; the `sui-dockerfile-wrapper` crate), matching the caixa-render /
;; cargo-bump precedent for Rust-CLI-backed actions in this repo. The
;; `:behavior` clause below is a second NOT-YET-MODELED shape (alongside
;; the tatara-script one named in the file header) — arch-synthesizer's
;; `ActionBehavior` also has no `rust-binary-crate-install` variant yet.

(defaction "sui-dockerfile-node-cache"
  :description "Daemon-aware sui-dockerfile-wrapper GHA integration point (supa-charge-akeyless-ci Phase 3b): probes the node-local sui-dockerfile-node-cache-daemon Unix socket, routes through DaemonAwareCacheClient when present, falls through cleanly to the direct-to-remote-tier Phase 2 wrapper when absent."
  :inputs  ((:name "dockerfile-path"        :type :string :required t)
            (:name "build-context"          :type :string :required nil :default ".")
            (:name "image-tag"              :type :string :required t)
            (:name "cache-backend-config"   :type :string :required t)
            (:name "node-cache-socket-path" :type :string :required nil :default ""))
  :outputs ((:name "daemon-used") (:name "outcome") (:name "cache-hit")
            (:name "docker-ran") (:name "duration-ms"))
  :behavior      (:runtime :rust-binary-crate-install :crate "sui-dockerfile-wrapper" :bin "gha-entrypoint")
  :semver-compat :minor
  :attestation   :required)

;; ── private-Zot delivery + multi-arch manifest + FedRAMP attest leg ──
;; The three verbs below are authored as CO-LOCATED defactions (each
;; ships its own <name>/defaction.lisp with the same tier-honest header),
;; matching the tameshi-attest / super-cache-build precedent — a
;; duplicated row here would be the exact drift CATALOG-REFLECTION
;; forbids. This is the POINTER (not a copy) so a reader of the seed
;; finds them; folding both the co-located entries and this seed into the
;; canonical repo-forge/pleme-actions-catalog is the shared TataraScript
;; `ActionBehavior`-variant LiveTODO named in every header:
;;
;;   zot-push            → zot-push/defaction.lisp
;;     push a nix OCI tarball to the PRIVATE in-cluster Zot under the
;;     AUTOBUMP exact tag <arch>-r<run>-<sha>; report the pushed digest.
;;     (Sibling of ghcr-publish; FedRAMP images NEVER go to ghcr.io.)
;;   manifest-list-join  → manifest-list-join/defaction.lisp
;;     compose per-arch digests into ONE multi-arch OCI index at
;;     r<run>-<sha>; report the index digest (the exact deploy coord).
;;   cartorio-attest     → cartorio-attest/defaction.lisp
;;     the FedRAMP three-pillar receipt: BLAKE3 chain link + Nix-closure
;;     SBOM (CycloneDX) + SLSA v1.0 provenance. Sibling of tameshi-attest
;;     (the build receipt), sharing the BLAKE3 core (stdlib hash:*).

;; ── per-package materializability gate leg (the cheap pre-derive gate) ──
;; Also a CO-LOCATED defaction (ships its own ferrite-check/defaction.lisp
;; with the same tier-honest header) — POINTER not copy, per the block
;; above:
;;
;;   ferrite-check       → ferrite-check/defaction.lisp
;;     for ONE package (a flake image attr) verify it is MATERIALIZABLE (the
;;     attr resolves to a derivation via a cheap `nix eval`, NOT a derive)
;;     BEFORE the expensive build, content-address its SOURCE (the output
;;     store-path), and emit a PoMS — a Proof-of-Materialization-Spec
;;     receipt (schema pleme-io.ferrite.materialization-spec/v1) — cached by
;;     that source hash so a re-run over unchanged source is a pure cache
;;     HIT (skip re-eval + derive). Single-responsibility sibling of
;;     build-matrix (the (svc,arch) fan) + gen-build-spec (the spec
;;     freshness gate); it gates one fan cell. Sibling of tameshi-attest /
;;     cartorio-attest on ONE chain (carries chain.prev, shares the BLAKE3
;;     core stdlib hash:*).
