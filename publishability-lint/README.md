# publishability-lint

Fail on a **new** disclosure of somebody else's estate in a repo that is public,
or about to be: an AWS account id, a live resource id, a cloud endpoint
hostname. Existing debt is baselined and reported every run; a new finding fails.

## Why it exists

On 2026-08-17 a sweep found customer-identifying content in 25 public pleme-io
repos — account numbers, tenant names, a partner registry, internal GitOps
paths, a live incident postmortem. All of it was written in good faith, as
"measured, not assumed" evidence, which is the right instinct in a private repo
and becomes a disclosure the moment the repo is public.

A one-time cleanup drifts back within a week, because the habit that produced it
is a *good* habit. So the cleanup is sealed here instead.

## Four ideas, each learned from a real failure

**1. A detector must not carry what it detects.** The account check in the
original (`magma`) implementation named the real account id as a constant so it
could grep for it. On a public repo that publishes the one string it exists to
keep out — and after the sweep, that constant was the last copy left in the
tree. It is now **inverted**: any standalone 12-digit run that is not one of
three reserved placeholders. It carries nothing, and it is strictly stronger,
because it catches every account rather than the one somebody remembered.

Every rule here is a **shape**. `rules.txt` ships in a public repo; putting a
real value in it to make a rule work recreates the defect the gate exists to
prevent.

**2. Scan decoded base64.** A textual cleanup ran on 2026-08-07, its gate went
3/3 green, and it shipped. It was wrong for ten days on a public repo: one
fixture carried a rendered `user_data`, a `user_data` is base64, and
find-and-replace cannot reach inside one. Every name the cleanup removed from
the plaintext was still there, one decode away. So the unit of scanning is not
a file's bytes — it is the bytes **plus every base64 run in them that decodes to
text**, each labelled so a hit says where it was hiding.

**3. Scan git-tracked files only.** Publishability is a property of what git
ships. Unfiltered, the check reported four "account ids" out of a gitignored
local build artifact — a false positive that fires differently on every machine.

**4. Refuse a vacuous pass.** A missing or empty rule table fails. A scan that
selects fewer files than `min-files` fails. A gate with no rules passes
everything and reads exactly like a clean run.

## Rule classes

`rules.txt` is TSV. Adding a row is the whole act of adding a rule.

| Class | Fields | Catches |
|---|---|---|
| `deny-substring` | `needle`, `reason` | A literal shape, case-insensitive — `.eks.amazonaws.com`, `.dkr.ecr.` |
| `allowlist-digit-run` | `len`, `allowed,csv`, `reason` | Any standalone run of `len` digits **not** in the allowed set |
| `prefix-hexbody` | `prefix`, `minlen`, `allowed,csv`, `reason` | `vpc-`/`subnet-`/… followed by ≥ `minlen` hex, minus canonical placeholders |

Two matcher properties worth knowing, both load-bearing:

- Digit runs are **maximal**, so a 13-digit millisecond timestamp is one run of
  13 and not a 12-digit slice of one. A fixed `\d{12}` would report every
  timestamp in the repo, and a gate drowning in false positives gets disabled.
- Prefixes are **`\b`-anchored**, so `myvpc-0abc…` is not a hit, and the hex
  body is greedy, so a long id is never truncated into a shorter allowed one.

## The baseline is checked in both directions

`baseline.txt` is TSV `<path>\t<rule-id>\t<reason>`. A row matching **no**
finding is an error, not a shrug: a stale row is a standing per-file permission
for the disclosure to come back. Checking both directions is also how a cleanup
observes its own completion — `baselined` and `stale-baseline` both reaching
zero is the finish line, which a one-directional check can never see.

## Usage

```yaml
- uses: actions/checkout@v4
- uses: pleme-io/actions/publishability-lint@main
  with:
    fail-on-violation: "false"   # survey first; ratchet after
```

Survey a repo before adopting it, rather than turning a fleet red on day one —
the reliable result of that is people learning to ignore the gate.

## What it does not catch

Stated plainly, because a gate whose limits are unwritten gets trusted past them.

- **Customer and tenant names.** They are arbitrary strings with no shape, and
  the only way to detect them is to carry them — which idea 1 forbids in a
  public rule table. Names are out of scope here and belong to a private
  sweeper. This is the largest gap.
- **History.** It reads the working tree at the current commit. Content already
  pushed stays in the history regardless.
- **Rendered output.** It sees sources, not what a template produces. The
  helm-unittest `notMatchRegex` pattern in `helmworks` covers that side.
- **Semantics.** A paragraph describing somebody's internal architecture in
  prose, naming nothing matchable, passes cleanly.

## Related

- `magma/magma-test/tests/publishability_no_host_estate.rs` — the reference
  implementation this generalizes, and the conformance oracle for its three
  finding classes.
- `banned-tool-lint` — the sibling whose rule-table + both-directions-baseline
  shape this follows.
