# pleme-io · benchmark-runner

> Polymorphic benchmark runner — criterion for Rust, pytest-benchmark for Python. Pushes results to a benches branch for trend tracking.

**Category**: `quality` — ✅ Code quality — mutation / benchmark / SonarQube / accessibility
**Backend**: shell
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/benchmark-runner@v1
    with:
      baseline: ""
      output-branch: "benches"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `baseline` | no | `` | Baseline ref to compare against (empty = no comparison) |
| `output-branch` | no | `benches` |  |

## Outputs

| Name | Description |
|---|---|
| `regressions` |  |
| `results-path` |  |

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

## Related primitives — `quality` category

[`mutation-test`](../mutation-test/) · [`pa11y-ci`](../pa11y-ci/) · [`sonarqube-scan`](../sonarqube-scan/)

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
