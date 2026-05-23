# pleme-io · pagerduty-notify

> Trigger / resolve a PagerDuty incident via the Events API v2. Useful for CI-driven on-call paging.

**Category**: `comms` — 💬 Notifications across 9 channels
**Backend**: tatara-lisp (run.tlisp) wrapping CLI tools via `exec-capture`
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/pagerduty-notify@v1
    with:
      integration-key: <required>
      action: "trigger"
      dedup-key: ""
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `integration-key` | yes | — | PagerDuty Events API v2 integration key |
| `action` | no | `trigger` | trigger | resolve | acknowledge |
| `dedup-key` | no | `` | Stable identifier for the incident (so re-triggers update, not duplicate) |
| `summary` | yes | — |  |
| `severity` | no | `error` | critical | error | warning | info |

## Outputs

| Name | Description |
|---|---|
| `dedup-key` |  |

## Configuration via `.pleme-io-release.toml`

Per-repo defaults follow 3-tier precedence:
**env var (workflow input) > `.pleme-io-release.toml` > hardcoded default**.

See the [full config schema](https://github.com/pleme-io/substrate/blob/main/lib/release/example-config.toml).

## Architecture

Composite GitHub Action. Logic lives in [`run.tlisp`](./run.tlisp);
[`action.yml`](./action.yml) orchestrates install steps + one
`tatara-script` invocation. Shared helpers from
[`_tlisp-stdlib`](../_tlisp-stdlib/).

Per the ★★ NO-SHELL prime directive
([pleme-io-pattern-core skill](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-pattern-core/SKILL.md)):
this action's primary logic is typed Lisp, not bash. The substrate's
[`action-shell-lint`](../action-shell-lint/) enforces this fleet-wide on every PR.

## Related primitives — `comms` category

[`discord-notify`](../discord-notify/) · [`email-notify`](../email-notify/) · [`matrix-notify`](../matrix-notify/) · [`mattermost-notify`](../mattermost-notify/) · [`slack-notify`](../slack-notify/) · [`teams-notify`](../teams-notify/) · [`telegram-notify`](../telegram-notify/) · [`twilio-sms`](../twilio-sms/)


## Sources

- **Action source**: [`action.yml`](./action.yml) + [`run.tlisp`](./run.tlisp)
- **Catalog entry**: `substrate.lib.release.patterns.comms.pagerduty-notify` —
  [patterns-full.nix](https://github.com/pleme-io/substrate/blob/main/lib/release/patterns-full.nix)
- **Future typed source**: `(defaction pagerduty-notify ...)` per
  [ACTION-AS-CAIXA.md](https://github.com/pleme-io/substrate/blob/main/docs/ACTION-AS-CAIXA.md) (M1+ migration)

## Operator-facing CLI

Same logic locally via `cargo install pleme-io-releaser`:

```bash
pleme-release plan      # preview what an auto-release would do
pleme-release onboard   # scaffold the 3-workflow surface to a fresh repo
pleme-release detect    # emit detected repo type
```

## Auto-published on free public CI

Every push to `main` on `pleme-io/actions`:
1. `auto-bump.yml` fires (~10s) → tags `v0.13.{next}`
2. `release.yml` cuts the Docker image (if applicable) + fast-forwards `v1`
3. Consumers using `@v1` or `@v0.13.{x}` see the new revision automatically

**$0/month cost** — GitHub-hosted runners + public-repo free tier.

## Discovery

Browse the [full catalog](../README.md) or query via Nix:

```bash
nix eval --raw github:pleme-io/substrate#lib.aarch64-darwin.release.patterns.comms.pagerduty-notify
```

## License

MIT.

---
*Auto-generated from `action.yml` by [`_gen-docs.py`](../_gen-docs.py).
Do not hand-edit; modify the source files or regenerate.*
