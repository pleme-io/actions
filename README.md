# `pleme-io/actions`

> Reusable GitHub Actions powered by [pleme-io](https://github.com/pleme-io) forge binaries.

This is a monorepo of first-class custom GitHub Actions. Each one wraps a single forge primitive (a Rust binary released by `pleme-io/iac-forge-cli` and friends, or a `nix run .#<app>` from `pleme-io/substrate`). Consumers compose these into thin 5-line workflows in their service repos.

See [`pleme-io/theory/CONSTRUCTIVE-SUBSTRATE-ENGINEERING.md`](https://github.com/pleme-io/theory/blob/main/CONSTRUCTIVE-SUBSTRATE-ENGINEERING.md) for the architectural rationale.

## Architecture

```
Layer 0: Rust binaries (forge crates) — cross-arch GH Release artifacts
Layer 1: pleme-io/actions       (this repo) — first-class custom GH Actions
Layer 2: pleme-io/substrate/.github/workflows — composite workflows
Layer 3: thin 5-line workflows in consumer repos
```

## Actions

| Action | What it does |
| --- | --- |
| [`iac-forge`](./iac-forge) | Run IaC codegen against a spec + provider TOML (wraps the `iac-forge` Rust binary) |
| [`substrate-bump`](./substrate-bump) | Bump version via `nix run .#bump -- <type>` |
| [`nix-flake-check`](./nix-flake-check) | Run `nix flake check` with DeterminateSystems + magic-nix-cache |
| [`ansible-collection-build`](./ansible-collection-build) | Build an Ansible collection tarball via `nix run .#build` |
| [`ansible-collection-publish`](./ansible-collection-publish) | Publish a collection to Galaxy via `nix run .#publish` |
| [`spec-watch`](./spec-watch) | Detect upstream OpenAPI/JSON spec changes by sha256 |

## Install pattern

Pin a floating major:

```yaml
- uses: pleme-io/actions/iac-forge@v1
```

Pin an exact version:

```yaml
- uses: pleme-io/actions/iac-forge@v0.1.0
```

Pin to `main` (not recommended for production):

```yaml
- uses: pleme-io/actions/iac-forge@main
```

## Versioning policy

- Semver tags: `vMAJOR.MINOR.PATCH`.
- A major-version branch (e.g. `v1`) is fast-forwarded to the latest matching tag on every release. Consumers pinning `@v1` get auto-updates within the major.
- Breaking changes bump the major and create a new branch (`v2`, …). The old `v1` branch keeps working but stops moving.

## Contributing

- Each action lives in its own subdirectory (`<name>/action.yml` + `README.md` + `tests/test.yml`).
- Composite actions are preferred over Docker actions (faster cold-start, no image registry overhead, easier to debug).
- For new actions that wrap a forge binary, follow the `iac-forge/` pattern: detect runner OS/arch, resolve version, download, exec.

## License

MIT — see [LICENSE](./LICENSE).
