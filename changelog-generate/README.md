# pleme-io · changelog-generate

Generate a CHANGELOG.md (or fragment) from git log since a base ref. Universal primitive — language-agnostic, used by every release flow that wants typed changelogs.

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  base-ref:
    description: "Base ref to diff from (e.g. previous tag). Empty means: use git describe --tags --abbrev=0 to auto-detect."
    required: false
    default: ""
  format:
    description: "markdown | keepachangelog | conventional"
    required: false
    default: "markdown"
  output-file:
    description: "Path to write the generated changelog. Empty means: only emit to outputs (no file write)."
    required: false
    default: ""
  fragment:
    description: "If true, emit only the new section (don't prepend to an existing file)"
    required: false
    default: "false"
```

## Outputs

```yaml
  changelog:
    description: "Generated changelog content (as a multi-line string)"
    value: ${{ steps.gen.outputs.changelog }}
  commit-count:
    description: "Number of commits between base-ref and HEAD"
    value: ${{ steps.gen.outputs.commit-count }}
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/changelog-generate@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
