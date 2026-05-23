#!/usr/bin/env python3
"""
_gen-docs.py — generate a rich, delightful README.md for every
pleme-io action.

Run from the actions repo root:
   python3 _gen-docs.py            # writes README.md for every action
   python3 _gen-docs.py --index    # also emits root README.md catalog
"""
import re, sys
from pathlib import Path
from collections import defaultdict

# Inline the category map (kept in sync with _gen-patterns.py)
CATEGORY_MAP = {
    'cargo': 'rust', 'rust-': 'rust',
    'npm-': 'npm', 'python-': 'python',
    'helm-': 'helm', 'caixa-': 'caixa', 'gem-': 'ruby',
    'ansible-': 'ansible',
    'go-': 'language', 'gradle-': 'language', 'maven-': 'language',
    'dotnet-': 'language', 'swift-': 'language', 'xcodebuild': 'language',
    'mix-': 'language', 'hex-': 'language', 'zig-': 'language',
    'golangci-': 'language', 'goreleaser': 'language', 'wasm-': 'language',
    'aws-': 'cloud', 'gcp-': 'cloud', 'cloudflare-': 'cloud',
    'azure-': 'cloud', 'vercel-': 'cloud', 'netlify-': 'cloud',
    'render-': 'cloud', 'railway-': 'cloud', 'heroku-': 'cloud',
    'doctl-': 'cloud', 'fly-': 'cloud',
    'datadog-': 'observability', 'grafana-': 'observability',
    'honeycomb-': 'observability', 'prometheus-': 'observability',
    'sentry-': 'observability', 'otel-': 'observability',
    'loki-': 'observability', 'pyroscope-': 'observability',
    'security-': 'security', 'sbom-': 'security',
    'license-header': 'security', 'license-finder': 'security',
    'provenance-': 'security', 'image-scan': 'security',
    'cosign-': 'security', 'tfsec': 'security', 'checkov': 'security',
    'bandit': 'security', 'gosec': 'security', 'conftest': 'security',
    'kics-': 'security', 'snyk-': 'security', 'vault-': 'security',
    'gh-secrets-': 'security', 'slsa-': 'security',
    'cyclonedx-': 'security', 'secrets-scan': 'security',
    'docker-': 'container', 'ko-': 'container', 'oci-': 'container',
    'podman-': 'container', 'buildah-': 'container', 'skopeo-': 'container',
    'crane-': 'container', 'buildkit-': 'container',
    'kubectl-': 'k8s', 'flux-': 'k8s', 'argocd-': 'k8s',
    'kustomize-': 'k8s', 'k8s-': 'k8s', 'velero-': 'k8s',
    'helmfile-': 'k8s', 'tanka-': 'k8s', 'helm-deploy': 'k8s',
    'helm-oci-publish': 'helm',
    'terraform-': 'iac', 'pulumi-': 'iac', 'iac-': 'iac',
    'db-': 'db', 'atlas-': 'db', 'prisma-': 'db',
    'flyway-': 'db', 'sqitch-': 'db',
    'playwright-': 'frontend', 'cypress-': 'frontend',
    'storybook-': 'frontend', 'percy-': 'frontend',
    'lighthouse-': 'frontend',
    'fastlane-': 'mobile', 'app-store-': 'mobile',
    'eas-': 'mobile', 'flutter-': 'mobile',
    'slack-': 'comms', 'discord-': 'comms', 'email-': 'comms',
    'pagerduty-': 'comms', 'matrix-': 'comms', 'teams-': 'comms',
    'telegram-': 'comms', 'twilio-': 'comms', 'mattermost-': 'comms',
    'nats-': 'messaging', 'kafka-': 'messaging',
    'mkdocs-': 'docs', 'docusaurus-': 'docs', 'mdbook-': 'docs',
    'hugo-': 'docs', 'vitepress-': 'docs', 'zola-': 'docs',
    'changelog-': 'docs', 'docs-': 'docs', 'api-spec-': 'docs',
    'toc-': 'docs',
    'mutation-': 'quality', 'benchmark-': 'quality',
    'sonarqube-': 'quality', 'pa11y-': 'quality',
    'dependency-': 'sdlc', 'nix-flake-update': 'sdlc',
    'pr-comment': 'sdlc', 'issue-create': 'sdlc',
    'status-badge': 'sdlc', 'dependabot-': 'sdlc',
    'changesets': 'release-mgmt', 'semantic-': 'release-mgmt',
    'release-please': 'release-mgmt', 'release-promote': 'release-mgmt',
    'yank-version': 'release-mgmt', 'onboard-': 'sdlc',
    'akeyless-': 'akeyless',
    'wireguard-': 'networking', 'tailscale-': 'networking',
    'artifact-fetch': 'storage', 's3-mirror': 'storage',
    'gcs-sync': 'storage', 'restic-': 'backup',
    'temporal-': 'workflow', 'airflow-': 'workflow',
    'devcontainer-': 'devx', 'pre-commit-': 'devx',
    'json-schema-': 'data', 'yaml-lint': 'data',
    'nix-': 'nix', 'nix-flake-check': 'validation',
    'branch-protect-': 'hygiene', 'codeowners-': 'hygiene',
    'stale-': 'hygiene', 'gh-team-': 'hygiene',
    'tlisp-lint': 'validation', 'action-shell-lint': 'meta',
    'adoption-audit': 'meta', 'defaction-render': 'meta',
    'tatara-script': 'runtime',
    'git-': 'git', 'gh-': 'gh', 'derive-version-': 'gh',
    'detect-repo-type': 'dispatch', 'spec-watch': 'spec',
    'caixa-detect': 'dispatch',
    'rust-gate': 'validation', 'npm-gate': 'validation',
    'python-gate': 'validation', 'typecheck-': 'validation',
    'rust-cross-': 'build',
    'rust-workspace-publish': 'publish', 'rust-workspace-bump': 'bump',
    'substrate-bump': 'bump',
}


CATEGORY_INTRO = {
    'rust': '🦀 Rust ecosystem',
    'npm': '📦 npm ecosystem',
    'python': '🐍 Python ecosystem',
    'helm': '⛵ Helm — chart packaging + deployment',
    'caixa': '📦 caixa — canonical SDLC primitive',
    'language': '🌐 Multi-language (Go/Java/.NET/Swift/Elixir/Zig/WASM)',
    'cloud': '☁️ Cloud providers (AWS/GCP/Cloudflare/Azure/Vercel/Netlify/Render/Railway/Heroku/DigitalOcean/Fly)',
    'k8s': '☸️ Kubernetes — apply / deploy / reconcile / wait',
    'iac': '🏗️ IaC — Terraform / Pulumi',
    'db': '🗄️ Database — migrations + backups',
    'frontend': '🖥️ Frontend testing + deployment',
    'mobile': '📱 Mobile — Fastlane / App Store / EAS / Flutter',
    'observability': '📊 Observability — markers / metrics / logs / profiles',
    'security': '🔒 Security — vuln scans / SBOM / signing / secrets',
    'comms': '💬 Notifications across 9 channels',
    'messaging': '📡 Message brokers — NATS / Kafka',
    'docs': '📚 Documentation generation + publishing',
    'quality': '✅ Code quality — mutation / benchmark / SonarQube / accessibility',
    'sdlc': '🔄 SDLC automation',
    'release-mgmt': '📦 Release management — Changesets / semantic-release',
    'akeyless': '🔑 Akeyless secret management',
    'networking': '🌐 Networking — WireGuard / Tailscale',
    'storage': '💾 Storage — S3 / GCS / cross-workflow',
    'backup': '🛡️ Backup — restic',
    'workflow': '⚙️ Workflow orchestration — Temporal / Airflow',
    'devx': '🛠️ Developer experience',
    'data': '📋 Data validation',
    'nix': '❄️ Nix — build / cache push',
    'hygiene': '🧹 Repo hygiene',
    'validation': '🚦 Validation — per-language gates + universal lints',
    'meta': '🪞 Meta — directive enforcement + audit + renderer',
    'runtime': '⚙️ Runtime — tatara-script',
    'git': '📝 Git operations',
    'gh': '🐙 GitHub API',
    'dispatch': '🚏 Repo-type dispatch',
    'spec': '📐 Spec watching',
    'container': '🐋 Container build (Docker / ko / buildah / podman)',
    'build': '🔨 Build — cross-compile / OCI / Ansible',
    'bump': '⬆️ Version bumping',
    'publish': '📤 Registry publishing',
    'ruby': '💎 Ruby gem',
    'ansible': '🅰️ Ansible Collection',
    'uncategorized': '🔧 Uncategorized — needs a home',
}


def categorize(name):
    for prefix in sorted(CATEGORY_MAP.keys(), key=lambda x: -len(x)):
        if name == prefix or name.startswith(prefix):
            return CATEGORY_MAP[prefix]
    return 'uncategorized'


def extract_field(yml, field):
    m = re.search(rf"^{field}:\s*['\"]?(.*?)['\"]?\s*$", yml, re.M)
    return m.group(1) if m else ''


def extract_inputs(yml):
    inputs = {}
    in_block = False
    current = None
    for line in yml.splitlines():
        if line.rstrip() == 'inputs:':
            in_block = True
            continue
        if in_block and line and not line.startswith(' ') and not line.startswith('#'):
            in_block = False
        if not in_block:
            continue
        if re.match(r'^  [a-z][\w-]*:\s*$', line):
            current = line.strip().rstrip(':')
            inputs[current] = {'required': False, 'default': None, 'description': ''}
        elif current and line.strip().startswith('required:'):
            inputs[current]['required'] = 'true' in line
        elif current and line.strip().startswith('default:'):
            d = line.split(':', 1)[1].strip().strip('"\'')
            inputs[current]['default'] = d
        elif current and line.strip().startswith('description:'):
            d = line.split(':', 1)[1].strip().strip('"\'')
            inputs[current]['description'] = d
    return inputs


def extract_outputs(yml):
    outputs = {}
    in_block = False
    current = None
    for line in yml.splitlines():
        if line.rstrip() == 'outputs:':
            in_block = True
            continue
        if in_block and line and not line.startswith(' '):
            in_block = False
        if not in_block:
            continue
        if re.match(r'^  [a-z][\w-]*:\s*$', line):
            current = line.strip().rstrip(':')
            outputs[current] = ''
        elif current and line.strip().startswith('description:'):
            outputs[current] = line.split(':', 1)[1].strip().strip('"\'')
    return outputs


def emit_readme(name, yml, category, siblings):
    desc = extract_field(yml, 'description')
    inputs = extract_inputs(yml)
    outputs = extract_outputs(yml)

    md = f"""# pleme-io · {name}

> {desc}

**Category**: `{category}` — {CATEGORY_INTRO.get(category, '')}
**Backend**: tatara-lisp (run.tlisp) wrapping CLI tools via `exec-capture`
**Auto-published**: pinnable via `@v0.13.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: pleme-io/actions/{name}@v1
"""
    if inputs:
        md += "    with:\n"
        for iname, ispec in list(inputs.items())[:3]:
            if ispec.get('required'):
                md += f"      {iname}: <required>\n"
            else:
                default = ispec.get('default', '')
                md += f"      {iname}: \"{default}\"\n"
    md += "```\n"

    if inputs:
        md += "\n## Inputs\n\n| Name | Required | Default | Description |\n|---|---|---|---|\n"
        for iname, ispec in inputs.items():
            req = 'yes' if ispec.get('required') else 'no'
            dflt = f"`{ispec['default']}`" if ispec.get('default') is not None else '—'
            d = ispec.get('description', '')
            md += f"| `{iname}` | {req} | {dflt} | {d} |\n"

    if outputs:
        md += "\n## Outputs\n\n| Name | Description |\n|---|---|\n"
        for oname, odesc in outputs.items():
            md += f"| `{oname}` | {odesc} |\n"

    md += f"""
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

## Related primitives — `{category}` category

"""
    related = [s for s in sorted(siblings) if s != name][:8]
    if related:
        md += " · ".join(f"[`{r}`](../{r}/)" for r in related) + "\n"
    else:
        md += "(this is the only primitive in this category)\n"

    md += f"""

## Sources

- **Action source**: [`action.yml`](./action.yml) + [`run.tlisp`](./run.tlisp)
- **Catalog entry**: `substrate.lib.release.patterns.{category}.{name}` —
  [patterns-full.nix](https://github.com/pleme-io/substrate/blob/main/lib/release/patterns-full.nix)
- **Future typed source**: `(defaction {name} ...)` per
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
1. `auto-bump.yml` fires (~10s) → tags `v0.13.{{next}}`
2. `release.yml` cuts the Docker image (if applicable) + fast-forwards `v1`
3. Consumers using `@v1` or `@v0.13.{{x}}` see the new revision automatically

**$0/month cost** — GitHub-hosted runners + public-repo free tier.

## Discovery

Browse the [full catalog](../README.md) or query via Nix:

```bash
nix eval --raw github:pleme-io/substrate#lib.aarch64-darwin.release.patterns.{category}.{name}
```

## License

MIT.

---
*Auto-generated from `action.yml` by [`_gen-docs.py`](../_gen-docs.py).
Do not hand-edit; modify the source files or regenerate.*
"""
    return md


def emit_index(by_category):
    total = sum(len(v) for v in by_category.values())
    md = f"""# pleme-io action catalog — {total} typed primitives

> The typed CI/CD vocabulary that powers the pleme-io fleet.
> **All actions auto-publish to free public GitHub-hosted compute.**

## Quickstart — adopt the directive in 6 lines

```yaml
# .github/workflows/auto-release.yml
on:
  push: {{ branches: [main] }}
jobs:
  release:
    uses: pleme-io/substrate/.github/workflows/auto-release.yml@main
    secrets: inherit
```

The polymorphic dispatcher detects your repo type
(rust / npm / python / helm / caixa) and routes to the right pipeline.

## Operator-facing CLI

```bash
cargo install pleme-io-releaser
pleme-release detect      # what kind of repo is this?
pleme-release plan        # preview what auto-release would do
pleme-release onboard     # scaffold the 3-workflow surface
```

## Discovery

```bash
nix eval --raw github:pleme-io/substrate#lib.aarch64-darwin.release.patterns \\
  --apply 'p: builtins.concatStringsSep "\\n" (builtins.attrNames p)'
```

## The {total}-primitive vocabulary

"""
    for cat in sorted(by_category.keys()):
        intro = CATEGORY_INTRO.get(cat, '')
        md += f"\n### `{cat}` — {len(by_category[cat])} primitive(s)\n\n"
        if intro:
            md += f"> {intro}\n\n"
        for name in sorted(by_category[cat]):
            md += f"- [`{name}`](./{name}/) — {by_category[cat][name]}\n"

    md += f"""

---

## How this catalog grows

Per the **★★ generation-over-composition** prime directive
([pleme-io-pattern-core](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-pattern-core/SKILL.md)):
this `README.md` + every per-action `README.md` is **mechanically
auto-generated** from `action.yml` source files via
[`_gen-docs.py`](./_gen-docs.py).

Adding a new primitive:

1. Author `your-action/action.yml` + `your-action/run.tlisp`
2. Run `python3 _gen-docs.py --index` to regenerate this index + the action's README
3. Commit + push → auto-bump fires → new primitive live on `@main` in seconds

## The pattern is self-documenting + self-publishing

| Artifact | Source | Generated |
|---|---|---|
| This `README.md` | action.yml files | by `_gen-docs.py` |
| Per-action `README.md` | action.yml | by `_gen-docs.py` |
| Typed catalog (`patterns-full.nix`) | action.yml | by `_gen-patterns.py` |
| Action triple (M2 target) | `.lisp` source | by `(defaction)` renderer |
| Substrate workflows (M3 target) | `.lisp` source | by `(defworkflow)` renderer |
| Consumer shims (M4 target) | `.lisp` `(defcaixa)` source | by caixa renderer |

After M4: hand-authoring is the FALLBACK. Every artifact is rendered.

## Related substrate docs

- [INTERLOCK.md](https://github.com/pleme-io/substrate/blob/main/docs/INTERLOCK.md) — unified substrate↔actions↔caixa vision
- [ACTION-AS-CAIXA.md](https://github.com/pleme-io/substrate/blob/main/docs/ACTION-AS-CAIXA.md) — `(defaction)` migration roadmap
- [patterns-full.nix](https://github.com/pleme-io/substrate/blob/main/lib/release/patterns-full.nix) — mechanical catalog (this surface)
- [patterns.nix](https://github.com/pleme-io/substrate/blob/main/lib/release/patterns.nix) — curated narrated mirror
- [renderer-poc](https://github.com/pleme-io/substrate/tree/main/lib/release/renderer-poc) — `(defaction)` POC + `(defworkflow)` examples

## Operator skills

- [`pleme-io-pattern-core`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-pattern-core/SKILL.md) — the 5-canonical-section + 5-step-body shape
- [`pleme-io-action-vocabulary`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-action-vocabulary/SKILL.md) — catalog reference
- [`pleme-io-auto-release`](https://github.com/pleme-io/blackmatter-pleme/blob/main/skills/pleme-io-auto-release/SKILL.md) — operator adoption protocol

## License

MIT.

---

*Auto-generated by [`_gen-docs.py`](./_gen-docs.py). Regenerate via CI on every PR.*
"""
    return md


if __name__ == '__main__':
    write_index = '--index' in sys.argv
    actions = []
    for action_yml in sorted(Path('.').glob('*/action.yml')):
        name = action_yml.parent.name
        if name.startswith('_') or name.startswith('.'):
            continue
        actions.append((name, action_yml))

    by_category = defaultdict(dict)
    for name, action_yml in actions:
        yml = action_yml.read_text()
        cat = categorize(name)
        desc = extract_field(yml, 'description')
        by_category[cat][name] = desc

    written = 0
    for name, action_yml in actions:
        yml = action_yml.read_text()
        cat = categorize(name)
        siblings = list(by_category[cat].keys())
        readme = emit_readme(name, yml, cat, siblings)
        (action_yml.parent / 'README.md').write_text(readme)
        written += 1

    print(f"wrote {written} per-action READMEs")

    if write_index:
        index = emit_index(by_category)
        Path('README.md').write_text(index)
        print("wrote root README.md catalog index")
