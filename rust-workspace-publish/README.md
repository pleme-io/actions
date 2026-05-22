# pleme-io · rust-workspace-publish

Ship every Rust workspace member to the registry in topological
dependency order. Auto-renames any name-conflicting crate to
`<prefix><original>` (default `pleme-io-<original>`) + commits
the rename back to the branch + retries.

Pure composite action — all the rename loop logic lives in
`run.tlisp` and runs through `pleme-io/actions/tatara-script`. No
shell beyond install glue.

## Inputs

| Name | Default | Description |
|---|---|---|
| `dry-run` | `false` | Run as `--dry-run` only (no actual upload) |
| `no-verify` | `true` | Skip the verification compile step |
| `rename-prefix` | `pleme-io-` | Prefix applied when auto-renaming a conflicting crate |
| `max-rename-retries` | `20` | Max conflict-rename iterations |

## Outputs

| Name | Description |
|---|---|
| `shipped-count` | `ok` on success, `0` on failure |
| `renamed-crates` | Comma-separated list of crates renamed during the run |

## Example: minimal tag-triggered ship workflow

```yaml
name: crates-publish
on:
  push:
    tags: ['v*']

permissions:
  contents: write

jobs:
  ship:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          ref: main
          token: ${{ secrets.BOT_PAT || secrets.GITHUB_TOKEN }}

      - uses: pleme-io/actions/rust-workspace-publish@v1
        env:
          CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_REGISTRY_TOKEN }}
```

## Conflict semantics

When a crate's name is already owned by another user, the action:

1. Renames the crate's `[package] name` from `foo` to `pleme-io-foo`.
2. Adds `package = "pleme-io-foo"` to the workspace.dependencies
   entry so other crates' Rust source can keep using `use foo::*`
   (cargo's rename-via-package field).
3. Commits the rename + pushes back to main.
4. Retries the ship.

Up to `max-rename-retries` iterations (default 20).
