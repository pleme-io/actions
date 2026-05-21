# `pleme-io/actions/ansible-collection-publish`

Publish an Ansible collection to Ansible Galaxy using the substrate flake's `publish` app: `nix run .#publish`.

## Inputs

None.

## Outputs

None.

## Required env

| Name | Description |
| --- | --- |
| `ANSIBLE_GALAXY_TOKEN` | Galaxy API token. **If unset the action is a silent no-op** (exit 0) so that PRs and unprivileged forks don't fail. |

## Usage

```yaml
- uses: pleme-io/actions/ansible-collection-publish@v1
  env:
    ANSIBLE_GALAXY_TOKEN: ${{ secrets.ANSIBLE_GALAXY_TOKEN }}
```

## How it works

This is a composite action. It:

1. Installs Nix (DeterminateSystems) and enables magic-nix-cache.
2. Checks for `$ANSIBLE_GALAXY_TOKEN`; if absent, exits 0 (so PR runs from forks degrade gracefully).
3. If present, runs `nix run .#publish` (the substrate flake's `publish` app), which uploads the most recent build artifact to Galaxy.

Upstream: [`pleme-io/substrate`](https://github.com/pleme-io/substrate) (provides `apps.publish`).
