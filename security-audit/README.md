# pleme-io · security-audit

Polymorphic dependency-vulnerability audit. Detects repo type + routes to cargo-audit / npm-audit / pip-audit / etc. Emits a typed severity summary.

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  fail-on-severity:
    description: "Lowest severity that fails the build: low | medium | high | critical | none"
    required: false
    default: "medium"
  ignore-list:
    description: "Space-separated list of advisory IDs to ignore (e.g. RUSTSEC-2024-0001)"
    required: false
    default: ""
```

## Outputs

```yaml
  severity:
    description: "Highest severity found (none / low / medium / high / critical)"
    value: ${{ steps.audit.outputs.severity }}
  vuln-count:
    description: "Total number of vulnerabilities found"
    value: ${{ steps.audit.outputs.vuln-count }}
  ecosystem:
    description: "Which auditor ran (cargo-audit / npm-audit / pip-audit / none)"
    value: ${{ steps.audit.outputs.ecosystem }}
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/security-audit@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
