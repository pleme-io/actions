# `pleme-io/actions/nix-flake-check`

Run `nix flake check` on a Nix flake, with the DeterminateSystems Nix installer and magic-nix-cache pre-wired.

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `flake-args` | no | `""` | Extra arguments appended to `nix flake check` (e.g. `--override-input foo path:./foo`) |
| `no-warn-dirty` | no | `"true"` | Pass `--no-warn-dirty` (string `"true"`/`"false"`) |

## Outputs

None.

## Usage

```yaml
- uses: pleme-io/actions/nix-flake-check@v1
```

With overrides:

```yaml
- uses: pleme-io/actions/nix-flake-check@v1
  with:
    flake-args: "--override-input substrate path:./substrate"
    no-warn-dirty: "false"
```

## How it works

This is a composite action. It:

1. Installs Nix via [`DeterminateSystems/nix-installer-action`](https://github.com/DeterminateSystems/nix-installer-action).
2. Enables [`DeterminateSystems/magic-nix-cache-action`](https://github.com/DeterminateSystems/magic-nix-cache-action) so repeated `nix build` calls in the same workflow share a cache.
3. Runs `nix flake check` with optional `--no-warn-dirty` and any extra args.

No external Rust binary is required — the heavy lifting is done by Nix itself.
