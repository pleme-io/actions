# pleme-io · manifest-list-join

> Compose separately-pushed per-arch images (`amd64=<ref>,arm64=<ref>`) into **one
> multi-arch OCI image index** (manifest list) and push it under the multi-arch
> deploy coordinate `r<run>-<sha>`; report the **index digest** — the single exact
> coordinate an environment pins.

Part of the **super-cache-ci** manifest leg (job 3). Consumes the per-arch refs
`zot-push` produced; its index digest is attested by `cartorio-attest`.

## Why a dedicated action

`skopeo` *copies* single images — it does **not** *compose* an index from
separately-pushed per-arch digests. So this action drives a real manifest tool,
auto-detected in order: **buildah** → **podman** (`manifest create/add/push`) →
**docker** (`docker manifest`) → **regctl** (`index create`). If none is present
it **fails loudly** — it never fakes an index digest.

```yaml
- uses: pleme-io/actions/manifest-list-join@v1
  id: index
  with:
    registry: zot.zot-system.svc.cluster.local:5000
    svc: auth
    arch-refs: "amd64=${{ steps.push-amd64.outputs.ref }},arm64=${{ steps.push-arm64.outputs.ref }}"
    run-number: ${{ github.run_number }}
    sha: ${{ github.sha }}
    insecure: "true"
    # tool: auto        # buildah|podman|docker|regctl
```

## The exact deploy coordinate

The joined index is tagged `r<run>-<sha>` (arch-less — a manifest list spans
arches; its per-arch children carry `<arch>-r<run>-<sha>` from `zot-push`). An
environment pins the returned `index-digest` (`sha256:…`) — never a moving tag
(org ★★ AUTOBUMP → "never `:latest`").

## Inputs

| Name | Default | Meaning |
|---|---|---|
| `registry` | `zot.zot-system.svc.cluster.local:5000` | cluster Zot host:port |
| `repo` / `image` / `svc` | `""` | index base (same resolution as `zot-push`) |
| `arch-refs` | *(required)* | `amd64=<ref>,arm64=<ref>` per-arch refs |
| `tag` | `""` | explicit index tag; else composed `r<run>-<sha>` |
| `run-number` / `sha` | `""` | compose the `r<run>-<sha>` index tag |
| `insecure` | `true` | http/self-signed cluster registry |
| `tool` | `auto` | `auto` \| `buildah` \| `podman` \| `docker` \| `regctl` |

## Outputs

| Name | Meaning |
|---|---|
| `index-ref` | full pushed index ref `<base>:r<run>-<sha>` |
| `index-digest` | index digest `sha256:…` (the exact multi-arch deploy coordinate) |
| `arches` | space-joined arches folded in (e.g. `amd64 arm64`) |
| `joined` | `true` iff composed + pushed |
| `reason` | `joined` \| `single-arch` \| `no-refs` \| `need-target` \| `need-tag` \| `no-tool` \| `join-fail` |

## Tier-honesty

- **SHIPPABLE-NOW** — index composition is deterministic; the tag/base algebra +
  arch/ref parsing are pure + unit-tested (`run.test.tlisp`).
- The **one runtime dependency** is a manifest tool on PATH; absence is a loud
  failure (`reason=no-tool`), never a faked digest.
- Today the akeyless build is **amd64-only**, so a 1-arch join is a
  **degenerate-but-honest** index (`reason=single-arch`). It becomes load-bearing
  the moment arm64-native lands — no action change, just a second `arch-refs`
  entry.

## Verification

`tests/test.yml` pushes both an amd64 and an arm64 image to a throwaway
`registry:2`, joins them, and independently re-inspects the index to prove it
carries both platforms.
