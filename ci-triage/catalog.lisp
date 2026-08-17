;; ci-triage/catalog.lisp — the typed fleet CI failure-signature catalog.
;;
;; ONE ROW PER CAUSE CLASS. A new failure is a catalog ROW, not a fresh
;; investigation. This file exists because the investigation was re-done by
;; hand four times in a single session (2026-08-17) — observe, normalize the
;; signature, bucket it, pick a remedy — and every re-derivation started from
;; zero because nothing durable recorded the previous one.
;;
;; ── THE LOAD-BEARING RULE ────────────────────────────────────────────────
;; MATCH ON `:signature` (a line from the LOG). NEVER on the step name.
;;
;; A step name is untrusted metadata: it names what the step MEANT to do, not
;; what failed. Receipt, measured 2026-08-17 on pleme-hotswap-derive: a step
;; named `cargo fmt --check (inside .#default)` failed with
;;   error: Dependency is not of a valid type: element 6 of buildInputs
;; — the devShell could not be ENTERED and rustfmt never ran. The fmt step is
;; merely the FIRST step that enters the devShell, so a broken shell is
;; reported under a formatting name. Two `cargo fmt` sweeps were spent on that
;; misreading before the real cause (substrate splicing a `flake = false`
;; source tree into buildInputs) was found. `:step` below is recorded for
;; grouping and reporting ONLY, and is explicitly not evidence of a cause.
;;
;; ── THE SECOND RULE ─────────────────────────────────────────────────────
;; An unmatched signature is reported as `unclassified`, never folded into the
;; nearest-looking row. Folding is precisely how the misdiagnosis above was
;; manufactured. Same discipline as ★★ kotae: `found` / `empty` / `refused` /
;; `blind` must not render as the same bytes.
;;
;; ── ONE STEP CAN CARRY TWO CAUSES ───────────────────────────────────────
;; `cargo fmt --check` appears TWICE below with different signatures and
;; different remedies. Any consumer that assumes step→cause is a function is
;; wrong; the relation is one-to-many in both directions.
;;
;; ── DENOMINATOR + DATE, per the fleet's dated-claim rule ────────────────
;; Every `:seen` count below is from ONE sweep: 2026-08-17, failures created
;; after 2026-08-10, over all 399 non-archived pleme-io repos.
;; Corpus: 534 failed runs / 764 failing steps / 188 repos.
;; A count here is a SNAPSHOT and rots downward — re-measure, never infer.
;;
;; `:verified` is the honest half and is per-row:
;;   :log-read   — a human/agent read the actual failing log for this class
;;   :step-only  — grouped by step name; the cause is INFERRED, not read
;; Never promote :step-only to :log-read without reading a log.

(defcatalog ci-triage
  :sweep {:date "2026-08-17"
          :window-from "2026-08-10"
          :repos-scanned 399
          :failed-runs 534
          :failing-steps 764
          :repos-with-failures 188}

  :rows
  [
   {:id :syft-install-not-writable
    :step "Run pleme-io/actions/sbom-generate@main"
    :signature "install: cannot create regular file '/usr/local/bin/syft': Permission denied"
    :seen 130
    :verified :log-read
    :cause "The action installed syft to /usr/local/bin, which needs root; the
            fleet's self-hosted ARC runners are not root, so the step failed
            before syft ran."
    :remedy "Install to $RUNNER_TEMP/bin + $GITHUB_PATH. FIXED in actions@e055bee."
    :tier "only-mitigated — still a job-time third-party install, and
           ./sbom-generate/action.yml stays a runtime-install-lint baseline
           entry. Graduating to a pre-baked hardened image is still owed."
    :note "Largest single class in the sweep. The cause is :log-read on ONE
           run (caixa-tempfile 32004168602); the other 129 are grouped by step
           name and NOT individually confirmed."}

   {:id :caixa-workspace-member-not-cargoable
    :step "Run pleme-io/actions/security-audit@main"
    :signature "error inheriting `lints` from workspace root manifest's `workspace.lints`"
    :seen 24
    :verified :log-read
    :cause "A crate absorbed as :rust-single-crate out of an upstream workspace
            keeps `[lints] workspace = true` with no `[workspace]` root, so
            cargo cannot parse the manifest at all."
    :remedy "NOT a manifest patch — deleting the inherited keys only moves the
             failure to `cargo update` on the missing siblings. Re-absorb the
             upstream WORKSPACE as one rust-workspace caixa. Creation of new
             instances is refused at source by pleme-doc-gen@3062bee."
    :tier "parse-time-rejected for NEW instances; the 24 existing repos are
           unfixed and need re-absorption."
    :note "See docs/caixa-absorption-granularity.md."}

   {:id :devshell-invalid-builtinput
    :step "cargo fmt --check (inside .#default)"
    :signature "Dependency is not of a valid type: element 6 of buildInputs for nix-shell"
    :seen 1
    :verified :log-read
    :cause "substrate's rust-library.nix spliced its crate2nix INPUT (declared
            `flake = false`, i.e. a bare source tree) into the devShell's
            buildInputs, so the devShell failed to EVALUATE."
    :remedy "pkgs.crate2nix instead of the source tree. FIXED in
             substrate@ef29009; consumers need a substrate lock bump to receive
             it (pleme-hotswap-derive@6d0fa81 did)."
    :tier "fixed at the shared layer — every rust-library consumer on the
           non-devenv path inherits it on their next lock bump."
    :note "THE canonical example of why this catalog matches on signature and
           not on step name. Read the header."}

   {:id :genuine-rustfmt-drift
    :step "cargo fmt --check (inside .#default)"
    :signature "Diff in .*\\.rs:[0-9]+"
    :seen 24
    :verified :log-read
    :cause "Committed source genuinely does not match rustfmt output."
    :remedy "`cargo fmt`. Confirmed to turn a whole run green: frost's ci went
             success after exactly this."
    :tier "only-mitigated — the gate catches drift; nothing prevents it. A
           pre-commit fmt gate would make it unrepresentable."
    :note "Same step as :devshell-invalid-builtinput, different cause and a
           different remedy. Do not treat step→cause as a function."}

   {:id :conflict-markers-in-lockfile
    :step "Run pleme-io/actions/nix-build@*"
    :signature "Could not parse '.*flake.lock': \\[json.exception.parse_error"
    :seen 21
    :verified :log-read
    :cause "Unresolved git merge-conflict markers committed into flake.lock —
            twice in three days on pleme-io/nix, from concurrent agent sessions
            sharing one checkout and therefore one git INDEX."
    :remedy "Resolve + recommit. Recurrence is now blocked at the commit
             boundary by blackmatter@3f5e0eb's pre-commit gate; `tend worktree
             session` is the isolation fix for the root cause."
    :tier "only-mitigated — a local hook, --no-verify bypasses it."
    :note "A corrupt flake.lock is fleet-scope: a flake with a dirty tree
           evaluates the WORKING-TREE lock, so `nix run .#rebuild` throws for
           everyone until it is reverted."}

   {:id :magic-nix-cache-unusable-on-runner
    :step "Run DeterminateSystems/magic-nix-cache-action@main"
    :signature "xz: not found"
    :seen 27
    :verified :log-read
    :cause "A third-party job-time Nix bootstrap that the ARC runner image does
            not satisfy — missing xz, no nix daemon socket, stack hard limit
            below what it wants. Pinned to @main, i.e. unpinned."
    :remedy "Bake the build environment into the runner image per
             NIX-HARDENING §VI rather than installing it per job. Tracked debt:
             runtime-install-lint's baseline (68 entries)."
    :tier "unfixed — this is the graduation campaign, not a patch."
    :note "The daemon-socket line ALSO appears inside a non-fatal
           `WARN SelfTest(...)` blob in unrelated jobs. Counting that string
           fleet-wide over-counts this class ~5x; match the step too."}

   {:id :gem-bump-app-absent
    :step "Run pleme-io/actions/substrate-bump@main"
    :signature "does not provide attribute 'apps\\..*\\.gem:bump'"
    :seen 20
    :verified :log-read
    :cause "substrate-bump detected the repo as a gem (a *.gemspec is present)
            and ran `nix run .#gem:bump`, which the flake does not expose."
    :remedy "UNDIAGNOSED beyond the symptom: either the detector is wrong for
             these repos or the flake is missing the app. Classify before
             fixing — do not add the app reflexively."
    :tier "unfixed."}

   {:id :flake-exposes-no-rootcrate
    :step "Run pleme-io/actions/nix-flake-check@main"
    :signature "attribute '(packages|rootCrate)' missing"
    :seen 10
    :verified :log-read
    :cause "UNDIAGNOSED. Surfaces during `nix flake check` against a
            crate2nix-generated Cargo.nix."
    :remedy "Unknown. Likely shared across consumers — a candidate for the next
             shared-layer fix."
    :tier "unfixed."}

   ;; ── :step-only rows — grouped by step, cause NOT read. Listed so the
   ;; corpus adds up and the unexamined remainder is VISIBLE rather than
   ;; silently dropped. Each needs a log read before it earns a remedy.
   {:id :unexamined-security-audit-remainder
    :step "Run pleme-io/actions/security-audit@main"
    :seen 140
    :verified :step-only
    :cause "UNKNOWN. 164 security-audit failures minus the 24 attributed to
            :caixa-workspace-member-not-cargoable. Known to contain at least
            one genuine advisory hit (caixa-rand: 'severity high >= fail-on
            threshold high'), so this bucket is certainly NOT one cause."
    :remedy "Read logs and split into real rows."
    :tier "unexamined — the single largest gap in this catalog."}

   {:id :unexamined-publish-family
    :step "cargo-bump | cargo-publish-crate | rust-workspace-publish | cargo-publish-each-member"
    :seen 104
    :verified :step-only
    :cause "UNKNOWN. Some are known shapes from earlier reads (a caixa manifest
            parse reaching cargo-bump; 'package.name not found in Cargo.toml';
            'unclassified cargo publish failure') but the split is unmeasured."
    :remedy "Read logs and split."
    :tier "unexamined."}

   {:id :unexamined-remainder
    :step "(various: license-header-check 19, zot-pull-scan 14, test gates 23,
            iac-forge 11, 'Repair and commit' 11, helm-unittest 8, cargo check
            7, cargo audit 6, unnamed job-level 78, …)"
    :seen 263
    :verified :step-only
    :cause "UNKNOWN. Includes an 86-step long tail below the top-22 steps, and
            78 failures with NO step name at all (job-level: setup, runner
            assignment, or cancellation) — that 78 is its own likely class and
            is the cheapest next thing to read."
    :remedy "Read logs and split."
    :tier "unexamined."}
  ])

;; ── COVERAGE, stated so it cannot be over-read ───────────────────────────
;; Rows with :verified :log-read account for 257 of 764 failing steps (34%).
;; The remaining 507 are :step-only — grouped, not diagnosed. This catalog is
;; therefore a THIRD of the way to explaining the fleet's CI failures, and the
;; three :unexamined- rows exist so that number is impossible to mistake for
;; full coverage. The largest gap is the 140 unattributed security-audit
;; failures.
