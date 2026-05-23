# pleme-io · cargo-publish-crate

Publish a single Rust crate to crates.io; skips if (name, version) already exists; sleeps + retries on 429 rate-limit. Sibling of rust-workspace-publish for non-workspace Rust repos.

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  dry-run:
    description: "Run as --dry-run only (no upload)"
    required: false
    default: "false"
  no-verify:
    description: "Skip the verification compile step"
    required: false
    default: "true"
```

## Outputs

```yaml
  shipped:
    description: "'true' on success (including skip-when-already), 'false' on failure"
    value: ${{ steps.ship.outputs.shipped }}
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/cargo-publish-crate@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
