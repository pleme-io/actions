# pleme-io · breathe-runner

> Preflight posture gate for breathable spot runners — assert the job
> landed on a 100%-spot, scale-to-zero, taint-isolated in-cluster GHA runner
> (never rio) and arm the retirada drain->checkpoint hook.

**Category**: `super-cache-ci` — 🌬️ breathable CI
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.x` tags or floating `@v1` / `@main`

This is **verb #1** of the super-cache-ci action vocabulary — the default
language for expressing CI on the sui-service super-cache stack. A
super-cache-ci build begins here, so it never silently runs on an unmanaged /
on-demand / rio runner and never gets spot-reclaimed without a checkpoint.

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - id: breathe
    uses: pleme-io/actions/breathe-runner@v1
    with:
      require-spot: "true"
      require-isolated-node-group: "true"
      drain-handler: "true"
```

## How the posture is observed

A runner cannot read its own node's Kubernetes labels from inside a job, so the
posture is surfaced as **env** the crunkrun Stream / ARC scale-set
injects (downward-API from the node's `karpenter.sh/capacity-type` label, the
node-group, and the stream's `minRunners`). The env var **names** are
config-driven, so a stream that surfaces them differently still works.

| Signal | Default env var | Meaning |
|---|---|---|
| capacity type | `RUNNER_POOL_CAPACITY_TYPE` | `spot` \| `on-demand` |
| node group | `RUNNER_POOL_NODE_GROUP` | non-empty ⇒ isolated |
| min runners | `RUNNER_POOL_MIN_RUNNERS` | `0` ⇒ scale-to-zero |
| retirada | `RUNNER_POOL_RETIRADA` | `ready` ⇒ drain hook present |

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `require-spot` | no | `true` | Fail (enforce=true) unless on a spot node |
| `require-isolated-node-group` | no | `true` | Fail unless on an ISOLATED node group |
| `require-camelot-taint` | no | — | DEPRECATED alias for the above; still honoured |
| `require-scale-to-zero` | no | `false` | Fail unless min-runners == 0 (informational by default) |
| `drain-handler` | no | `true` | Arm the retirada drain->checkpoint hook |
| `enforce` | no | `true` | false ⇒ unmet requirements are advisory warnings |
| `capacity-type-env` | no | `RUNNER_POOL_CAPACITY_TYPE` | Env var carrying the node capacity type |
| `node-group-env` | no | `RUNNER_POOL_NODE_GROUP` | Env var carrying the node-group |
| `min-runners-env` | no | `RUNNER_POOL_MIN_RUNNERS` | Env var carrying the stream's minRunners |

## Outputs

| Name | Description |
|---|---|
| `runner-ok` | true when every required posture assertion is satisfied |
| `capacity-type` | Observed capacity type: `spot` \| `on-demand` \| `unknown` |
| `node-group` | Observed node-group (empty when not surfaced) |
| `scale-to-zero` | `true` \| `false` \| `unknown` |
| `drain-armed` | true when the retirada drain->checkpoint hook was armed |

## Tier-honest status (never rounded up)

- **Shipped now**: the posture **assertions** (read injected env, gate the job).
  Exercised green by [`tests/test.yml`](./tests/test.yml) across three
  scenarios (full posture, advisory, enforce-fail).
- **LiveTODO — signal injection**: the live pool signals are surfaced by
  the super-cache-ci crunkrun Stream. Until that Stream ships, run with
  `enforce: false` (advisory) on hosted runners.
- **LiveTODO — retirada drain**: `drain-armed` is `true` **only** when
  `RUNNER_POOL_RETIRADA=ready` is present. The retirada `Spot::InterruptionHandler`
  checkpoint-to-Pg is not shipped; the action never claims armed without it.
- **LiveTODO — output forwarding**: the outputs are declared here + in
  `tatara-script/action.yml`, but a composite forwards only DECLARED keys and
  the published `tatara-script@v1` tag carries them only after its next
  re-release. Until then, cross-verb output threading via the reusable workflow
  lags; the gate's **exit-code** contract works today regardless (that is what
  the smoke asserts), and the output values are proven by `run.test.tlisp`.

## Typed Action-domain catalog entry

The typed border in arch-synthesizer's `Action` domain (the `(defaction …)`
authoring surface — the compiler refuses an action whose declared inputs don't
match its `Input` struct):

```lisp
(defaction "breathe-runner"
  :description "Preflight posture gate for breathable spot runners."
  :inputs  ((:name "require-spot"          :type :bool :default "true")
            (:name "require-isolated-node-group" :type :bool :default "true")
            (:name "require-scale-to-zero" :type :bool :default "false")
            (:name "drain-handler"         :type :bool :default "true")
            (:name "enforce"               :type :bool :default "true")
            (:name "capacity-type-env"     :type :string :default "RUNNER_POOL_CAPACITY_TYPE")
            (:name "node-group-env"        :type :string :default "RUNNER_POOL_NODE_GROUP")
            (:name "min-runners-env"       :type :string :default "RUNNER_POOL_MIN_RUNNERS"))
  :outputs ((:name "runner-ok") (:name "capacity-type") (:name "node-group")
            (:name "scale-to-zero") (:name "drain-armed"))
  :behavior      (:tatara-script "breathe-runner/run.tlisp")
  :semver-compat :minor
  :attestation   :none)
```

## Architecture

Composite GitHub Action. Logic lives in [`run.tlisp`](./run.tlisp) (pure posture
helpers + a gated `main`); [`action.yml`](./action.yml) loads the shared
`_tlisp-stdlib` and runs one `tatara-script` invocation. Per the ★★ NO-SHELL
directive there is no bash beyond the stdlib loader. Unit tests:
[`run.test.tlisp`](./run.test.tlisp) (7 `deftest` forms).
