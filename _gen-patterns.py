#!/usr/bin/env python3
"""Auto-derive substrate/lib/release/patterns-full.nix from
*/action.yml in pleme-io/actions. Run from the actions repo root:
   python3 _gen-patterns.py > /path/to/substrate/lib/release/patterns-full.nix"""
import re
from pathlib import Path

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


def categorize(name):
    for prefix in sorted(CATEGORY_MAP.keys(), key=lambda x: -len(x)):
        if name == prefix or name.startswith(prefix):
            return CATEGORY_MAP[prefix]
    return 'uncategorized'


def extract_field(yml, field):
    m = re.search(rf"^{field}:\s*['\"]?(.*?)['\"]?\s*$", yml, re.M)
    return m.group(1) if m else ''


if __name__ == '__main__':
    actions_dir = Path('.')
    catalog = {}
    for action_yml in sorted(actions_dir.glob('*/action.yml')):
        name = action_yml.parent.name
        if name.startswith('_') or name.startswith('.'):
            continue
        yml = action_yml.read_text()
        desc = extract_field(yml, 'description')
        desc = desc.replace('\\', '\\\\').replace('"', '\\"')
        backend = 'tatara-lisp' if (action_yml.parent / 'run.tlisp').exists() else 'shell'
        cat = categorize(name)
        catalog.setdefault(cat, {})[name] = (desc, backend)

    print("# auto-generated from pleme-io/actions/*/action.yml")
    print("# regenerate: python3 pleme-io/actions/_gen-patterns.py > patterns-full.nix")
    print()
    print("{")
    for cat in sorted(catalog.keys()):
        print(f"  {cat} = {{")
        for name in sorted(catalog[cat].keys()):
            desc, backend = catalog[cat][name]
            print(f'    "{name}" = {{')
            print(f'      uses = "pleme-io/actions/{name}@main";')
            print(f'      backend = "{backend}";')
            print(f'      role = "{desc}";')
            print(f'    }};')
        print(f"  }};")
    print("}")
