use("deeta", [:json_at])

use(
  "koutei",
  %i[
    annotate
    diagnostic?
    diagnostic_annotation
    fail
    input_lines
    lines_of
    mark
    output
    summary
  ]
)

use("shisutemu", %i[status_of stdout_of])

def files()
  given = input_lines("paths")
  if given == []
    lines_of(stdout_of(exec_capture("git", "ls-files", "--", "*.b")))
  else
    given
  end
end

def severity_of(line)
  json_at(json_parse(line), "severity")
end

def check_file(file)
  diagnostics = filter(
    diagnostic?,
    lines_of(stdout_of(exec_capture("blue", "check", "--format", "json", file)))
  )
  map((d) -> write_stdout(unlines([diagnostic_annotation(d)])), diagnostics)
  canonical = status_of(exec_capture("blue", "fmt", "--check", file)) == 0
  if not canonical
    annotate(
      "error",
      "not in canonical form; run `blue fmt --write #{file}`",
      [["file", file], ["title", "blue fmt"]]
    )
  end
  {
    file:,
    errors: length(filter((d) -> severity_of(d) == "error", diagnostics)),
    warnings: length(filter((d) -> severity_of(d) == "warning", diagnostics)),
    canonical:
  }
end

def total(key, results)
  reduce((acc, r) -> acc + get(r, key), 0, results)
end

def clean?(r)
  r[:errors] == 0 and r[:canonical]
end

def row(r)
  "| #{mark(clean?(r))} | `#{r[:file]}` | #{r[:errors]} | #{r[:warnings]} | #{mark(r[:canonical])} |"
end

def main()
  results = map(check_file, files)
  errors = total(:errors, results)
  warnings = total(:warnings, results)
  unformatted = length(filter((r) -> not r[:canonical], results))
  output("files", length(results))
  output("errors", errors)
  output("warnings", warnings)
  output("unformatted", unformatted)
  summary(
    join(
      append(
        [
          "### blue check",
          "",
          "| | file | errors | warnings | form |",
          "|---|---|---|---|---|"
        ],
        map(row, results)
      ),
      line_break
    )
  )
  if errors > 0 or unformatted > 0
    fail(
      "blue check: #{errors} error(s), #{unformatted} file(s) not canonical, in #{length(results)} file(s)"
    )
  end
end
