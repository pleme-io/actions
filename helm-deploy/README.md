# pleme-io · helm-deploy

> helm upgrade --install with --wait. Sibling of helm-publish — this is for in-cluster installation, not registry push.

**Category**: `k8s` — ☸️ Kubernetes — apply / deploy / reconcile / wait
**Backend**: tatara-lisp (run.tlisp) wrapping CLI tools via `exec-capture`
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/helm-deploy@v1
    with:
      release: <required>
      chart: <required>
      namespace: "default"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `release` | yes | — | Helm release name |
| `chart` | yes | — | Chart ref (local path or registry ref like oci://ghcr.io/pleme-io/helm/myapp) |
| `namespace` | no | `default` | Target namespace |
| `values-files` | no | `` | Space-separated values files (-f flags) |
| `set-args` | no | `` | Space-separated key=value --set args |
| `wait-timeout` | no | `5m` | --timeout for helm upgrade --wait |

## Outputs

| Name | Description |
|---|---|
| `deployed` |  |
| `revision` |  |

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

## Related primitives — `k8s` category

[`argocd-sync`](../argocd-sync/) · [`flux-reconcile`](../flux-reconcile/) · [`helmfile-apply`](../helmfile-apply/) · [`k8s-rollout-wait`](../k8s-rollout-wait/) · [`kubectl-apply`](../kubectl-apply/) · [`kustomize-render`](../kustomize-render/) · [`tanka-apply`](../tanka-apply/) · [`velero-backup`](../velero-backup/)


## Sources

- **Action source**: [`action.yml`](./action.yml) + [`run.tlisp`](./run.tlisp)
- **Catalog entry**: `substrate.lib.release.patterns.k8s.helm-deploy` —
  [patterns-full.nix](https://github.com/pleme-io/substrate/blob/main/lib/release/patterns-full.nix)
- **Future typed source**: `(defaction helm-deploy ...)` per
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
nix eval --raw github:pleme-io/substrate#lib.aarch64-darwin.release.patterns.k8s.helm-deploy
```

## License

MIT.

---
*Auto-generated from `action.yml` by [`_gen-docs.py`](../_gen-docs.py).
Do not hand-edit; modify the source files or regenerate.*
