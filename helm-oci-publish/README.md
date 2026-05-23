# pleme-io · helm-oci-publish

Lint, package, and push a Helm chart to an OCI registry

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  chart-path:
    description: "Path to the Helm chart directory (containing Chart.yaml)"
    required: true
  registry:
    description: "OCI registry URL (oci:// scheme)"
    required: true
  version:
    description: "Override chart version; empty falls through to Chart.yaml's version"
    required: false
    default: ""
  lib-chart-dir:
    description: "External library chart directory for file:// deps"
    required: false
    default: ""
  lib-chart-name:
    description: "Library chart name"
    required: false
    default: "pleme-lib"
```

## Outputs

```yaml
(none)
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/helm-oci-publish@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
