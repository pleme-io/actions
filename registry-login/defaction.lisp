;; registry-login/defaction.lisp — the typed catalog entry for the OCI
;; registry-login overlay. Field vocabulary mirrors arch-synthesizer's
;; typed `Action` domain (arch-synthesizer/src/action_domain/mod.rs) and
;; the sibling co-located defactions (zot-push / ghcr-publish / skopeo-login).
;;
;; ── TIER-HONEST placement note ──────────────────────────────────────
;; Co-located with the action (self-contained), matching the
;; zot-push / gen-build-spec / breathe-runner precedent. Like those, this
;; is a tatara-script (run.tlisp) action; the shipped Rust `ActionBehavior`
;; models only Rust-crate actions, so admitting a tatara-script action into
;; arch-synthesizer's `Action` proofs needs a `TataraScript` behaviour
;; variant (a Rust change, a NAMED LiveTODO). The `:behavior` clause names
;; the tatara-script runtime + its run.tlisp explicitly and is NOT claimed
;; to parse into the shipped Rust struct.
;;
;; WHY THIS EXISTS: the token-resolution priority (BOT_PAT > GHCR_TOKEN >
;; GITHUB_TOKEN) was hand-repeated as a `||` expression in every publish
;; reusable (helm-monorepo-auto-release.yml / image-push.yml /
;; nix-image-auto-release.yml). Per the org directive "instead of || do
;; overlays of yaml" + the PRIME DIRECTIVE (duplication is a bug), the
;; priority lives here once and each reusable overlays it with one `uses:`.

(defaction "registry-login"
  :description "Resolve an OCI-registry credential from the typed fallback (BOT_PAT > GHCR_TOKEN > GITHUB_TOKEN) and log the chosen client (helm | docker) into the registry. The single overlay every publish reusable calls in place of a hand-repeated `secrets.BOT_PAT || secrets.GHCR_TOKEN || ...` expression. BOT_PAT carries write:packages on the org-shared ghcr.io/pleme-io/* namespace (a repo-scoped GITHUB_TOKEN 403s on cross-namespace push); on the Free plan it reaches public repos only, so a private caller passes it empty and the fallback lands on GITHUB_TOKEN — the two approved tracks, expressed once. The product is the login SIDE-EFFECT on the runner's credential store, which the caller's publish step consumes."
  :inputs  ((:name "registry"     :type :string :required t)
            (:name "client"       :type :string :required nil :default "docker")
            (:name "username"     :type :string :required t)
            (:name "bot-pat"      :type :string :required nil :default "")
            (:name "ghcr-token"   :type :string :required nil :default "")
            (:name "github-token" :type :string :required nil :default ""))
  :outputs ((:name "logged-in"))
  :behavior      (:runtime :tatara-script :run-tlisp "registry-login/run.tlisp")
  :semver-compat :minor
  :attestation   :required)
