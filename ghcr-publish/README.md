# pleme-io · ghcr-publish

> Push a nix OCI image tarball to a private registry (`ghcr.io/pleme-io/<svc>`)
> under the **★ AUTOBUMP** exact tag `<arch>-r<run>-<sha>`.

Part of the **super-cache-ci** delivery leg. Consumes a tarball from `nix-image`.

```yaml
- uses: pleme-io/actions/ghcr-publish@v1
  id: publish
  with:
    repo: ghcr.io/pleme-io/akeyless-auth
    arch: amd64
    run-number: ${{ github.run_number }}
    sha: ${{ github.sha }}
    tarball: ${{ steps.image.outputs.tarball-amd64 }}
    # moving-latest: "true"   # also push <arch>-latest (human pointer, NEVER a deploy source)
```

## AUTOBUMP tag law (org directive ★★ AUTO-RELEASE → "never `:latest`")

Every push emits a **sortable, exact, immutable** tag `<arch>-r<run>-<sha>`:
`r<run>` is the numeric sort key a Flux `ImagePolicy` extracts
(`^<arch>-r(?P<n>\d+)-`); `<sha>` is the trace. A moving `<arch>-latest` MAY also
be pushed as a **human** pointer — but is **never a deploy source**.

## Outputs

| Name | Meaning |
|---|---|
| `tag` | the exact pushed tag `<arch>-r<run>-<sha>` |
| `ref` / `ref-amd64` / `ref-arm64` | full pushed ref `<base>:<tag>` |
| `pushed` | `true` iff the exact tag pushed |
| `result` | the exact pushed ref |

## Tier-honesty

- **now** — the tag algebra + ref composition (`autobump-tag`, `image-base`,
  `target-ref`, `moving-tag`) are pure + unit-tested; the skopeo push wraps a
  baked-in binary.
- **needs creds** — a real **private-ghcr** push requires registry credentials
  supplied by the workflow (`docker/login-action` first). This is credential
  wiring, not an unshipped seam in the action's logic.

Auth is a **pre-condition**: skopeo reads `~/.docker/config.json`.

## Architecture

Composite action; logic is typed tatara-lisp in [`run.tlisp`](./run.tlisp) over
`_tlisp-stdlib`. Pure helpers are unit-tested by [`run.test.tlisp`](./run.test.tlisp).
