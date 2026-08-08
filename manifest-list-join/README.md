# pleme-io · manifest-list-join

> Compose separately-pushed per-arch images (`amd64=<ref>,arm64=<ref>`) into **one
> multi-arch OCI image index** (manifest list) and push it under the multi-arch
> deploy coordinate `r<run>-<sha>`; report the **index digest** — the single exact
> coordinate an environment pins.

Part of the **super-cache-ci** manifest leg (job 3). Consumes the per-arch refs
`zot-push` produced; its index digest is attested by `cartorio-attest`.

## Why a dedicated action

`doca` (`pleme-io/substrate#oci-push`), the fleet's OCI tool, has **no
index-composition verb** — its subcommands are `push`/`transfer`/`inspect`/
`pull`/`list`/`resolve`/`tag`/`delete`/… (read 2026-08-08). Neither does
`skopeo`, which *copies* single images but does not *compose* an index from
separately-pushed per-arch digests. So this action drives a foreign manifest
tool, auto-detected in order:

**regctl** (`index create`) → **buildah** → **podman** (`manifest
create/add/push`) → **docker** (`buildx imagetools create`).

regctl is FIRST (since 2026-07-23) because it is the one candidate that accepts
per-registry TLS/CA trust without touching a shared daemon's global config —
which is what the cluster Zot's self-signed in-pod TLS needs. If none of the four
is reachable the action **fails loudly** (`reason=no-tool`) — it never fakes an
index digest. doca is still used, for the digest readback.

**regctl is not installed at job time.** It is resolved the way the stdlib
resolves doca: a baked `regctl` on PATH wins, `nix run ${{ inputs.regctl-ref }}`
is the logged fallback. The `nix profile install …#regctl` shell step this
action used to carry was deleted 2026-08-08 (★★ HERMETIC SUPPLY CHAIN + the
NO-SHELL directive). Baking regctl and doca into the runner image removes the
fallback — and with it the `nix-installer-action` step.

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
    dest-user: ${{ secrets.ZOT_ADMIN_USERNAME }}
    dest-pass: ${{ secrets.ZOT_ADMIN_PASSWORD }}
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
| `dest-user` / `dest-pass` | *(required)* | registry push credentials — Zot rejects anonymous index writes the same way it rejects anonymous blob pushes (same shape as `zot-push`) |
| `tool` | `auto` | `auto` \| `regctl` \| `buildah` \| `podman` \| `docker` (an explicitly named tool that is not reachable is now `reason=no-tool`, not a crash) |
| `ca-cert-url` / `ca-cert-path` / `ca-cert-token` | committed cluster cert | the pinned PEM trusted by BOTH the regctl join and the doca digest readback |
| `regctl-ref` | `github:NixOS/nixpkgs/nixos-24.05#regctl` | flake ref `nix run` resolves when regctl is not baked |
| `doca-ref` | `github:pleme-io/substrate#oci-push` | flake ref `nix run` resolves when doca is not baked |

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
- The **one runtime dependency** is a manifest tool reachable from the runner
  (baked, or `nix run` for regctl); absence is a loud failure (`reason=no-tool`),
  never a faked digest.
- Today the akeyless build is **amd64-only**, so a 1-arch join is a
  **degenerate-but-honest** index (`reason=single-arch`). It becomes load-bearing
  the moment arm64-native lands — no action change, just a second `arch-refs`
  entry.
- **2026-07-24 fix:** this action shipped with **zero credential wiring** since
  inception — `dest-user`/`dest-pass` are new required inputs. Every tool path
  authenticates before the join, closing "no credentials available: unauthorized"
  against an authz-enabled Zot at every tool path, not just the regctl instance
  that happened to be live-tested (task #74).
- **2026-08-08 fix — ★ the credential no longer travels on argv.** That 2026-07-24
  wiring used `regctl registry login --pass <secret>`, `docker login --password
  <secret>` and buildah/podman `--creds <user>:<secret>` (re-passed once per
  architecture). `/proc/<pid>/cmdline` is world-readable and GitHub masks logs,
  not the process table. Every path now reads a credential FILE created 0600
  inside a 0700 directory — `$DOCKER_CONFIG`, `--authfile`, `$REGCTL_CONFIG`,
  and `INPUT_USER`/`INPUT_PASS` for doca. Tier: **only-mitigated** (owner-only
  instead of world-readable), not unrepresentable — a stdin channel on
  `exec-capture` is the structural fix and lives upstream in tatara-lisp.
- **2026-08-08 fix — `index-digest` was structurally always empty on the target
  cluster.** The readback ran `doca inspect --insecure`, and doca's `--insecure`
  is *plain HTTP*, not *skip verification*. The Zot has served TLS only since
  2026-07-18, so the action's headline output could never resolve — degraded to
  a `::warning::` that read like an occasional hiccup. The pinned CA cert was
  already fetched on disk and simply never handed to doca; it is now, via
  `INPUT_DEST_CA_CERT`, and `--insecure` is used only when there is no cert and
  `insecure` permits it.
- **Outputs are written with `emit-output`**, so a newline in a caller-supplied
  value (`tag`, `arch-refs`, …) is refused rather than silently writing
  additional `$GITHUB_OUTPUT` keys.
- **Known limit (measured 2026-08-08):** doca pins TLS through rustls, which
  requires the pinned PEM to be a real **CA** certificate — a self-signed *leaf*
  is rejected. regctl's `regcert` is more permissive. If `ca-cert-url` points at
  a leaf, the join succeeds and the digest readback still returns an honest
  empty. Point `ca-cert-url` at the issuing CA.

## Verification

`tests/test.yml` pushes both an amd64 and an arm64 image to a throwaway
`registry:2`, joins them, and independently re-inspects the index to prove it
carries both platforms.
