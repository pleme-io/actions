# pleme-io · darwin-zig-build

> cargo zigbuild --release for an apple-darwin target (cross-compiles from Linux), stage binary + sha256 into ./dist

**Category**: `build` — 🔨 Build — cross-compile / OCI / Ansible
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.x` tags or floating `@v1` / `@main`

## What it is

The Linux-friendly peer of [`rust-cross-build`](../rust-cross-build). Where that
runs a native `cargo build` (so an apple-darwin artifact needs a macOS runner),
this runs `cargo zigbuild` — zig supplies the macOS libSystem/CRT stubs, so a
**macOS binary links from a Linux runner** (a rio self-hosted runner, no
GitHub-hosted macOS minutes). With `target: universal2-apple-darwin` it emits a
single fat arm64+x86_64 binary. Pure-Rust crates only (no macOS-framework deps).

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: dtolnay/rust-toolchain@stable
    with: { targets: aarch64-apple-darwin,x86_64-apple-darwin }
  - uses: mlugg/setup-zig@v1
  - uses: taiki-e/install-action@v2
    with: { tool: cargo-zigbuild }
  - uses: pleme-io/actions/darwin-zig-build@v1
    with:
      binary-name: shaar
      package: shaar-cli
      suffix: macos-universal
      # target defaults to universal2-apple-darwin
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `binary-name` | yes | — | Cargo binary name |
| `suffix` | yes | — | Artifact suffix appended to `<binary-name>` (e.g. `macos-universal`) |
| `target` | no | `universal2-apple-darwin` | apple-darwin target triple |
| `package` | no | `` | Cargo package to build (workspace member); empty = whole workspace |
| `features` | no | `` | Space-separated cargo features |
| `no-default-features` | no | `false` | When `'true'`, pass `--no-default-features` |

## Output

Stages `dist/<binary-name>-<suffix>` plus a `dist/<binary-name>-<suffix>.sha256`
sidecar — ready to attach to a GitHub release via
[`gh-release-create`](../gh-release-create).

## Architecture

Composite GitHub Action. Logic lives in [`run.tlisp`](./run.tlisp); inputs are
forwarded as env vars to `pleme-io/actions/tatara-script@v1`. No `format!()`, no
hand-rolled bash beyond the stdlib loader.
