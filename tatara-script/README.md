# `pleme-io/actions/tatara-script`

Execute an embedded [`tatara-lisp`](https://github.com/pleme-io/tatara-lisp) source string with the `tatara-script` interpreter on a GitHub Actions runner. Install path is **binary-first** (cross-arch pre-built artifact from `pleme-io/tatara-lisp` releases), with a `cargo install --git` fallback if the binary asset is missing for the requested tag/arch.

This is the redistributable primitive that every other tlisp-backed `pleme-io/actions/*` action delegates to. Use it directly when you have a one-off .tlisp body that does not warrant its own action.

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `script` | yes | — | Multi-line `.tlisp` source executed by `tatara-script` (the entire body of a `.tlisp` file) |
| `version` | no | `latest` | `tatara-lisp` release tag (e.g. `v0.1.0`) or `latest` |
| `args` | no | `""` | Whitespace-split positional arguments forwarded to the script as `$@` |

## Outputs

None. The action exits with whatever exit code the script returns.

## Usage

```yaml
- uses: pleme-io/actions/tatara-script@v1
  with:
    script: |
      (define name (env-get "GREET_NAME" "world"))
      (log-info (string-append "hello, " name "!"))
      (exit 0)
```

Pin a specific version when reproducibility matters:

```yaml
- uses: pleme-io/actions/tatara-script@v1
  with:
    version: v0.1.0
    script: |
      (log-info "pinned interpreter")
```

Pass positional args:

```yaml
- uses: pleme-io/actions/tatara-script@v1
  with:
    args: foo bar baz
    script: |
      (log-info (string-append "got " (string-format "{}" (length argv)) " args"))
```

## Install fallback

If the requested tag has no pre-built `tatara-script-<os>-<arch>` asset on the release page (e.g. an old tag predating the binary-release workflow, or a brand-new tag still being built), the action falls back to:

```
cargo install --git https://github.com/pleme-io/tatara-lisp --tag <tag> tatara-lisp-script
```

This requires `cargo` on the runner (GitHub-hosted Ubuntu/macOS runners ship it). Self-hosted runners without Rust toolchains should pin a version that has binary assets.
