"""crash-certain-reader.py — the STATIC s-expression reader behind tlisp-lint
Layer 6 (crash-certain forms).

WHY THIS EXISTS AT ALL, AND WHY IT IS NOT A TEXT SCAN
=====================================================
tatara-script defers both of the forms this reader finds to CALL time, so
neither is visible to any load-based check:

    (define (never-called) (let loop ((x 1)) x))

loads fine and exits 0. The error — `bad \\`let\\`: bindings must be a list` —
fires only when `never-called` is actually called. MEASURED 2026-07-30. So the
detection has to be STATIC, and it has to be structural: `grep '(let [a-z]* (('`
cannot tell a named let from a comment quoting one, and no regex at all can
count the arguments of a call whose args span lines and contain nested strings.

WHY PYTHON, HONESTLY
====================
The NO SHELL law names Rust + tatara-lisp + Nix + YAML. Python is none of them.
Two facts make it the right interim step and not a new precedent:
  * tlisp-lint ALREADY runs `python3` — Layer 1's paren/string balance scan is
    an inline `python3 -c` program, and has been since the linter shipped. This
    is the same primitive, moved out of a 20-line inline string so it can be
    read and tested.
  * The DESTINATION is not python. It is a rule in `tatara-lisp-lint`, which
    already has the real parser AND the `Arity` registry in one process — no
    reader to re-derive, no interpreter to probe. That crate is a different
    repo, so this pass, scoped to `pleme-io/actions`, lands the gate where it
    can run today. When the tatara-lisp-lint rule exists, DELETE this file and
    Layer 6 with it; `tatara-script lint` (Layer 3) is already wired.

Two modes, so the arity table can be derived from the LIVE INTERPRETER in
between them rather than hand-listed here:

  heads <listfile>
      Emit  NAMEDLET<TAB>path<TAB>line<TAB>form   (every named let/let*/letrec)
      Emit  HEAD<TAB>name                         (each distinct call head, once)

  arity <listfile> <aritytable>
      <aritytable> is  name<TAB>n  rows meaning "the interpreter rejects any
      count but n for this name". Emit
            ARITYVIOL<TAB>path<TAB>line<TAB>head<TAB>got<TAB>want
"""

import sys

LP, RP, AT, ST, QU = 0, 1, 2, 3, 4

BINDERS = ('let', 'let*', 'letrec')


def tokens(s):
    """Lex to (kind, text, line). Comments and string bodies are consumed here,
    which is what makes a commented-out named let invisible to the walker."""
    out = []
    i = 0
    line = 1
    n = len(s)
    while i < n:
        c = s[i]
        if c == '\n':
            line += 1
            i += 1
        elif c == ';':
            while i < n and s[i] != '\n':
                i += 1
        elif c in ' \t\r':
            i += 1
        elif c == '"':
            start = line
            i += 1
            while i < n:
                if s[i] == '\\':
                    i += 2
                    continue
                if s[i] == '"':
                    i += 1
                    break
                if s[i] == '\n':
                    line += 1
                i += 1
            out.append((ST, '', start))
        elif c == '(':
            out.append((LP, '', line))
            i += 1
        elif c == ')':
            out.append((RP, '', line))
            i += 1
        elif c in "'`,":
            out.append((QU, c, line))
            i += 1
        else:
            j = i
            while j < n and s[j] not in ' \t\r\n()";':
                j += 1
            out.append((AT, s[i:j], line))
            i = j
    return out


def parse(tks):
    """Tokens -> nodes. node = (kind, payload, line) with kind in
    atom | str | list | quote."""
    stack = [[]]
    opened = [(0, 0)]
    # A quote/quasiquote/unquote mark BINDS TO THE NEXT DATUM — it is not itself
    # a datum. Counting it as one inflated every `(equal? x 'sym)` to three
    # arguments and produced 50 false positives on this repo. MEASURED: the raw
    # count went 86 -> 20 when this was fixed.
    pending = [0]

    def emit(node):
        k = pending[0]
        pending[0] = 0
        while k > 0:
            node = ('quote', node, node[2])
            k -= 1
        stack[-1].append(node)

    for kind, val, line in tks:
        if kind == LP:
            stack.append([])
            opened.append((line, pending[0]))
            pending[0] = 0
        elif kind == RP:
            if len(stack) == 1:
                continue          # stray close; Layer 1 owns balance
            kids = stack.pop()
            ln, q = opened.pop()
            pending[0] = q
            emit(('list', kids, ln))
        elif kind == AT:
            emit(('atom', val, line))
        elif kind == ST:
            emit(('str', '', line))
        elif kind == QU:
            pending[0] += 1
    while len(stack) > 1:
        kids = stack.pop()
        ln, q = opened.pop()
        pending[0] = q
        emit(('list', kids, ln))
    return stack[0]


def walk(node, path, on_namedlet, on_call, on_define):
    """Walk a node that is in a VALUE position, i.e. a list here is a call.

    The special-form arms below are the whole false-positive defence: a binding
    list, a lambda parameter list and a `(define (f a b) …)` signature are all
    lists whose head is an identifier, and treating them as calls is how a lint
    like this cries wolf. `(define (filter x) …)` would otherwise report
    `filter` called with 1 argument against the primitive's Exact(2)."""
    if node[0] == 'quote' or node[0] != 'list':
        return
    kids = node[1]
    if not kids:
        return
    h = kids[0]
    hname = h[1] if h[0] == 'atom' else None

    if hname in BINDERS:
        # (let NAME ((v e)) body) — NAME is an atom where a bindings LIST must
        # be. tatara-script has no named let; this is a hard error when reached.
        if len(kids) >= 2 and kids[1][0] == 'atom':
            on_namedlet(path, node[2], hname)
            for k in kids[2:]:
                walk(k, path, on_namedlet, on_call, on_define)
            return
        if len(kids) >= 2 and kids[1][0] == 'list':
            for b in kids[1][1]:
                if b[0] == 'list':
                    for e in b[1][1:]:      # skip the bound NAME, walk its init
                        walk(e, path, on_namedlet, on_call, on_define)
        for k in kids[2:]:
            walk(k, path, on_namedlet, on_call, on_define)
        return

    if hname == 'define':
        if len(kids) >= 2:
            sig = kids[1]
            if sig[0] == 'atom':
                on_define(path, sig[1])
            elif sig[0] == 'list' and sig[1] and sig[1][0][0] == 'atom':
                on_define(path, sig[1][0][1])
        for k in kids[2:]:                  # signature is NOT a call
            walk(k, path, on_namedlet, on_call, on_define)
        return

    if hname in ('lambda', 'fn'):
        for k in kids[2:]:                  # parameter list is NOT a call
            walk(k, path, on_namedlet, on_call, on_define)
        return

    if hname == 'quote':
        return

    if hname == 'cond':
        for cl in kids[1:]:                 # each clause is data; its parts are calls
            if cl[0] == 'list':
                for e in cl[1]:
                    walk(e, path, on_namedlet, on_call, on_define)
            else:
                walk(cl, path, on_namedlet, on_call, on_define)
        return

    if hname == 'case':
        if len(kids) >= 2:
            walk(kids[1], path, on_namedlet, on_call, on_define)
        for cl in kids[2:]:                 # (datum...) head is data, not a call
            if cl[0] == 'list':
                for e in cl[1][1:]:
                    walk(e, path, on_namedlet, on_call, on_define)
        return

    if hname == 'catch':
        for k in kids[2:]:                  # (catch (e) body) — (e) is a binding
            walk(k, path, on_namedlet, on_call, on_define)
        return

    if hname is not None:
        on_call(path, node[2], hname, len(kids) - 1)
    for k in kids[1:]:
        walk(k, path, on_namedlet, on_call, on_define)


def read_list(p):
    return [l.strip() for l in open(p, encoding='utf-8') if l.strip()]


def main(argv):
    if len(argv) < 3:
        sys.stderr.write('usage: crash-certain-reader.py heads|arity <listfile> [aritytable]\n')
        return 2
    mode, listfile = argv[1], argv[2]
    paths = read_list(listfile)

    namedlets = []
    calls = []
    defines = {}
    heads = []
    seen_head = set()

    def on_namedlet(path, line, form):
        namedlets.append((path, line, form))

    def on_call(path, line, head, argc):
        calls.append((path, line, head, argc))
        if head not in seen_head:
            seen_head.add(head)
            heads.append(head)

    def on_define(path, name):
        defines.setdefault(path, set()).add(name)

    for p in paths:
        try:
            src = open(p, encoding='utf-8', errors='replace').read()
        except OSError:
            continue
        for top in parse(tokens(src)):
            walk(top, p, on_namedlet, on_call, on_define)

    rows = []
    if mode == 'heads':
        for path, line, form in namedlets:
            rows.append('NAMEDLET\t%s\t%d\t%s' % (path, line, form))
        for h in heads:
            rows.append('HEAD\t%s' % h)
    elif mode == 'arity':
        if len(argv) < 4:
            sys.stderr.write('arity mode needs an arity table\n')
            return 2
        want = {}
        for row in read_list(argv[3]):
            parts = row.split('\t')
            if len(parts) == 2 and parts[1].isdigit():
                want[parts[0]] = int(parts[1])
        for path, line, head, argc in calls:
            if head not in want or argc == want[head]:
                continue
            # A file that DEFINES the name shadows the interpreter's binding —
            # its own arity governs, and this rule knows nothing about it.
            # breathe-band-lint's own 2-arg `count` vs the stdlib's Exact(1)
            # closure is 7 of these; every one is a false positive. MEASURED.
            if head in defines.get(path, ()):
                continue
            rows.append('ARITYVIOL\t%s\t%d\t%s\t%d\t%d' % (path, line, head, argc, want[head]))
    else:
        sys.stderr.write('unknown mode %r\n' % mode)
        return 2

    if rows:
        print('\n'.join(rows))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
