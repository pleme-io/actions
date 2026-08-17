# job-selection-lint

Assert **which jobs run** for a table of inputs.

## Why

On 2026-08-17 `pleme-io/graphql-synthesizer` ran `cargo-auto-release`. The run
reported **success**. `bump` bumped, tagged and pushed; `ship` was **skipped**;
the crate was never published; and nothing anywhere said so. The condition:

```yaml
if: needs.bump.outputs.bumped == 'true' && !github.event.repository.private
```

That expression is correct, well-typed, and does exactly what it says — the repo
was private, and publishing from a private repo is deliberately forbidden. The
problem was never the condition. It was that **nobody had written down which
jobs must run for a given input**, so a deliberate no-publish and a broken
no-publish produced the same green tick.

Three testing layers exist for GitHub Actions and the fleet was running two:

| Layer | Tests | Tool | Catches this? |
|---|---|---|---|
| Unit | the action's own logic | `run.test.tlisp` + `tatara-script --test` | **no** — the condition is not in any action's code |
| Static | workflow YAML validity | `actionlint` | **no** — the expression is valid |
| **Behavioural** | **which jobs select** | **this** | **yes** |

## What it checks

| Finding | Meaning |
|---|---|
| `NEVER` | a job that selects in **no** case — it can never run, and that looks exactly like a job that works. **The headline check.** |
| `NOT-RUN` | a job the table expects to run that did not select |
| `RAN` | a job the table expects to skip that selected |
| `STALE` | the table names a job the workflow does not have — an assertion about nothing, reading as if it asserts something |
| `EVAL` | the condition uses a construct outside the supported subset |

Jobs no case mentions are reported as **unasserted** without failing. Silence
about a job is not a claim about it.

## The case table

TSV: `name` · `context (k=v;k=v)` · `expect-run (csv)` · `expect-skip (csv)`

```
public-bump	github.actor=human;github.event.repository.private=false;needs.bump.outputs.bumped=true	bump,ship	drip
```

A context path a case does not declare is an **error**, not an empty string.
GitHub itself would yield empty — but for an oracle that silently turns an
incomplete case into a confident verdict, which is how a table drifts out from
under the workflow it claims to cover.

An empty value (`needs.bump.outputs.bumped=`) models a **skipped** upstream job,
which is a distinct state from `false`.

## Fidelity, and its limits

Modelled: `!` `&&` `||` `==` `!=`, parentheses, string literals, `true`/`false`,
context paths, the four status functions, an absent `if:`, `${{ }}` wrapping,
and **needs-propagation** — a job whose dependency skipped is itself skipped
unless its condition calls `always()`. That last rule is not optional detail:
`cargo-auto-release`'s own catch-up job documents `always()` as load-bearing for
exactly that reason.

**Refused, deliberately:** `contains()`, `startsWith()`, `fromJSON()`, `hashFiles()`
and every other function. They are an error naming the construct, never a
guess — including when a case declares a context key of the same name, which
would otherwise evaluate the call as that value and be confidently wrong.

**Not modelled:** matrix expansion, `continue-on-error`, reusable-workflow
`with:` propagation into a called workflow's own conditions, concurrency
cancellation. A job selected here can still be skipped at runtime by something
in that list.

This evaluates the workflow **as written**. It is not a runner and does not
prove a job succeeds — only that it is reachable and selected when it should be.

## Verification

14 unit tests (`run.test.tlisp`), and all three finding classes red-run against
the real `cargo-auto-release.yml`:

- every case private → `ship` and `drip` both reported `NEVER` — the
  graphql-synthesizer situation, caught mechanically
- a case expecting `ship` to run on a private repo → `NOT-RUN`
- a table naming `publishh` → `STALE`

`cases/cargo-auto-release.tsv` is the live table for that workflow: 5 jobs,
5 cases, clean.
