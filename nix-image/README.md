# pleme-io · nix-image

> Build multi-arch nix OCI image tarballs via `dockerTools` (**NO Dockerfile**),
> one per requested arch, from the substrate `dockerImage-<arch>` convention.

Part of the **super-cache-ci** delivery leg. A camelot build composes this with
`ghcr-publish` + `zot-pull-scan`.

```yaml
- uses: pleme-io/actions/nix-image@v1
  id: image
  with:
    image-attr: dockerImage      # per-arch => dockerImage-amd64 / -arm64
    arches: "amd64"              # space-separated; 'amd64 arm64' for both
    flake-ref: "."
    # endpoint: ${{ steps.sui.outputs.endpoint }}   # LiveTODO: sui warm-layer routing
```

## Outputs

| Name | Meaning |
|---|---|
| `tarball-amd64` / `tarball-arm64` | per-arch docker-archive out-path |
| `tarballs` | `arch:path` list of every built tarball |
| `built` | `true` iff every requested arch built |
| `via-service` | `true` iff a build was sui-served (**today always `false`**) |
| `result` | first successful tarball path |

## Tier-honesty (SUPER-CACHE-CI ledger)

- **now** — local `nix build .#<image-attr>-<arch>` on a native-arch runner.
- **LiveTODO:super-cache-build** — when `endpoint` (SUI_ENDPOINT) is set, route the
  derivation through the sui daemon for warm layer-cache reuse. The seam is not
  yet live: the action logs the LiveTODO, performs a **correct local build**, and
  reports `via-service=false` — it never fakes a warm hit.

Non-native builds emit a `::warning::` (image-push.yml native-arch rule) — an
off-target build mislabels the arch and `exec format error`s at runtime.

## Architecture

Composite action; logic is typed tatara-lisp in [`run.tlisp`](./run.tlisp) over
`_tlisp-stdlib`. Pure helpers (`arch->system`, `image-attr-for`, `native-arch?`)
are unit-tested by [`run.test.tlisp`](./run.test.tlisp) via the `tlisp-test` gate.
