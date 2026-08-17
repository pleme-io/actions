# hardened-image-plan

Read a hardened-image **catalog** out of a flake and emit the resolved delivery
matrices. The single-responsibility sibling of `build-matrix`.

`build-matrix` enumerates a flake's colon-triple image attrs and fans them across
`(service, arch)`; it knows nothing about a component beyond its name. This verb
reads a *rich* per-component catalog — `zot` / `harbor` / `publishName` / scan
posture — and resolves the **delivery** conditions into plain booleans on each row.

## Why

`pleme-io/hardened-images` carries one hand-written job per component per phase.
Measured 2026-08-12: **7027 lines, 109 jobs, 40 catalog rows** — of which 22 have
a mirror job and 13 a promote job. The other 18 declare `zot = true` and nothing
honours it.

That gap is invisible, and that is the point: a typed catalog flag read by
nothing does not fail. Resolving the conditions here makes the flag the only
place a component is configured, so a new component is a catalog row rather than
three more jobs.

## Usage

```yaml
- id: runner
  uses: pleme-io/actions/runner-resolve@main
- id: plan
  uses: pleme-io/actions/hardened-image-plan@main
  with:
    flake-ref: "."
    catalog-attr: hardenedImageCatalog
    event: ${{ github.event_name }}
    only: ${{ inputs.only }}
    stage: ${{ inputs.stage }}
    max-stage: ${{ inputs.ship-downstream && 'all' || 'mirror' }}
    held-file: tools/delivery-hold.txt
    runner: ${{ steps.runner.outputs.runner }}

# then, in a separate job:
strategy:
  matrix: ${{ fromJSON(needs.plan.outputs.pipeline-matrix) }}
uses: pleme-io/substrate/.github/workflows/hardened-image-pipeline.yml@main
with:
  spec: ${{ toJSON(matrix) }}
```

## The four phase booleans

Each row carries `doBuild`, `doPush`, `doMirror`, `doPromote`, already resolved.
The called workflow branches on them and contains no lane logic, so it cannot
re-invent any.

| stage | build | push | mirror | promote |
|---|---|---|---|---|
| `build` | ✓ | | | |
| `publish` | ✓ | ✓ | | |
| `mirror` | ✓ | ✓ | ✓ (if `zot` and not held) | |
| `all` | ✓ | ✓ | ✓ | ✓ (if `harbor` and not held) |
| `rescan` | | | | |

Default per event: `push` → publish · `workflow_dispatch` → all ·
`pull_request` → build · `schedule` → rescan · anything unrecognised → **build**
(the least destructive, never the most).

## `max-stage` is a ceiling, never a floor

It clamps the resolved stage **down** and can only reduce: under a `mirror` cap
an explicit `build` still yields `build`. That one-directional property is what
makes it safe to leave on in a caller.

It exists because the last phase is the only irreversible one. `build`, `publish`
and `mirror` act on artifacts we own; `all` writes a commit into another team's
environment repo, and that commit *is* the deploy. Without a cap, a caller ships
by leaving `stage` empty — an empty stage on a dispatch resolves to `all`.

`rescan` ranks 0 deliberately: it neither builds nor pushes nor writes
downstream, so no ceiling excludes it.

## The hold set is the rollout brake

A component listed in `held-file` builds and publishes but never mirrors or
promotes. It starts delivering by being **deleted** from that file, so the list's
done-predicate is a deletion and its end state is that the file does not exist.

The file's leading `<slug>:` per line is the component; comments and blanks are
skipped and repeat findings collapse to one slug. That shape is deliberate — it
keeps the ledger readable by a human *and* parseable here, instead of a second
machine-only list beside it.

## `scanned` is the denominator, and it is an output

Every matrix here is derived from discovery, and discovery that silently finds
nothing yields an empty plan — which reads as "nothing to do" and is
indistinguishable from "everything is done". `scanned` carries the row count read
*before* any filter, so a catalog that stops being discovered reports
`scanned=0` with empty matrices instead of a clean-looking no-op.

## Catalog shape (measured, not assumed)

```
<catalog-attr> . <system> . <componentKey> . { service, publishName, publishTag,
  pushTag, upstreamImage, zot, harbor, hardeningTarget, cveClaims,
  grypeIgnoreFile, vulnixWhitelist, ... }
```

Two things a reader gets wrong:

- It is keyed **by system first** (`x86_64-linux`). Read as a flat component map
  it yields two rows named after the systems. An absent system key is a hard
  error, never an empty component set.
- `package`, `base`, `entrypoint`, `extraContents` are **not in the JSON** —
  they hold derivations, which `nix eval --json` drops rather than serializes.
  Asking for `base` yields null on every row, forever, quietly.

Also: `publishTag` is a static per-row alias. The tag that actually ships comes
from the repo-wide release mint (`release-file`), which is the same file
`flake.nix` reads for the image's `org.opencontainers.image.version` label — so
bytes and tag cannot disagree. An empty mint is refused rather than pushing an
untagged alias.

## Verification

`run.test.tlisp` — 15 `(deftest …)` over the pure helpers (the event→stage table,
the ledger parser, the stage cap). Run via `tatara-script --test`; `TLISP_TEST=1`
gates `main` so no `nix eval` runs.

The **projection** is jq and is verified differently: against the live catalog,
by parity with the workflow it replaces. Measured 2026-08-12 on
`pleme-io/hardened-images` — 40 rows in → 22 `doMirror`, 13 `doPromote`, 18 held,
matching one-for-one the 22 `mirror-*-to-zot` and 13 `promote-trigger-*`
jobs that physically exist. That parity is the real acceptance gate; the deftests
guard what parity cannot see into.

## Exit codes (keyway three-code contract)

| code | meaning |
|---|---|
| 0 | ≥1 pipeline row emitted |
| 2 | catalog read fine, 0 rows matched, `require-nonempty=false` |
| 1 | nix/jq absent or failed · a malformed row under `strict` · a lane naming no component · an empty release mint · 0 rows with `require-nonempty=true` |
