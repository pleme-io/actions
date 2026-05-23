# pleme-io · npm-bump

Bump an npm package.json version via `npm version --no-git-tag-version <type>`, refresh package-lock.json. Sibling of cargo-bump for the npm ecosystem.

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
    description: "Space-separated globs the skip-detector inspects"
    required: false
    default: "src package.json package-lock.json"
```

## Outputs

```yaml
  bumped:
    description: "true if a bump happened, false if skipped"
    value: ${{ steps.bump.outputs.bumped }}
  new-version:
    description: "New version after bump (empty when skipped)"
    value: ${{ steps.bump.outputs.new-version }}
  old-version:
    description: "Previous version (always populated)"
    value: ${{ steps.bump.outputs.old-version }}
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/npm-bump@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
