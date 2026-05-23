# pleme-io · git-push-with-token

Rewrite origin URL with the given token, push branch + tags so downstream workflows can be triggered

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  token:
    description: "Token used as x-access-token in the rewritten origin URL"
    required: true
  branch:
    description: "Branch to push (default: main)"
    required: false
    default: main
  push-tags:
    description: "Whether to also push --tags (default: true)"
    required: false
    default: "true"
```

## Outputs

```yaml
(none)
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/git-push-with-token@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
