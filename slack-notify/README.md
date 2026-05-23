# pleme-io · slack-notify

> Post a typed release event to a Slack webhook. Universal — works for any release flow that wants typed notifications.

**Category**: `comms` — 💬 Notifications across N channels
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/slack-notify@v1
    with:
      body: ""
      color: "good"
      fields: "[]"
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `body` | no | `` | Markdown body (Slack mrkdwn flavor) |
| `color` | no | `good` | Sidebar color (good / warning / danger / hex) |
| `fields` | no | `[]` | JSON array of {title, value, short} field objects |
| `title` | yes | — | Headline of the notification |
| `webhook-url` | yes | — | Slack incoming-webhook URL (read from secrets, NOT hardcoded) |

## Outputs

| Name | Description |
|---|---|
| `delivered` | 'true' on 2xx response, 'false' on error |

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

[`discord-notify`](../discord-notify/) · [`email-notify`](../email-notify/) · [`matrix-notify`](../matrix-notify/) · [`mattermost-notify`](../mattermost-notify/) · [`pagerduty-notify`](../pagerduty-notify/) · [`teams-notify`](../teams-notify/) · [`telegram-notify`](../telegram-notify/) · [`twilio-sms`](../twilio-sms/)

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
