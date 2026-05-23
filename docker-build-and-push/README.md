# pleme-io · docker-build-and-push

> Multi-arch docker buildx build + push to ghcr.io (or any OCI registry). Universal — works on any Dockerfile-bearing repo.

**Category**: `container` — 🐋 Container build (Docker / ko / buildah / podman)
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/docker-build-and-push@v1
    with:
      context: "."
      dockerfile: "Dockerfile"
      image: <required>
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `context` | no | `.` | Build context dir |
| `dockerfile` | no | `Dockerfile` | Path to Dockerfile |
| `image` | yes | — | Image ref (e.g. ghcr.io/pleme-io/myapp). Tag inferred from git or set via tag input. |
| `platforms` | no | `linux/amd64,linux/arm64` | Comma-separated buildx platforms |
| `push` | no | `true` | Push to registry (false = build only) |
| `tag` | no | `` | Image tag (defaults to short SHA + 'latest') |

## Outputs

| Name | Description |
|---|---|
| `digest` |  |
| `image-ref` |  |

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

[`buildah-build`](../buildah-build/) · [`buildkit-cache-warm`](../buildkit-cache-warm/) · [`crane-mutate`](../crane-mutate/) · [`ko-build`](../ko-build/) · [`oci-image-push`](../oci-image-push/) · [`podman-build`](../podman-build/) · [`skopeo-copy`](../skopeo-copy/)

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
