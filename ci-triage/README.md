# ci-triage — the fleet CI failure-signature catalog

**A new CI failure is a catalog row, not a fresh investigation.**

[`catalog.lisp`](./catalog.lisp) is the typed signature catalog: one row per
*cause class*, each carrying the log signature that identifies it, how many
failures it explained in the last sweep, whether that cause was actually read
from a log, the remedy, and the honest tier of that remedy.

## Why it exists

The same four-step investigation — observe → normalize the signature → bucket
it → pick a remedy — was hand-run four times in a single session (2026-08-17),
each time from zero, because nothing durable recorded the previous pass. Per the
fleet rule that the third hand-wiring of a shape is a primitive rather than a
task, the shape is now data.

## The two rules that make it correct

**1. Match on the log signature. Never on the step name.**

A step name says what the step *meant* to do. On `pleme-hotswap-derive` a step
named `cargo fmt --check (inside .#default)` failed with:

```
error: Dependency is not of a valid type: element 6 of buildInputs for nix-shell
```

The devShell could not be *entered*; rustfmt never ran. That step is simply the
first one that enters the devShell, so a broken shell is reported under a
formatting name — and two `cargo fmt` sweeps were spent on the misreading before
the real cause (substrate splicing a `flake = false` source tree into
`buildInputs`) was found. `:step` is recorded for grouping only.

Corollary: **step → cause is not a function.** `cargo fmt --check` appears twice
in the catalog with different signatures, different remedies, different tiers.

**2. An unmatched signature is `unclassified`.**

Never folded into the nearest-looking row. Folding is exactly how the
misdiagnosis above was manufactured. Same discipline as ★★ kotae: `found` /
`empty` / `refused` / `blind` must never render as the same bytes.

## Reading a count honestly

Every `:seen` is from one dated sweep with its denominator recorded in
`:sweep` — 2026-08-17, 534 failed runs / 764 failing steps / 188 repos, over all
399 non-archived pleme-io repos. Counts rot **downward**: a stale snapshot reads
as merely modest once the fleet grows past it, so nothing ever flags it as
wrong. Re-measure; never infer.

`:verified` is per row and must not be promoted without doing the work:

| value | meaning |
|---|---|
| `:log-read` | someone read the actual failing log for this class |
| `:step-only` | grouped by step name; the cause is **inferred, not read** |

**Current coverage: 257 of 764 failing steps (34%) are `:log-read`.** The other
507 sit in three explicit `:unexamined-*` rows so the gap is impossible to
mistake for full coverage. The rows sum exactly to the corpus by construction —
if they stop summing, a class has been dropped.

## Extending it

1. Read the failing log. Not the step name.
2. Normalize the message to a signature: strip paths, hashes, digits.
3. Search the catalog for that signature. If it matches, you are done — apply
   the recorded remedy.
4. If it does not, add a row: `:signature`, `:seen`, `:verified :log-read`,
   `:cause`, `:remedy`, `:tier`. State the tier honestly — a `Result::Err` is
   mitigation, a compile error is unrepresentability, and rounding up is the
   defect this catalog is designed to prevent.
5. If your row splits an `:unexamined-*` bucket, decrement that bucket by the
   same amount so the total still equals the corpus.

## The classifier

`run.tlisp` — a `.tlisp`, not shell, because the triage it replaces was being
done with a bash poll loop and `python3` heredocs. `classify` is **pure** (log
text in, a row id out), which is precisely what makes it testable; the shell it
replaces could not be tested at all, which is why each class got re-derived by
hand every time.

```yaml
- uses: pleme-io/actions/ci-triage@main
  with:
    log-file: failing-job.log
# -> outputs.class = "syft-install-not-writable" | … | "unclassified"
```

Three states, none rendering as another: a **row id** (classified), the literal
**`unclassified`** (a finding — exit 0, since this reports rather than gates),
and **refused** (exit 2, when no `log-file` was supplied — a verdict about a log
it never read would be fabricated).

**Verified, both directions.** `tatara-script --test` → 4/4, every assertion
using a real log line from the named failing run. Then two red runs, because a
green suite proves nothing until it has been seen to fail:

| red run | expected catch | result |
|---|---|---|
| drift row moved above the devShell row | ordering test | ✘ 3/4, names the assertion |
| unmatched log falls back to a plausible row | anti-fold test | ✘ 3/4, names the assertion |

Both red runs were done by **shadowing** a definition in a throwaway file
concatenated after `run.tlisp` — additive, never an in-place edit of the file
under test, so a mutation cannot silently corrupt the thing being verified.

**Still owed:** an operator-side sweep that classifies the whole org through this
same function. `pending-ci-triage: org-sweep`.

**No claim that the fixed classes are green.** Rows record the fix and the
commit; confirming the count is a re-measurement, not an inference. The
`:syft-install-not-writable` row is explicit that its cause is `:log-read` on
one run of 130.
