# pleme-io action catalog — 193 typed primitives

> The typed CI/CD vocabulary that powers the pleme-io fleet.
> **All actions auto-publish to free public GitHub-hosted compute.**

## Quickstart — adopt the directive in 6 lines

```yaml
# .github/workflows/auto-release.yml
on:
  push: { branches: [main] }
jobs:
  release:
    uses: pleme-io/substrate/.github/workflows/auto-release.yml@main
    secrets: inherit
```

## Operator-facing CLI

```bash
cargo install pleme-io-releaser
pleme-release detect / plan / onboard
```

## Discovery

```bash
nix eval --raw github:pleme-io/substrate#lib.aarch64-darwin.release.patterns
```

## The 193-primitive vocabulary


### `akeyless` — 5 primitive(s)

> 🔑 Akeyless secret management

- [`akeyless-auth`](./akeyless-auth/) — Akeyless login via access-id + (access-key | SAML | JWT). Exports AKEYLESS_TOKEN to subsequent steps so siblings (secret-fetch / rotate / etc) can reuse.
- [`akeyless-export-config`](./akeyless-export-config/) — Export an Akeyless gateway config snapshot (auth methods + roles + items) for audit / diff / backup.
- [`akeyless-injector-validate`](./akeyless-injector-validate/) — Validate Akeyless sidecar injector annotations on a set of k8s manifests. Sanity-check that secret references point at valid Akeyless paths before applying.
- [`akeyless-rotate`](./akeyless-rotate/) — Rotate a rotated-secret in Akeyless. Reads $AKEYLESS_TOKEN.
- [`akeyless-secret-fetch`](./akeyless-secret-fetch/) — Fetch a static / dynamic / rotated secret from Akeyless. Reads $AKEYLESS_TOKEN (set by akeyless-auth) — operator typically invokes akeyless-auth in a prior step.

### `ansible` — 2 primitive(s)

> 🅰️ Ansible Collection

- [`ansible-collection-build`](./ansible-collection-build/) — Build an Ansible collection tarball via substrate flake (nix run .#build)
- [`ansible-collection-publish`](./ansible-collection-publish/) — Publish an Ansible collection to Galaxy via substrate flake (nix run .#publish)

### `backup` — 1 primitive(s)

> 🛡️ Backup — restic

- [`restic-backup`](./restic-backup/) — Run a restic backup to any supported repo (s3/b2/sftp/etc).

### `build` — 1 primitive(s)

> 🔨 Build — cross-compile / OCI / Ansible

- [`rust-cross-build`](./rust-cross-build/) — cargo build --release for a target, stage binary + sha256 into ./dist

### `bump` — 2 primitive(s)

> ⬆️ Version bumping

- [`rust-workspace-bump`](./rust-workspace-bump/) — Bump a Rust workspace.package.version via `cargo set-version --workspace --bump <type>`, regen Cargo.nix, commit + tag locally. No shell — composes existing rust + tatara-script + git primitives.
- [`substrate-bump`](./substrate-bump/) — Bump version using substrate flake `bump` app (nix run .#bump -- <type>)

### `caixa` — 4 primitive(s)

> 📦 caixa — canonical SDLC primitive

- [`caixa-bump`](./caixa-bump/) — Bump the :version field inside a (defcaixa ...) form. Sibling of cargo-bump / npm-bump for the tatara-lisp + caixa SDLC primitive.
- [`caixa-publish`](./caixa-publish/) — Publish caixa-rendered Helm chart to an OCI registry. Wraps helm-publish but consumes the caixa-render output dir.
- [`caixa-render`](./caixa-render/) — Render cluster artifacts (Helm chart + Kubernetes manifests + Flux + CI workflows) from a (defcaixa ...) form via the `feira` CLI.
- [`caixa-render-pr`](./caixa-render-pr/) — Render every .caixa.lisp at the repo root via pleme-doc-gen + open a PR if the rendered artifacts drift from on-disk files. The META-PRIMITIVE that closes the typed-source → mechanical-render → PR loop without operator intervention.

### `cloud` — 14 primitive(s)

> ☁️ Cloud providers

- [`aws-assume-role`](./aws-assume-role/) — Assume an AWS IAM role via OIDC (no long-lived creds). Exports AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY + AWS_SESSION_TOKEN to subsequent steps.
- [`aws-s3-upload`](./aws-s3-upload/) — Upload a file or directory to S3. Pairs with aws-assume-role for IAM. Useful for build-artifact ship, backup, SBOM archive, etc.
- [`azure-deploy`](./azure-deploy/) — Deploy via Azure CLI (az deployment group create).
- [`cloudflare-pages-deploy`](./cloudflare-pages-deploy/) — Deploy a static build dir to Cloudflare Pages via wrangler. Universal — works with any output dir (Vite, mkdocs, cargo doc, hand-built static).
- [`cloudflare-r2-upload`](./cloudflare-r2-upload/) — Upload a file or directory to Cloudflare R2 via wrangler r2 object put. S3-compatible alternative.
- [`cloudflare-worker-deploy`](./cloudflare-worker-deploy/) — Deploy a Cloudflare Worker via wrangler. Reads wrangler.toml at repo root or at the given path.
- [`doctl-deploy`](./doctl-deploy/) — Deploy a DigitalOcean App Platform app.
- [`fly-deploy`](./fly-deploy/) — Deploy a Fly.io app via flyctl. Uses fly.toml at repo root; honors $FLY_API_TOKEN env var.
- [`gcp-auth`](./gcp-auth/) — GCP Workload Identity Federation login (no service-account JSON key). Exports GOOGLE_APPLICATION_CREDENTIALS to subsequent steps.
- [`heroku-deploy`](./heroku-deploy/) — Deploy via git push heroku main.
- [`netlify-deploy`](./netlify-deploy/) — Deploy to Netlify via netlify CLI.
- [`railway-up`](./railway-up/) — Deploy via railway up.
- [`render-deploy`](./render-deploy/) — Trigger a Render service deploy via API.
- [`vercel-deploy`](./vercel-deploy/) — Deploy to Vercel via vercel CLI.

### `comms` — 9 primitive(s)

> 💬 Notifications across N channels

- [`discord-notify`](./discord-notify/) — Post a typed release event to a Discord webhook. Sibling of slack-notify.
- [`email-notify`](./email-notify/) — Send a plain-text email via SMTP. Sibling of slack-notify / discord-notify for ops contexts where webhooks aren''t available.
- [`matrix-notify`](./matrix-notify/) — Send a message to a Matrix room via the appservice REST API.
- [`mattermost-notify`](./mattermost-notify/) — POST to a Mattermost webhook.
- [`pagerduty-notify`](./pagerduty-notify/) — Trigger / resolve a PagerDuty incident via the Events API v2. Useful for CI-driven on-call paging.
- [`slack-notify`](./slack-notify/) — Post a typed release event to a Slack webhook. Universal — works for any release flow that wants typed notifications.
- [`teams-notify`](./teams-notify/) — Post an adaptive card to a Microsoft Teams incoming webhook.
- [`telegram-notify`](./telegram-notify/) — Send a message to a Telegram chat via bot API.
- [`twilio-sms`](./twilio-sms/) — Send an SMS via Twilio.

### `container` — 8 primitive(s)

> 🐋 Container build (Docker / ko / buildah / podman)

- [`buildah-build`](./buildah-build/) — Build an OCI image with buildah (rootless alternative).
- [`buildkit-cache-warm`](./buildkit-cache-warm/) — Pre-warm buildkit''s registry-mounted layer cache for an image. Useful for cold-start CD runners or fan-out builds.
- [`crane-mutate`](./crane-mutate/) — Mutate an OCI image's labels/tags via crane.
- [`docker-build-and-push`](./docker-build-and-push/) — Multi-arch docker buildx build + push to ghcr.io (or any OCI registry). Universal — works on any Dockerfile-bearing repo.
- [`ko-build`](./ko-build/) — Containerless Go image build + push via ko. No Dockerfile required.
- [`oci-image-push`](./oci-image-push/) — Push an OCI image tarball (Nix dockerTools output) to a registry — skopeo fallback
- [`podman-build`](./podman-build/) — Build a container image with podman (rootless, daemonless alternative to docker).
- [`skopeo-copy`](./skopeo-copy/) — Copy an OCI image between registries via skopeo copy.

### `data` — 2 primitive(s)

> 📋 Data validation

- [`json-schema-check`](./json-schema-check/) — Validate JSON files against JSON Schema.
- [`yaml-lint`](./yaml-lint/) — Run yamllint on yaml files.

### `db` — 6 primitive(s)

> 🗄️ Database — migrations + backups

- [`atlas-migrate`](./atlas-migrate/) — Apply schema migrations via Atlas.
- [`db-backup`](./db-backup/) — Dump a database to a backup artifact. PostgreSQL via pg_dump, MySQL via mysqldump.
- [`db-migrate`](./db-migrate/) — Polymorphic DB migration — sqlx-migrate / alembic / knex / etc by detect.
- [`flyway-migrate`](./flyway-migrate/) — Run flyway migrate.
- [`prisma-migrate`](./prisma-migrate/) — Run prisma migrate deploy.
- [`sqitch-deploy`](./sqitch-deploy/) — Run sqitch deploy.

### `devx` — 2 primitive(s)

> 🛠️ Developer experience

- [`devcontainer-build`](./devcontainer-build/) — Build a devcontainer image via @devcontainers/cli.
- [`pre-commit-run`](./pre-commit-run/) — Run pre-commit on all files.

### `dispatch` — 2 primitive(s)

> 🚏 Repo-type dispatch

- [`caixa-detect`](./caixa-detect/) — Find caixa.tlisp (or any .tlisp file containing (defcaixa ...)) at repo root. Emits the file path + the caixa kind (Biblioteca | Binario | Servico | Supervisor | Aplicacao).
- [`detect-repo-type`](./detect-repo-type/) — Auto-detect the repo type from manifest file presence at the root. Emits a typed identifier (rust-workspace / rust-single-crate / npm / python / helm / ansible-collection / ruby-gem / github-action / unknown) that downstream jobs route on.

### `docs` — 10 primitive(s)

> 📚 Documentation generation + publishing

- [`api-spec-diff`](./api-spec-diff/) — Detect breaking changes in an OpenAPI / GraphQL / gRPC spec between base + head refs. Useful PR-time gate for API surface stability.
- [`changelog-generate`](./changelog-generate/) — Generate a CHANGELOG.md (or fragment) from git log since a base ref. Universal primitive — language-agnostic, used by every release flow that wants typed changelogs.
- [`docs-publish`](./docs-publish/) — Polymorphic doc generation + deploy to GitHub Pages. Detects repo type + routes to cargo doc / mkdocs / typedoc. The third compounding leg of the publish-side primitives (release + sbom + docs).
- [`docusaurus-build`](./docusaurus-build/) — Build a Docusaurus site.
- [`hugo-build`](./hugo-build/) — Build a Hugo site.
- [`mdbook-build`](./mdbook-build/) — Build an mdBook.
- [`mkdocs-build`](./mkdocs-build/) — Build mkdocs site.
- [`toc-update`](./toc-update/) — Auto-update markdown table-of-contents between <!-- toc --> markers. Idempotent — re-runs are no-op when TOC matches headings.
- [`vitepress-build`](./vitepress-build/) — Build a VitePress site.
- [`zola-build`](./zola-build/) — Build a Zola site.

### `frontend` — 5 primitive(s)

> 🖥️ Frontend testing + deployment

- [`cypress-test`](./cypress-test/) — Run cypress run.
- [`lighthouse-ci`](./lighthouse-ci/) — Run Lighthouse CI on a URL list + assert score thresholds.
- [`percy-snapshot`](./percy-snapshot/) — Capture Percy visual regression snapshots.
- [`playwright-test`](./playwright-test/) — Run @playwright/test suite.
- [`storybook-deploy`](./storybook-deploy/) — Build + deploy a Storybook to gh-pages.

### `gh` — 2 primitive(s)

> 🐙 GitHub API

- [`derive-version-from-tag`](./derive-version-from-tag/) — Strip leading "v" from a tag ref to derive a SemVer version string
- [`gh-release-create`](./gh-release-create/) — Create a GitHub Release for a tag with optional auto-generated notes + asset uploads. Universal primitive — any language, any package shape.

### `git` — 2 primitive(s)

> 📝 Git operations

- [`git-commit-tag`](./git-commit-tag/) — Configure github-actions bot identity, stage typed paths, commit with a typed message template, and create an annotated tag. Composes with git-push-with-token for the push half.
- [`git-push-with-token`](./git-push-with-token/) — Rewrite origin URL with the given token, push branch + tags so downstream workflows can be triggered

### `helm` — 3 primitive(s)

> ⛵ Helm — chart packaging + deployment

- [`helm-bump`](./helm-bump/) — Bump a Helm Chart.yaml version field via in-place yaml-edit. Sibling of cargo-bump for the Helm ecosystem.
- [`helm-oci-publish`](./helm-oci-publish/) — Lint, package, and push a Helm chart to an OCI registry
- [`helm-publish`](./helm-publish/) — Publish a Helm chart to an OCI registry (default ghcr.io/pleme-io/helm); skip if (name, version) already exists.

### `hygiene` — 4 primitive(s)

> 🧹 Repo hygiene

- [`branch-protect-sync`](./branch-protect-sync/) — Apply branch-protection rules from a JSON spec.
- [`codeowners-validate`](./codeowners-validate/) — Validate .github/CODEOWNERS against repo file tree (catch unowned paths).
- [`gh-team-sync`](./gh-team-sync/) — Sync GitHub team membership from a declarative YAML spec via gh api. Source-of-truth for org RBAC.
- [`stale-issue-bot`](./stale-issue-bot/) — Mark stale issues + close after threshold.

### `iac` — 4 primitive(s)

> 🏗️ IaC — Terraform / Pulumi

- [`iac-forge`](./iac-forge/) — Run iac-forge codegen against a spec + provider TOML
- [`pulumi-up`](./pulumi-up/) — Run pulumi up on a stack.
- [`terraform-apply`](./terraform-apply/) — Run terraform apply against a previously-generated plan file. Pairs with terraform-plan.
- [`terraform-plan`](./terraform-plan/) — Run terraform init + plan + emit plan file. Pairs with terraform-apply for the GitOps split-flow.

### `k8s` — 9 primitive(s)

> ☸️ Kubernetes — apply / deploy / reconcile / wait

- [`argocd-sync`](./argocd-sync/) — Trigger argocd app sync + wait for Healthy/Synced. Sibling of flux-reconcile.
- [`flux-reconcile`](./flux-reconcile/) — Trigger FluxCD reconcile on a HelmRelease / Kustomization / GitRepository / OCIRepository. Useful in CD pipelines that want to force-converge after a release lands.
- [`helm-deploy`](./helm-deploy/) — helm upgrade --install with --wait. Sibling of helm-publish — this is for in-cluster installation, not registry push.
- [`helmfile-apply`](./helmfile-apply/) — Run helmfile apply.
- [`k8s-rollout-wait`](./k8s-rollout-wait/) — Wait for a single k8s rollout to converge. Sibling of kubectl-apply (which applies + waits on detected resources); this targets a single named resource for finer-grained gating.
- [`kubectl-apply`](./kubectl-apply/) — Apply k8s manifests + wait for rollout. Universal — works with any kubectl-reachable cluster.
- [`kustomize-render`](./kustomize-render/) — kustomize build → emit rendered manifests. Optional in-place commit to a target branch for GitOps workflows.
- [`tanka-apply`](./tanka-apply/) — Run tk apply on a Tanka environment.
- [`velero-backup`](./velero-backup/) — Run velero backup create.

### `language` — 13 primitive(s)

> 🌐 Multi-language (Go/Java/.NET/Swift/Elixir/Zig/WASM)

- [`dotnet-publish`](./dotnet-publish/) — dotnet publish + push to NuGet.
- [`go-build`](./go-build/) — Build Go binaries with go build.
- [`go-test`](./go-test/) — Run go test with coverage.
- [`golangci-lint`](./golangci-lint/) — Run golangci-lint with configurable preset.
- [`goreleaser`](./goreleaser/) — Run goreleaser to publish Go binaries to GH Releases.
- [`gradle-build`](./gradle-build/) — Build a Gradle project (Java/Kotlin/Scala).
- [`hex-publish`](./hex-publish/) — Publish an Elixir package to hex.pm.
- [`maven-build`](./maven-build/) — Build a Maven project.
- [`mix-test`](./mix-test/) — Run mix test on an Elixir project.
- [`swift-build`](./swift-build/) — Run swift build on a Swift package.
- [`wasm-build`](./wasm-build/) — Build a Rust crate to wasm32 (wasm32-unknown-unknown / wasm32-wasi). Universal — wraps cargo + wasm-pack when needed.
- [`xcodebuild`](./xcodebuild/) — Build an Xcode project/workspace.
- [`zig-test`](./zig-test/) — Run zig build test.

### `messaging` — 2 primitive(s)

> 📡 Message brokers — NATS / Kafka

- [`kafka-publish`](./kafka-publish/) — Publish a message to a Kafka topic via kcat.
- [`nats-publish`](./nats-publish/) — Publish a message to a NATS subject via natscli.

### `meta` — 3 primitive(s)

> 🪞 Meta — directive enforcement + audit + renderer

- [`action-shell-lint`](./action-shell-lint/) — Enforce the ★★ NO-SHELL directive on pleme-io/actions/* — scans every action.yml + counts shell-line bodies outside the canonical loader; rejects PRs that exceed threshold.
- [`adoption-audit`](./adoption-audit/) — Scan a GH org for AUTO-RELEASE directive adoption — counts repos with/without the canonical 3-workflow surface. Emits a markdown report + sets typed outputs. Runs cheap on free public CI.
- [`defaction-render`](./defaction-render/) — Render a typed (defaction ...) or (defworkflow ...) .lisp source into the action triple (action.yml + run.tlisp + README.md) or workflow yaml. The Pillar 12 (generation over composition) primitive at the CI layer.

### `mobile` — 4 primitive(s)

> 📱 Mobile — Fastlane / App Store / EAS / Flutter

- [`app-store-connect`](./app-store-connect/) — Upload an iOS build to App Store Connect via altool.
- [`eas-build`](./eas-build/) — Run expo eas build for iOS/Android.
- [`fastlane-deploy`](./fastlane-deploy/) — Run a fastlane lane to deploy iOS/Android build.
- [`flutter-build`](./flutter-build/) — Build a Flutter app for a target.

### `networking` — 2 primitive(s)

> 🌐 Networking — WireGuard / Tailscale

- [`tailscale-auth`](./tailscale-auth/) — Authenticate runner with Tailscale via OAuth or auth-key.
- [`wireguard-up`](./wireguard-up/) — Bring up a WireGuard tunnel for ephemeral runner access.

### `nix` — 3 primitive(s)

> ❄️ Nix — build / cache push

- [`nix-attic-push`](./nix-attic-push/) — Push a built nix path to an Attic binary cache.
- [`nix-build`](./nix-build/) — Build a flake output (universal). Optionally pushes to cachix/attic afterward.
- [`nix-cachix-push`](./nix-cachix-push/) — Push a built nix path to a Cachix binary cache.

### `npm` — 2 primitive(s)

> 📦 npm ecosystem

- [`npm-bump`](./npm-bump/) — Bump an npm package.json version via `npm version --no-git-tag-version <type>`, refresh package-lock.json. Sibling of cargo-bump for the npm ecosystem.
- [`npm-publish`](./npm-publish/) — Publish an npm package to npmjs.org; skip if (name, version) already exists; auto-rename to @pleme-io/<original> on name conflict.

### `observability` — 8 primitive(s)

> 📊 Observability — markers / metrics / logs / profiles

- [`datadog-event`](./datadog-event/) — Post a typed event to Datadog Events API. Universal for release markers, deploy events, alert correlations.
- [`grafana-annotation`](./grafana-annotation/) — Create a Grafana annotation (release marker, deploy event, incident note). Visible on every dashboard that overlaps the time range.
- [`honeycomb-marker`](./honeycomb-marker/) — Add a Honeycomb marker (release/deploy correlation).
- [`loki-log-push`](./loki-log-push/) — Push a batch of log lines to a Loki ingester.
- [`otel-collector-deploy`](./otel-collector-deploy/) — Deploy an OpenTelemetry Collector config to a k8s ConfigMap.
- [`prometheus-push`](./prometheus-push/) — Push metrics to a Prometheus pushgateway. Useful for emitting deploy/release counters from CI.
- [`pyroscope-push`](./pyroscope-push/) — Push a profiling sample to a Pyroscope server.
- [`sentry-release`](./sentry-release/) — Create a Sentry release + associate commits.

### `publish` — 1 primitive(s)

> 📤 Registry publishing

- [`rust-workspace-publish`](./rust-workspace-publish/) — Ship every workspace member to the Rust registry in topological dependency order. Auto-renames any conflicting crate to pleme-io-<original> + commits the rename back to main + retries. Pure tlisp logic, no shell beyond install glue.

### `python` — 2 primitive(s)

> 🐍 Python ecosystem

- [`python-bump`](./python-bump/) — Bump a Python pyproject.toml version field via uv version --bump. Sibling of cargo-bump for the Python ecosystem.
- [`python-publish`](./python-publish/) — Publish a Python package to pypi.org via uv publish; skip if (name, version) already exists; sleep + retry on rate limit.

### `quality` — 4 primitive(s)

> ✅ Code quality — mutation / benchmark / SonarQube / accessibility

- [`benchmark-runner`](./benchmark-runner/) — Polymorphic benchmark runner — criterion for Rust, pytest-benchmark for Python. Pushes results to a benches branch for trend tracking.
- [`mutation-test`](./mutation-test/) — Polymorphic mutation testing — cargo-mutants for Rust, stryker for npm/python. Surface real test gaps the regular test-gate doesn''t catch.
- [`pa11y-ci`](./pa11y-ci/) — Run pa11y-ci accessibility scan.
- [`sonarqube-scan`](./sonarqube-scan/) — Run SonarQube/SonarCloud scan + push results.

### `release-mgmt` — 5 primitive(s)

> 📦 Release management — Changesets / semantic-release

- [`changesets`](./changesets/) — Run npm/changesets version + publish flow.
- [`release-please`](./release-please/) — Run google/release-please-action.
- [`release-promote`](./release-promote/) — Promote a built artifact between environments (dev → staging → prod). Re-tags an existing image/version rather than rebuilding — ensures bit-identical artifact at each stage.
- [`semantic-release`](./semantic-release/) — Run semantic-release (conventional-commits → version).
- [`yank-version`](./yank-version/) — Polymorphic yank/unpublish — cargo yank / npm deprecate / pip remove. Surgical rollback for a single bad version (does NOT delete previous versions).

### `ruby` — 1 primitive(s)

> 💎 Ruby gem

- [`gem-publish`](./gem-publish/) — Build & push a Ruby gem to RubyGems.org, tolerating identical-version re-pushes

### `runtime` — 1 primitive(s)

> ⚙️ Runtime — tatara-script

- [`tatara-script`](./tatara-script/) — Execute an embedded .tlisp source string with tatara-script (binary-first, cargo-install fallback)

### `rust` — 2 primitive(s)

> 🦀 Rust ecosystem

- [`cargo-bump`](./cargo-bump/) — Bump a single-crate Rust repo via cargo set-version --bump <type>, regenerate Cargo.nix, refresh Cargo.lock. Sibling of rust-workspace-bump for non-workspace Rust repos.
- [`cargo-publish-crate`](./cargo-publish-crate/) — Publish a single Rust crate to crates.io; skips if (name, version) already exists; sleeps + retries on 429 rate-limit. Sibling of rust-workspace-publish for non-workspace Rust repos.

### `sdlc` — 7 primitive(s)

> 🔄 SDLC automation

- [`dependabot-trigger`](./dependabot-trigger/) — Trigger Dependabot to re-evaluate dependency updates via gh api.
- [`dependency-update`](./dependency-update/) — Polymorphic dependency lock refresh + open PR if anything changed. Detects ecosystem (rust → cargo update; npm → npm update; python → uv lock --upgrade; nix → nix flake update). Idempotent — exits 0 with no PR when nothing to update.
- [`issue-create`](./issue-create/) — Create (or reuse) a GitHub issue for a typed event. Useful for workflow auto-reporting (test failures, broken deps, drift, etc.). Idempotent via title-match deduplication.
- [`nix-flake-update`](./nix-flake-update/) — Run `nix flake update` + open PR if flake.lock changed. Idempotent — exits 0 with no PR when lock is current. Specific case of dependency-update for nix-only repos.
- [`onboard-auto-release`](./onboard-auto-release/) — Scaffold the canonical 3-workflow pleme-io auto-release surface into a repo (auto-release.yml + pre-merge-gate.yml + security-gate.yml). Idempotent — skips files that already exist unless --force is set.
- [`pr-comment`](./pr-comment/) — Post or update a comment on a pull request. Idempotent via a magic marker — re-running updates the existing comment instead of spamming.
- [`status-badge`](./status-badge/) — Generate an SVG status badge (shields.io-style) for a label/value pair. Universal — used to render build/test/coverage/version badges into a repo or a static site.

### `security` — 19 primitive(s)

> 🔒 Security — vuln scans / SBOM / signing / secrets

- [`bandit`](./bandit/) — Run bandit Python security scan.
- [`checkov`](./checkov/) — Run checkov IaC security scan.
- [`conftest`](./conftest/) — Run conftest OPA-based policy check.
- [`cosign-verify`](./cosign-verify/) — Verify a cosign signature on an artifact or image.
- [`cyclonedx-merge`](./cyclonedx-merge/) — Merge multiple CycloneDX SBOMs into a single combined doc.
- [`gh-secrets-sync`](./gh-secrets-sync/) — Sync GitHub repo/org/env secrets from a typed YAML spec (encrypted).
- [`gosec`](./gosec/) — Run gosec Go security scan.
- [`image-scan`](./image-scan/) — Scan a container image for vulnerabilities + secrets via Trivy. Emits typed severity + vuln-count outputs. Configurable fail-on-severity gate.
- [`kics-scan`](./kics-scan/) — Run KICS IaC security scan.
- [`license-finder`](./license-finder/) — Scan dependencies for license compatibility via license_finder.
- [`license-header-check`](./license-header-check/) — Verify every source file has a typed SPDX-License-Identifier header. Universal — works on any source tree; configurable extensions + license set.
- [`provenance-attest`](./provenance-attest/) — Sign artifacts with sigstore/cosign keyless OIDC. Universal — works on any file (binary, tarball, SBOM, container image digest). Produces a .sig + .cert pair downstream consumers can verify with cosign verify-blob.
- [`sbom-generate`](./sbom-generate/) — Generate a CycloneDX or SPDX SBOM from the repo via syft. Universal — works on any source tree (Rust, Node, Python, Helm, Docker context, etc).
- [`secrets-scan`](./secrets-scan/) — gitleaks-based secret scan across the repo. Emits typed finding count + severity. Configurable fail-on-found gate.
- [`security-audit`](./security-audit/) — Polymorphic dependency-vulnerability audit. Detects repo type + routes to cargo-audit / npm-audit / pip-audit / etc. Emits a typed severity summary.
- [`slsa-attest`](./slsa-attest/) — Generate SLSA provenance attestation for a build artifact (Level 3 via in-toto).
- [`snyk-test`](./snyk-test/) — Snyk dependency vulnerability scan with severity gate.
- [`tfsec`](./tfsec/) — Run tfsec on Terraform code.
- [`vault-fetch`](./vault-fetch/) — Fetch a secret from HashiCorp Vault via JWT-OIDC auth.

### `spec` — 1 primitive(s)

> 📐 Spec watching

- [`spec-watch`](./spec-watch/) — Detect changes in an upstream OpenAPI/JSON spec by sha256 against a cached value

### `storage` — 3 primitive(s)

> 💾 Storage — S3 / GCS / cross-workflow

- [`artifact-fetch`](./artifact-fetch/) — Fetch an artifact from a previous workflow run (cross-workflow handoff).
- [`gcs-sync`](./gcs-sync/) — Sync a local directory to GCS via gsutil rsync.
- [`s3-mirror`](./s3-mirror/) — Mirror a local directory tree to S3 with --delete semantics (aws s3 sync).

### `uncategorized` — 5 primitive(s)

> 🔧 Uncategorized — needs a home

- [`codeql-scan`](./codeql-scan/) — GitHub CodeQL SAST scan. Polymorphic — auto-detects language; uploads SARIF to GitHub Code Scanning.
- [`coverage-upload`](./coverage-upload/) — Generate test coverage + upload to Codecov. Polymorphic — detects ecosystem (rust uses cargo-tarpaulin, npm uses jest --coverage, python uses pytest --cov).
- [`k6-load-test`](./k6-load-test/) — Run a k6 load test script + emit summary JSON. Pairs with thresholds for PR-time perf regression gating.
- [`onepassword-fetch`](./onepassword-fetch/) — Fetch a secret from 1Password via Service Account token. Sibling of akeyless-secret-fetch.
- [`semgrep-scan`](./semgrep-scan/) — Semgrep SAST scan with configurable rule set.

### `validation` — 6 primitive(s)

> 🚦 Validation — per-language gates + universal lints

- [`nix-flake-check`](./nix-flake-check/) — Run `nix flake check` with DeterminateSystems Nix
- [`npm-gate`](./npm-gate/) — PR-time quality gate for an npm repo: prettier --check + eslint + npm test (each conditionally run based on script presence in package.json).
- [`python-gate`](./python-gate/) — PR-time quality gate for a Python repo: ruff format --check + ruff check + pytest. Universal across uv/poetry/hatch layouts.
- [`rust-gate`](./rust-gate/) — PR-time quality gate for a Rust repo: cargo fmt --check + cargo clippy + cargo test. Universal for both workspace + single-crate shapes.
- [`tlisp-lint`](./tlisp-lint/) — Validate every *.tlisp file under the repo: balanced parens, balanced strings, balanced comments, and (when tatara-script is installed) a parser-level dry-run. Catches the parse-error class of bug at PR time instead of after-tag.
- [`typecheck-gate`](./typecheck-gate/) — Polymorphic typecheck gate — runs cargo check / tsc --noEmit / mypy based on repo type. Faster than the full test-gate when you just want type validity.

### `workflow` — 2 primitive(s)

> ⚙️ Workflow orchestration — Temporal / Airflow

- [`airflow-trigger`](./airflow-trigger/) — Trigger an Airflow DAG via REST API.
- [`temporal-trigger`](./temporal-trigger/) — Start a Temporal workflow via tctl/temporal CLI.

---

## How this catalog grows

Per the **★★ generation-over-composition** prime directive:
this `README.md` is mechanically auto-generated from `action.yml` files
via [`pleme-doc-gen`](https://github.com/pleme-io/pleme-doc-gen) (Rust binary,
published to crates.io via the directive's own dogfood).

## License

MIT.
