@moduledoc """
blue-service-release — release a blue service and ask the fleet to run it.

Four modes, one per step of the canned path. `bump` raises the version in the
Bluefile's `package(...)` line and regenerates what the Bluefile renders.
`tag` commits that change, writes an annotated `v<version>` tag, and pushes
both at once, rebasing and retrying when the branch moved. `request-deploy`
sends a `repository_dispatch` (`flake-input-update`) to the consumer repository.
`flake-bump` runs in the consumer: it updates the named flake inputs, builds
the verify installables, commits, and pushes; when the branch moved it starts
again from the new head, so a concurrent push is retried, never reported as
rejected.

Every function that decides something is pure and tested here; each command
is built by a function, so its argv is tested too.
"""

use("koutei", %i[fail input input_or output summary])
use("retsu", %i[first last rest])
use("shisutemu", %i[status_of stderr_of stdout_of])

@doc """
must: run a command, fail the step when it exits non-zero, else its stdout.
"""
def must(what, cmd, *args)
  r = exec_capture(cmd, *args)
  if status_of(r) != 0
    write_stderr(stderr_of(r))
    fail("#{what}: #{cmd} exited #{to_s(status_of(r))}")
  end
  stdout_of(r)
end

@doc """
required: input `name`, or fail the step naming the mode that needs it.
"""
def required(name)
  v = input(name)
  if v.nil?
    fail("input #{name} is required in mode #{input("mode")}")
  end
  v
end

@doc """
words: the names in a space- or newline-separated list.

    words(" a  b c ") #=> ["a", "b", "c"]
"""
def words(text)
  if text.nil?
    []
  else
    filter((w) -> w != "", split(replace(text, line_break, " "), " "))
  end
end

@doc """
digits?: whether a text is one or more decimal digits.

    digits?("012") #=> true
"""
def digits?(text)
  text != "" and every?((c) -> member?(c, %w[0 1 2 3 4 5 6 7 8 9]), chars(text))
end

@doc """
parse_version: `major.minor.patch` as three integers, or nil.

    parse_version("1.2.3") #=> [1, 2, 3]
"""
def parse_version(text)
  parts = split(text, ".")
  if length(parts) == 3 and every?(digits?, parts)
    map(to_int, parts)
  end
end

@doc """
version_text: three integers written as `major.minor.patch`.

    version_text([1, 2, 3]) #=> "1.2.3"
"""
def version_text(v)
  join(map(to_s, v), ".")
end

@doc """
bumped: the next version for a part: major, minor or patch; nil for any other.

    bumped([1, 2, 3], "minor") #=> [1, 3, 0]
"""
def bumped(v, part)
  if part == "major"
    [first(v) + 1, 0, 0]
  elsif part == "minor"
    [first(v), second(v) + 1, 0]
  elsif part == "patch"
    [first(v), second(v), third(v) + 1]
  end
end

@doc """
newer?: whether version `a` is greater than version `b`.

    newer?([1, 10, 0], [1, 9, 9]) #=> true
"""
def newer?(a, b)
  if a == []
    false
  elsif first(a) > first(b)
    true
  elsif first(a) < first(b)
    false
  else
    newer?(rest(a), rest(b))
  end
end

@doc """
tag_name: the release tag of a version text.

    tag_name("1.2.3") #=> "v1.2.3"
"""
def tag_name(version)
  "v#{version}"
end

@doc """
tag_version: the version a `vX.Y.Z` tag names, or nil for any other tag.

    tag_version("v0.1.0") #=> [0, 1, 0]
"""
def tag_version(tag)
  if starts_with?(tag, "v")
    parse_version(join(drop(1, chars(tag)), ""))
  end
end

@doc """
highest: the greatest version among release tags, or nil when there is none.

    highest(["v0.2.0", "latest", "v0.10.0"]) #=> [0, 10, 0]
"""
def highest(tags)
  versions = filter((v) -> not v.nil?, map(tag_version, tags))
  pick_highest(versions, nil)
end

def pick_highest(versions, best)
  if versions == []
    best
  elsif best.nil? or newer?(first(versions), best)
    pick_highest(rest(versions), first(versions))
  else
    pick_highest(rest(versions), best)
  end
end

@doc """
tag_refusal: why `tag` may not be written beside `existing` tags, or nil when
it may: it must be a release tag, new, and greater than the highest.

    tag_refusal("v0.2.0", ["v0.1.0"]) #=> nil
"""
def tag_refusal(tag, existing)
  v = tag_version(tag)
  top = highest(existing)
  if v.nil?
    "#{tag} is not a vMAJOR.MINOR.PATCH tag"
  elsif member?(tag, existing)
    "#{tag} exists"
  elsif not top.nil? and not newer?(v, top)
    "#{tag} is not greater than v#{version_text(top)}"
  end
end

@doc """
released?: whether one of the tags on HEAD is a release tag, which makes this
run the one its own release commit started.

    released?(["v0.1.1"]) #=> true
"""
def released?(head_tags)
  any?((t) -> not tag_version(t).nil?, head_tags)
end

@doc """
superseded?: whether the branch head is not the commit this run was started
for, so a later run releases it; nil `expected` checks nothing.

    superseded?("b", "a") #=> true
"""
def superseded?(head, expected)
  not expected.nil? and head != expected
end

@doc """
package_line?: whether a Bluefile line is the `package(...)` declaration.

    package_line?("  package(") #=> true
"""
def package_line?(line)
  starts_with?(trim(line), "package(")
end

@doc """
package_of: the name and version of a Bluefile's `package(...)` line, or nil.

    package_of(package_line("rubrica", "0.1.0")) #=> {name: "rubrica", version: "0.1.0"}
"""
def package_of(text)
  lines = filter(package_line?, split(text, line_break))
  if lines == []
    nil
  else
    parts = split(first(lines), "\"")
    if length(parts) == 5
      {name: parts[1], version: parts[3]}
    end
  end
end

@doc """
package_line: the `package(...)` declaration blue writes.

    package_of(package_line("rubrica", "0.1.1"))[:version] #=> "0.1.1"
"""
def package_line(name, version)
  "package(\"#{name}\", \"#{version}\")"
end

@doc """
with_version: a Bluefile with its package version replaced and every other
line kept as it was.
"""
def with_version(text, version)
  pkg = package_of(text)
  join(
    map(
      fn(l)
        if package_line?(l)
          package_line(pkg[:name], version)
        else
          l
        end
      end,
      split(text, line_break)
    ),
    line_break
  )
end

@doc """
release_message: the subject of a release commit.

    release_message("rubrica", "0.1.1") #=> "Release rubrica 0.1.1."
"""
def release_message(name, version)
  "Release #{name} #{version}."
end

@doc """
short_rev: the first twelve characters of a revision.

    short_rev("0123456789abcdef") #=> "0123456789ab"
"""
def short_rev(rev)
  join(take(12, chars(rev)), "")
end

@doc """
and_list: names joined the way a sentence lists them.

    and_list(["a", "b", "c"]) #=> "a, b and c"
"""
def and_list(items)
  if length(items) <= 1
    join(items, "")
  else
    "#{join(butlast(items), ", ")} and #{last(items)}"
  end
end

@doc """
bump_message: the subject of a flake lock commit, naming each input and the
revision it now locks.

    bump_message([["rubrica", "0123456789abcdef"]]) #=> "Bump rubrica to 0123456789ab in flake.lock."
"""
def bump_message(revs)
  named = map((p) -> "#{first(p)} to #{short_rev(second(p))}", revs)
  "Bump #{and_list(named)} in flake.lock."
end

@doc """
locked_rev: the revision a flake lock pins for a root input, or nil. The root
names each input's node, which can differ from the input name.
"""
def locked_rev(lock, name)
  node = dig(lock, "nodes", dig(lock, "root"), "inputs", name)
  if not string?(node)
    nil
  else
    dig(lock, "nodes", node, "locked", "rev")
  end
end

@doc """
update_argv: the command that updates the named flake inputs.

    update_argv(["rubrica"]) #=> ["nix", "flake", "update", "rubrica"]
"""
def update_argv(names)
  append(%w[nix flake update], names)
end

@doc """
verify_argv: the command that builds one verify installable.

    verify_argv(".#checks.x86_64-linux.promotion-gate") #=> ["nix", "build", "--no-link", ".#checks.x86_64-linux.promotion-gate"]
"""
def verify_argv(installable)
  ["nix", "build", "--no-link", installable]
end

@doc """
commit_argv: a commit of the staged change, by the named committer.
"""
def commit_argv(committer, message)
  [
    "git",
    "-c",
    "user.name=#{committer[:name]}",
    "-c",
    "user.email=#{committer[:email]}",
    "commit",
    "--quiet",
    "--message",
    message
  ]
end

@doc """
tag_argv: an annotated tag on HEAD, by the named tagger.
"""
def tag_argv(committer, tag, message)
  [
    "git",
    "-c",
    "user.name=#{committer[:name]}",
    "-c",
    "user.email=#{committer[:email]}",
    "tag",
    "--annotate",
    tag,
    "--message",
    message
  ]
end

@doc """
push_argv: one atomic push of HEAD to a branch and, when given, a tag.

    push_argv("main", nil) #=> ["git", "push", "--quiet", "--atomic", "origin", "HEAD:refs/heads/main"]
"""
def push_argv(branch, tag)
  base = [
    "git",
    "push",
    "--quiet",
    "--atomic",
    "origin",
    "HEAD:refs/heads/#{branch}"
  ]
  if tag.nil?
    base
  else
    append(base, ["refs/tags/#{tag}"])
  end
end

@doc """
committer: who the release and lock commits are written by.
"""
def committer(role)
  {name: "pleme-io #{role}", email: "#{role}@users.noreply.github.com"}
end

@doc """
dispatch_url: the REST endpoint of a repository dispatch. It needs only
`contents: write`, which the fleet App grants; a workflow dispatch needs
`actions: write`, which the App does not hold (measured 2026-11-07: a mint
asking for it answers 422).

    dispatch_url("pleme-io/nix") #=> "https://api.github.com/repos/pleme-io/nix/dispatches"
"""
def dispatch_url(repository)
  "https://api.github.com/repos/#{repository}/dispatches"
end

@doc """
dispatch_body: the repository dispatch: its event type and the flake inputs
to bump.
"""
def dispatch_body(event, names)
  json_stringify(
    {event_type: event, client_payload: {inputs: join(names, " ")}}
  )
end

@doc """
curl_config: the token as a curl config line, given on stdin so it never
appears in an argv.

    contains?(curl_config("t"), "Bearer t") #=> true
"""
def curl_config(token)
  unlines(["header = \"Authorization: Bearer #{token}\""])
end

@doc """
dispatch_argv: the POST that sends the dispatch; it prints the HTTP status and
writes the response body to `body_file`.
"""
def dispatch_argv(url, body, body_file)
  [
    "curl",
    "--silent",
    "--show-error",
    "--config",
    "-",
    "--request",
    "POST",
    "--header",
    "Accept: application/vnd.github+json",
    "--header",
    "X-GitHub-Api-Version: 2022-11-28",
    "--output",
    body_file,
    "--write-out",
    "%{http_code}",
    "--data",
    body,
    url
  ]
end

@doc """
dispatched?: whether an HTTP status means GitHub accepted the dispatch.

    dispatched?("204") #=> true
"""
def dispatched?(code)
  member?(code, %w[200 204])
end

@doc """
handler: the mode a mode name runs, or nil for a name that is not a mode.

    handler("bump") #=> :bump
"""
def handler(mode)
  if mode == "bump"
    :bump
  elsif mode == "tag"
    :tag
  elsif mode == "request-deploy"
    :request_deploy
  elsif mode == "flake-bump"
    :flake_bump
  end
end

def head_tags()
  filter(
    (l) -> l != "",
    map(
      trim,
      split(
        must("listing HEAD's tags", "git", "tag", "--points-at", "HEAD"),
        line_break
      )
    )
  )
end

def all_tags()
  filter(
    (l) -> l != "",
    map(trim, split(must("listing tags", "git", "tag", "--list"), line_break))
  )
end

def fetch_tags()
  must(
    "fetching tags",
    "git",
    "fetch",
    "--quiet",
    "--tags",
    "--force",
    "origin"
  )
end

def bluefile()
  input_or("bluefile", "Bluefile")
end

def read_package()
  pkg = package_of(read_file(bluefile))
  if pkg.nil?
    fail("#{bluefile} has no package(\"name\", \"version\") line")
  end
  pkg
end

def mode_bump()
  fetch_tags
  head = trim(must("reading HEAD", "git", "rev-parse", "HEAD"))
  if superseded?(head, input("expect-head"))
    output("released", "false")
    summary(
      "the branch moved past #{input("expect-head")}; its own run releases #{head}"
    )
  elsif released?(head_tags)
    output("released", "false")
    summary("HEAD is already a release; nothing to bump")
  else
    pkg = read_package
    current = parse_version(pkg[:version])
    if current.nil?
      fail("#{pkg[:name]}'s version #{pkg[:version]} is not MAJOR.MINOR.PATCH")
    end
    part = input_or("bump", "patch")
    next_version = bumped(current, part)
    if next_version.nil?
      fail("bump is major, minor or patch (got #{part})")
    end
    version = version_text(next_version)
    write_file(bluefile, with_version(read_file(bluefile), version))
    if input_or("lock", "true") == "true"
      must("locking the Bluefile", "blue", "lock", ".")
    end
    regen = input("regen")
    if not regen.nil?
      must("regenerating #{regen}", "nix", "run", regen)
    end
    output("released", "true")
    output("name", pkg[:name])
    output("version", version)
    output("tag", tag_name(version))
    summary("#{pkg[:name]} #{pkg[:version]} → #{version}")
  end
end

def publish_release(branch, name, version, attempt)
  tag = tag_name(version)
  fetch_tags
  refusal = tag_refusal(tag, all_tags)
  if not refusal.nil?
    fail("not tagging: #{refusal}")
  end
  who = committer("release")
  must("tagging #{tag}", *tag_argv(who, tag, "#{name} #{version}"))
  pushed = exec_capture(*push_argv(branch, tag))
  if status_of(pushed) == 0
    tag
  elsif attempt >= 4
    write_stderr(stderr_of(pushed))
    fail("pushing #{tag} failed #{to_s(attempt)} times")
  else
    must("dropping the local tag", "git", "tag", "--delete", tag)
    must(
      "rebasing on #{branch}",
      "git",
      "pull",
      "--quiet",
      "--rebase",
      "origin",
      branch
    )
    sleep_ms(1000 * attempt)
    publish_release(branch, name, version, attempt + 1)
  end
end

def mode_tag()
  pkg = read_package
  version = input_or("version", pkg[:version])
  branch = input_or("branch", "main")
  must("staging the release", "git", "add", "--all")
  if status_of(exec_capture("git", "diff", "--cached", "--quiet")) != 0
    must(
      "committing the release",
      *commit_argv(committer("release"), release_message(pkg[:name], version))
    )
  end
  tag = publish_release(branch, pkg[:name], version, 1)
  output("tag", tag)
  output("version", version)
  output("commit-sha", trim(must("reading HEAD", "git", "rev-parse", "HEAD")))
  summary("#{pkg[:name]} #{version} tagged #{tag} on #{branch}")
end

def mode_request_deploy()
  names = words(required("flake-input"))
  repository = input_or("consumer-repo", "pleme-io/nix")
  event = input_or("event", "flake-input-update")
  body_file = path_join(
    getenv("RUNNER_TEMP", "/tmp"),
    "dispatch-#{to_s(now_ms)}.json"
  )
  r = exec_with_stdin(
    curl_config(required("token")),
    *dispatch_argv(
      dispatch_url(repository),
      dispatch_body(event, names),
      body_file
    )
  )
  code = trim(stdout_of(r))
  output("status", code)
  if status_of(r) != 0 or not dispatched?(code)
    write_stderr(read_file(body_file) rescue "")
    write_stderr(stderr_of(r))
    output("dispatched", "false")
    fail("#{repository} refused the #{event} dispatch (HTTP #{code})")
  end
  output("dispatched", "true")
  summary("asked #{repository} to bump #{and_list(names)} (HTTP #{code})")
end

def first_failing(installables)
  if installables == []
    nil
  elsif exec_ok?(*verify_argv(first(installables)))
    first_failing(rest(installables))
  else
    first(installables)
  end
end

def bump_lock(names, verify, branch, attempt)
  must("updating #{and_list(names)}", *update_argv(names))
  if exec_ok?("git", "diff", "--quiet", "--", "flake.lock")
    output("changed", "false")
    output("reason", "unchanged")
    summary("flake.lock already locks the newest #{and_list(names)}")
  else
    failed = first_failing(verify)
    if not failed.nil?
      output("changed", "true")
      output("verified", "false")
      output("reason", "verify-failed")
      fail("#{failed} did not build against the new lock; nothing pushed")
    end
    lock = json_read(read_file("flake.lock"))
    message = bump_message(
      map((n) -> [n, locked_rev(lock, n) or "unknown"], names)
    )
    must("staging flake.lock", "git", "add", "flake.lock")
    must(
      "committing flake.lock",
      *commit_argv(committer("flake-bump"), message)
    )
    pushed = exec_capture(*push_argv(branch, nil))
    if status_of(pushed) == 0
      sha = trim(must("reading HEAD", "git", "rev-parse", "HEAD"))
      output("changed", "true")
      output("verified", "true")
      output("pushed", "true")
      output("commit-sha", sha)
      output("reason", "published")
      summary("#{message} (#{sha}, attempt #{to_s(attempt)})")
    elsif attempt >= 4
      write_stderr(stderr_of(pushed))
      output("pushed", "false")
      output("reason", "push-rejected")
      fail("pushing to #{branch} failed #{to_s(attempt)} times")
    else
      must("fetching #{branch}", "git", "fetch", "--quiet", "origin", branch)
      must(
        "starting again from #{branch}",
        "git",
        "reset",
        "--quiet",
        "--hard",
        "FETCH_HEAD"
      )
      sleep_ms(2000 * attempt)
      bump_lock(names, verify, branch, attempt + 1)
    end
  end
end

def mode_flake_bump()
  bump_lock(
    words(required("flake-inputs")),
    words(input("verify")),
    input_or("branch", "main"),
    1
  )
end

def main()
  mode = required("mode")
  h = handler(mode)
  if h == :bump
    mode_bump
  elsif h == :tag
    mode_tag
  elsif h == :request_deploy
    mode_request_deploy
  elsif h == :flake_bump
    mode_flake_bump
  else
    fail("mode is bump, tag, request-deploy or flake-bump (got #{mode})")
  end
end

test "every mode name routes to its mode, and any other name to none"
  assert handler("bump") == :bump
  assert handler("tag") == :tag
  assert handler("request-deploy") == :request_deploy
  assert handler("flake-bump") == :flake_bump
  assert handler("deploy").nil?
end

test "a version is three decimal parts and nothing else"
  assert parse_version("0.1.0") == [0, 1, 0]
  assert parse_version("10.20.30") == [10, 20, 30]
  assert parse_version("0.1").nil?
  assert parse_version("0.1.0-rc1").nil?
  assert parse_version("a.b.c").nil?
  assert parse_version("1..2").nil?
end

test "each bump part raises its part and zeroes the lower ones"
  assert bumped([1, 2, 3], "patch") == [1, 2, 4]
  assert bumped([1, 2, 3], "minor") == [1, 3, 0]
  assert bumped([1, 2, 3], "major") == [2, 0, 0]
  assert bumped([1, 2, 3], "huge").nil?
  assert version_text(bumped([0, 1, 9], "patch")) == "0.1.10"
end

test "versions order by number, not by text"
  assert newer?([0, 10, 0], [0, 9, 0]) == true
  assert newer?([0, 9, 0], [0, 10, 0]) == false
  assert newer?([1, 0, 0], [1, 0, 0]) == false
  assert newer?([2, 0, 0], [1, 99, 99]) == true
end

test "the highest release tag ignores tags that are not releases"
  assert highest(%w[v0.2.0 latest v0.10.0 v0.9.9]) == [0, 10, 0]
  assert highest(%w[latest nightly]).nil?
  assert highest([]).nil?
end

test "a tag is refused when it exists, is not greater, or is not a release tag"
  assert tag_refusal("v0.1.1", ["v0.1.0"]).nil?
  assert tag_refusal("v0.1.0", []).nil?
  assert tag_refusal("v0.1.0", ["v0.1.0"]) == "v0.1.0 exists"
  assert tag_refusal("v0.1.0", ["v0.2.0"]) ==
    "v0.1.0 is not greater than v0.2.0"
  assert tag_refusal("0.1.0", []) == "0.1.0 is not a vMAJOR.MINOR.PATCH tag"
end

test "a run started by a release commit sees its own tag and releases nothing"
  assert released?(["v0.1.1"]) == true
  assert released?(["latest"]) == false
  assert released?([]) == false
end

test "only the run for the branch head releases"
  assert superseded?("b", "a") == true
  assert superseded?("a", "a") == false
  assert superseded?("a", nil) == false
end

test "the Bluefile version is rewritten and every other line kept"
  before = unlines(["package(\"rubrica\", \"0.1.0\")", "", "tool(\"qpdf\")"])
  after = unlines(["package(\"rubrica\", \"0.1.1\")", "", "tool(\"qpdf\")"])
  assert package_of(before) == {name: "rubrica", version: "0.1.0"}
  assert with_version(before, "0.1.1") == after
  assert package_of(unlines(["tool(\"qpdf\")"])).nil?
end

test "the commit subjects are sentences naming what moved"
  assert release_message("rubrica", "0.1.1") == "Release rubrica 0.1.1."
  assert bump_message([%w[rubrica 0123456789abcdef0123]]) ==
    "Bump rubrica to 0123456789ab in flake.lock."
  assert bump_message([%w[a 111111111111111], %w[b 222222222222222]]) ==
    "Bump a to 111111111111 and b to 222222222222 in flake.lock."
  assert and_list(%w[a b c]) == "a, b and c"
end

test "the locked revision is read through the root's node name"
  lock = json_read("{\"root\":\"root\",\"nodes\":{\"root\":{\"inputs\":{\"rubrica\":\"rubrica_2\",\"x\":[\"a\",\"b\"]}},\"rubrica_2\":{\"locked\":{\"rev\":\"abc\"}}}}")
  assert locked_rev(lock, "rubrica") == "abc"
  assert locked_rev(lock, "x").nil?
  assert locked_rev(lock, "absent").nil?
end

test "the flake commands update only the named inputs and build each verify"
  assert update_argv(["rubrica"]) == %w[nix flake update rubrica]
  assert update_argv(words("a  b")) == %w[nix flake update a b]
  assert verify_argv(".#checks.x86_64-linux.promotion-gate") ==
    ["nix", "build", "--no-link", ".#checks.x86_64-linux.promotion-gate"]
end

test "git commands carry the committer and push branch and tag atomically"
  who = committer("release")
  assert who ==
    {name: "pleme-io release", email: "release@users.noreply.github.com"}
  assert take(5, commit_argv(who, "m")) ==
    [
      "git",
      "-c",
      "user.name=pleme-io release",
      "-c",
      "user.email=release@users.noreply.github.com"
    ]
  assert drop(5, tag_argv(who, "v0.1.1", "rubrica 0.1.1")) ==
    ["tag", "--annotate", "v0.1.1", "--message", "rubrica 0.1.1"]
  assert push_argv("main", "v0.1.1") ==
    %w[git push --quiet --atomic origin HEAD:refs/heads/main refs/tags/v0.1.1]
  assert push_argv("main", nil) ==
    %w[git push --quiet --atomic origin HEAD:refs/heads/main]
end

test "the dispatch is a repository dispatch naming the inputs, and keeps the token out of the argv"
  url = dispatch_url("pleme-io/nix")
  body = dispatch_body("flake-input-update", ["rubrica"])
  argv = dispatch_argv(url, body, "/tmp/b")
  assert url == "https://api.github.com/repos/pleme-io/nix/dispatches"
  assert json_read(body) ==
    json_read("{\"event_type\":\"flake-input-update\",\"client_payload\":{\"inputs\":\"rubrica\"}}")
  assert last(argv) == url
  assert not any?((a) -> contains?(a, "Bearer"), argv)
  assert curl_config("t") == unlines(["header = \"Authorization: Bearer t\""])
  assert dispatched?("204") == true
  assert dispatched?("200") == true
  assert dispatched?("403") == false
  assert dispatched?("") == false
end

test "a list of names is read from spaces and lines"
  assert words(" a  b") == %w[a b]
  assert words(unlines(%w[a b])) == %w[a b]
  assert words("") == []
  assert words(nil) == []
end
