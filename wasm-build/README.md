# pleme-io · wasm-build

> Build a Rust crate to wasm32 (wasm32-unknown-unknown / wasm32-wasi). Universal — wraps cargo + wasm-pack when needed.

**Category**: `language` — 🌐 Multi-language (Go/Java/.NET/Swift/Elixir/Zig/WASM)
**Backend**: shell
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/wasm-build@v1
    with:
      package: ""
      release: "true"
      target: "wasm32-unknown-unknown"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `package` | no | `` | Cargo package to build (empty = workspace default) |
| `release` | no | `true` |  |
| `target` | no | `wasm32-unknown-unknown` | wasm32-unknown-unknown | wasm32-wasi | wasm32-wasip1 |
| `wasm-pack` | no | `false` | Use wasm-pack (true) or plain cargo (false) |

## Outputs

| Name | Description |
|---|---|
| `artifact-path` |  |

## Configuration via `.pleme-io-release.toml`

Per-repo defaults follow 3-tier precedence:
**env var (workflow input) > `.pleme-io-release.toml` > hardcoded default**.

See the [full config schema](https://github.com/pleme-io/substrate/blob/main/lib/release/example-config.toml).

## Architecture

Composite GitHub Action. Logic lives in [`run.tlisp`](./run.tlisp);
[`action.yml`](./action.yml) orchestrates install steps + one
`tatara-script` invocation.

Per the ★★ NO-SHELL prime directive
([pleme-io-pattern-core skill](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-pattern-core/SKILL.md)):
this action's primary logic is typed Lisp, not bash. The substrate's
[`action-shell-lint`](../action-shell-lint/) enforces this fleet-wide on every PR.

## Related primitives — `language` category

[`dotnet-publish`](../dotnet-publish/) · [`go-build`](../go-build/) · [`go-test`](../go-test/) · [`golangci-lint`](../golangci-lint/) · [`goreleaser`](../goreleaser/) · [`gradle-build`](../gradle-build/) · [`hex-publish`](../hex-publish/) · [`maven-build`](../maven-build/)

## Auto-published on free public CI

Every push to `main` on `pleme-io/actions`:
1. `auto-bump.yml` fires (~10s) → tags `v0.13.{next}`
2. `release.yml` cuts the Docker image (if applicable) + fast-forwards `v1`
3. Consumers using `@v1` see the new revision automatically

**$0/month cost** — GitHub-hosted runners + public-repo free tier.

## License

MIT.

---
*Auto-generated from `action.yml` by [`pleme-doc-gen`](https://github.com/pleme-io/pleme-doc-gen). Do not hand-edit.*
