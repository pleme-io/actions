# pleme-io · sbom-generate

Generate a CycloneDX or SPDX SBOM from the repo via syft. Universal — works on any source tree (Rust, Node, Python, Helm, Docker context, etc).

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  output-format:
    description: "cyclonedx-json | spdx-json | syft-json"
    required: false
    default: "cyclonedx-json"
  output-file:
    description: "Path to write the SBOM"
    required: false
    default: "sbom.cyclonedx.json"
```

## Outputs

```yaml
  sbom-path:
    description: "Path of the written SBOM"
    value: ${{ steps.sbom.outputs.sbom-path }}
  component-count:
    description: "Number of components in the SBOM"
    value: ${{ steps.sbom.outputs.component-count }}
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/sbom-generate@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
