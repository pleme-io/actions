# pleme-io · oci-image-push

Push an OCI image tarball (Nix dockerTools output) to a registry — skopeo fallback

Part of the [pleme-io action catalog](https://github.com/pleme-io/actions).
Under the ★★ AUTO-RELEASE prime directive — see the
[`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md)
skill for the full operating protocol.

## Inputs

```yaml
  registry:
    description: "Target OCI registry (e.g. ghcr.io)"
    required: true
  image:
    description: "Image path (e.g. pleme-io/pangea-operator)"
    required: true
  tag:
    description: "Image tag"
    required: true
  tarball:
    description: "Path to the Docker/OCI image tarball produced by Nix"
    required: false
    default: "./result"
  flake-ref:
    description: "(unused in Docker mode — kept for input-compat with composite caller)"
    required: false
    default: "."
```

## Outputs

```yaml
(none)
```

## Example

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/oci-image-push@main
```

## Architecture

Composite action backed by Rust + tatara-lisp. Logic lives in
`run.tlisp`; `action.yml` orchestrates the install steps + one
`tatara-script` invocation. Helpers shared via
[`_tlisp-stdlib`](../_tlisp-stdlib/) — no per-action duplication.
