# pleme-io · zot-pull-scan

> The **zot faucet gate**: pull an image from a private zot registry, scan the
> **pulled bytes** with Trivy, and admit it into the trusted zone **only** when
> the scan clears the `fail-on-severity` gate. Nothing enters unscanned.

Part of the **super-cache-ci** delivery leg — the faucet between the build
registry and the trusted zone. Composes skopeo (pull) + Trivy (the `image-scan`
surface). The scan runs on the **local docker-archive we pulled**, so you scan
exactly what you pulled — not a re-resolved tag.

```yaml
- uses: pleme-io/actions/zot-pull-scan@v1
  id: scan
  with:
    ref: ${{ steps.publish.outputs.ref-amd64 }}
    fail-on-severity: HIGH
    # ignore-unfixed: "false"
```

## Outputs

| Name | Meaning |
|---|---|
| `admitted` | `true` iff pulled AND the scan cleared the gate |
| `severity` | highest severity found (`CRITICAL`…`LOW`/`none`) |
| `vuln-count` | coarse count of `Severity` occurrences |
| `local-archive` | path of the pulled docker-archive |
| `result` | `admitted` \| `rejected` \| `pull-failed` |

## Tier-honesty

- **now** — pull + scan + gate all wrap shipped, baked-in binaries (skopeo,
  trivy). The gate logic (`severity-rank`, `classify-severity`, `rejects?`,
  `count-occurrences`) is pure + unit-tested. A live pull needs a reachable zot
  + docker auth (a runtime pre-condition, not an unshipped seam).

## Architecture

Composite action; logic is typed tatara-lisp in [`run.tlisp`](./run.tlisp) over
`_tlisp-stdlib`. Pure helpers are unit-tested by [`run.test.tlisp`](./run.test.tlisp).

> **Compounding note:** `severity-rank` / `classify-severity` duplicate the
> `image-scan` action. This is the second site — they should lift to a `scan:`
> section of `_tlisp-stdlib` (Pillar 12). Kept local here to avoid cross-agent
> stdlib contention during the super-cache-ci build.
