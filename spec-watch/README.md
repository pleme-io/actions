# `pleme-io/actions/spec-watch`

Detect changes in an upstream OpenAPI/JSON spec by comparing its sha256 against a value cached in the repo. Useful for "regenerate codegen when upstream changes" cron workflows.

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `upstream-url` | yes | — | URL of the upstream spec (any text/binary file) |
| `cache-file` | no | `.ci/openapi-sha` | Path (relative to repo root) where the last-seen sha256 is stored |

## Outputs

| Name | Description |
| --- | --- |
| `changed` | `true` if the upstream sha differs from cached, `false` otherwise |
| `new-sha` | sha256 of the upstream spec fetched this run |
| `cached-sha` | sha256 previously stored in the cache file (empty on first run) |

## Usage

```yaml
- uses: pleme-io/actions/spec-watch@v1
  id: watch
  with:
    upstream-url: https://api.example.com/openapi.json

- if: steps.watch.outputs.changed == 'true'
  run: |
    echo "${{ steps.watch.outputs.new-sha }}" > .ci/openapi-sha
    # ... regenerate, commit, open PR ...
```

## How it works

This is a composite action. It:

1. `curl`s the `upstream-url` to a tempfile.
2. Computes `sha256sum` of the response.
3. Reads `cache-file` (if present) and compares.
4. Emits `changed`, `new-sha`, `cached-sha` outputs.

No external Rust binary needed — this is pure shell.
