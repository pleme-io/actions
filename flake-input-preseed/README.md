# pleme-io · flake-input-preseed

**WARM flake-input lever.** Pull a heavy flake input's **source FOD** out of
the super-cache into the local Nix store **before** the build, so the
in-flake locked eval reuses the content-addressed path and **skips the
eval-time git clone**. Pairs with `super-cache-save`'s flake-inputs push
(the cold/push-back leg populates the cache; this pulls it back warm).

## Why this exists

Wiring `substituters=<sui>` warms the *build output* closures — but **nix's
git/tarball fetcher never consults substituters for a flake input's SOURCE
tree.** So a heavy git input (e.g. the akeyless-main-repo 18,904-commit
monorepo, 450 MiB tip tree) is **re-git-cloned at eval time on every fresh
runner pod** — ~21–40s (egress-bound), paid cold *and* warm. Measured: a
warm `nix flake prefetch` of a LOCKED input already present in sui still
clones (== cold). `substituters=<sui>` alone is a no-op for source.

A locked input's source is a fixed-output (content-addressed) store path
derivable **purely from `flake.lock`'s narHash** — knowable with no fetch.
This action computes it and `nix copy --from <endpoint>` pulls it into the
local store (an in-cluster ~8s substituter pull for the 70 MiB xz'd
akeyless-main-repo source). Once the CA path is local, the in-flake locked
eval **reuses it and skips the clone** (measured: in-flake `drvPath` eval
21s→14s, zero akeyless-main-repo clone). No `--override-input` needed.

## Where it sits in the pipeline

```
sui-service-up        → endpoint
  → flake-input-preseed  ← YOU ARE HERE (pull the heavy input source, warm)
    → nix-image (nix build .#…)   ← locked eval reuses the preseeded path
      → super-cache-save (endpoint + flake-inputs)  ← the push half, next run
```

## Usage

```yaml
- id: preseed
  uses: pleme-io/actions/flake-input-preseed@main
  with:
    endpoint:   ${{ steps.sui.outputs.endpoint }}   # http://sui.camelot-build.svc
    flake-lock: flake.lock
    inputs:     akeyless-main-repo
```

## Inputs

| Input | Default | Meaning |
|---|---|---|
| `endpoint` | `""` | super-cache endpoint to pull from; empty ⇒ honest no-op (build clones) |
| `flake-lock` | `flake.lock` | lock whose locked narHash pins the input source (resolved to absolute) |
| `inputs` | `""` | space/comma list of flake-input **node** names to preseed (`akeyless-main-repo`) |
| `require` | `false` | `true` ⇒ a partial preseed is a hard failure instead of degrade-to-clone |

## Outputs

| Output | Meaning |
|---|---|
| `paths` | space-separated SOURCE store paths pulled into the local store |
| `requested` | number of input names requested |
| `preseeded` | number actually pulled (0 ⇒ the build clones) |
| `reason` | `no-endpoint` \| `no-inputs` \| `nothing-preseeded` \| `partial` \| `preseeded` |

## Tier-honest

A miss — endpoint down, source not yet pushed to the cache, or an
unresolvable path — is a **legitimate degrade**: the action reports it and
the build falls back to the git clone. It is **never** a faked warm.
`require=true` turns a partial preseed into a loud failure.

The destination that makes this whole class *unrepresentable* on a fresh pod
(cold **and** warm, no per-build pull) is baking the source store path into
the Nix-built runner image — this action is the interim that needs no image
rebuild and rides the live super-cache.
