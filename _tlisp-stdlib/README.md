# `_tlisp-stdlib` — shared helper library for tlisp-backed actions

Prepended to each action's `run.tlisp` by the action's loader
step. Holds every helper that appeared in ≥2 actions as of the
v0.13.x release line.

The `_` prefix marks this as a non-action directory (action
discovery / CI lint targets only sibling-dirs with an
`action.yml`).

## Contents

### Output sink

| Fn | Signature | Purpose |
|---|---|---|
| `append-output` | `(append-output LINE)` | Append `LINE\n` to `$GITHUB_OUTPUT` (no-op outside Actions) |

### exec-capture accessors

| Fn | Signature | Purpose |
|---|---|---|
| `status-of` | `(status-of RESULT)` | Exit code (`-1` on missing key) |
| `stdout-of` | `(stdout-of RESULT)` | Captured stdout (`""` on missing) |
| `stderr-of` | `(stderr-of RESULT)` | Captured stderr (`""` on missing) |

### TOML line walker

| Fn | Signature | Purpose |
|---|---|---|
| `extract-quoted-value` | `(extract-quoted-value LINE)` | Pull the first `"X"` (or `'X'`) substring |
| `line-is-section-header?` | `(line-is-section-header? LINE)` | True iff line contains `[` |
| `toml-read-field` | `(toml-read-field PATH SECTION FIELD)` | Read a quoted field value from a TOML section |
| `cargo-workspace-version` | `()` | Read `[workspace.package].version` from `./Cargo.toml` |
| `cargo-package-version` | `()` | Read `[package].version` |
| `cargo-package-name` | `()` | Read `[package].name` |

### Git introspection

| Fn | Signature | Purpose |
|---|---|---|
| `last-tag` | `()` | `git describe --tags --abbrev=0`; `""` on no tags |
| `has-changes-since?` | `(has-changes-since? TAG PATHS)` | True iff `git diff --quiet TAG HEAD -- <PATHS>` reports changes; `""` tag treats as always-changed |
| `configure-git-bot` | `()` | Set `user.name`/`user.email` to github-actions[bot] + add `safe.directory *` |

### Log scanning

| Fn | Signature | Purpose |
|---|---|---|
| `any-line-matches?` | `(any-line-matches? LINES PRED)` | True iff any line satisfies the predicate |
| `log-contains?` | `(log-contains? LOG SUBSTR)` | True iff any line of LOG contains SUBSTR |

### HTTP existence probe

| Fn | Signature | Purpose |
|---|---|---|
| `http-200?` | `(http-200? URL)` | True iff GET returns HTTP 200 |
| `cargo-published?` | `(cargo-published? NAME VERSION)` | True iff `(name, version)` is on crates.io |

## Adoption template for an action's `action.yml`

```yaml
- name: Load stdlib + run.tlisp
  id: src
  shell: bash
  run: |
    {
      echo 'script<<TLISP_EOF'
      curl -sL https://raw.githubusercontent.com/pleme-io/actions/main/_tlisp-stdlib/stdlib.tlisp
      echo
      cat ${{ github.action_path }}/run.tlisp
      echo 'TLISP_EOF'
    } >> "$GITHUB_OUTPUT"

- name: Run action
  uses: pleme-io/actions/tatara-script@v1
  with:
    script: ${{ steps.src.outputs.script }}
```

## Versioning

The stdlib's contract is bump-compatible with the actions repo's
floating `v1` tag. Breaking changes to a helper require a major
bump on the action that broke; the stdlib stays
backwards-compatible by adding new helpers + deprecating old
ones (marked with `;; DEPRECATED:` comments) rather than removing.

## Adding a helper

Trigger conditions:
1. A pattern appears in ≥2 action `run.tlisp` files
2. The pattern has a clear single-line contract
3. The pattern doesn't reach into action-specific state

Process:
1. Add the fn to `stdlib.tlisp` with a doc comment
2. Add a row to the table above
3. Refactor the consumer actions to drop their local copy
4. Bump the actions repo's version tag (`v0.x.y → v0.x.{y+1}`)
