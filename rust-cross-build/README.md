# pleme-io · rust-cross-build

cargo build --release for a target, stage binary + sha256 into ./dist

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  binary-name:
    description: "Cargo binary name (used for target/<triple>/release/<name> and the staged artifact basename)"
    required: true
  target:
    description: "Rust target triple (e.g. x86_64-unknown-linux-gnu)"
    required: true
  suffix:
    description: "Artifact suffix appended to <binary-name> (e.g. linux-x86_64)"
    required: true
  features:
    description: "Space-separated cargo features; empty = no --features flag"
    required: false
    default: ""
  no-default-features:
    description: "When 'true', pass --no-default-features"
    required: false
    default: "false"
```

## Outputs

```yaml
(none)
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/rust-cross-build@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
