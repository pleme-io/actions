;; sui-warm-hydrate/defaction.lisp — the typed catalog entry for the
;; GRAPH-job warm verb: pre-load the sui daemon's tiered super-cache with
;; the fan-out's content keys BEFORE the build matrix explodes, so every
;; parallel build job starts warm. Field vocabulary mirrors
;; arch-synthesizer's typed `Action` domain
;; (arch-synthesizer/src/action_domain/mod.rs) and the sibling seed
;; catalog (super-cache-ci-catalog.lisp).
;;
;; ── TIER-HONEST placement note ──────────────────────────────────────
;; Co-located with the action (self-contained) rather than folded into
;; the sibling super-cache-ci-catalog.lisp only, because that file is
;; edited in the same commit — a git-least-disturbance choice, not a
;; permanent home. Folding this entry into the suite seed catalog +
;; wiring it into arch-synthesizer's `Action` domain proofs is the
;; SHARED, suite-wide LiveTODO: these are tatara-script (run.tlisp)
;; actions and the shipped `ActionBehavior` models only Rust-crate
;; actions, so admitting a tatara-script action needs a `TataraScript`
;; `ActionBehavior` variant (a Rust change, out of this coordination
;; slice). The `:behavior` clause names the tatara-script runtime + its
;; run.tlisp explicitly and is NOT claimed to parse into the shipped
;; Rust struct.
;;
;; ── DEGRADED-UNTIL-STORE ────────────────────────────────────────────
;; This verb's fast behavior (pre-load Redis L1 / Postgres L2 for the
;; fan-out keys via a daemon warm-set RPC) is gated on the keystone
;; `TieredBackend = RedisBackend(L1)→PgStore(L2)→S3Storage(L3)` behind
;; sui's SHIPPED `Store` + `StorageBackend` traits, plus a daemon
;; warm-set RPC surface. Until that lands, the verb is an HONEST NO-OP:
;; it resolves + counts the requested keys, reports `warmed=false`
;; `warm-count=0` `reason=store-absent-degraded`, and NEVER fakes a warm
;; hit. `require-warm=true` turns the degrade into a loud exit 1.

(defaction "sui-warm-hydrate"
  :description "GRAPH-job warm verb: pre-load the sui daemon's tiered super-cache (Redis L1 -> Postgres L2 -> object L3) with the fan-out's content keys BEFORE the build matrix explodes, so every parallel job starts warm. DEGRADED-UNTIL-STORE: the warm-set RPC + TieredBackend are a named LiveTODO; today an honest no-op (warmed=false, never a faked warm), never a rounded-up hit."
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
