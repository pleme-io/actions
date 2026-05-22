# pleme-io · rust-workspace-bump

Bump a Rust workspace's `workspace.package.version` via
`cargo set-version --workspace --bump <type>`, regenerate
`Cargo.nix`, refresh `Cargo.lock`. Pure composite action — no
shell beyond install glue; all logic lives in `run.tlisp` and
runs through `pleme-io/actions/tatara-script`.

## Inputs

| Name | Default | Description |
|---|---|---|
| `bump-type` | `patch` | `patch` / `minor` / `major` |
| `skip-when-no-source-changes` | `true` | Skip the bump when none of the `source-paths` changed since the previous tag |
| `source-paths` | `engenho* Cargo.toml Cargo.lock` | Space-separated globs the skip-detector inspects |

## Outputs

| Name | Description |
|---|---|
| `bumped` | `true` if a bump happened, `false` if skipped/no-op |
| `new-version` | New `workspace.package.version` after bump (empty when `bumped=false`) |
| `old-version` | Previous `workspace.package.version` (always populated) |

## Example: minimal auto-bump workflow

```yaml
name: auto-bump
on:
  push:
    branches: [main]

permissions:
  contents: write

jobs:
  bump:
    runs-on: ubuntu-latest
    if: github.actor != 'github-actions[bot]'
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: ${{ secrets.BOT_PAT || secrets.GITHUB_TOKEN }}

      - id: bump
        uses: pleme-io/actions/rust-workspace-bump@v1

      - if: steps.bump.outputs.bumped == 'true'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add Cargo.toml Cargo.lock Cargo.nix
          git commit -m "release: workspace v${{ steps.bump.outputs.new-version }}"
          git tag "v${{ steps.bump.outputs.new-version }}"

      - if: steps.bump.outputs.bumped == 'true'
        uses: pleme-io/actions/git-push-with-token@v1
        with:
          token: ${{ secrets.BOT_PAT || secrets.GITHUB_TOKEN }}
          branch: main
          push-tags: "true"
```

## NO SHELL prime directive

Per the org rule, ALL non-trivial logic lives in `run.tlisp`
(tatara-lisp). The shell snippets above wrapping git commit/tag
are 3-line glue (acceptable); the bump/regen/refresh logic itself
is pure tlisp.

A future iteration will collapse the commit/tag glue into a
`pleme-io/actions/git-commit-tag` action so this workflow is
zero-shell end-to-end.
