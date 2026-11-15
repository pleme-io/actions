use("kakehashi/hyouka", [:capture])
use("koutei", %i[fail flag? input input_lines input_or mark output summary])
use("retsu", %i[flat_map last])
use("shisutemu", %i[status_of stderr_of stdout_of])

@doc """
chart_dir: the directory of a Chart.yaml path, without a leading ./, or "."
for a chart at the root.

    chart_dir("./a/b/Chart.yaml") #=> "a/b"
    chart_dir("a/Chart.yaml") #=> "a"
    chart_dir("Chart.yaml") #=> "."
"""
def chart_dir(path)
  parts = filter((p) -> p != ".", butlast(split(path, "/")))
  if parts == []
    "."
  else
    join(parts, "/")
  end
end

@doc """
inside?: whether directory `d` sits under directory `parent`.

    inside?("a/charts/b", "a") #=> true
    inside?("ab", "a") #=> false
    inside?("a/x", ".") #=> true
    inside?(".", ".") #=> false
"""
def inside?(d, parent)
  d != parent and (parent == "." or starts_with?(d, "#{parent}/"))
end

@doc """
top_charts: the chart directories for a list of Chart.yaml paths, sorted and
once each, without a chart nested in another (a subchart is rendered by its
parent).

    top_charts(["./x/Chart.yaml", "a/charts/s/Chart.yaml", "a/Chart.yaml", "./x/Chart.yaml"]) #=> ["a", "x"]
"""
def top_charts(paths)
  dirs = distinct(map(chart_dir, paths))
  sort_keyed(
    (d) -> d,
    filter((d) -> not any?((p) -> inside?(d, p), dirs), dirs)
  )
end

@doc """
chart_files: every Chart.yaml at or under `root`.

    chart_files("koutei-no-such-dir") #=> []
"""
def chart_files(root)
  if root == "."
    glob("**/Chart.yaml")
  else
    filter(
      is_file?,
      append(glob("#{root}/Chart.yaml"), glob("#{root}/**/Chart.yaml"))
    )
  end
end

@doc """
release_name: the release name helm template is given for a chart directory.

    release_name("a/b-c") #=> "b-c"
    release_name(".") #=> "chart"
"""
def release_name(dir)
  if dir == "."
    "chart"
  else
    last(split(dir, "/"))
  end
end

@doc """
when_: `xs` when `holds`, else no elements.

    when_(false, ["a"]) #=> []
"""
def when_(holds, xs)
  if holds
    xs
  else
    []
  end
end

@doc """
value_flags: the flags every lint and render shares: values files, --set
lines and the Kubernetes version.

    value_flags({values: ["v.yaml"], set: ["a=1"], kube: nil}) #=> ["--values", "v.yaml", "--set", "a=1"]
    value_flags({values: [], set: [], kube: "1.31.0"}) #=> ["--kube-version", "1.31.0"]
"""
def value_flags(opts)
  append(
    flat_map(opts[:values], (f) -> ["--values", f]),
    flat_map(opts[:set], (l) -> ["--set", l]),
    when_(not opts[:kube].nil?, ["--kube-version", opts[:kube]])
  )
end

@doc """
lint_argv: the helm lint argv for a chart.

    lint_argv("c", {strict: true, values: [], set: [], kube: nil}) #=> ["helm", "lint", "c", "--strict"]
"""
def lint_argv(dir, opts)
  append(
    ["helm", "lint", dir],
    when_(opts[:strict], ["--strict"]),
    value_flags(opts)
  )
end

@doc """
template_argv: the helm template argv for a chart.

    template_argv("a/c", {namespace: "ns", values: [], set: [], kube: nil}) #=> ["helm", "template", "c", "a/c", "--namespace", "ns"]
"""
def template_argv(dir, opts)
  append(
    [
      "helm",
      "template",
      release_name(dir),
      dir,
      "--namespace",
      opts[:namespace]
    ],
    value_flags(opts)
  )
end

def ok?(cap)
  not cap.nil? and status_of(cap) == 0
end

def show(title, cap)
  write_stdout(unlines(["::group::#{title}"]))
  if cap.nil?
    write_stdout(unlines(["could not start helm", "::endgroup::"]))
  else
    write_stdout(unlines([stdout_of(cap), stderr_of(cap), "::endgroup::"]))
  end
end

def render(dir, opts)
  deps = if is_file?("#{dir}/Chart.lock")
    capture(["helm", "dependency", "build", dir])
  end
  lint = capture(lint_argv(dir, opts))
  show("helm lint #{dir}", lint)
  tpl = capture(template_argv(dir, opts))
  if not ok?(tpl)
    show("helm template #{dir}", tpl)
  end
  {
    dir:,
    deps: deps.nil? or ok?(deps),
    lint: ok?(lint),
    template: ok?(tpl),
    docs: documents(tpl)
  }
end

def documents(cap)
  if ok?(cap)
    length(
      filter((l) -> l == "---", map(trim, split(stdout_of(cap), line_break)))
    )
  else
    0
  end
end

def clean?(r)
  r[:deps] and r[:lint] and r[:template]
end

def row(r)
  "| #{mark(clean?(r))} | `#{r[:dir]}` | #{mark(r[:lint])} | #{mark(r[:template])} | #{r[:docs]} |"
end

def main()
  root = input_or("path", ".")
  charts = top_charts(chart_files(root))
  output("charts", length(charts))
  if charts == []
    output("failed", 0)
    fail("helm-chart-render: no Chart.yaml at or under #{root}")
  end
  opts = {
    strict: flag?("strict"),
    namespace: input_or("namespace", "default"),
    kube: input("kube-version"),
    values: input_lines("values"),
    set: input_lines("set")
  }
  results = map((d) -> render(d, opts), charts)
  failed = length(filter((r) -> not clean?(r), results))
  output("failed", failed)
  summary(
    join_lines(
      append(
        [
          "### helm-chart-render",
          "",
          "| | chart | lint | template | documents |",
          "|---|---|---|---|---|"
        ],
        map(row, results)
      )
    )
  )
  if failed > 0
    fail("helm-chart-render: #{failed} of #{length(results)} chart(s) failed")
  end
end
