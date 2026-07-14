# pleme-io · nix-image

> Build **native-arch** nix OCI image tarballs via `dockerTools`
> (**NO Dockerfile, NO QEMU**), one per requested arch. The flake attr is
> resolved from a typed `{base}/{arch}/{svc}` template, so one verb targets
> every flake-attr convention without a fork.

Part of the **super-cache-ci** delivery leg. A camelot build composes this with
`ghcr-publish` (or `zot-push`) + `zot-pull-scan`.

## Native-arch fan-out (no QEMU)

Each arch builds on its **own native-metal runner** — no binfmt/QEMU emulation,
so the emulated leg that made the Dockerfile pipeline slow disappears:

```yaml
jobs:
  image:
    strategy:
      matrix:
        include:
          - arch: amd64
            runs-on: [camelot, amd64]
          - arch: arm64
            runs-on: [camelot, arm64]
    runs-on: ${{ matrix.runs-on }}
    steps:
      - uses: actions/checkout@v4
      - uses: pleme-io/actions/nix-image@v1
        id: image
        with:
          image-attr: dockerImage
          attr-template: "{base}-{arch}-{svc}"   # substrate mkGoDockerImage multi-service
          svc: auth                               # => dockerImage-amd64-auth / -arm64-auth
          arches: ${{ matrix.arch }}              # ONE arch, native to the runner
          flake-ref: "."
          # endpoint: ${{ steps.sui.outputs.endpoint }}  # LiveTODO: sui warm-layer routing
```

## attr-template — the flake-attr conventions

| `attr-template` | resolves (arch=amd64, svc=auth) | source convention |
|---|---|---|
| `{base}-{arch}` *(default)* | `dockerImage-amd64` | substrate `mkImageReleaseApp` (single image) |
| `{base}-{arch}-{svc}` | `dockerImage-amd64-auth` | substrate `mkGoDockerImage` (multi-service) |
| `dockerImage:{arch}:{svc}` | `dockerImage:amd64:auth` | akeyless-nix-images (multi-service) |
| `dockerImage:{arch}` | `dockerImage:amd64` | substrate go `service-flake` (single-service) |

`{base}` = `image-attr`. A template that names `{svc}` requires a non-empty
`svc` (else the resolved attr is ambiguous — see the keyway contract).

## Adaptive core-partition (within-node)

`auto-tune` (default `true`) makes the verb **discover** the node's actual vCPU
count `V` (`nproc`) and **partition** it across `N = targets` parallel builds so
total planned concurrency ≈ `V` **without over-subscribing** it:

- `dag-shape: narrow` (default; the monolithic `buildGoModule` fleet) →
  `--max-jobs N`, `--cores max(1, floor(V/N))`. `V=96, N=9` → `9 × 10` (90 ≤ 96);
  `V=192, N=9` → `9 × 21`; `V=32, N=9` → `9 × 3`.
- `dag-shape: wide` (per-package / gen-gomod, many small derivations) →
  `--max-jobs V`, `--cores 1` (nix's list-scheduler fills the box with 1-core builds).

The typed invariant (unit-tested over the full `V × N` grid): `planned = max-jobs
× cores ≤ V` (no over-subscription) and `slack < N` (saturating). The tuner also
bounds **Go's own** parallelism (`GOMAXPROCS` + `GOFLAGS=-p`) to `cores`, because
nix `--cores` alone does not reach a raw `go install` (substrate service-flake
passes `-p $NIX_BUILD_CORES` to close that seam).

Why not blind `--max-jobs auto --cores 0`? That over-subscribes: with `N` images
concurrent, each build fans out to **all** `V` cores → demand `N × V ≫ V`
(MEASURED: 9-service cold fleet peaked at load 300 on a 96-vCPU node = 3.1×; the
partition dropped it to 139 = 1.45×). The tuner is **adaptive** — it reads
whatever spot instance the evolving-degrade ladder placed, never a hardcoded count.

An explicit `max-jobs` (non-`auto`) or `cores` (non-`0`) is a **hard quota cap**
that WINS over the tuner; `auto-tune: false` is the legacy raw passthrough. The
build logs the discovered box + the chosen partition. The **across-images** level
(build every service concurrently) lives in the `super-cache-ci-build-matrix.yml`
reusable, which passes the row count as `targets` — this verb owns one
`(svc, arch)` cell and its within-node partition.

## Keyway contract

| | |
|---|---|
| **inputs** | `image-attr`, `attr-template`, `svc`, `arches`, `flake-ref`, `endpoint`, `targets`, `dag-shape`, `auto-tune`, `max-jobs`, `cores` (typed YAML) |
| **receipt** | `tarball-<arch>`, `tarballs` (`arch:path;…`), `built`, `via-service`, `result` (→ `$GITHUB_OUTPUT`) |
| **exit 0** | every requested arch built (or a degenerate empty arch-set) |
| **exit 1** | a build failed, **or** `attr-template` names `{svc}` but `svc` is empty (a loud, honest config error — never a faked green) |

## Outputs

| Name | Meaning |
|---|---|
| `tarball-amd64` / `tarball-arm64` | per-arch docker-archive out-path |
| `tarballs` | `arch:path` list of every built tarball |
| `built` | `true` iff every requested arch built |
| `via-service` | `true` iff a build was sui-served (**today always `false`**) |
| `result` | first successful tarball path |

## Tier-honesty (SUPER-CACHE-CI ledger)

- **now (SHIPPABLE-NOW)** — local native `nix build .#<resolved-attr>` on a
  `runs-on:[camelot,<arch>]` runner; `dockerTools.buildLayeredImage` (layered).
- **LiveTODO:super-cache-build** — when `endpoint` (SUI_ENDPOINT) is set, route the
  derivation through the sui daemon for warm layer-cache reuse. The seam is not
  yet live: the action logs the LiveTODO, performs a **correct local build**, and
  reports `via-service=false` — it never fakes a warm hit.

Non-native builds emit a `::warning::` (the native-arch rule) — an off-target
build mislabels the arch and `exec format error`s at runtime.

## Architecture

Composite action; logic is typed tatara-lisp in [`run.tlisp`](./run.tlisp) over
`_tlisp-stdlib`. Pure helpers (`arch->system`, `render-attr`, `image-attr-for`,
`template-uses-svc?`, `native-arch?`) are unit-tested by
[`run.test.tlisp`](./run.test.tlisp) via the `tlisp-test` gate — including the
attr-template matrix (one assertion per convention above).
