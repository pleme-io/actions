# pleme-io · image-scan

> Scan a container image for vulnerabilities + secrets via Trivy. Emits typed severity + vuln-count outputs. Configurable fail-on-severity gate.

**Category**: `security` — 🔒 Security — vuln scans / SBOM / signing / secrets
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/image-scan@v1
    with:
      fail-on-severity: "HIGH"
      ignore-unfixed: "false"
      image-ref: <required>
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `fail-on-severity` | no | `HIGH` | Lowest severity that fails the build: LOW | MEDIUM | HIGH | CRITICAL | none |
| `ignore-unfixed` | no | `false` | Skip vulns without an available fix |
| `image-ref` | yes | — | Image to scan (e.g. ghcr.io/pleme-io/foo:latest) |

## Outputs

| Name | Description |
|---|---|
| `severity` |  |
| `vuln-count` |  |

## Configuration via `.pleme-io-release.toml`

Per-repo defaults follow 3-tier precedence:
**env var (workflow input) > `.pleme-io-release.toml` > hardcoded default**.

See the [full config schema](https://github.com/pleme-io/substrate/blob/main/lib/release/example-config.toml).

## Architecture

Composite GitHub Action. Logic lives in [`run.tlisp`](./run.tlisp);
[`action.yml`](./action.yml) orchestrates install steps + one
`tatara-script` invocation.

Per the ★★ NO-SHELL prime directive
([pleme-io-pattern-core skill](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-pattern-core/SKILL.md)):
this action's primary logic is typed Lisp, not bash. The substrate's
[`action-shell-lint`](../action-shell-lint/) enforces this fleet-wide on every PR.

## Related primitives — `security` category

[`bandit`](../bandit/) · [`checkov`](../checkov/) · [`conftest`](../conftest/) · [`cosign-verify`](../cosign-verify/) · [`cyclonedx-merge`](../cyclonedx-merge/) · [`gh-secrets-sync`](../gh-secrets-sync/) · [`gosec`](../gosec/) · [`kics-scan`](../kics-scan/)

## Auto-published on free public CI

Every push to `main` on `pleme-io/actions`:
1. `auto-bump.yml` fires (~10s) → tags `v0.13.{next}`
2. `release.yml` cuts the Docker image (if applicable) + fast-forwards `v1`
3. Consumers using `@v1` see the new revision automatically

**$0/month cost** — GitHub-hosted runners + public-repo free tier.

## License

MIT.

---
*Auto-generated from `action.yml` by [`pleme-doc-gen`](https://github.com/pleme-io/pleme-doc-gen). Do not hand-edit.*
