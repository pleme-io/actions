# pleme-io · oci-image-push

> Push an OCI image tarball (Nix dockerTools output) to a registry — skopeo fallback

**Category**: `container` — 🐋 Container build (Docker / ko / buildah / podman)
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/oci-image-push@v1
    with:
      flake-ref: "."
      image: <required>
      registry: <required>
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `flake-ref` | no | `.` | (unused in Docker mode — kept for input-compat with composite caller) |
| `image` | yes | — | Image path (e.g. pleme-io/pangea-operator) |
| `registry` | yes | — | Target OCI registry (e.g. ghcr.io) |
| `tag` | yes | — | Image tag |
| `tarball` | no | `./result` | Path to the Docker/OCI image tarball produced by Nix |

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

## Related primitives — `container` category

[`buildah-build`](../buildah-build/) · [`buildkit-cache-warm`](../buildkit-cache-warm/) · [`crane-mutate`](../crane-mutate/) · [`docker-build-and-push`](../docker-build-and-push/) · [`ko-build`](../ko-build/) · [`podman-build`](../podman-build/) · [`skopeo-copy`](../skopeo-copy/)

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
