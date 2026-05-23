# pleme-io · license-header-check

Verify every source file has a typed SPDX-License-Identifier header. Universal — works on any source tree; configurable extensions + license set.

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  license:
    description: "Required SPDX license expression (e.g. MIT, Apache-2.0, MIT OR Apache-2.0)"
    required: false
    default: "MIT"
  extensions:
    description: "Space-separated file extensions to check"
    required: false
    default: "rs ts js py rb sh"
  exclude-paths:
    description: "Space-separated path-prefix excludes"
    required: false
    default: "target node_modules .git vendor dist build"
```

## Outputs

```yaml
  missing-count:
    value: ${{ steps.check.outputs.missing-count }}
  files-scanned:
    value: ${{ steps.check.outputs.files-scanned }}
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/license-header-check@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
