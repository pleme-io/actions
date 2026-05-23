# pleme-io · helm-publish

Publish a Helm chart to an OCI registry (default ghcr.io/pleme-io/helm); skip if (name, version) already exists.

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  registry:
    description: "OCI registry to push to"
    required: false
    default: "ghcr.io/pleme-io/helm"
  registry-username:
    description: "Registry login username (default github.actor)"
    required: false
    default: ""
  dry-run:
    description: "Package the chart but don't push"
    required: false
    default: "false"
```

## Outputs

```yaml
  shipped:
    value: ${{ steps.ship.outputs.shipped }}
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/helm-publish@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
