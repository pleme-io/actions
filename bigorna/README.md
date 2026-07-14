# pleme-io · bigorna

**CI ENTRY** for pleme-io's typed buildx-native-multi-arch primitive
(`sui-bigorna` — *bigorna*, the anvil). **One step** gives a consumer a
`docker buildx` builder whose nodes are **real, native per-architecture**
build nodes (no QEMU) **plus** a cache front that points at the shipped
`sui` tiered content-addressed store. After it runs, an **unchanged**
`docker buildx build --platform linux/amd64,linux/arm64` dispatches each
platform to native metal **and** answers seen layers warm — native
multi-arch and layer caching land through **one** integration point.

It owns no build algebra: it is a thin, zero-shell keyway front over the
shipped `bigorna setup` binary. It renders a typed `BigornaConfig` (YAML)
from the inputs, hands it to `bigorna setup --config`, and forwards the
binary's typed JSON receipt to `GITHUB_OUTPUT`. The emulated-node refusal,
the native-vs-QEMU guarantee, and the cache-endpoint bridge all live **in**
the binary (proven by its unit tests); this action never re-implements them.

## The native model (tier-honest)

A bigorna node is native **by construction**: it can only be registered
when its host arch equals its target arch — an *emulated* node has no
constructor (`sui-bigorna/src/node.rs`). So on **one runner**:

- the runner's **own** arch is the create-time native node (no endpoint);
- a **foreign** target arch is native **only** if you supply a native
  `arch-endpoints` entry for it (a docker context / `tcp://` remote, e.g.
  the camelot `runs-on:[camelot,<arch>]` fan);
- a foreign arch with **no** endpoint would be **emulated** — which bigorna
  refuses. `fallthrough` decides what happens then:
  - `error` (default) → the honest hard fail;
  - `native-subset` → set up the native-covered platforms, warn, proceed.

Single-runner native-multi-arch therefore covers the runner's own arch for
free; true cross-arch native needs an endpoint per foreign arch. This is
stated, not hidden.

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `platforms` | no | `linux/amd64` | Comma/space OCI platform list to cover natively. |
| `cache` | no | `""` | Registry cache ref fronting the sui store (`ghcr.io/pleme-io/<svc>:buildcache`). Empty = no cache front. |
| `cache-mode` | no | `max` | `max` (intermediate layers too) \| `min`. |
| `arch-endpoints` | no | `""` | `<arch>=<endpoint>` list for foreign native nodes (e.g. `arm64=arm64-ctx`). |
| `fallthrough` | no | `error` | `error` (hard fail) \| `native-subset` (partial + warn). |
| `builder-name` | no | `bigorna` | buildx builder name. |
| `driver` | no | `docker-container` | `docker-container` \| `kubernetes` \| `remote`. |
| `bigorna-version` | no | `main` | sui ref for `nix run github:pleme-io/sui/<ref>#bigorna` when no `bigorna` is on PATH. |

## Outputs

| Output | Description |
|---|---|
| `builder` | The buildx builder name that was set up (`--use`d — an unchanged `docker buildx build` picks it up). |
| `native-platforms` | Comma-joined platforms covered by a native node. |
| `emulation` | `native-for-all` \| `needs-native-node`. |
| `cache-from` | A `--cache-from` token the consumer's build reuses (`""` when no cache front). |
| `cache-to` | A `--cache-to` token the consumer's build reuses (`""` when no cache front). |
| `ok` | `true` iff every requested platform got a native node and every create step succeeded. |
| `result` | Generic catch-all == builder name (or `""` on failure). |

## Usage

```yaml
# The whole point: set up the builder in ONE step, then build UNCHANGED.
- id: bigorna
  uses: pleme-io/bigorna@v1
  with:
    platforms: linux/amd64,linux/arm64
    cache: ghcr.io/pleme-io/my-svc:buildcache
    # Foreign arch goes native via a supplied endpoint; drop it and the
    # arm64 request is an honest hard fail (fallthrough=error) instead of QEMU.
    arch-endpoints: arm64=arm64-ctx

- name: Build (native multi-arch + warm — no bigorna-specific flags)
  run: |
    docker buildx build \
      --platform ${{ steps.bigorna.outputs.native-platforms }} \
      --cache-from ${{ steps.bigorna.outputs.cache-from }} \
      --cache-to   ${{ steps.bigorna.outputs.cache-to }} \
      -t ghcr.io/pleme-io/my-svc:latest --push .
```

Single-runner, own-arch only (the common case — native for the runner's
arch, no endpoint needed):

```yaml
- uses: pleme-io/bigorna@v1
  with:
    platforms: linux/amd64
    cache: ghcr.io/pleme-io/my-svc:buildcache
```

## Exit codes (keyway)

- `0` — setup succeeded (or a `native-subset` partial).
- `1` — a requested platform is emulated under `fallthrough=error`, a
  buildx create step failed, or the binary could not be resolved. Never a
  faked green.

## Composition

`bigorna` is the **entry** verb of the super-cache-ci delivery leg — it sets
up the builder that the `nix-image` / `ghcr-publish` / cache verbs then use,
and its cache front is the buildx face of the same `sui` tiered store the
`super-cache-restore` / `super-cache-save` verbs speak. See
`theory/SUPER-CACHE-CI.md`.
