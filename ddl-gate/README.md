# ddl-gate

Refuses destructive DDL in a committed model tree. Parses `.sql` only — it
never contacts a database, so it is safe to run on every pull request.

Fifth baseline-debt sibling of `action-shell-lint`, `runtime-install-lint`,
`no-cve-suppression` and `breathe-band-lint`, and it follows the same
discipline: existing debt is NAMED in a baseline file and reported on every
run; only a NEW, non-baselined finding fails the build. The goal is an empty
baseline.

## Why this exists

shinka's `EvolutionOp` has two arms and no destructive variant, so a mold file
naming one is rejected at the wire boundary. That is a real guarantee about the
*op vocabulary*. It says nothing about the SQL carried inside a `RawAdditive`,
whose own doc comment is explicit that it is additive **by intent, not by a
type guarantee**. This gate is the layer that reads that SQL.

Camelot non-negotiable #13 is the rule it enforces: every schema, table, grant
and seed row arrives as a `DatabaseMigration`, and the model grows rather than
being cut. Columns are tagged and sunset, drained and sealed — not dropped.

## Verdicts

| verdict | disposition |
|---|---|
| additive | permit |
| blocking | permit, report a warning |
| data-destructive | refuse unless `sunset-step: drain` |
| schema-destructive | refuse, no waiver |
| unknown | refuse (fail-closed) |

Fail-closed is the important one: an unmatched statement is refused, so a novel
statement shape is a refusal rather than a silent permit. A dollar-quoted body
(`$$ … $$`) refuses the whole document, because its semicolons survive
literal-blanking and the statement splitter cannot be trusted on it.

## The scanner

Keyword matching raw SQL is wrong in the one direction that matters — it can
miss a destructive statement. Three stages run before any rule is tested:

1. `--` comments are stripped **quote-aware**. A naive split-at-`--` deletes
   the tail of `SELECT '--' ; DROP TABLE t` and hides the second statement.
2. `/* */` blocks are stripped after lines are joined, since they span lines.
3. Single-quoted literal *contents* are blanked, keeping the quotes, so a
   semicolon inside a literal cannot split a statement. SQL's `''` escape
   toggles twice and correctly lands back outside. Double-quoted identifiers
   are left alone — they carry the names the rules read.

## Finding keys

`RULE <relpath>#<sha8>` where `sha8` fingerprints the **normalised statement**.
Content-addressed, not line- or index-addressed, so reformatting a file or
moving a statement does not silently un-baseline it, while genuinely changing
the statement does.

## Usage

```yaml
- uses: pleme-io/actions/ddl-gate@main
  with:
    root: clusters/camelot-eks/apps/camelot/schemas
```

Run it locally — the same code path CI executes:

```bash
cat _tlisp-stdlib/stdlib.tlisp _tlisp-ddl/stdlib.tlisp ddl-gate/run.tlisp > /tmp/gate.tlisp
ROOT=clusters/camelot-eks/apps/camelot/schemas tatara-script /tmp/gate.tlisp
```

## Sunset lifecycle

Five steps, and deliberately no sixth: `deprecate`, `dual-write`, `backfill`,
`drain`, `seal`. A sealed column stays in the table forever, empty. Only
`sunset-step: drain` unlocks the data-destructive verdicts, and nothing unlocks
a schema cut.

## Library

The classifier lives in `../_tlisp-ddl/stdlib.tlisp` and is packaged for reuse
as [`caixa-tlisp-ddl`](https://github.com/pleme-io/caixa-tlisp-ddl). Keep the
two in sync. Its own suite is 12 tests; run them with
`tatara-script --test _tlisp-ddl/stdlib.tlisp`, and set `DDL_CORPUS` to a
directory of `.sql` to assert that a real corpus classifies with zero unknowns.

Those tests assert with the built-in `assert` macro, and that detail is
load-bearing: `error` in tatara-lisp is a CONSTRUCTOR that returns a
`Value::Error`, and `deftest` fails only on a *thrown* error, so a hand-rolled
`(if c #t (error "tag" msg))` assert is inert and its suite passes vacuously.
Four mutations are verified caught — quote-blind comments, no literal blanking,
fail-open on unknown, and a destructive verb permitted.
