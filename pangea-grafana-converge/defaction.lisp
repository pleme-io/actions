;; pangea-grafana-converge/defaction.lisp — the typed catalog entry for
;; the MODEL-2 (remote-reconcile) FedRAMP observability executor. Field
;; vocabulary mirrors arch-synthesizer's typed `Action` domain
;; (arch-synthesizer/src/action_domain/mod.rs).
;;
;; ── TIER-HONEST placement note ──────────────────────────────────────
;; Co-located with the action (self-contained), matching the
;; tameshi-attest / cartorio-attest / attestation-gate defaction.lisp
;; precedent. These are tatara-script (run.tlisp) actions and the shipped
;; `ActionBehavior` models only Rust-crate actions, so folding this entry
;; into arch-synthesizer's `Action` domain needs a `TataraScript`
;; `ActionBehavior` variant (a Rust change, out of this coordination
;; slice). The `:behavior` clause names the tatara-script runtime + its
;; run.tlisp explicitly and is NOT claimed to parse into the shipped Rust
;; struct — a NAMED LiveTODO.

(defaction "pangea-grafana-converge"
  :description "MODEL-2 remote-reconcile FedRAMP observability executor: health-probe a remote (inbound-only, scoped-SA-token) Grafana REST endpoint, then drive the shipped pangea rio-observability workspace + deployment-agnostic pangea-grafana provider + magma runner against it — converging 2F Grafana from our side (same Pangea AST → same CRs → same provider code → same fixpoint as Model 1; only executor residency moves). No new provider code — a typed shim over `nix run` of the shipped workspace. Reports the runner's real status; the exact flake app attr + the thinner alert remote-apply leg are named LiveTODOs, never faked."
  :inputs  ((:name "grafana-url"     :type :string :required #t)
            (:name "grafana-token"   :type :string :required #t :sensitive #t)
            (:name "workspace"       :type :string :required nil :default "github:pleme-io/pangea-architectures")
            (:name "app"             :type :string :required nil :default "rio-observability-converge")
            (:name "converge-cmd"    :type :string :required nil :default "")
            (:name "provider"        :type :string :required nil :default "grafana")
            (:name "dry-run"         :type :string :required nil :default "false")
            (:name "require-healthy" :type :string :required nil :default "true")
            (:name "model"           :type :string :required nil :default "2"))
  :outputs ((:name "healthy") (:name "converged") (:name "reason")
            (:name "dry-run") (:name "model"))
  :behavior      (:runtime :tatara-script :run-tlisp "pangea-grafana-converge/run.tlisp")
  :semver-compat :minor
  :attestation   :optional)
