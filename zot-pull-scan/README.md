# pleme-io · zot-pull-scan

> The **zot faucet gate**: pull an image from a private zot registry, then gate
> admission through **[`image-scan`](../image-scan/)** — the fleet's ONE
> canonical Trivy severity implementation — scanning the **pulled bytes**, never
> a re-resolved tag. Nothing enters the trusted zone unscanned, and nothing
> enters on a scan failure, a parse failure, or a misconfigured override either.

Part of the **super-cache-ci** delivery leg — the faucet between the build
registry and the trusted zone. Composes skopeo (pull, stage 1) + `image-scan`
(scan + gate, stage 2, a nested `uses:`) + a small verdict arbiter (stage 3)
that translates image-scan's step outcome into this action's typed
`admitted`/`result` contract and re-asserts it as this action's own exit code.
The scan runs on the **local docker-archive we pulled**, so you scan exactly
what you pulled — not a re-resolved tag.

```yaml
- uses: pleme-io/actions/zot-pull-scan@main
  id: scan
  with:
    ref: ${{ steps.publish.outputs.ref-amd64 }}
    # fail-on-severity: UNKNOWN   # default — zero-tolerance, every severity gates
    # ignore-unfixed: "false"
    # ignore-file: ".trivyignore"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `ref` | yes | — | zot image ref to pull + scan |
| `fail-on-severity` | no | `UNKNOWN` | Lowest severity that REJECTS admission: `UNKNOWN\|LOW\|MEDIUM\|HIGH\|CRITICAL\|none`. Zero-tolerance by default — this is the trusted-zone admission gate, matching the fleet's proven convention for faucet/pre-publish gates. Forwarded verbatim to `image-scan`, which forces the strictest recognized value on a malformed override. |
| `ignore-unfixed` | no | `false` | Skip vulns without an available fix. Forwarded verbatim. |
| `ignore-file` | no | `""` | Path to a `.trivyignore`-format file of named, tracked exceptions (never a blanket loosening). Forwarded verbatim. |
| `dest` | no | `zot-pull.tar` | Local docker-archive path for the pulled bytes |

## Outputs

| Name | Meaning |
|---|---|
| `admitted` | `true` iff pulled AND the scan cleared the gate |
| `severity` | highest severity found (`CRITICAL`…`UNKNOWN`/`none`), as classified by `image-scan` |
| `vuln-count` | coarse count of `Severity` occurrences, as reported by `image-scan` |
| `local-archive` | path of the pulled docker-archive |
| `result` | `admitted` \| `rejected` \| `pull-failed` |

## Tier-honesty

- **now** — pull wraps a shipped, baked-in binary (skopeo); scan+gate delegate
  entirely to `image-scan` (real jq-parsed severity classification, hard-fails
  on a broken/unreachable trivy run or a malformed trivy JSON output rather
  than defaulting to "clean", forces the strictest threshold on a malformed
  `fail-on-severity`). The verdict arbiter's pure decision logic
  (`admitted-outcome?`, `verdict-of`) is unit-tested. A live pull needs a
  reachable zot + docker/skopeo auth (a runtime pre-condition, not an
  unshipped seam).

## Architecture

Composite action, three stages, each a small typed tatara-lisp script over
`_tlisp-stdlib`:

1. [`pull.tlisp`](./pull.tlisp) — skopeo pull into a local docker-archive.
   Hard-fails (terminal) on a pull failure and emits this action's full
   output contract itself in that case.
2. `image-scan@v1` (a nested `uses:`, not a local file) — scans the pulled
   archive. Runs with `continue-on-error: true` so a rejected image still
   reaches stage 3.
3. [`verdict.tlisp`](./verdict.tlisp) — translates `steps.scan.outcome` into
   this action's `admitted`/`result` vocabulary and re-asserts the decision
   as this action's own exit code (the one true arbiter — see the file's own
   header for why this re-derivation is explicit rather than relying on
   `continue-on-error`'s interaction with the rest of the composite to
   propagate correctly on its own).

Pure decision logic is unit-tested: [`verdict.test.tlisp`](./verdict.test.tlisp).

> **Resolved (2026-07-20):** an earlier version of this action carried its own
> `severity-rank` / `classify-severity` — a substring-matched classifier that
> never matched trivy's real `--format json` output (missing-space bug, the
> same class `image-scan` itself carried until 2026-07-17), so this gate had
> never actually rejected anything. It now composes `image-scan` instead of
> duplicating its logic — one canonical severity implementation, not two
> independently-drifting copies.
