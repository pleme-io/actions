# caixa-render — what was superseded, and why

Retirement is a **declared state, not a silent deletion** — the same discipline
`caixa-bevy-log/.github/workflows/RETIRED.md` records for retired workflows.
Nothing here was removed; one broken invocation was replaced and one
never-implementable promise became a typed mode that refuses out loud.

## `feira render` — superseded 2026-08-08

**It never existed.** The action's argv was:

```lisp
(exec-or-die (append feira-argv (list "render" "--in" caixa "--out" out-dir)))
```

Measured against the installed **feira 0.1.46**: there is no `render`
subcommand and no `--in` flag. Every invocation died at clap. feira's actual
verbs are `init add resolve lock build fmt lint dialeto nix chart deploy app
ephemeral pool allocation publish tofu`.

### The promise was four artifact classes; one has a renderer

The old `description` read *"Render cluster artifacts (Helm chart + Kubernetes
manifests + Flux + CI workflows)"*.

| Promised | feira verb | State |
|---|---|---|
| Helm chart | `feira chart --out <dir> --path <root>` | **exists** |
| Kubernetes manifests | — | no renderer |
| Flux resources | — | no renderer (`feira deploy` *deploys*; it does not render) |
| CI workflows | — | no renderer |

So three quarters was aspirational and one quarter was misspelled.

### ★ The quarter that exists is the only quarter anyone consumed

This is what makes the supersession a restoration rather than a downgrade. The
single live consumer chain is substrate's `caixa-auto-release.yml`:

```
caixa-render  →  caixa-publish
```

and `caixa-publish` reads `<rendered-dir>/<chart-subdir>` (default `helm`) and
runs `helm package` on it. **It wants a Helm chart and nothing else.** Nothing
in the fleet ever consumed the other three classes, because they were never
produced — the action has been failing at clap for its whole life.

Switching the default to `chart` therefore delivers **100% of the consumed
promise**, restored from permanently-broken to working.

## What the supersession did

- **`mode: chart` (default)** — renders via `feira chart` to
  `<output-dir>/<chart-subdir>`, which is exactly where `caixa-publish` looks.
  The two actions are one pipeline; `chart-subdir` is that seam, made
  configurable in one place instead of assumed at both ends.
- **`mode: full`** — the original four-artifact promise, **retained as a typed
  state that refuses**, naming the gap and the feira version it was measured
  against. Per ★★ MODULARIZE, DON'T DELETE: the declaration stays, and when
  those renderers land, `full` becomes reachable by implementing it — the
  declaration is already where that code goes.
- **The `description` is now true.** It says Helm chart, and names the three
  classes that have no renderer rather than continuing to promise them.

Both new inputs are **additive with defaults**; no existing input or output
name, default or `required:` flag changed, so no consumer breaks.

## Why a refusal beats an alias

Silently aliasing `full` → `chart` would render a quarter of what the caller
asked for and report success. A caller who genuinely wants Flux resources would
get a Helm chart and a green check. The refusal names the missing renderers, so
the failure carries the information needed to fix it — which
`unrecognized subcommand 'render'` never did.

## Re-entry condition

`mode: full` becomes implementable when feira grows renderers for Kubernetes
manifests, Flux resources and CI workflows. At that point implement it here and
delete the refusal branch; the input, its documentation and this file are the
record of what it is supposed to do.
