# pleme-io · cosign-sign

Sign an OCI image with [sigstore/cosign](https://github.com/sigstore/cosign).
The **L-sign** layer of the super-cache-ci per-derivation security stack
(theory/SUPER-CACHE-CI-SECURITY.md).

- **Keyless by default** — Fulcio short-lived cert + Rekor transparency via
  the runner's ambient OIDC token (`id-token: write` required).
- **Keyed** — pass `key-ref` for a cofre / ESO / KMS-held key (the DoD-PKI
  keyless / HSM path at IL5).
- **Digest-bound** — cosign always signs the resolved digest; an AUTOBUMP
  `<arch>-r<run>-<sha>` tag is accepted (cosign binds to its digest), a
  `:latest` moving pointer is refused.

```yaml
- uses: pleme-io/actions/cosign-sign@main
  with:
    image-ref: ${{ steps.publish.outputs.ref }}   # AUTOBUMP tag or @sha256: digest
    # key-ref: ""        # empty = keyless Fulcio+Rekor
    # recursive: "true"  # sign every manifest in a multi-arch index
```

| Input | Required | Default | Description |
|---|---|---|---|
| `image-ref` | yes | — | OCI image, digest-preferred; `:latest` refused |
| `key-ref` | no | `""` | cosign key (file/KMS/`k8s://`); empty = keyless |
| `recursive` | no | `false` | sign all manifests in a multi-arch index |

Output: `signed` (`true`/`false`).

Verify: `cosign verify <ref>` (keyed) or `cosign verify --certificate-identity
… --certificate-oidc-issuer …` (keyless).
