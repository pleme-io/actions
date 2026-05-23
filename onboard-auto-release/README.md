# pleme-io · onboard-auto-release

> Scaffold the canonical 3-workflow pleme-io auto-release surface into a repo (auto-release.yml + pre-merge-gate.yml + security-gate.yml). Idempotent — skips files that already exist unless --force is set.

**Category**: `sdlc` — 🔄 SDLC automation
**Backend**: tatara-lisp (run.tlisp) wrapping CLI tools via `exec-capture`
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/onboard-auto-release@v1
    with:
      include-pre-merge-gate: "true"
      include-security-gate: "true"
      include-auto-release: "true"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `include-pre-merge-gate` | no | `true` | Scaffold pre-merge-gate.yml (PR-time quality gate) |
| `include-security-gate` | no | `true` | Scaffold security-gate.yml (vuln/SBOM/SPDX) |
| `include-auto-release` | no | `true` | Scaffold auto-release.yml (merge-time publish) |
| `force` | no | `false` | Overwrite existing workflow files |
| `open-pr` | no | `false` | Commit + open a PR with the new workflows |
| `pr-branch` | no | `chore/onboard-auto-release` | Branch name for the onboarding PR |
| `default-bump-type` | no | `patch` | Default bump-type input in the auto-release.yml shim |

## Outputs

| Name | Description |
|---|---|
| `files-written` | Space-separated list of workflow files created |
| `files-skipped` | Space-separated list of files already present (skipped) |
| `pr-url` | URL of the opened PR (empty when open-pr=false) |

## Configuration via `.pleme-io-release.toml`

Per-repo defaults follow 3-tier precedence:
**env var (workflow input) > `.pleme-io-release.toml` > hardcoded default**.

See the [full config schema](https://github.com/pleme-io/substrate/blob/main/lib/release/example-config.toml).

## Architecture

Composite GitHub Action. Logic lives in [`run.tlisp`](./run.tlisp);
[`action.yml`](./action.yml) orchestrates install steps + one
`tatara-script` invocation. Shared helpers from
[`_tlisp-stdlib`](../_tlisp-stdlib/).

Per the ★★ NO-SHELL prime directive
([pleme-io-pattern-core skill](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-pattern-core/SKILL.md)):
this action's primary logic is typed Lisp, not bash. The substrate's
[`action-shell-lint`](../action-shell-lint/) enforces this fleet-wide on every PR.

## Related primitives — `sdlc` category

[`dependabot-trigger`](../dependabot-trigger/) · [`dependency-update`](../dependency-update/) · [`issue-create`](../issue-create/) · [`nix-flake-update`](../nix-flake-update/) · [`pr-comment`](../pr-comment/) · [`status-badge`](../status-badge/)


## Sources

- **Action source**: [`action.yml`](./action.yml) + [`run.tlisp`](./run.tlisp)
- **Catalog entry**: `substrate.lib.release.patterns.sdlc.onboard-auto-release` —
  [patterns-full.nix](https://github.com/pleme-io/substrate/blob/main/lib/release/patterns-full.nix)
- **Future typed source**: `(defaction onboard-auto-release ...)` per
  [ACTION-AS-CAIXA.md](https://github.com/pleme-io/substrate/blob/main/docs/ACTION-AS-CAIXA.md) (M1+ migration)

## Operator-facing CLI

Same logic locally via `cargo install pleme-io-releaser`:

```bash
pleme-release plan      # preview what an auto-release would do
pleme-release onboard   # scaffold the 3-workflow surface to a fresh repo
pleme-release detect    # emit detected repo type
```

## Auto-published on free public CI

Every push to `main` on `pleme-io/actions`:
1. `auto-bump.yml` fires (~10s) → tags `v0.13.{next}`
2. `release.yml` cuts the Docker image (if applicable) + fast-forwards `v1`
3. Consumers using `@v1` or `@v0.13.{x}` see the new revision automatically

**$0/month cost** — GitHub-hosted runners + public-repo free tier.

## Discovery

Browse the [full catalog](../README.md) or query via Nix:

```bash
nix eval --raw github:pleme-io/substrate#lib.aarch64-darwin.release.patterns.sdlc.onboard-auto-release
```

## License

MIT.

---
*Auto-generated from `action.yml` by [`_gen-docs.py`](../_gen-docs.py).
Do not hand-edit; modify the source files or regenerate.*
