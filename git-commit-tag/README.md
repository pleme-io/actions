# pleme-io · git-commit-tag

Configure github-actions bot identity, stage typed paths, commit
with a templated message, and create an annotated tag. Pairs
with `pleme-io/actions/git-push-with-token` for the push half.

## Inputs

| Name | Default | Description |
|---|---|---|
| `version` | (required) | Version string used in commit message + tag |
| `tag-prefix` | `v` | Prefix prepended to the tag name |
| `commit-message-template` | `release: workspace v{version}` | `{version}` substituted |
| `add-paths` | `Cargo.toml Cargo.lock Cargo.nix` | Space-separated git pathspecs to stage |
| `identity-name` | `github-actions[bot]` | git user.name |
| `identity-email` | `41898282+github-actions[bot]@...` | git user.email |

## Outputs

| Name | Description |
|---|---|
| `tag` | The created tag name (e.g. `v0.1.1`) |

## Example

```yaml
- uses: pleme-io/actions/git-commit-tag@v1
  with:
    version: ${{ steps.bump.outputs.new-version }}
    add-paths: "Cargo.toml Cargo.lock Cargo.nix engenho-*/Cargo.toml engenho/Cargo.toml"

- uses: pleme-io/actions/git-push-with-token@v1
  with:
    token: ${{ secrets.BOT_PAT || secrets.GITHUB_TOKEN }}
    branch: main
    push-tags: "true"
```
