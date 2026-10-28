use(
  "koutei",
  [
    :annotate,
    :fail,
    :flag?,
    :input,
    :input_lines,
    :input_or,
    :lines_of,
    :mark,
    :output,
    :summary
  ]
)

use("shisutemu", [:status_of, :stderr_of])

def default_rust_marks()
  ["rust_", "cargo-", "-deps-", "crate-"]
end

def header(line)
  if contains?(line, "will be built")
    :build
  elsif contains?(line, "will be fetched")
    :fetch
  end
end

def step(acc, line)
  h = header(line)
  section = acc[:section]
  path = trim(line)
  if not h.nil?
    assoc(acc, :section, h)
  elsif starts_with?(path, "/nix/store/") and section == :build
    assoc(acc, :build, append(acc[:build], [path]))
  elsif starts_with?(path, "/nix/store/") and section == :fetch
    assoc(acc, :fetch, append(acc[:fetch], [path]))
  else
    assoc(acc, :section, nil)
  end
end

def plan_of(text)
  reduce(step, {section: nil, build: [], fetch: []}, lines_of(text))
end

def name_of(path)
  base = split(path, "/")[3] or ""
  join(drop(1, split(base, "-")), "-")
end

def rust?(path, marks)
  any?((m) -> contains?(name_of(path), m), marks)
end

def main()
  installable = input("installable")
  if installable.nil?
    fail("installable is required, e.g. .#checks.x86_64-linux.project")
  end
  marks = input_lines("rust-marks")
  marks = if marks == []
    default_rust_marks
  else
    marks
  end
  cap = exec_capture("nix", "build", "--dry-run", installable)
  if status_of(cap) != 0
    fail("nix build --dry-run #{installable} failed: #{trim(stderr_of(cap))}")
  end
  plan = plan_of(stderr_of(cap))
  build = plan[:build]
  fetch = plan[:fetch]
  rust = filter((p) -> rust?(p, marks), build)
  output("will-build", length(build))
  output("will-fetch", length(fetch))
  output("rust-builds", length(rust))
  budget = to_int(input_or("max-builds", ""))
  over = not budget.nil? and length(build) > budget
  only = flag?("blue-only")
  summary(
    join(
      [
        "### build plan: `#{installable}`",
        "",
        "| | measure | value |",
        "|---|---|---|",
        "| ➖ | derivations to build | #{length(build)} |",
        "| ➖ | paths to fetch | #{length(fetch)} |",
        "| #{mark(not (only and rust != []))} | Rust builds outside the toolchain | #{length(rust)} |",
        "| #{mark(not over)} | build budget | #{input_or("max-builds", "none")} |"
      ],
      line_break
    )
  )
  map(
    fn(p)
      annotate(
        "warning",
        "builds Rust: #{name_of(p)}",
        [["title", "blue-only"]]
      )
    end,
    rust
  )
  if only and rust != []
    fail(
      "blue-only: #{length(rust)} Rust derivation(s) would build here; the toolchain must come from a cache"
    )
  end
  if over
    fail(
      "build budget: #{length(build)} derivations to build, budget #{budget}"
    )
  end
end
