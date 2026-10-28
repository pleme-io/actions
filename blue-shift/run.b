use("deeta", [:json_at])

use(
  "koutei",
  [
    :annotate,
    :fail,
    :input_lines,
    :input_or,
    :lines_of,
    :mark,
    :output,
    :summary
  ]
)

use("shisutemu", [:stdout_of])

def rungs()
  ["dynamic", "annotated", "checked", "restricted"]
end

def rank(rung)
  hits = filter((i) -> rungs[i] == rung, range(0, length(rungs)))
  if hits == []
    -1
  else
    hits[0]
  end
end

def files()
  given = input_lines("paths")
  if given == []
    lines_of(stdout_of(exec_capture("git", "ls-files", "--", "*.b")))
  else
    given
  end
end

def reading(file)
  r = json_parse(stdout_of(exec_capture("blue", "shift", "--json", file)))
  held = json_at(r, "holding_back") or []
  first_held = if held == []
    nil
  else
    held[0]
  end
  {
    file:,
    rung: json_at(r, "rung") or "dynamic",
    typed: json_at(r, "typed"),
    total: json_at(r, "total"),
    line: if first_held.nil?
      nil
    else
      json_at(first_held, "line")
    end,
    why: if first_held.nil?
      nil
    else
      json_at(first_held, "detail")
    end
  }
end

def below?(r, floor)
  rank(r[:rung]) < rank(floor)
end

def row(r, floor)
  "| #{mark(not below?(r, floor))} | `#{r[:file]}` | #{r[:rung]} | #{r[:typed]}/#{r[:total]} |"
end

def lowest(results)
  reduce(
    fn(acc, r)
      if rank(r[:rung]) < rank(acc)
        r[:rung]
      else
        acc
      end
    end,
    "restricted",
    results
  )
end

def main()
  floor = input_or("floor", "dynamic")
  if rank(floor) < 0
    fail("floor #{floor} is not a rung; the rungs are #{join(rungs, ", ")}")
  end
  results = map(reading, files)
  short = filter((r) -> below?(r, floor), results)
  map(
    fn(r)
      annotate(
        "error",
        "#{r[:file]} is #{r[:rung]}, below the floor #{floor}: #{r[:why]}",
        [["file", r[:file]], ["line", r[:line]], ["title", "blueshift"]]
      )
    end,
    short
  )
  output("lowest", lowest(results))
  output("below-floor", length(short))
  summary(
    join(
      append(
        [
          "### blueshift (floor: #{floor})",
          "",
          "| | file | rung | typed |",
          "|---|---|---|---|"
        ],
        map((r) -> row(r, floor), results)
      ),
      line_break
    )
  )
  if short != []
    fail("blueshift: #{length(short)} file(s) below the floor #{floor}")
  end
end
