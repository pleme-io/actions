# pleme-io · helm-mirror

Mirror a Helm monorepo's **third-party subchart dependencies** into the pleme-io
OCI registry, so the auto-release (and any consumer) fetches every subchart from a
registry **we control** — never from a third-party `*.github.io` Helm repo. This
is the hermetic supply-chain law operationalized for Helm.

Everything is derived from the wrapper charts' own `Chart.yaml` dependencies by
`forge helm mirror` — there is **no catalog to drift**. The operator declares the
real upstream + version once, in the dependency; the substrate mirrors it and, at
release time, transparently routes resolution through the mirror
(`forge`'s `redirect_remote_deps_to_mirror`). The committed `Chart.yaml` keeps
declaring the honest upstream; only the per-release copy is rerouted.

Idempotent: a `(name, version)` already in the registry is skipped, so only a
**new** upstream version ever touches the third-party repo. A repo with no
third-party subchart deps is a clean no-op.

## Why

- **Air-gap / regulated posture by construction.** pleme-lib's `compliance.airgap`
  overlays forbid pulling images from uncontrolled registries; this is the Helm
  chart-level analog. Mirroring makes the air-gap posture true, not asserted.
- **No third-party uptime dependency.** A slow or down upstream `*.github.io` repo
  can no longer wedge or flake a release.
- **Reproducibility.** The exact subchart bytes live in our registry, immutable.

## Usage

```yaml
- name: Mirror upstream subcharts
  uses: pleme-io/actions/helm-mirror@v1
  with:
    registry: oci://ghcr.io/pleme-io/charts   # optional; this is the default
```

Run it **before** the publish step (so the mirror is populated before the release
resolves subcharts). Requires `helm registry login` to the registry to have run
first (the OCI write credential).

## Inputs

| Input      | Required | Default                         | Description                       |
|------------|----------|---------------------------------|-----------------------------------|
| `registry` | no       | `oci://ghcr.io/pleme-io/charts` | OCI registry to mirror INTO       |

## Implementation

`run.tlisp` (tatara-lisp, no shell) invokes the consumer flake's `.#mirror` app
(`forge helm mirror`, from substrate's `mkHelmAllApps`), falling back to
`.#forge -- helm mirror` if the app isn't exposed.
