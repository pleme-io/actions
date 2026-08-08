# pleme-io · email-notify

> Send a plain-text email via SMTP. Sibling of slack-notify / discord-notify for ops contexts where webhooks aren''t available.

**Category**: `comms` — 💬 Notifications across N channels
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/email-notify@v1
    with:
      body: <required>
      from: <required>
      smtp-host: <required>
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `body` | yes | — | The message body, as literal text. A value naming an existing path is refused: swaks would otherwise mail that FILE's contents. |
| `from` | yes | — |  |
| `smtp-host` | yes | — |  |
| `smtp-password` | yes | — | Passed to swaks through `$SWAKS_OPT_auth_password`, never argv. An unset secret interpolates to `""` here rather than failing the expression, so an empty value is refused instead of dialled. |
| `smtp-port` | no | `587` | Submission port. 465 selects implicit TLS (swaks `--tlsc`); anything else selects STARTTLS (swaks `--tls`). |
| `smtp-username` | yes | — |  |
| `subject` | yes | — |  |
| `to` | yes | — | Comma-separated recipients. Whitespace around each address is trimmed. An empty or all-blank value is REFUSED. |

## Outputs

| Name | Description |
|---|---|
| `sent` | `"true"` only when EVERY recipient was accepted. |
| `failed-count` | Recipients that did not receive the message. Written only once delivery was attempted, so it is empty when the action refused on configuration. |

## Requirements

`swaks` must be present in the job's environment. This action no longer
installs it — see [`run.tlisp`](./run.tlisp) §D4 (★★ HERMETIC SUPPLY CHAIN).

## Configuration via `.pleme-io-release.toml`

Per-repo defaults follow 3-tier precedence:
**env var (workflow input) > `.pleme-io-release.toml` > hardcoded default**.

See the [full config schema](https://github.com/pleme-io/substrate/blob/main/lib/release/example-config.toml).

## Architecture

Composite GitHub Action. Logic lives in [`run.tlisp`](./run.tlisp);
[`action.yml`](./action.yml) orchestrates install steps + one
`tatara-script` invocation.

Per the ★★ NO-SHELL prime directive
([pleme-io-pattern-core skill](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-pattern-core/SKILL.md)):
this action's primary logic is typed Lisp, not bash. The substrate's
[`action-shell-lint`](../action-shell-lint/) enforces this fleet-wide on every PR.

## Related primitives — `comms` category

[`discord-notify`](../discord-notify/) · [`matrix-notify`](../matrix-notify/) · [`mattermost-notify`](../mattermost-notify/) · [`pagerduty-notify`](../pagerduty-notify/) · [`slack-notify`](../slack-notify/) · [`teams-notify`](../teams-notify/) · [`telegram-notify`](../telegram-notify/) · [`twilio-sms`](../twilio-sms/)

## Auto-published on free public CI

Every push to `main` on `pleme-io/actions`:
1. `auto-bump.yml` fires (~10s) → tags `v0.13.{next}`
2. `release.yml` cuts the Docker image (if applicable) + fast-forwards `v1`
3. Consumers using `@v1` see the new revision automatically

**$0/month cost** — GitHub-hosted runners + public-repo free tier.

## License

MIT.

---
*Auto-generated from `action.yml` by [`pleme-doc-gen`](https://github.com/pleme-io/pleme-doc-gen). Do not hand-edit.*
