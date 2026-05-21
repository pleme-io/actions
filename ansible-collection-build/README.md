# `pleme-io/actions/ansible-collection-build`

Build an Ansible collection tarball using the substrate flake's `build` app: `nix run .#build`.

## Inputs

None.

## Outputs

| Name | Description |
| --- | --- |
| `tarball-path` | Path to the produced collection tarball (e.g. `./namespace-collection-1.2.3.tar.gz`) |
| `version` | Collection version read from `galaxy.yml` |

## Usage

```yaml
- uses: pleme-io/actions/ansible-collection-build@v1
  id: build

- name: Upload tarball
  uses: actions/upload-artifact@v4
  with:
    name: collection-${{ steps.build.outputs.version }}
    path: ${{ steps.build.outputs.tarball-path }}
```

## How it works

This is a composite action. It:

1. Installs Nix (DeterminateSystems) and enables magic-nix-cache.
2. Runs `nix run .#build` (the substrate flake's `build` app) against the consumer's repo, which produces a `*.tar.gz` in the working directory.
3. Reads `version:` from `galaxy.yml` (best-effort) and emits both outputs.

Upstream: [`pleme-io/substrate`](https://github.com/pleme-io/substrate) (provides `apps.build`).
