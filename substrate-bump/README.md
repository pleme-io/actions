# `pleme-io/actions/substrate-bump`

Bump a project's version using the substrate flake's `bump` app: `nix run .#bump -- <type>`.

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `bump-type` | no | `patch` | One of `patch`, `minor`, `major` |
| `release-paths` | no | `plugins/ meta/ galaxy.yml` | Space-separated paths the bump app should touch (forward-compat; substrate decides which paths it actually edits) |

## Outputs

| Name | Description |
| --- | --- |
| `bumped` | `true` if a bump was performed, `false` if it was a no-op |
| `new-version` | New version after the bump (empty when no-op) |

## Usage

```yaml
- uses: pleme-io/actions/substrate-bump@v1
  id: bump
  with:
    bump-type: minor

- if: steps.bump.outputs.bumped == 'true'
  run: echo "Bumped to ${{ steps.bump.outputs.new-version }}"
```

## How it works

This is a composite action. It:

1. Installs Nix (DeterminateSystems installer) and enables magic-nix-cache.
2. Reads the current `version:` from `galaxy.yml` (best-effort, may be empty for non-Ansible projects).
3. Runs `nix run .#bump -- <bump-type>` against the consumer's flake (which must expose a `bump` app).
4. Re-reads `version:` and emits `bumped` + `new-version` outputs accordingly.

Upstream: [`pleme-io/substrate`](https://github.com/pleme-io/substrate).
