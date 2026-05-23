# pleme-io · cargo-bump

Bump a single-crate Rust repo via cargo set-version --bump <type>, regenerate Cargo.nix, refresh Cargo.lock. Sibling of rust-workspace-bump for non-workspace Rust repos.

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  bump-type:
    description: "patch | minor | major"
    required: false
    default: patch
  skip-when-no-source-changes:
    description: "Skip the bump when no source path changed since the previous tag"
    required: false
    default: "true"
  source-paths:
    description: "Space-separated globs the skip-detector inspects for changes since the last tag"
    required: false
    default: "src Cargo.toml Cargo.lock"
```

## Outputs

```yaml
  bumped:
    description: "true if a bump happened, false if skipped/no-op"
    value: ${{ steps.bump.outputs.bumped }}
  new-version:
    description: "New package.version after bump (empty when bumped=false)"
    value: ${{ steps.bump.outputs.new-version }}
  old-version:
    description: "Previous package.version (always populated)"
    value: ${{ steps.bump.outputs.old-version }}
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/cargo-bump@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
