@moduledoc """
sui-cache-probe: one quick question before a job leans on the fleet sui
cache: does its origin answer as a nix cache right now? The answer is a typed
state, never a hang: `up`, `down`, `off`, `on` (used without a probe) or
`absent` (no cache on this runner). Pull and push are each decided from it,
and a cache that is down costs the job one bounded probe instead of a stalled
build step.
"""

use("kakehashi/tehai", %i[probe_substituter substituter])

use("koutei", %i[annotate input output present])

use("moji", [:trim])

@doc """
mode: a cache setting read as `:auto`, `:on` or `:off`; `true` reads as
auto and `false` as off, the words nix-setup took before; anything else is
nil, a value the action refuses.

    mode("auto") #=> :auto
    mode(" on ") #=> :on
    mode("false") #=> :off
    mode("true") #=> :auto
    mode("sometimes") #=> nil
"""
def mode(text)
  t = trim(text or "")
  if t == "auto" or t == "true"
    :auto
  elsif t == "on"
    :on
  elsif t == "off" or t == "false"
    :off
  end
end

@doc """
seconds: a probe bound in whole seconds, or nil when the text is not a
positive whole number.

    seconds("2") #=> 2
    seconds("0") #=> nil
    seconds("2s") #=> nil
"""
def seconds(text)
  n = to_int(trim(text or ""))
  if not n.nil? and n > 0
    n
  end
end

@doc """
setting: the first present value: the action input, then the workflow
environment variable, then the default.

    setting(nil, nil, "auto") #=> "auto"
    setting(nil, "off", "auto") #=> "off"
    setting("on", "off", "auto") #=> "on"
"""
def setting(given, env, fallback)
  present(given) or present(env) or fallback
end

@doc """
resolved: a setting parsed by `parse`, with the default and a refusal note
when the value given is not one the action takes. A bad value is refused
alone: the default stands for it, and every other setting is unaffected.

    resolved("cache", "auto", "auto", mode) #=> [:auto, nil]
    resolved("cache", "maybe", "auto", mode) #=> [:auto, "cache: maybe is not one of auto, on, off; auto applies"]
"""
def resolved(name, text, fallback, parse)
  v = parse(text)
  if v.nil?
    [
      parse(fallback),
      "#{name}: #{text} is not one of auto, on, off; #{fallback} applies"
    ]
  else
    [v, nil]
  end
end

@doc """
verdict: the cache state and what it allows, from the origin url, the cache
and cache-push modes and a probe result (nil when no probe ran). Pull follows
the state; push follows it in auto, always runs in on, never in off.

    verdict(nil, :auto, :auto, nil)[:state] #=> :absent
    verdict("u", :off, :auto, nil) #=> {state: :off, pull: false, push: false, reason: "cache is off"}
    verdict("u", :off, :on, nil)[:push] #=> true
    verdict("u", :on, :auto, nil) #=> {state: :on, pull: true, push: true, reason: "used without a probe"}
    verdict("u", :on, :off, nil)[:push] #=> false
    verdict("u", :auto, :auto, [true, "StoreDir: /nix/store"]) #=> {state: :up, pull: true, push: true, reason: "StoreDir: /nix/store"}
    verdict("u", :auto, :off, [true, "ok"])[:push] #=> false
    verdict("u", :auto, :auto, [false, "timed out"]) #=> {state: :down, pull: false, push: false, reason: "u did not answer: timed out"}
    verdict("u", :auto, :on, [false, "timed out"])[:push] #=> true
"""
def verdict(url, cache, push, probed)
  if url.nil?
    {
      state: :absent,
      pull: false,
      push: false,
      reason: "no fleet cache on this runner"
    }
  elsif cache == :off
    {state: :off, pull: false, push: push == :on, reason: "cache is off"}
  elsif cache == :on
    {state: :on, pull: true, push: push != :off, reason: "used without a probe"}
  elsif probed[0]
    {state: :up, pull: true, push: push != :off, reason: probed[1]}
  else
    {
      state: :down,
      pull: false,
      push: push == :on,
      reason: "#{url} did not answer: #{probed[1]}"
    }
  end
end

@doc """
needs_probe?: whether the decision waits on a probe: only an auto cache with
an origin to ask.

    needs_probe?("u", :auto) #=> true
    needs_probe?("u", :on) #=> false
    needs_probe?(nil, :auto) #=> false
"""
def needs_probe?(url, cache)
  not url.nil? and cache == :auto
end

@doc """
probe: [up?, detail] for the origin, held to `bound` seconds in all: curl's
connect bound is half of it and its whole-request bound all of it, so an
origin that accepts the connection and never answers is down when the bound
runs out, not when the job does.

    probe("http://127.0.0.1:1", 2, "")[0] #=> false
"""
def probe(url, bound, curl)
  probe_substituter(substituter(url), bound / 2.0, curl)
end

@doc """
word: a boolean as the text a step output carries.

    word(true) #=> "true"
    word(false) #=> "false"
"""
def word(b)
  if b
    "true"
  else
    "false"
  end
end

def main()
  url = setting(input("cache-url"), getenv("SUI_CACHE_URL"), nil)
  cache = resolved(
    "cache",
    setting(input("cache"), getenv("SUI_CACHE"), "auto"),
    "auto",
    mode
  )
  push = resolved(
    "cache-push",
    setting(input("cache-push"), getenv("SUI_CACHE_PUSH"), "auto"),
    "auto",
    mode
  )
  bound_text = setting(
    input("cache-probe-timeout"),
    getenv("SUI_CACHE_PROBE_TIMEOUT"),
    "2"
  )
  bound = seconds(bound_text) or 2
  refusals = filter((n) -> not n.nil?, [cache[1], push[1]])
  map((n) -> annotate("warning", n, [%w[title sui-cache-probe]]), refusals)
  if seconds(bound_text).nil?
    annotate(
      "warning",
      "cache-probe-timeout: #{bound_text} is not a whole number of seconds; 2 applies",
      [%w[title sui-cache-probe]]
    )
  end
  probed = if needs_probe?(url, cache[0])
    probe(url, bound, "curl")
  end
  v = verdict(url, cache[0], push[0], probed)
  if v[:state] == :down
    annotate(
      "notice",
      "sui cache down, skipped (no pull, no push): #{v[:reason]}",
      [%w[title sui-cache]]
    )
  end
  output("state", to_s(v[:state]))
  output("pull", word(v[:pull]))
  output("push", word(v[:push]))
  output("url", url or "")
  output("reason", v[:reason])
  output("probe-timeout", bound)
end

test "an origin that accepts and never answers is down within the probe bound"
  l = tcp_listen("127.0.0.1:0")
  url = "http://127.0.0.1:#{tcp_port(l)}"
  t0 = now_ms
  v = verdict(url, :auto, :auto, probe(url, 2, "curl"))
  assert v[:state] == :down
  assert v[:pull] == false
  assert v[:push] == false
  assert now_ms - t0 < 3500
end

test "an origin with nothing listening is down, and the push stays off"
  l = tcp_listen("127.0.0.1:0")
  port = tcp_port(l)
  tcp_close(l)
  v = verdict(
    "http://127.0.0.1:#{port}",
    :auto,
    :auto,
    probe("http://127.0.0.1:#{port}", 2, "curl")
  )
  assert v[:state] == :down
  assert v[:push] == false
end

test "cache auto asks the origin; cache on and cache off never do"
  assert needs_probe?("u", mode("auto")) == true
  assert needs_probe?("u", mode("on")) == false
  assert needs_probe?("u", mode("off")) == false
end

test "cache-push auto follows the probe"
  assert verdict("u", :auto, mode("auto"), [true, "ok"])[:push] == true
  assert verdict("u", :auto, mode("auto"), [false, "x"])[:push] == false
end

test "cache-push on pushes whatever the probe says, cache-push off never pushes"
  assert verdict("u", :auto, mode("on"), [false, "x"])[:push] == true
  assert verdict("u", :off, mode("on"), nil)[:push] == true
  assert verdict("u", :auto, mode("off"), [true, "ok"])[:push] == false
  assert verdict("u", :on, mode("off"), nil)[:push] == false
end

test "the input wins over the workflow environment, which wins over the default"
  assert setting(" ", "off", "auto") == "off"
  assert setting("on", "off", "auto") == "on"
  assert nth(
    0,
    resolved("cache-push", setting(nil, "sideways", "auto"), "auto", mode)
  ) == :auto
end
