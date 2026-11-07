# blue-service-release

Release a blue service and ask the fleet to run it. The logic is `run.b`;
`blue test run.b` runs its tests.

## The path

A service repository calls `pleme-io/substrate/.github/workflows/blue-service-release.yml`
after its CI job, on a push to `main`:

1. **release**: `bump` raises the version in the Bluefile's
   `package("name", "X.Y.Z")` line, runs `blue lock .` and `nix run .#regen`;
   `tag` commits that as `Release <name> <X.Y.Z>.`, writes the annotated tag
   `vX.Y.Z`, and pushes the commit and the tag in one atomic push.
2. **chart**: `pleme-io/actions/helm-publish` packages `deploy/<name>/chart`
   at that tag and pushes it to `oci://ghcr.io/pleme-io/charts`.
3. **deploy**: `request-deploy` sends a `repository_dispatch` (`flake-input-update`) to
   `pleme-io/nix`'s `flake-update.yml` with `mode: push` and
   `inputs: <name>`.
4. In `pleme-io/nix`, `flake-update.yml` runs `flake-bump`: `nix flake update
   <name>`, the promotion gate `.#checks.x86_64-linux.promotion-gate`, a commit
   `Bump <name> to <rev> in flake.lock.`, and a push to `main`. plo's sentinela
   deploys that commit.

The release commit starts the service's CI again. `bump` sees the `vX.Y.Z`
tag on HEAD, reports `released=false`, and the run releases nothing. A run
whose commit is no longer the head of `main` (`expect-head`) also releases
nothing: the run for the newer commit releases it after that commit's CI.

## Modes

| Mode | Runs in | Inputs | Outputs |
|---|---|---|---|
| `bump` | the service, a checkout with tags | `bump` (patch, minor, major), `bluefile`, `lock`, `regen` | `released`, `name`, `version`, `tag` |
| `tag` | the same checkout, after `bump` | `version` (default: the Bluefile's), `branch` | `tag`, `version`, `commit-sha` |
| `request-deploy` | anywhere | `flake-input`, `consumer-repo`, `event`, `token` | `status`, `dispatched` |
| `flake-bump` | the consumer, a checkout | `flake-inputs`, `verify`, `branch` | `changed`, `verified`, `pushed`, `commit-sha`, `reason` |

`tag` refuses a tag that exists, and a tag not greater than the highest
`vX.Y.Z` tag. When the push is refused because the branch moved, `tag` drops
its local tag, rebases on the branch, checks the tag again, and retries, four
times at most. `flake-bump` retries the same way, but starts again from the new
head: it updates and verifies again, because the lock it verified is not the
lock it would push.

## Tokens

| Step | Token | Why |
|---|---|---|
| release | the fleet App token (`pleme-io/actions/github-token`, contents write) in the checkout | a push made with `GITHUB_TOKEN` starts no workflow, and the release must be visible to the next CI run |
| chart | `GITHUB_TOKEN` with `packages: write`, or `BOT_PAT` when the token source is pat | the ghcr login of `helm-publish` |
| deploy | the fleet App token, contents write on `pleme-io/nix` | a `repository_dispatch` needs only contents write; the App holds no actions permission (a mint asking for it answers 422, 2026-11-07) |
| flake-bump | `pleme-io/nix`'s own App token | the push to nix `main` |

The push to `pleme-io/nix` stays inside nix's own workflow. A service never
holds a token that can write the fleet's configuration: it can only ask for one
named input to be bumped, and nix decides, gates and pushes. The dispatch is
the whole interface, so a compromised service repository can start an update
but cannot write a lock.

The dispatch token goes to curl on stdin as a config line, never in the argv.
