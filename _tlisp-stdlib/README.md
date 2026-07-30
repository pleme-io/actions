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
| `line-is-section-header?` | `(line-is-section-header? LINE)` | True iff the text before the first `[` trims to empty **and** the line has no `=`. **This row used to read "True iff line contains `[`" — that was the OLD, broken rule**, which mis-read `keywords = ["a","b"]` and a comment like `# see [lib]` as section headers and exited the `[package]` walker early (→ spurious "package.version not found") |
| `line-assigns-field?` | `(line-assigns-field? LINE FIELD)` | True iff the trimmed text left of the first `=` byte-equals FIELD (so `rust-version` never matches `version`) |
| `toml-read-field` | `(toml-read-field PATH SECTION FIELD)` | Read a quoted field value from a TOML section |
| `toml-line-in-section` | `(toml-line-in-section PATH SECTION FIELD)` | The **verbatim** line assigning FIELD in SECTION, `""` if absent. Use this instead of re-synthesizing a line you mean to patch |
| `toml-inline-table-line?` | `(toml-inline-table-line? LINE)` | True iff LINE is a single-line `key = { … }` inline table |
| `toml-inline-table-add-key` | `(toml-inline-table-add-key LINE KEY VALUE)` | Insert `, KEY = "VALUE"` before the closing brace, preserving every other byte (notably a `=`/`^` version requirement). `""` when LINE is a shape it will not mangle |
| `cargo-workspace-version` | `()` | Read `[workspace.package].version` from `./Cargo.toml` |
| `cargo-package-version` | `()` | Read `[package].version` |
| `cargo-package-name` | `()` | Read `[package].name` |

### Verified text mutation — the mutate-and-report-success-regardless seal

`(write-file path (string-replace (read-file path) needle repl))` **cannot
fail**. MEASURED: `(string-replace "abc" "ZZZ" "Q")` returns `"abc"`, so an
absent needle rewrites the file byte-identically, `write-file` returns normally,
and the caller cannot tell "I patched the line" from "I did nothing". That shape
made `rust-workspace-publish`'s `rename-crate` log `renamed 'X' -> 'Y'` while
changing zero bytes. Never hand-roll it again — use these.

| Fn | Signature | Purpose |
|---|---|---|
| `replace-once-in-file-verified` | `(… PATH NEEDLE REPL)` | Mutate and return a typed outcome: `'replaced` · `'needle-absent` · `'needle-ambiguous` · `'unchanged` · `'write-mismatch`. Writes **nothing** unless the needle occurs exactly once; verifies `'replaced` by re-reading |
| `replace-once-in-file-or-die` | `(… PATH NEEDLE REPL)` | Same, but logs the diagnosis and `(exit 1)` on anything but `'replaced`. Use wherever the rewrite landing is a precondition for what follows (i.e. every manifest rewrite before a commit) |
| `replace-outcome-reason` | `(… OUTCOME PATH NEEDLE)` | The shared human diagnosis, so every caller reports the same wording |
| `string-occurrence-count` | `(string-occurrence-count S NEEDLE)` | Exact match count. `string-replace` replaces **all** occurrences, so "once" has to be enforced, not intended |
| `string-suffix?` | `(string-suffix? S SUFFIX)` | True iff S ends with SUFFIX. Do **not** write this by splitting on `""` — MEASURED, `(string-split "ab}" "")` is `("" "a" "b" "}" "")`, sentinels at both ends, so a "last character" test reads the sentinel |

**Tier: only-mitigated.** The illegal state is still representable — a caller can
ignore the returned symbol. `replace-once-in-file-or-die` removes the ignore path
for callers whose mutation must land; genuine unrepresentability would need the
interpreter to not offer a `string-replace` + `write-file` pair at all.

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
