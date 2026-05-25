# pleme-io · cargo-publish-each-member

Publish each workspace member to crates.io at its own `[package].version`.
For multi-crate workspaces **without** a shared `[workspace.package].version`
(rust-url / bindgen / dirs-next / ratatui pattern).

## When to use

| Pattern | Action |
|---|---|
| Single crate (root `[package].version`) | `cargo-bump` + `cargo-publish-crate` |
| Workspace with shared `[workspace.package].version` (engenho) | `rust-workspace-bump` + `rust-workspace-publish` |
| **Workspace where each member owns its `[package].version`** | **this action** |

If `pleme-io/actions/detect-repo-type` returns `rust-workspace` but the
substrate's bumpable-version guard skipped emitting `auto-release.yml`,
this action is what your repo needs.

## What it does

1. `cargo metadata --no-deps` → list every workspace member + manifest path
2. For each member:
   - Read `<dir>/Cargo.toml`'s `[package].version`
   - Read the latest tag matching `<member-name>-v*` (per-member tag convention)
   - If `--skip-when-no-source-changes` AND no `<dir>` files changed since
     that tag → skip
   - Otherwise: `cargo set-version --bump <type>` in the member dir
   - `cargo publish` from the member dir (honors `--dry-run`, `--no-verify`)
3. Output `published-count` / `skipped-count` / `failed-count`

## Inputs

| name | default | meaning |
|---|---|---|
| `bump-type` | `patch` | `patch | minor | major` (per-member bump) |
| `dry-run` | `false` | run `cargo publish --dry-run` only (no upload) |
| `no-verify` | `true` | skip cargo's verification compile (faster) |
| `skip-when-no-source-changes` | `true` | skip member when no source change since its last tag |

## Outputs

- `published-count` — members successfully uploaded (or already-uploaded, treated as success)
- `skipped-count` — members with no source changes since last tag
- `failed-count` — members that failed transient errors (rate limit / compile error)

## Required secrets

- `CRATES_API_TOKEN` — crates.io publish token, written to `~/.cargo/credentials.toml` before publish

## Companion: `cargo-publish-each-member-auto-release.yml`

The reusable workflow at `pleme-io/substrate/.github/workflows/cargo-publish-each-member-auto-release.yml`
wires this action into the canonical 3-line auto-release shim. Consumers point
their `auto-release.yml` at that workflow.
