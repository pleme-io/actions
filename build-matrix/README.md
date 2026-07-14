# build-matrix

Enumerate a flake's colon-triple image attrs (`dockerImage:<arch>:<svc>`) and
emit the GitHub Actions **image×arch build matrix**. Step 2 of the
super-cache-ci graph job — the single-responsibility **sibling** of
`gen-build-spec` (which gates spec freshness); `build-matrix` fans the fresh
spec across every `(service, arch)` the flake actually exposes.

```yaml
jobs:
  graph:
    runs-on: [self-hosted, camelot]   # a runner that bakes nix + jq
    outputs:
      matrix: ${{ steps.m.outputs.matrix }}
      count:  ${{ steps.m.outputs.count }}
    steps:
      - uses: actions/checkout@v4
      - id: m
        uses: pleme-io/actions/build-matrix@v1
        with:
          flake-ref: github:akeylesslabs/akeyless-nix-images
          eval-system: x86_64-linux    # where the colon-triple attrs live
          image-base: dockerImage
          services: "auth uam gateway"  # empty = all discovered
          arches: "amd64"               # empty = all discovered
  build:
    needs: graph
    strategy:
      matrix: ${{ fromJSON(needs.graph.outputs.matrix) }}
    runs-on: [self-hosted, camelot]
    steps:
      - uses: pleme-io/actions/nix-image@v1
        with:
          flake-ref: github:akeylesslabs/akeyless-nix-images
          # ${{ matrix.image }} / ${{ matrix.arch }} / ${{ matrix.attr }} / ${{ matrix.system }}
```

## Inputs

| input | default | meaning |
|---|---|---|
| `flake-ref` | `.` | flake to enumerate |
| `eval-system` | `x86_64-linux` | `packages.<system>` to read attrNames from — the `<arch>` in the attr, not this, selects the image target arch |
| `image-base` | `dockerImage` | only `<base>:<arch>:<svc>` attrs become rows; `default:<svc>` and the substrate `<base>-<arch>` dash convention are rejected |
| `services` | `""` | space/comma allowlist; empty = all discovered |
| `arches` | `""` | space/comma allowlist; empty = all discovered |
| `exclude` | `""` | space/comma exclusions, each `<arch>:<svc>` or bare `<svc>` |
| `require-nonempty` | `true` | 0 rows is a hard exit 1; set false for a clean typed exit 2 |

## Outputs

| output | meaning |
|---|---|
| `matrix` | GHA matrix JSON `{"include":[{image,arch,attr,system},…]}` — consume via `fromJSON` |
| `count` | number of rows (integer) |
| `reason` | `ok` \| `empty-matrix` \| `nix-eval-failed` \| `jq-failed` \| `nix-absent` \| `jq-absent` |

## Exit codes (keyway three-code contract)

- **0** — ≥1 matrix row emitted (`reason=ok`).
- **2** — eval OK but 0 rows matched AND `require-nonempty=false` — a clean typed
  "no" the caller branches on in YAML.
- **1** — a loud failure: `nix eval` failed, `jq` failed, a required tool is
  absent, OR 0 rows with `require-nonempty=true` (no silent empty matrix — an
  empty `include` breaks the downstream job).

## Tier-honesty

- **SHIPPABLE-NOW.** Deterministic `nix eval` enumeration over the flake's real
  attr set. **Honest per-service arch discovery** — an `arm64` row appears iff
  the flake exposes `dockerImage:arm64:<svc>`; the `arches` input is a *filter*
  over discovered attrs, never a hard-coded `(amd64, arm64)` pair. Today amd64
  is the confirmed-built path, so a request for arm64 against an amd64-only
  flake yields amd64 rows only (honest), and `require-nonempty=true` turns a
  surprise-empty into a loud failure rather than an unrunnable empty matrix.
- **TYPED EMISSION.** The matrix JSON is composed by `jq` (the typed
  serializer), NEVER hand string-concatenated — the same rule the
  `tameshi-attest` receipt obeys. The jq program carries no double-quotes; the
  row separator is a `--arg`.
- **Required tools are probed on PATH first** (`exec-capture` raises on an
  absent binary), so an absent `nix`/`jq` is an honest `reason=nix-absent` /
  `jq-absent` (exit 1), never a crash and never a faked matrix.

Pure decision helpers (`bm:parse-attr`, `bm:arch->system`, `bm:rows-from-names`,
`bm:selected?`, `bm:excluded?`, `bm:row->arg`) are unit-tested as an 11-case
verification matrix in `run.test.tlisp` via `tatara-script --test`.
