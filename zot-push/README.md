# pleme-io · zot-push

> Push a nix OCI image tarball to the **PRIVATE in-cluster Zot** registry
> (`zot.zot-system.svc.cluster.local:5000/akeyless-<svc>`) under the
> **★ AUTOBUMP** exact tag `<arch>-r<run>-<sha>`, and report the pushed
> repository **digest** (the exact deploy coordinate).

Part of the **super-cache-ci** delivery leg. Consumes a tarball from `nix-image`;
its per-arch digests are joined by `manifest-list-join` and attested by
`cartorio-attest`.

## Sibling of `ghcr-publish` — not a duplicate

| | `ghcr-publish` | `zot-push` |
|---|---|---|
| Target | `ghcr.io/pleme-io/<svc>` (public TLS) | `zot.zot-system…:5000/akeyless-<svc>` (cluster-internal) |
| Purpose | pleme-io **OSS** artifacts (★★ TOOL-DISTRIBUTION) | akeyless **FedRAMP-sensitive** images |
| TLS | public | `insecure: true` (http / self-signed) |
| ghcr.io | yes | **never** (routing a FedRAMP image through ghcr is the wrong-org trap) |

Both are `skopeo copy docker-archive: → docker://`. The shared push/tag/inspect
algebra lives in `_tlisp-stdlib` (`oci:autobump-tag`, `oci:skopeo-push-archive`,
`oci:skopeo-remote-digest`, …) — this action is a thin typed wrapper, not a
re-implementation.

```yaml
- uses: pleme-io/actions/zot-push@v1
  id: push
  with:
    registry: zot.zot-system.svc.cluster.local:5000
    svc: auth                       # → repo akeyless-auth
    arch: amd64
    run-number: ${{ github.run_number }}
    sha: ${{ github.sha }}
    tarball: ${{ steps.image.outputs.tarball-amd64 }}
    insecure: "true"                # cluster-internal Zot
    # moving-latest: "false"        # exact-only by default for FedRAMP images
```

## AUTOBUMP tag law (org ★★ AUTO-RELEASE → "never `:latest`")

Every push emits a **sortable, exact, immutable** tag `<arch>-r<run>-<sha>`:
`r<run>` is the numeric sort key a Flux `ImagePolicy` extracts
(`^<arch>-r(?P<n>\d+)-`); `<sha>` is the trace. The **multi-arch** coordinate
`r<run>-<sha>` is composed by `manifest-list-join` over the per-arch digests this
action reports. A moving `<arch>-latest` is **off by default** for FedRAMP images
and is never a deploy source.

## Inputs

| Name | Default | Meaning |
|---|---|---|
| `registry` | `zot.zot-system.svc.cluster.local:5000` | cluster Zot host:port (used when `repo` empty) |
| `repo` | `""` | full base override `<host>/<repo>` (wins when set) |
| `image` | `""` | repo path override (composed with `registry`) |
| `svc` | `""` | akeyless service → repo `akeyless-<svc>` |
| `arch` | `amd64` | tag prefix |
| `run-number` | *(required)* | numeric sort key `r<n>` |
| `sha` | *(required)* | trace suffix |
| `tarball` | `./result` | docker-archive from `nix-image` |
| `moving-latest` | `false` | also push `<arch>-latest` (human pointer) |
| `insecure` | `true` | http/self-signed cluster registry |

## Outputs

| Name | Meaning |
|---|---|
| `tag` | the exact pushed tag `<arch>-r<run>-<sha>` |
| `ref` / `ref-amd64` / `ref-arm64` | full pushed ref `<base>:<tag>` |
| `digest` | pushed repository digest `sha256:…` (the exact deploy coordinate) |
| `pushed` | `true` iff the exact tag pushed |
| `reason` | `pushed` \| `need-target` \| `push-fail` |

## Tier-honesty

- **SHIPPABLE-NOW** — the tag/base algebra (`zot:compose-base`, `oci:autobump-tag`,
  `oci:target-ref`, `oci:moving-tag`) is pure + unit-tested (`run.test.tlisp`); the
  push wraps `skopeo` (baked into the super-cache-ci runner). Auth is a
  pre-condition (docker login to the Zot, or `insecure: true` for the
  cluster-internal registry).
- `digest=` may be empty if `skopeo inspect` cannot resolve the pushed digest —
  reported honestly; the push itself still succeeded.

## Verification

`tests/test.yml` pushes to a throwaway `registry:2` service and independently
re-inspects it to prove the exact-tagged image landed — a real green path with no
cluster Zot needed.
