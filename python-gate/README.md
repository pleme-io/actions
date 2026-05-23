# pleme-io · python-gate

PR-time quality gate for a Python repo: ruff format --check + ruff check + pytest. Universal across uv/poetry/hatch layouts.

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  run-fmt:
    description: "Run ruff format --check"
    required: false
    default: "true"
  run-lint:
    description: "Run ruff check"
    required: false
    default: "true"
  run-test:
    description: "Run pytest"
    required: false
    default: "true"
```

## Outputs

```yaml
  fmt-passed:
    value: ${{ steps.gate.outputs.fmt-passed }}
  lint-passed:
    value: ${{ steps.gate.outputs.lint-passed }}
  test-passed:
    value: ${{ steps.gate.outputs.test-passed }}
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/python-gate@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
