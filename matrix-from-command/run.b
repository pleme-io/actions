use("koutei", %i[fail flag? input input_lines output summary])
use("shisutemu", [:run_capture])

@doc """
rows_of: read a command's stdout as matrix rows. Answers {ok: true, rows} with
the array as canonical JSON, or {ok: false, reason, why} when the text is not
JSON or is JSON but not an array.

    rows_of("[{\"a\": 1}]")[:rows] #=> "[{\"a\":1}]"
    rows_of(" [] ")[:ok] #=> true
    rows_of("{\"a\": 1}")[:reason] #=> "not-array"
    rows_of("nope")[:reason] #=> "not-json"
"""
def rows_of(text)
  canonical = json_canonical(trim(text)) rescue nil
  if canonical.nil?
    {ok: false, reason: "not-json", why: "the command's stdout is not JSON"}
  elsif not starts_with?(canonical, "[")
    {
      ok: false,
      reason: "not-array",
      why: "the command's stdout is JSON but not an array"
    }
  else
    {ok: true, rows: canonical}
  end
end

@doc """
matrix_of: the strategy.matrix object {"include": rows} for canonical rows.

    matrix_of("[{\"a\":1}]") #=> "{\"include\":[{\"a\":1}]}"
    matrix_of("[]") #=> "{\"include\":[]}"
"""
def matrix_of(rows)
  json_stringify({include: json_parse(rows)})
end

@doc """
count_of: the number of rows in canonical rows.

    count_of("[1,2,3]") #=> 3
"""
def count_of(rows)
  length(json_parse(rows))
end

def finish(reason, rows, why)
  output("reason", reason)
  output("rows", rows)
  output("matrix", matrix_of(rows))
  output("count", count_of(rows))
  if why
    fail("matrix-from-command: #{why}")
  end
end

def main()
  program = input("program")
  if program.nil?
    output("reason", "no-program")
    fail("matrix-from-command: input `program` is required")
  end
  run = run_capture(append([program], input_lines("args")))
  if not run[:ok]
    output("reason", "command-failed")
    fail("matrix-from-command: #{run[:why]}")
  end
  read = rows_of(run[:stdout])
  if not read[:ok]
    output("reason", read[:reason])
    fail("matrix-from-command: #{read[:why]}")
  end
  rows = read[:rows]
  n = count_of(rows)
  summary(
    join_lines(
      ["### matrix-from-command", "", "`#{program}` printed #{n} row(s)."]
    )
  )
  if n == 0 and flag?("require-nonempty")
    finish("empty", rows, "`#{program}` printed an empty array")
  elsif n == 0
    finish("empty", rows, nil)
  else
    finish("ok", rows, nil)
  end
end
