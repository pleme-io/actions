use("kazu", [:max])
use("koutei", %i[annotate input_or lines_of output summary])
use("retsu", %i[drop_n first flat_map is_empty size])
use("shisutemu", %i[status_of stdout_of strip_ansi])

@doc """
quoted_drv: The derivation a nix error line names between single quotes, or
nil when the line names none.

    quoted_drv("error: Cannot build '/nix/store/a-x.drv'.") #=> "/nix/store/a-x.drv"
    quoted_drv("error: builder for '/nix/store/a-x.drv' failed with exit code 1;") #=> "/nix/store/a-x.drv"
    quoted_drv("no quote") #=> nil
"""
def quoted_drv(line)
  parts = split(line, "'")
  if size(parts) > 1 and ends_with?(parts[1], ".drv")
    parts[1]
  end
end

@doc """
failure_line?: Whether a line of `nix flake check` output opens a failed
derivation: Determinate Nix says `Cannot build`, upstream says `builder for`.

    failure_line?("error: Cannot build '/nix/store/a-x.drv'.") #=> true
    failure_line?("error: builder for '/nix/store/a-x.drv' failed with exit code 1;") #=> true
    failure_line?("building '/nix/store/a-x.drv'...") #=> false
"""
def failure_line?(line)
  contains?(line, "Cannot build '") or contains?(line, "builder for '")
end

@doc """
check_name: The flake attribute a red-mark line names, or nil.

    check_name("❌ checks.x86_64-linux.conformance") #=> "checks.x86_64-linux.conformance"
    check_name("❓ checks.x86_64-linux.kiwari (cancelled)") #=> nil
"""
def check_name(line)
  t = trim(line)
  if starts_with?(t, "❌ ")
    replace(t, "❌ ", "")
  end
end

@doc """
failed_derivations: Every failed derivation in the output of `nix flake check`,
in order and once each, with the check that named it and nix's stated reason.

    failed_derivations(["❌ checks.s.a", "error: Cannot build '/nix/store/a.drv'.", "       Reason: builder failed with exit code 1."]) #=> [{check: "checks.s.a", drv: "/nix/store/a.drv", reason: "builder failed with exit code 1."}]
    failed_derivations(["all good"]) #=> []
"""
def failed_derivations(lines)
  reverse(
    reduce(
      fn(found, pair)
        i = pair[0]
        line = pair[1]
        drv = quoted_drv(line)
        if not failure_line?(line) or
            drv.nil? or
            any?((f) -> f[:drv] == drv, found)
          found
        else
          cons(
            {
              check: check_before(lines, i),
              drv:,
              reason: reason_after(lines, i, line)
            },
            found
          )
        end
      end,
      [],
      retsu::enumerate(lines)
    )
  )
end

def check_before(lines, i)
  above = check_name(
    if i > 0
      lines[i - 1]
    else
      ""
    end
  )
  if above.nil?
    "the derivation #{derivation_name(lines[i])}"
  else
    above
  end
end

@doc """
derivation_name: A store path's name, for a failure `nix build` reports with no
check beside it.

    derivation_name("error: Cannot build '/nix/store/abc-docs.drv'.") #=> "abc-docs"
"""
def derivation_name(line)
  replace(path_basename(quoted_drv(line)), ".drv", "")
end

def reason_after(lines, i, line)
  next_line = if i + 1 < size(lines)
    trim(lines[i + 1])
  else
    ""
  end
  if starts_with?(next_line, "Reason: ")
    replace(next_line, "Reason: ", "")
  else
    trim(line)
  end
end

@doc """
named_line?: Whether a build-log line names what failed: a test harness's
failure line or a compiler's error, the lines a tail of the log loses.

    named_line?("FAIL row.buried@walker") #=> true
    named_line?("test tests::second ... FAILED") #=> true
    named_line?("thread 'x' panicked at src/lib.rs:1:1:") #=> true
    named_line?("MISSING rule:B0001 has no spec row") #=> true
    named_line?("test tests::first ... ok") #=> false
"""
def named_line?(line)
  t = trim(line)
  any?(
    (p) -> starts_with?(t, p),
    ["FAIL", "MISSING ", "REFUSED ", "error:", "error[", "not ok", "failed:"]
  ) or
    any?(
      (p) -> contains?(t, p),
      [" FAILED", "panicked at", "❌", "✗ ", "assertion failed"]
    )
end

@doc """
named_lines: The lines of a build log that name what failed, the first `cap`
of them, in order.

    named_lines(["ok", "FAIL a", "ok", "FAIL b"], 1) #=> ["FAIL a"]
    named_lines([], 5) #=> []
"""
def named_lines(lines, cap)
  take(cap, filter(named_line?, map(strip_ansi, lines)))
end

@doc """
tail_of: The last `n` lines.

    tail_of(["a", "b", "c"], 2) #=> ["b", "c"]
    tail_of(["a"], 5) #=> ["a"]
    tail_of([], 5) #=> []
"""
def tail_of(lines, n)
  drop_n(lines, max(0, size(lines) - n))
end

@doc """
network_lines: The lines of the run that say a substitute could not be fetched:
a failure with no log of its own, which is the only cause a `dependency failed`
reason ever states.

    network_lines(["error: unable to download 'u': HTTP error 416", "ok"]) #=> ["error: unable to download 'u': HTTP error 416"]
"""
def network_lines(lines)
  filter(
    fn(l)
      starts_with?(trim(l), "error:") and
        any?(
          (p) -> contains?(l, p),
          ["unable to download", "no substituter", "some substitutes"]
        )
    end,
    lines
  )
end

@doc """
finding: One failed derivation with the lines of its log that name the failure
and the tail, read through `nix log`. A derivation with no log, one whose
dependency failed, reports the run's substitute failures instead.
"""
def finding(failed, lines, tail_lines)
  read = exec_capture("nix", "log", failed[:drv])
  log = if status_of(read) == 0
    lines_of(stdout_of(read))
  else
    []
  end
  named = if is_empty(log)
    network_lines(lines)
  else
    named_lines(log, 100)
  end
  {
    check: failed[:check],
    drv: failed[:drv],
    reason: failed[:reason],
    named:,
    tail: tail_of(log, tail_lines)
  }
end

@doc """
headline: The one line that says why a finding failed: the first line naming
it, else nix's reason.

    headline({named: ["FAIL a"], reason: "builder failed"}) #=> "FAIL a"
    headline({named: [], reason: "1 dependency failed."}) #=> "1 dependency failed."
"""
def headline(f)
  if is_empty(f[:named])
    f[:reason]
  else
    first(f[:named])
  end
end

def print_finding(f)
  annotate("error", headline(f), [["title", f[:check]]])
  write_stdout(
    unlines(
      flat_map(
        [
          [
            "::group::#{f[:check]}: #{size(f[:tail])} lines of nix log #{f[:drv]}"
          ],
          f[:tail],
          ["::endgroup::", "#{f[:check]}: #{f[:reason]}"],
          map((l) -> "  #{l}", f[:named])
        ],
        (part) -> part
      )
    )
  )
end

@doc """
section: A finding as markdown for the step summary: its check and headline,
then the naming lines and the tail, folded.

    contains?(section({check: "c", drv: "d", reason: "r", named: ["FAIL a"], tail: ["t"]}), "FAIL a") #=> true
"""
def section(f)
  fence = "````"
  join(
    [
      "❌ `#{f[:check]}`: #{headline(f)}",
      "",
      "<details><summary>the log, #{size(f[:named])} naming lines and #{size(f[:tail])} of the tail</summary>",
      "",
      "`nix log #{f[:drv]}`",
      "",
      fence,
      join(f[:named], line_break),
      "...",
      join(f[:tail], line_break),
      fence,
      "</details>",
      ""
    ],
    line_break
  )
end

@doc """
main: Name each derivation a `nix flake check` output reports failed: annotate
it, print its log, write the step summary and set `failed` and `names`. Reads
the output from NIX_FLAKE_CHECK_LOG. It fails nothing; the check's own step did.
"""
def main()
  path = input_or("log", "")
  lines = map(strip_ansi, lines_of(read_file(path)))
  failed = failed_derivations(lines)
  tail_lines = to_int(input_or("tail-lines", "400"))
  findings = map((f) -> finding(f, lines, tail_lines), failed)
  map(print_finding, findings)
  output("failed", size(findings))
  output(
    "names",
    join(flat_map(findings, (f) -> cons(f[:check], f[:named])), line_break)
  )
  summary(
    join(
      cons(
        unlines(
          ["### nix flake check: #{size(findings)} failed derivation(s)"]
        ),
        map(section, findings)
      ),
      line_break
    )
  )
end

test "the receipt's conformance failure is named, though 25 lines of tail lost it"
  log = append(["FAIL spec.row@walker"], map((i) -> "noise #{i}", range(80)))
  assert named_lines(log, 100) == ["FAIL spec.row@walker"]
  assert not member?("FAIL spec.row@walker", tail_of(log, 25))
end

test "the receipt's network failure names the download, since the check has no log"
  lines = [
    "error: unable to download 'https://cache.nixos.org/nar/x.nar.xz': HTTP error 416",
    "❌ checks.x86_64-linux.network",
    "error: Cannot build '/nix/store/q-blue-network.drv'.",
    "       Reason: 1 dependency failed."
  ]
  failed = failed_derivations(lines)
  assert size(failed) == 1
  assert first(failed)[:check] == "checks.x86_64-linux.network"
  assert first(failed)[:reason] == "1 dependency failed."
  assert size(network_lines(lines)) == 1
end

test "every failed derivation is listed once and in order, with keep-going's many"
  lines = [
    "❌ checks.s.a",
    "error: Cannot build '/nix/store/a.drv'.",
    "       Reason: builder failed with exit code 1.",
    "error: Cannot build '/nix/store/a.drv'.",
    "❌ checks.s.b",
    "error: builder for '/nix/store/b.drv' failed with exit code 1;"
  ]
  assert map((f) -> f[:drv], failed_derivations(lines)) ==
    %w[/nix/store/a.drv /nix/store/b.drv]
end

test "a run with no failed derivation has nothing to name"
  assert failed_derivations([]) == []
  assert failed_derivations(["✅ checks.s.a", "error: flake has no checks"]) ==
    []
  assert named_lines([], 100) == []
end
