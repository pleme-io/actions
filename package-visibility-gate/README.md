# package-visibility-gate

Refuses to publish a package from a repository whose visibility would make that
package bill the organisation's one shared storage allowance.

## Why this is load-bearing, not bookkeeping

Artifact and package storage is **free and unlimited for public repositories**
and billed against **one shared org-wide allowance** for private and internal
ones — 500 MB on the free plan. pleme-io has 649 private repos against that
single allowance.

So the cost is pooled and the blame is not. Measured 2026-08-20: the allowance
was exhausted, and the failures landed on `ensaio` and `hardened-images`, which
were merely uploading a scan report — while the actual consumer was `sui`, 218
versions at ~33 MB, published from a repo that is *itself public* and whose
package should therefore have been free. It was private only because its image
carried no `org.opencontainers.image.source` label pointing at a specific repo,
so GHCR never linked it and it defaulted to private. 220 of 281 non-public
packages were orphaned that way.

That label defect is fixed at the source in substrate (`74cc650`). This gate is
the other half: it stops a genuinely-private repo from silently minting a new
private package.

## The four ways out, in preference order

1. **Make the repository public** — then the package is free and unlimited.
2. **Ship it as a flake output.** A nix-built tool needs no registry at all;
   the binary cache distributes it and nothing is billed. Most of the fleet's
   ~84 non-chart packages are CLI tools that were never needed as images.
3. **Push to the fleet's own Zot registry** — for anything Kubernetes must pull,
   since a cluster cannot pull from a flake.
4. **Declare `allow-private: '<typed reason>'`** — the fleet's
   `skip-<name>: <typed-reason>` grammar. Written at the call site so the
   exception is visible and countable. Time pressure is not a typed reason.

## Modes

`enforce` (default) refuses. `warn` reports and continues — the survey half of
survey-then-ratchet, the same ramp `publishability-lint` documents for its first
sweep, because failing a whole fleet on day one teaches people to ignore a gate.
A caller in `warn` should say, at the call site, what must be true before it
flips.

## Inputs

| input | default | meaning |
|---|---|---|
| `allow-private` | `""` | typed reason to publish from a non-public repo; empty refuses |
| `what` | `package` | what is being published, for the message |
| `mode` | `enforce` | `enforce` refuses, `warn` reports and continues |
