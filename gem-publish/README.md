# pleme-io · gem-publish

Build & push a Ruby gem to RubyGems.org, tolerating identical-version re-pushes

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  gem-name:
    description: "Gem name (matches <gem-name>.gemspec at repo root)"
    required: true
  tag-version:
    description: "Version expected on rubygems (derived from tag)"
    required: true
```

## Outputs

```yaml
(none)
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/gem-publish@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
