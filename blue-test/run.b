use(
  "koutei",
  [:annotate, :fail, :input_lines, :lines_of, :mark, :output, :summary]
)

use("shisutemu", [:status_of, :stderr_of, :stdout_of])

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
    to_int(replace(replace(nth(at - 1, fields), ",", ""), ":", "")) or 0
  end
end

def index_of(xs, word)
  hits = filter((i) -> starts_with?(nth(i, xs), word), range(0, length(xs)))
  if hits == []
    nil
  else
    nth(0, hits)
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
    nth(length(hits) - 1, hits)
  end
end

def run_target(target)
  cap = exec_capture("blue", "test", target)
  text = "#{stdout_of(cap)}\n#{stderr_of(cap)}"
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
  "| #{mark(get(r, :ok))} | `#{get(r, :target)}` | #{get(r, :passed)} | #{get(r, :failed)} |"
end

def main()
  results = map(run_target, targets)
  passed = reduce((acc, r) -> acc + get(r, :passed), 0, results)
  failed = reduce((acc, r) -> acc + get(r, :failed), 0, results)
  broken = filter((r) -> not get(r, :ok), results)
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
      "\n"
    )
  )
  if broken != []
    fail(
      "blue test: #{failed} failed in #{length(broken)} target(s): #{join(map((r) -> get(r, :target), broken), ", ")}"
    )
  end
end
