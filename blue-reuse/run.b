use("koutei", %i[annotate input lines_of mark output summary truthy?])
use("moji", %i[after_first before_first includes])
use("retsu", %i[first size take_while])

use("shisutemu", %i[read_or status_of stderr_of stdout_of])

WAIVER = "skip-reuse-ratchet:"

ADOPT = "blue census --reuse . --record --receipt \"first measure\""

def waiver_reason(text)
  head = take_while((l) -> not starts_with?(l, "## "), split(text, line_break))
  hits = filter((l) -> includes(l, WAIVER), head)
  if hits == []
    nil
  else
    rest = trim(after_first(first(hits), WAIVER))
    if includes(rest, "`")
      trim(before_first(rest, "`"))
    else
      rest
    end
  end
end

def report_of(text)
  json_read(text) rescue nil
end

def state_of(has_blue, reason, cap_status, doc)
  if reason != nil and reason != ""
    :skipped
  elsif not has_blue
    :no_blue
  elsif doc.nil? or cap_status > 1
    :blind
  else
    :ran
  end
end

def broken_scopes(doc)
  map((b) -> b["scope"], doc["broken"])
end

def in_broken_row?(doc, finding)
  member?(finding["scope"], broken_scopes(doc))
end

def row_line(b)
  "| #{mark(false)} | `#{b["scope"]}` | #{b["verdict"]} | #{b["measured"]} | #{b["recorded"] or "-"} |"
end

def copy_line(doc, f)
  "| #{mark(not in_broken_row?(doc, f))} | `#{f["file"]}:#{f["line"]}` | `#{f["name"]}` | `#{f["home"]}` | #{f["fix"]} |"
end

def headline(doc)
  "#{mark(doc["broken"] == [])} #{doc["copies"]} copies in #{doc["definitions"]} definitions across #{doc["files"]} files, #{size(doc["broken"])} rows grew or are new, #{doc["waived"]} waived, #{size(doc["blind"])} blind"
end

def summary_text(doc)
  rows = if doc["broken"] == []
    []
  else
    append(
      [
        "",
        "| | row | verdict | measured | recorded |",
        "|---|---|---|---|---|"
      ],
      map(row_line, doc["broken"])
    )
  end
  copies = if doc["findings"] == []
    []
  else
    append(
      ["", "| | where | definition | home | fix |", "|---|---|---|---|---|"],
      map((f) -> copy_line(doc, f), doc["findings"])
    )
  end
  advisory = if doc["adopted"]
    []
  else
    [
      "",
      "advisory: no baseline, so nothing is enforced. Adopt it: `#{ADOPT}`, then commit `reuse.baseline`."
    ]
  end
  join(
    append(["### blue reuse", "", headline(doc)], rows, advisory, copies),
    line_break
  )
end

def enforcing?(given)
  given.nil? or truthy?(given)
end

def level_of_copy(enforce)
  if enforce
    "error"
  else
    "warning"
  end
end

def annotate_copy(level, f)
  annotate(
    level,
    "#{f["name"]} is #{f["home"]} (#{f["fix"]})",
    [["file", f["file"]], ["line", f["line"]], ["title", "blue reuse"]]
  )
end

def outputs_of(state, doc)
  output("state", to_s(state))
  if doc != nil
    output("adopted", to_s(doc["adopted"]))
    output("files", doc["files"])
    output("definitions", doc["definitions"])
    output("copies", doc["copies"])
    output("waived", doc["waived"])
    output("broken", size(doc["broken"]))
  else
    output("adopted", "false")
    output("files", 0)
    output("definitions", 0)
    output("copies", 0)
    output("waived", 0)
    output("broken", 0)
  end
end

def census_args(baseline)
  if baseline.nil?
    %w[census --reuse . --json]
  else
    ["census", "--reuse", ".", "--json", "--baseline", baseline]
  end
end

def main()
  reason = waiver_reason(read_or("CLAUDE.md", ""))
  listed = exec_capture("git", "ls-files", "--", "*.b")
  has_blue = status_of(listed) != 0 or lines_of(stdout_of(listed)) != []
  waived_repo = reason != nil and reason != ""
  if reason == ""
    annotate(
      "warning",
      "#{WAIVER} names no reason, so the ratchet runs",
      [%w[file CLAUDE.md], ["title", "blue reuse"]]
    )
  end
  if waived_repo or not has_blue
    state = state_of(has_blue, reason, 0, nil)
    outputs_of(state, nil)
    summary(
      join(
        [
          "### blue reuse",
          "",
          if waived_repo
            "➖ skipped: `#{WAIVER} #{reason}`"
          else
            "➖ no .b files"
          end
        ],
        line_break
      )
    )
  else
    cap = exec_capture("blue", *census_args(input("baseline")))
    doc = report_of(stdout_of(cap))
    state = state_of(has_blue, reason, status_of(cap), doc)
    outputs_of(
      state,
      if state == :ran
        doc
      end
    )
    if state == :blind
      annotate(
        "warning",
        "blue census --reuse could not run (exit #{status_of(cap)}): #{stderr_of(cap)}",
        [["title", "blue reuse"]]
      )
      summary(
        join(
          [
            "### blue reuse",
            "",
            "⚠️ blind: this blue could not run the ratchet; nothing was judged"
          ],
          line_break
        )
      )
    else
      enforce = enforcing?(input("enforce"))
      summary(summary_text(doc))
      map(
        (f) -> annotate_copy(level_of_copy(enforce), f),
        filter((f) -> in_broken_row?(doc, f), doc["findings"])
      )
      if doc["broken"] != []
        annotate(
          level_of_copy(enforce),
          "blue reuse: #{size(doc["broken"])} row(s) grew or are new. Use the word, move the shape down, or promote it; an exception is # waive B0070: <reason>",
          [["title", "blue reuse"]]
        )
      end
    end
  end
end

def doc_of(broken, findings)
  {
    "adopted" => true,
    "copies" => size(findings),
    "definitions" => 10,
    "files" => 2,
    "waived" => 0,
    "blind" => [],
    "broken" => broken,
    "findings" => findings
  }
end

def finding(scope)
  {
    "scope" => scope,
    "file" => "#{scope}.b",
    "line" => 3,
    "name" => "tally",
    "home" => "kazu::sum",
    "fix" => "import"
  }
end

test "a repo waiver is a line at the top with its reason"
  assert waiver_reason("").nil?
  assert waiver_reason(
    unlines(["# t", "", "skip-reuse-ratchet: vendored fixtures"])
  ) == "vendored fixtures"
  assert waiver_reason(unlines(["- `skip-reuse-ratchet: vendored` — why"])) ==
    "vendored"
  assert waiver_reason(unlines(["skip-reuse-ratchet:"])) == ""
end

test "a waiver below the first section is no waiver"
  assert waiver_reason(
    unlines(["# t", "", "## body", "", "skip-reuse-ratchet: late"])
  ).nil?
end

test "the state says why nothing was judged, and only ran can fail"
  doc = doc_of([], [])
  assert state_of(true, "vendored", 0, doc) == :skipped
  assert state_of(true, "", 0, doc) == :ran
  assert state_of(false, nil, 0, nil) == :no_blue
  assert state_of(true, nil, 2, nil) == :blind
  assert state_of(true, nil, 2, doc) == :blind
  assert state_of(true, nil, 1, doc) == :ran
  assert state_of(true, nil, 0, doc) == :ran
end

test "a report that is no json reads as nothing"
  assert report_of("error: unexpected argument").nil?
  assert report_of("{\"copies\":1}")["copies"] == 1
end

test "the summary names each copy's home, and a held row carries a check"
  held = summary_text(doc_of([], [finding("a")]))
  assert includes(held, "`a.b:3`")
  assert includes(held, "`kazu::sum`")
  assert not includes(held, "| row |")
  assert not includes(held, "advisory")
end

test "the summary names a broken row and marks only its copies"
  row = {"scope" => "b", "verdict" => "grew", "measured" => 2, "recorded" => 1}
  doc = doc_of([row], [finding("a"), finding("b")])
  text = summary_text(doc)
  assert includes(text, "| ❌ | `b` | grew | 2 | 1 |")
  assert includes(text, "| ✅ | `a.b:3`")
  assert includes(text, "| ❌ | `b.b:3`")
end

test "an unadopted repo reads as advisory and names the command"
  doc = assoc(doc_of([], []), "adopted", false)
  assert includes(summary_text(doc), "--record --receipt")
end

test "enforce defaults on, and only a no word turns it off"
  assert enforcing?(nil)
  assert enforcing?("true")
  assert not enforcing?("false")
  assert level_of_copy(true) == "error"
  assert level_of_copy(false) == "warning"
end
