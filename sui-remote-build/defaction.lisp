;; sui-remote-build/defaction.lisp — the typed catalog entry for the
;; BUILD-job remote-execution verb: dispatch a derivation to a REAPI
;; (Remote Execution API) spot worker over the sui daemon; on no worker,
;; fall back to the correct local daemon-node build. Field vocabulary
;; mirrors arch-synthesizer's typed `Action` domain
;; (arch-synthesizer/src/action_domain/mod.rs) and the sibling seed
;; catalog (super-cache-ci-catalog.lisp).
;;
;; ── TIER-HONEST placement note ──────────────────────────────────────
;; Co-located with the action rather than folded into the sibling
;; super-cache-ci-catalog.lisp only, because that file is edited in the
;; same commit — a git-least-disturbance choice, not a permanent home.
;; Folding this entry into the suite seed catalog + wiring it into
;; arch-synthesizer's `Action` domain proofs is the SHARED, suite-wide
;; LiveTODO: these are tatara-script (run.tlisp) actions and the shipped
;; `ActionBehavior` models only Rust-crate actions, so admitting a
;; tatara-script action needs a `TataraScript` `ActionBehavior` variant
;; (a Rust change, out of this coordination slice). The `:behavior`
;; clause names the tatara-script runtime + its run.tlisp explicitly and
;; is NOT claimed to parse into the shipped Rust struct.
;;
;; ── DEGRADED-UNTIL-STORE ────────────────────────────────────────────
;; The remote path (worker=reapi) is DOUBLY gated: (a) the REAPI worker
;; binary is UNWIRED, and (b) it rides the same keystone
;; `TieredBackend = RedisBackend(L1)→PgStore(L2)→S3Storage(L3)` behind
;; sui's SHIPPED `Store`/`StorageBackend` traits. Until both land, the
;; verb GRACEFULLY FALLS BACK to a correct local daemon-node build
;; (worker=local) — which delegates to super-cache-build's derive core,
;; itself a named LiveTODO (no sui-graph build CLI; sui-daemon-client is
;; a library). So today: worker=local, built=false, reason=
;; local-fallback-derive-livetodo, NEVER a faked build; require-build=true
;; turns the fallback LiveTODO into a loud exit 1.

(defaction "sui-remote-build"
  :description "BUILD-job remote-execution verb: dispatch a derivation to a REAPI spot worker over the sui daemon (RAM eval, tmpfs sandbox, DB store), keyed by the gen build-spec. DEGRADED-UNTIL-STORE: the REAPI worker binary + TieredBackend are a named LiveTODO; gracefully falls back to the correct local daemon-node build (worker=local, built=false honest — super-cache-build's derive core is itself unshipped), never a faked build."
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
