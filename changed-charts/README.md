# pleme-io · changed-charts

> Which chart directories moved in this push, as a matrix-ready JSON array

**Category**: `helm` — ⛵ Helm — chart packaging + deployment
**Backend**: tatara-lisp
**Auto-published**: pinnable via `@v0.x` tags or floating `@v1` / `@main`

## 30-second quickstart

```yaml
jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set.outputs.matrix }}
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 2 }
      - id: set
        uses: pleme-io/actions/changed-charts@main
  publish:
    needs: changes
    if: needs.changes.outputs.matrix != '[]'
    strategy:
      matrix:
        chart: ${{ fromJson(needs.changes.outputs.matrix) }}
    uses: pleme-io/flows/.github/workflows/helm-publish.yml@main
    with:
      chartPath: ./charts/${{ matrix.chart }}
```

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `path` | no | `charts` | Directory holding one subdirectory per chart |
| `before` | no | `` | The push's before SHA; empty or the all-zero SHA falls back to `HEAD~1` |

## Outputs

| Name | Description |
|---|---|
| `matrix` | JSON array of changed chart directory names (those with a `Chart.yaml`); `[]` when none |

## Why an action and not a workflow

GitHub startup_fails a reusable workflow called from a reusable workflow
with a matrix (measured 2026-11-21, helmworks run 44861052761), so the
composed detect→publish chain cannot live in one reusable. Detection ships
as this action (actions nest without limit); the publish call stays at
depth 2 in the consumer's own caller.
