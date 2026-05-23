# pleme-io · gh-release-create

Create a GitHub Release for a tag with optional auto-generated notes + asset uploads. Universal primitive — any language, any package shape.

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  tag:
    description: "Tag name to release (e.g. v0.1.4). Defaults to the current ref."
    required: false
    default: ""
  title:
    description: "Release title. Defaults to the tag name."
    required: false
    default: ""
  notes:
    description: "Release notes body (markdown). When empty, gh's --generate-notes is used."
    required: false
    default: ""
  draft:
    description: "Create as draft"
    required: false
    default: "false"
  prerelease:
    description: "Mark as prerelease"
    required: false
    default: "false"
  assets:
    description: "Space-separated paths to upload as release assets"
    required: false
    default: ""
  if-exists:
    description: "skip | update | fail when the release already exists"
    required: false
    default: "skip"
```

## Outputs

```yaml
  release-url:
    description: "URL of the created (or existing) release"
    value: ${{ steps.create.outputs.release-url }}
  created:
    description: "'true' if a new release was created, 'false' if skipped/updated"
    value: ${{ steps.create.outputs.created }}
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/gh-release-create@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
