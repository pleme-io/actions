# pleme-io · derive-version-from-tag

Strip leading "v" from a tag ref to derive a SemVer version string

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  ref-name:
    description: "Tag ref name (default: github.ref_name)"
    required: false
    default: ${{ github.ref_name }}
```

## Outputs

```yaml
  version:
    description: "Derived version (ref-name with leading 'v' stripped); set by run.tlisp via $GITHUB_OUTPUT"
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/derive-version-from-tag@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
