# pleme-io · kustomize-render

> kustomize build → emit rendered manifests. Optional in-place commit to a target branch for GitOps workflows.

**Category**: `k8s` — ☸️ Kubernetes — apply / deploy / reconcile / wait
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/kustomize-render@v1
    with:
      output: "rendered.yaml"
      overlay: <required>
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `output` | no | `rendered.yaml` | Path to write rendered manifests |
| `overlay` | yes | — | Path to the kustomize overlay (or base) to render |

## Outputs

| Name | Description |
|---|---|
| `output-path` |  |

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

## Related primitives — `k8s` category

[`argocd-sync`](../argocd-sync/) · [`flux-reconcile`](../flux-reconcile/) · [`helm-deploy`](../helm-deploy/) · [`helmfile-apply`](../helmfile-apply/) · [`k8s-rollout-wait`](../k8s-rollout-wait/) · [`kubectl-apply`](../kubectl-apply/) · [`tanka-apply`](../tanka-apply/) · [`velero-backup`](../velero-backup/)

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
