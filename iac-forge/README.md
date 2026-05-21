# `pleme-io/actions/iac-forge`

Generate IaC provider code (Ansible, Terraform, Pulumi, Crossplane, Steampipe, Helm) from an OpenAPI spec + a directory of resource TOMLs, using the [`iac-forge`](https://github.com/pleme-io/iac-forge-cli) Rust binary.

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `backend` | yes | — | One of `ansible`, `terraform`, `pulumi`, `crossplane`, `steampipe`, `helm` |
| `spec` | yes | — | Path to OpenAPI spec (yaml or json) |
| `resources` | yes | — | Path to resource TOML directory |
| `provider` | yes | — | Path to `provider.toml` |
| `data-sources` | no | `""` | Path to data-source TOML directory |
| `output` | yes | — | Output directory for generated artifacts |
| `version` | no | `latest` | iac-forge-cli release tag (e.g. `v0.2.0`) or `latest` |

## Outputs

This action has no outputs. The generated files appear in the path given by `output`.

## Usage

```yaml
- uses: pleme-io/actions/iac-forge@v1
  with:
    backend: ansible
    spec: openapi.yaml
    resources: resources/
    provider: provider.toml
    output: generated/
```

Pinning a version:

```yaml
- uses: pleme-io/actions/iac-forge@v1
  with:
    backend: terraform
    spec: openapi.yaml
    resources: resources/
    provider: provider.toml
    output: generated/
    version: v0.2.0
```

## How it works

This is a composite action. On every run it:

1. Detects `$RUNNER_OS-$RUNNER_ARCH` and maps it to one of `linux-x86_64`, `linux-aarch64`, `macos-x86_64`, `macos-aarch64`.
2. Resolves `version` (calling the GitHub API when `latest`) and downloads `iac-forge-<suffix>` from the matching [`iac-forge-cli` release](https://github.com/pleme-io/iac-forge-cli/releases).
3. Runs `iac-forge generate --backend ... --spec ... --resources ... --provider ... [--data-sources ...] --output ...`.

Upstream: [`pleme-io/iac-forge-cli`](https://github.com/pleme-io/iac-forge-cli).
