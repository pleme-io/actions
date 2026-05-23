# pleme-io · npm-publish

Publish an npm package to npmjs.org; skip if (name, version) already exists; auto-rename to @pleme-io/<original> on name conflict.

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
  access:
    description: "npm publish --access flag (public | restricted)"
    required: false
    default: "public"
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
  - uses: pleme-io/actions/npm-publish@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
