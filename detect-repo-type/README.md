# pleme-io · detect-repo-type

Detect the repo type from manifest file presence at the root.
Emits a typed identifier the polymorphic auto-release workflow
routes on.

## Outputs

| Name | Description |
|---|---|
| `repo-type` | One of: `rust-workspace`, `rust-single-crate`, `npm`, `python`, `helm`, `ansible-collection`, `ruby-gem`, `github-action`, `unknown` |
| `manifest-path` | The file that drove the detection (`Cargo.toml`, `package.json`, etc) |

## Example

```yaml
jobs:
  detect:
    runs-on: ubuntu-latest
    outputs:
      repo-type: ${{ steps.detect.outputs.repo-type }}
    steps:
      - uses: actions/checkout@v4
      - id: detect
        uses: pleme-io/actions/detect-repo-type@v1

  rust-workspace-release:
    needs: detect
    if: needs.detect.outputs.repo-type == 'rust-workspace'
    uses: ./.github/workflows/rust-workspace-pipeline.yml

  cargo-release:
    needs: detect
    if: needs.detect.outputs.repo-type == 'rust-single-crate'
    uses: ./.github/workflows/cargo-pipeline.yml
```

## Precedence

When multiple manifests coexist (e.g. a Rust repo that also has
a `Chart.yaml` for its helm chart), detection picks the FIRST
match in this order:

1. `Cargo.toml` with `[workspace]` → rust-workspace
2. `Cargo.toml` with `[package]` (no `[workspace]`) → rust-single-crate
3. `galaxy.yml` → ansible-collection
4. `Chart.yaml` → helm
5. `pyproject.toml` → python
6. `package.json` → npm
7. `*.gemspec` at root → ruby-gem
8. `action.yml` (or `action.yaml`) → github-action
9. otherwise → `unknown` (exit 1)

The precedence reflects fleet-wide convention: a repo's
"primary" artifact wins. Subordinate manifests get released via
separate workflows triggered by the primary release.
