# pleme-io · tlisp-lint

Validate every `*.tlisp` file under the repo at PR time. Catches
the "extra close paren / missing close paren / unterminated
string" class of bug BEFORE it hits a tag-triggered release
workflow.

Pure tatara-lisp; runs on every PR via the actions-repo CI.

## Inputs

| Name | Default | Description |
|---|---|---|
| `paths` | `**/*.tlisp` | Glob pattern for files to lint |
| `fail-on-unbalanced` | `true` | Exit non-zero on any error |
| `run-parser-check` | `true` | Additionally invoke tatara-script's parser (when installed) |

## Outputs

| Name | Description |
|---|---|
| `files-scanned` | Number of `.tlisp` files scanned |
| `errors-found` | Number of files with errors |

## Example: CI integration

```yaml
# .github/workflows/ci.yml
on:
  pull_request:
  push:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pleme-io/actions/tlisp-lint@v1
```

## What it catches

Every bug class I personally hit during the rust-workspace-bump +
rust-workspace-publish build today:

1. **Extra close paren** — `(else (foo)))))` when only `(else (foo)))` is needed
2. **Missing close paren** — `(define (f x) ...` without final `)`
3. **Unterminated string literal** — `"hello` without closing `"`

Each scan emits `balance=N first_neg=L unterminated_string_line=L`
so the failure mode is immediately diagnosable from the CI log.

## Architecture

Pure composite action — no Docker. The tlisp source itself
invokes `python3 -c '...'` (one shell command per file) for the
paren-counting state machine because doing the same in pure
tatara-lisp would re-implement what python already does in 10
lines. The 3-line shell delegation IS the inline-glue exception
the NO SHELL prime directive allows.
