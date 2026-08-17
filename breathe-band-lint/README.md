# breathe-band-lint

Static coverage gate for [breathe](https://github.com/pleme-io/breathe) bands in
a GitOps tree. **Parses committed YAML only — it never contacts a cluster**, so
it runs on any PR with no credentials, no kubeconfig, and no network.

The fourth baseline-debt sibling of `action-shell-lint`, `runtime-install-lint`,
and `no-cve-suppression`, and it follows their shape exactly: pre-existing debt
is **named** in a baseline file and reported on every run; only a **new**,
non-baselined finding fails the build.

## Why it exists

Band coverage drifted silently on `camelot-eks` in three distinct ways, none of
which any human review caught — each was found only by hand-auditing the live
cluster:

1. **A band outlived its target.** A band's selector stopped matching after a
   label/name change. It kept reporting `Healthy` / `Dormant` with
   `lastDecision: "no pods in the label group — waiting (target scaled to
   zero)"` while matching **zero** pods. At runtime a dead band and a correctly
   idle band are *indistinguishable*. Only a static join over the tree
   separates them.
2. **`spec.mode` was left unset on 61 of 74 bands.** Unset resolves to
   `ShadowConfirmEffect`, which **self-promotes to live** once the confirm gate
   passes. So "we added a shadow band" silently became "we added a live
   carver" — 61 times, with nobody ever deciding to promote one.
   `spec.dryRun` is **not** a substitute: it is dead code for 8 of breathe's 10
   kinds (only `HostParam`/`KubeParam` honour it).
3. **New workloads landed with no band**, and nothing said so.

Each rule below is traceable to one of those.

## Rules

| Rule | Check | The defect it catches |
|---|---|---|
| **R1-COVERAGE** | Every `Deployment`/`StatefulSet`/`DaemonSet` in the tree has a `MemoryBand` whose `targetRef` points at it | A workload lands with no band |
| **R2-TARGET** | Every band's `targetRef` resolves to a workload in the tree, a declared `generatedTarget`, or a waiver | A band outlives a rename/removal and reports Healthy forever |
| **R3-QOS** | No BestEffort (no container declares `requests`) workload that is a `StatefulSet`, in a `controlPlaneNamespace`, or listed in `statefulWorkloads` | First-to-be-evicted control-plane pods with `oom_score_adj 1000` |
| **R4-MODE** | Every band declares `spec.mode` explicitly | Silent self-promotion from shadow to live |

### R1's two automatic exemptions are load-bearing

**A breathe band writes LIMITS ONLY — it never raises a request.** Two
consequences are encoded as automatic exemptions rather than left to reviewer
memory, because getting either wrong is actively harmful:

- **No declared limit on a dimension ⇒ never band that dimension.** breathe
  would *invent* a limit and ratchet it down. This really happened:
  `ebs-csi-controller`'s `ebs-plugin` had no CPU limit, was banded, and got
  capped at **22 millicores** — on the controller that mediates every volume
  attach/detach.
- **Guaranteed (`requests == limits`) ⇒ never band.** Writing a limit breaks
  `requests == limits` and demotes the pod to Burstable, undoing the
  `oom_score_adj -997` protection that is often the entire point (this is why
  `sui-cache-pg` is Guaranteed — it was the fix for 34 OOMKills, and a band
  would silently undo it).

A gate that demanded a band unconditionally would cause outages. R1 demands one
only where a memory **limit** is declared **and** the workload is not
Guaranteed. Both conditions are derived from the manifests — never listed in
config.

## Usage

```yaml
# .github/workflows/breathe-band-lint.yml
name: breathe-band-lint
on:
  pull_request:
  push: { branches: [main] }

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pleme-io/actions/breathe-band-lint@main
        with:
          root: clusters/<cluster>
```

### Running it locally

The action is a thin wrapper: it concatenates the shared tlisp stdlib with
`run.tlisp` and hands the result to `tatara-script`. The same path runs by hand,
which is how every result in this README was produced:

```sh
curl -sL https://raw.githubusercontent.com/pleme-io/actions/main/_tlisp-stdlib/stdlib.tlisp > /tmp/lint.tlisp
cat "$(git rev-parse --show-toplevel)/breathe-band-lint/run.tlisp" >> /tmp/lint.tlisp
ROOT=clusters/<cluster> tatara-script /tmp/lint.tlisp   # exit 0 = clean, 1 = new findings
```

Requires `yq` (v4) and `tatara-script` on `PATH`.

## Configuration — `<root>/.breathe-bands.yaml`

| Key | Meaning |
|---|---|
| `generatedTargets` | `Kind/namespace/name` of workloads with **no raw manifest** in the tree because a HelmRelease / EKS addon / ARC controller generates them |
| `controlPlaneNamespaces` | A BestEffort workload in one of these is a hard R3 failure |
| `statefulWorkloads` | `Deployment`s that are really stateful (a `StatefulSet` is stateful by kind, automatically) |
| `coverageWaivers` | Exempt from R1. **Only** for reasons the linter cannot derive — the two derivable exemptions above are automatic and must not be listed |

### Why `generatedTargets` is hand-declared rather than inferred

A static linter cannot render a Helm chart — that needs the chart, its
dependencies, and network access. So it cannot know that a HelmRelease produces
`vmsingle-lareira-vm-stack-victoria-metrics-k8s-stack`.

The tempting alternative — accept any band whose namespace merely contains
*some* HelmRelease — would **not catch a typo in the target name**, which is
precisely the bug R2 exists to catch. So a band against a generated workload
costs one declared line, and **that line is the review surface**.

This is an honest limitation, not a hidden one: R1 and R3 can only see
workloads with a raw manifest. A BestEffort pod created by a HelmRelease's
`values.resources` is **invisible** to this gate. Closing that needs chart
rendering (a `helm template` step with network), which is a deliberate
non-goal for a gate that must run on every PR in seconds.

## Baseline — `<root>/.breathe-bands-baseline.txt`

One finding key per line (`RULE Kind/namespace/name` — the stable prefix before
` :: `, so rewording a message never silently un-baselines an entry).

Remove an entry **only** by actually fixing that band, in the same commit.
Never delete a line to make the gate green. The goal is an empty file.

## Proven to bite

A gate that has never been shown to fail is not a gate. All four rules were
verified against the real `camelot-eks` tree by deliberately introducing each
defect and confirming a non-zero exit, then restoring:

| Test | Mutation | Result |
|---|---|---|
| R1 | deleted the `rustfs` MemoryBand | `EXIT=1` — `NEW R1-COVERAGE Deployment/camelot/rustfs` |
| R2 | pointed `neo4j-cpu` at `neo4j-renamed` | `EXIT=1` — `NEW R2-TARGET CpuBand/camelot/neo4j-cpu` |
| R3 | stripped `requests` from `source-controller` | `EXIT=1` — `NEW R3-QOS Deployment/flux-system/source-controller` |
| R4 | added a new band with no `spec.mode` | `EXIT=1` — `NEW R4-MODE CpuBand/camelot/rustfs-cpu-second` |

The R4 test is the important one for the baseline discipline: it fails on a
**new** unset-mode band even though 44 existing ones are baselined — proving the
baseline tracks debt without blanket-suppressing the rule.

## Named, not-yet-built

- **A Guaranteed workload must not carry a *live* band.** Today `spec.mode:
  shadow` on such a band is correct and permanent (`sui-cache-pg-memory`), and
  R4 already forces the mode to be explicit. A dedicated rule asserting
  `Guaranteed ⇒ mode == shadow` is the natural next one.
- **Selector grounding.** Bands may use `targetRef.podSelector`; a key that
  appears in no pod template anywhere is a phantom (this is how the
  `builders-amd64` bands silently matched zero pods across 152 carves).
  R2 covers name-based dangling only.
- **Bounds sanity** — `floor <= ceiling`, and `floor >= the target's declared
  request` (a limit below a request is unwritable).
- **A Rust implementation.** This follows the house tlisp shape because that is
  what the sibling gates use and what ships today. A typed Rust binary with a
  real YAML parser is the destination; `yq` shelling out is honest interim.
