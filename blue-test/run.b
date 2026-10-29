use("koutei", %i[annotate fail input_lines lines_of mark output summary])

use("shisutemu", %i[status_of stderr_of stdout_of])

def targets()
  given = input_lines("paths")
  if given == []
    ["."]
  else
    given
  end
end

def count_in(line, word)
  fields = split(trim(line), " ")
  at = index_of(fields, word)
  if at.nil? or at == 0
    0
  else
    to_int(replace(replace(fields[at - 1], ",", ""), ":", "")) or 0
  end
end

def index_of(xs, word)
  hits = filter((i) -> starts_with?(xs[i], word), range(0, length(xs)))
  if hits == []
    nil
  else
    hits[0]
  end
end

def totals_line(text)
  hits = filter(
    (l) -> contains?(l, " passed, ") and contains?(l, " failed"),
    lines_of(text)
  )
  if hits == []
    ""
  else
    hits[length(hits) - 1]
  end
end

def run_target(target)
  cap = exec_capture("blue", "test", target)
  text = join_lines([stdout_of(cap), stderr_of(cap)])
  map(
    (l) -> annotate("error", trim(l), [["title", "blue test #{target}"]]),
    filter((l) -> starts_with?(trim(l), "FAIL "), lines_of(text))
  )
  last = totals_line(text)
  {
    target:,
    ok: status_of(cap) == 0,
    passed: count_in(last, "passed"),
    failed: count_in(last, "failed"),
    totals: last
  }
end

def row(r)
  "| #{mark(r[:ok])} | `#{r[:target]}` | #{r[:passed]} | #{r[:failed]} |"
end

def main()
  results = map(run_target, targets)
  passed = reduce((acc, r) -> acc + r[:passed], 0, results)
  failed = reduce((acc, r) -> acc + r[:failed], 0, results)
  broken = filter((r) -> not r[:ok], results)
  output("passed", passed)
  output("failed", failed)
  summary(
    join(
      append(
        [
          "### blue test",
          "",
          "| | target | passed | failed |",
          "|---|---|---|---|"
        ],
        map(row, results)
      ),
      line_break
    )
  )
  if broken != []
    fail(
      "blue test: #{failed} failed in #{length(broken)} target(s): #{join(map((r) -> r[:target], broken), ", ")}"
    )
  end
end
