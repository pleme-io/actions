# pleme-io · rust-gate

PR-time quality gate for a Rust repo: cargo fmt --check + cargo clippy + cargo test. Universal for both workspace + single-crate shapes.

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  run-fmt:
    description: "Run cargo fmt --check"
    required: false
    default: "true"
  run-clippy:
    description: "Run cargo clippy --all-targets -- -D warnings"
    required: false
    default: "true"
  run-test:
    description: "Run cargo test --workspace"
    required: false
    default: "true"
  rust-toolchain:
    description: "Rust toolchain channel (stable / nightly / 1.89.0)"
    required: false
    default: "stable"
```

## Outputs

```yaml
  fmt-passed:
    value: ${{ steps.gate.outputs.fmt-passed }}
  clippy-passed:
    value: ${{ steps.gate.outputs.clippy-passed }}
  test-passed:
    value: ${{ steps.gate.outputs.test-passed }}
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/rust-gate@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
