use("koutei", %i[fail input input_or output summary])
use("shisutemu", %i[status_of stderr_of stdout_of])

def must(what, cmd, *args)
  r = exec_capture(cmd, *args)
  if status_of(r) != 0
    write_stderr(stderr_of(r))
    fail("#{what}: #{cmd} exited #{to_s(status_of(r))}")
  end
  stdout_of(r)
end

def required(name)
  v = input(name)
  if v.nil?
    fail("input #{name} is required in mode #{input("mode")}")
  end
  v
end

def last_line(text)
  lines = filter((l) -> trim(l) != "", split(text, line_break))
  trim(lines[length(lines) - 1])
end

def nar_hash_of(info, path)
  if list?(info)
    hits = filter((e) -> e["path"] == path, info)
    if hits == []
      nil
    else
      hits[0]["narHash"]
    end
  else
    entry = get(info, path)
    if entry.nil?
      nil
    else
      entry["narHash"]
    end
  end
end

def installable(flake, attr)
  "#{flake}##{attr}"
end

def build_closure(flake, system, attr)
  path = last_line(
    must(
      "building the closure",
      "nix",
      "build",
      "--no-link",
      "--print-out-paths",
      installable(flake, attr)
    )
  )
  info = json_read(
    must("reading the closure", "nix", "path-info", "--json", path)
  )
  nar = nar_hash_of(info, path)
  if nar.nil?
    fail("nix path-info printed no narHash for #{path}")
  end
  {system:, storePath: path, narHash: nar}
end

def this_system()
  trim(
    must(
      "reading the system",
      "nix",
      "eval",
      "--impure",
      "--raw",
      "--expr",
      "builtins.currentSystem"
    )
  )
end

def locked(flake)
  meta = json_read(
    must("locking #{flake}", "nix", "flake", "metadata", "--json", flake)
  )
  {path: meta["path"], url: meta["url"], rev: meta["locked"]["rev"]}
end

def values_text(store_path)
  json_stringify({image: {repository: "nix:#{store_path}", tag: ""}})
end

def tag_for(stamp)
  "v1.#{to_s(stamp)}.0"
end

def stage_dir(root, app, stage)
  path_join(path_join(root, app), stage)
end

def remote(repository)
  "https://github.com/#{repository}.git"
end

def auth_config(encoded)
  [
    %w[GIT_CONFIG_COUNT 1],
    %w[GIT_CONFIG_KEY_0 http.https://github.com/.extraheader],
    ["GIT_CONFIG_VALUE_0", "AUTHORIZATION: basic #{encoded}"]
  ]
end

def git_env()
  if input("remote").nil?
    r = exec_with_stdin("x-access-token:#{required("token")}", "base64")
    if status_of(r) != 0
      fail("encoding the token: base64 exited #{to_s(status_of(r))}")
    end
    auth_config(replace(trim(stdout_of(r)), line_break, ""))
  else
    []
  end
end

def git(what, dir, *args)
  r = exec_with_env(git_env, "git", "-C", dir, *args)
  if status_of(r) != 0
    write_stderr(stderr_of(r))
    fail("#{what}: git exited #{to_s(status_of(r))}")
  end
  stdout_of(r)
end

def try_git(dir, *args)
  exec_with_env(git_env, "git", "-C", dir, *args)
end

def delivery_remote()
  input("remote") or remote(required("repository"))
end

def checkout()
  parent = getenv("RUNNER_TEMP", "/tmp")
  name = "fleet-delivery-#{to_s(now_ms)}"
  git(
    "cloning the delivery repository",
    parent,
    "clone",
    "--quiet",
    delivery_remote,
    name
  )
  dir = path_join(parent, name)
  git(
    "naming the committer",
    dir,
    "config",
    "user.name",
    "pleme-io fleet delivery"
  )
  git(
    "naming the committer",
    dir,
    "config",
    "user.email",
    "fleet-delivery@users.noreply.github.com"
  )
  dir
end

def publish(dir, message, attempt)
  git("staging the record", dir, "add", "-A")
  if status_of(try_git(dir, "diff", "--cached", "--quiet")) == 0
    fail("the record did not change; nothing to deliver")
  end
  git("committing the record", dir, "commit", "--quiet", "-m", message)
  tag = tag_for(now)
  git("tagging the record", dir, "tag", tag)
  pushed = try_git(
    dir,
    "push",
    "--quiet",
    "--atomic",
    "origin",
    "HEAD:main",
    tag
  )
  if status_of(pushed) == 0
    tag
  elsif attempt >= 4
    write_stderr(stderr_of(pushed))
    fail("pushing the record failed #{to_s(attempt)} times")
  else
    try_git(dir, "tag", "-d", tag)
    try_git(dir, "reset", "--soft", "HEAD~1")
    git("stashing the record", dir, "stash", "--quiet")
    git(
      "rebasing on the delivery repository",
      dir,
      "pull",
      "--quiet",
      "--rebase",
      "origin",
      "main"
    )
    git("restoring the record", dir, "stash", "pop", "--quiet")
    sleep_ms(1000 * attempt)
    publish(dir, message, attempt + 1)
  end
end

def install_chart(source, chart_path, library, dest)
  rm_rf(dest)
  mkdir_p(path_dirname(dest))
  must("copying the chart", "cp", "-R", path_join(source, chart_path), dest)
  must("opening the chart", "chmod", "-R", "u+w", dest)
  rm_rf(path_join(dest, "charts"))
  rm_rf(path_join(dest, "Chart.lock"))
  mkdir_p(path_join(dest, "charts"))
  must(
    "vendoring pleme-lib",
    "cp",
    "-R",
    path_join(library, "charts/pleme-lib"),
    path_join(dest, "charts/pleme-lib")
  )
  must("opening the chart", "chmod", "-R", "u+w", dest)
end

def release_doc(app, stage, source, library, closure, promoted_from)
  doc = {
    app:,
    stage:,
    source: {flake: source[:url], rev: source[:rev]},
    library: {flake: library[:url], rev: library[:rev]},
    closure:,
    recordedAt: now_rfc3339
  }
  if promoted_from.nil?
    doc
  else
    assoc(doc, :promotedFrom, promoted_from)
  end
end

def write_record(dir, release, store_path)
  write_file(path_join(dir, "release.json"), json_stringify(release))
  write_file(path_join(dir, "values.yaml"), values_text(store_path))
  rm_rf(path_join(dir, "health.json"))
end

def mode_closure()
  closure = build_closure(required("flake"), this_system, required("attr"))
  sub = input("substituter")
  if not sub.nil?
    must(
      "reading the closure back from #{sub}",
      "nix",
      "path-info",
      "--store",
      sub,
      closure[:storePath]
    )
  end
  output("store-path", closure[:storePath])
  output("nar-hash", closure[:narHash])
  summary(
    "closure #{closure[:system]}: `#{closure[:storePath]}` #{closure[:narHash]}"
  )
end

def mode_record()
  app = required("app")
  stage = required("stage")
  source = locked(required("flake"))
  library = locked(input_or("library-flake", "github:pleme-io/helmworks"))
  closure = build_closure(required("flake"), this_system, required("attr"))
  repo = checkout
  dir = stage_dir(repo, app, stage)
  install_chart(
    source[:path],
    required("chart-path"),
    library[:path],
    path_join(dir, "chart")
  )
  write_record(
    dir,
    release_doc(app, stage, source, library, closure, nil),
    closure[:storePath]
  )
  tag = publish(
    dir,
    "#{app} #{stage}: #{source[:rev]} as #{closure[:storePath]}",
    1
  )
  output("store-path", closure[:storePath])
  output("nar-hash", closure[:narHash])
  output("tag", tag)
  summary("#{app} → #{stage}: `#{closure[:storePath]}` at #{tag}")
end

def pod_images(namespace)
  doc = json_read(
    must(
      "listing pods",
      "kubectl",
      "get",
      "pods",
      "--namespace",
      namespace,
      "--output",
      "json"
    )
  )
  map(
    fn(p)
      {
        images: map((c) -> c["image"], p["spec"]["containers"]),
        ready: any?(
          (c) -> c["type"] == "Ready" and c["status"] == "True",
          p["status"]["conditions"] or []
        )
      }
    end,
    doc["items"]
  )
end

def runs_closure?(pods, store_path)
  image = "nix:#{store_path}"
  hits = filter((p) -> member?(image, p[:images]), pods)
  hits != [] and every?((p) -> p[:ready], hits)
end

def answers?(url)
  url.nil? or
    exec_ok?(
      "curl",
      "--silent",
      "--fail",
      "--max-time",
      "10",
      "--output",
      "/dev/null",
      url
    )
end

def wait_healthy(namespace, store_path, url, deadline)
  pods = pod_images(namespace) rescue []
  if runs_closure?(pods, store_path) and answers?(url)
    true
  elsif now >= deadline
    false
  else
    sleep_ms(10000)
    wait_healthy(namespace, store_path, url, deadline)
  end
end

def mode_health()
  app = required("app")
  stage = required("stage")
  repo = checkout
  dir = stage_dir(repo, app, stage)
  release = json_read(read_file(path_join(dir, "release.json")))
  store_path = release["closure"]["storePath"]
  deadline = now + to_int(input_or("timeout-seconds", "900"))
  healthy = wait_healthy(
    required("namespace"),
    store_path,
    input("health-url"),
    deadline
  )
  write_file(
    path_join(dir, "health.json"),
    json_stringify(
      {
        storePath: store_path,
        rev: release["source"]["rev"],
        healthy:,
        checkedAt: now_rfc3339
      }
    )
  )
  tag = publish(
    dir,
    "#{app} #{stage}: #{store_path} healthy #{to_s(healthy)}",
    1
  )
  output("healthy", to_s(healthy))
  output("tag", tag)
  if not healthy
    fail("#{app} on #{stage} did not run #{store_path} healthy in time")
  end
end

def promotable?(release, health, rev)
  not health.nil? and
    health["healthy"] == true and
    health["storePath"] == release["closure"]["storePath"] and
    release["source"]["rev"] == rev
end

def mode_promote()
  app = required("app")
  from = required("from-stage")
  stage = required("stage")
  source = locked(required("flake"))
  repo = checkout
  earlier = stage_dir(repo, app, from)
  release = json_read(read_file(path_join(earlier, "release.json")))
  health = json_read(read_file(path_join(earlier, "health.json"))) rescue nil
  if not promotable?(release, health, source[:rev])
    fail(
      "#{app} #{source[:rev]} is not recorded healthy on #{from}; #{stage} keeps its release"
    )
  end
  closure = {
    system: required("system"),
    storePath: required("store-path"),
    narHash: required("nar-hash")
  }
  dir = stage_dir(repo, app, stage)
  rm_rf(path_join(dir, "chart"))
  mkdir_p(dir)
  must(
    "copying the chart",
    "cp",
    "-R",
    path_join(earlier, "chart"),
    path_join(dir, "chart")
  )
  library = {url: release["library"]["flake"], rev: release["library"]["rev"]}
  doc = release_doc(app, stage, source, library, closure, from)
  write_record(dir, doc, closure[:storePath])
  tag = publish(
    dir,
    "#{app} #{stage}: #{source[:rev]} from #{from} as #{closure[:storePath]}",
    1
  )
  output("tag", tag)
  summary(
    "#{app} → #{stage}: promoted from #{from}, `#{closure[:storePath]}` at #{tag}"
  )
end

def main()
  mode = required("mode")
  if mode == "closure"
    mode_closure
  elsif mode == "record"
    mode_record
  elsif mode == "health"
    mode_health
  elsif mode == "promote"
    mode_promote
  else
    fail("mode is closure, record, health or promote (got #{mode})")
  end
end

test "a narHash is read from either path-info shape"
  m = json_read("{\"/nix/store/a-k\":{\"narHash\":\"sha256-x\"}}")
  l = json_read("[{\"path\":\"/nix/store/a-k\",\"narHash\":\"sha256-y\"}]")
  assert nar_hash_of(m, "/nix/store/a-k") == "sha256-x"
  assert nar_hash_of(l, "/nix/store/a-k") == "sha256-y"
  assert nar_hash_of(m, "/nix/store/b-k").nil?
end

test "the values pin the image to the closure and nothing else"
  assert json_read(values_text("/nix/store/a-kensa")) ==
    json_read("{\"image\":{\"repository\":\"nix:/nix/store/a-kensa\",\"tag\":\"\"}}")
end

test "the token travels as a header, never in the remote"
  assert remote("pleme-io/fleet-delivery") ==
    "https://github.com/pleme-io/fleet-delivery.git"
  assert auth_config("eA==")[2] ==
    ["GIT_CONFIG_VALUE_0", "AUTHORIZATION: basic eA=="]
end

test "a tag is semver, so Flux's ref.semver orders deliveries"
  assert tag_for(1_761_650_000) == "v1.1761650000.0"
end

test "the last non-empty line is the out path"
  assert last_line(unlines(["warning: x", "/nix/store/a-k", ""])) ==
    "/nix/store/a-k"
end

test "a promotion needs the earlier stage healthy on the same closure and rev"
  r = json_read("{\"closure\":{\"storePath\":\"/nix/store/a\"},\"source\":{\"rev\":\"r1\"}}")
  ok = json_read("{\"healthy\":true,\"storePath\":\"/nix/store/a\"}")
  sick = json_read("{\"healthy\":false,\"storePath\":\"/nix/store/a\"}")
  other = json_read("{\"healthy\":true,\"storePath\":\"/nix/store/b\"}")
  assert promotable?(r, ok, "r1") == true
  assert promotable?(r, sick, "r1") == false
  assert promotable?(r, other, "r1") == false
  assert promotable?(r, ok, "r2") == false
  assert promotable?(r, nil, "r1") == false
end

test "a stage runs a closure only when every pod naming it is ready"
  ready = {images: ["nix:/nix/store/a"], ready: true}
  starting = {images: ["nix:/nix/store/a"], ready: false}
  old = {images: ["nix:/nix/store/b"], ready: true}
  assert runs_closure?([ready, old], "/nix/store/a") == true
  assert runs_closure?([ready, starting], "/nix/store/a") == false
  assert runs_closure?([old], "/nix/store/a") == false
end
