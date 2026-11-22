---
paths:
  - "**/*.kai"
---

# Writing kaikai

km2 is written in kaikai and should read like an example of the language
used well, not like Rust transcribed from Kimün.

## `kai info` is authoritative

Before writing a kaikai snippet, run `kai info syntax` and the relevant
topic (`kai info idiomatic`, `kai info effects`, `kai info match`,
`kai info pipes`, `kai info ffi`, ...). `kai info syntax` lists the forms
kaikai has and, under **NOT IN KAIKAI**, the plausible false friends it
does not (`\x -> body`, `do { }`, `return`, `throw/catch`, ...).
`kai info idiomatic` pairs each idiom with the wrong reach. Do not
extrapolate from Rust, Haskell, Elixir or Python, and do not port Kimün's
Rust line by line.

`kai doc <module>.<symbol>` is cheaper than a topic page when the question
is one signature. When in doubt between two forms, write both and let the
compiler decide.

## Kaikai 0.196.3

The pinned version is in `.kaikai-version`. Breaking changes since 0.193
that older examples (and older repos) do not reflect:

- A partial handler inside a lambda, or in a `test`, `bench`, `check` or
  `const` body, is a compile error, as it already was in a `fn` body
  (0.193). Since 0.195, a handler that omits an op inherits it when the
  effect's default gives a clause for it.
- Reading or building a `priv` field of another module in a lambda, a
  `const` or a `test` body is an error, and so is spawning, in a `test`
  body, a thunk that captures per-fiber state or runs an effect nothing
  resolves (0.194).
- An effect performed in a dispatching-pipe stage appears in the enclosing
  row and must be handled or declared (0.196).

## Reuse the stdlib and the ecosystem before writing helpers

- Stdlib: `fs/dir` (walking), `fs/file`, `os/args`, `os/process`
  (running `git`), `encoding/json`, `encoding/toml` (`.kimun.toml`),
  `regexp`, `collections`, `string_builder`, `actor` (`with_mailbox`).
- **ahu** for concurrency: `ahu.cell` (`with_cell`, `ask`, `keep`,
  `cell_done`) for workers, `ahu.restart` (`with_restart`,
  `restartable_cell`) for fault tolerance, `ahu.log` for structured
  logging, `ahu.app.run_app` for the bootstrap, `ahu.cli` for the command
  line (declared commands and options; `cli.resolve` is pure and is what
  tests use). Do not hand-roll an argument parser, a message loop or a
  supervisor.
- **henua** for the domain: `domain_event` and `event_bus` carry
  per-file results to reports, `aggregate.fold_events` folds them; the
  `Repository[a, i]` effect (`find`, `save`, `delete`, `size`, `all`)
  with `repository_effect.with_in_memory` holds measured files behind a
  port; `validation` turns configuration values into `Result`s.
  **No SQL**: do not import `henua.sqlite_repository` or kohau.
  henua's `kai.toml` names kohau, so `kai fetch` brings it in; km2's
  code never imports it.

If something is missing or broken in any of them, open an issue upstream
with a repro instead of working around it silently here.

## The four guarantees

kaikai offers four ways to state that code is right, and they are not
redundant: each catches a class of bug the others miss (book ch. 11.6).
A module that deserves trust uses all four:

| Mechanism | States | Checked |
|---|---|---|
| **Types**: sum types, exhaustive `match` | every case of a value is covered | compile time |
| **Contracts**: `requires` / `ensures`, `T where P` | what an operation demands and promises | compile time when provable, runtime otherwise |
| **`test`** | for *this* input, the output is *that* | `kai test` |
| **`check`** | for *every* input, this invariant holds | `kai check`, with generated values and shrinking |

Write them in that order of discovery: a `test` for the case at hand,
more `test`s for the edges, a `check` once several tests are visibly the
same invariant with different data, a `bench` only when speed is in
question. A `check` written before the invariant is understood passes by
accident and proves nothing.

Properties that belong in km2: a flattened tree has one root and every
other node has exactly one parent; byte ranges nest; a metric is the same
however files are split across workers; every JSON report decodes back
into the shape it was encoded from.

### Contracts are for our own invariants, never for a user's input

`requires i >= 0 and i < count(doc)` on a node accessor states what this
code guarantees; a violation is a bug here, and a panic with the value is
the right outcome. Anything read from a user's project (source files,
`.kimun.toml`, git output) is input, validated into a `Result` whose error
names the file and the reason. A contract there turns someone's odd file
into a crash, which is the opposite of what a metrics tool should do.

## Effects are the architecture

Side effects (files, processes, clock, FFI) enter through effect rows so
the metrics can be tested with **handlers**, not with real files. Logic
that decides *what* to measure stays free of `File`, `Process` and `Ffi`;
only the edges perform them. Metrics take a parsed tree and return values.

### A handler is how effectful code is tested

There is no mocking in kaikai and none is needed: the nearest
`handle ... with` wins over an effect's default, including for the
builtins (book ch. 12.4, 12.11). A fake file system is a handler that
answers `read` from a list.

**A handler reaches its own fiber, and no further.** A fiber does not
inherit its parent's handlers, and a capability cannot be carried into a
`spawn` (§12.9). A fake installed around a parallel walk covers what the
walk does itself, not what its workers do.

### A resource that must be released belongs in a bracket

`initially { }` / `finally { }` on a handler run on **every** path out of
the scope: normal return, an outer handler that abandons `resume`, and
cancellation. Cleanup written after a `handle` block runs on none of
those (book ch. 12.8). Every tree-sitter handle (`Doc`, `Query`,
`Matches`) is acquired in `initially` and freed in `finally`, never by a
line at the end of a function. `finally` does not run on `panic`.

## Idioms worth following

- **Everything is an expression.** `if` and `match` return values; a
  function body is an expression. Bind the result, do not declare a name
  and assign into it from branches.
- **`=` for a direct function, `{ }` for several steps.**
- **Iterate with pipes or tail recursion, not `while`.** A loop that
  carries state is a tail-recursive function whose accumulators are its
  parameters (`fn scan(line, i, n, acc) = if i >= n { acc } else {
  scan(line, i + 1, n, ...) }`); a pass over a collection is a pipe or a
  fold. A recursive call that is not in tail position (`1 + f(i + 1)`)
  takes an accumulator instead. `var` is sugar over `State` and stays for
  a local accumulation inside a pipe stage, not as a loop counter.
  Mutual tail calls are eliminated too.
- **Positional tuples `(a, b)`**, not `Pair { fst:, snd: }`. Do not
  avoid tuples, records or variants for speed: a cost kaikai charges for
  them is a kaikai issue (see `perf.md`).
- **The core stdlib is auto-loaded**: no `import core.*`.
- **`!` propagates** `None`/`Err` through the return type. It never
  raises; it is Rust's `?`.
- **Pipes**: `|>` applies, `|` maps, `||` flat-maps, `|?` filters, `|!`
  iterates for effect. The map pipe is not for `Option` or `Result`: use
  a `match` or `|> option.map(f)`. A dropped value is dropped on purpose:
  `|> ignore` or `let _ =`.
- **Point-free sections** for projections: `files | .path`, not
  `f => f.path`.
- **`??` is the default of an `Option`**, and it binds tighter than the
  pipes: write `(get(v, "id") || as_int) ?? 0`. A `Result` takes a
  default through `ok(r) ?? d`, so the place an error is dropped stays
  visible. Never `unwrap_or_else(... panic ...)`.
- **`Map`/`Set` when the result is compared, printed or serialised**
  (AVL, key order, deterministic JSON); `HashMap`/`HashSet` for hot
  lookups whose order nothing depends on. Reports must be deterministic.
- **Spread to prepend**: `[h, ...t]`, not `[h] ++ t`.
- **No UFCS.** kaikai has no method form `x.f(a)`: write `x |> f(a)` and
  chain with more pipes. Field access (`r.field`) and projections
  (`| .field`) are not UFCS and stay. Three things the method form hid:
  - `|>` resolves `f` by name, not by the receiver's type. Where an
    import brings its own `map`, `filter` or `get`, qualify the call:
    `o |> option.map(f)`, `r |> result.map_err(g)`.
  - `|>` binds looser than operators and is not a postfix, so a pipe
    inside an operator, a condition or an interpolation is
    parenthesised: `n + (o |> unwrap_or(0))`.
  - A section that calls (`.unwrap_or([])`, `.length()`) is the method
    form too: write a lambda or a plain call instead.
- **`#[doc]` on every `pub` symbol**, first line a one-sentence synopsis.

## Code-quality bar

Measured with `km` from the first commit, and with `km2` as each command
exists (`tools/quality-gate.sh`):

- Every file scores **A− or better; B is the hard floor.**
- < 400 LOC target, < 800 hard cap. Split before growing.
- Cognitive complexity: average < 5 per function, max < 25.
- No new duplicate groups.
- `kai fmt --check` and `kai lint` clean.

## Traps

Each of these cost a debugging session in kalku and was rechecked
against 0.196.3; none is in `kai info`.

- **Constructor names collide across modules**, and the collision is a
  *runtime* panic (`ambiguous constructor 'X'`), not a compile error.
  Prefix constructors that live in widely imported modules.
- **`#[derive(Eq, Show)]` fails on a record holding a type without those
  impls** (`Instant`, `JsonValue`). Drop the derive or keep the field out.
- **A clause-block needs one pattern per parameter**: a two-parameter
  function is `case Ready(m), caps ->`, never `case Ready(m) ->`.
- **`when` is a reserved word**; a binder named `when` fails to parse.
- **A lambda's body ends at the first top-level pipe**:
  `x => xs | (l => f(x, l))` is `(x => xs) | (l => ...)`. Parenthesise a
  body that holds a pipe: `x => (xs | (l => f(x, l)))`.
- **`length(s)` on a `String` counts bytes**, not codepoints
  (`length("ñ")` is 2). tree-sitter's ranges are bytes too, which is what
  km2 wants; columns shown to a user are not.
- **`argv()` (from `os.args`) excludes the program name**, and `kai run
  file.kai -- x` passes the `--` through: the arguments are `[--, x]`.
- **An effect row cannot be wrapped onto the next line** in a signature.
- **A lambda that assigns needs a block**: `i => { total := total + i }`.
- **A one-variant sum needs the leading bar**: `type Msg = | Ping`, or
  the name is an alias and not a constructor.
- **`??` cannot be a `|>` stage**: `r |> ok ?? 0` is rejected; write
  `ok(r) ?? 0` or `(r |> ok) ?? 0`.
- **`Actor[msg]` has no default handler at `main`**: code that talks to
  an ahu cell runs inside
  `with_mailbox(() => ...)` (`import actor.{with_mailbox}`).
- **`map.update(m, k, default, f)` inserts `default` as is** when `k` is
  absent; `f` runs only on a present key. To accumulate, write
  `map.put(m, k, add(map.get(m, k) ?? zero, x))`.
- **`Mutable` is not masked across calls**: a function that writes an
  `Array` it was handed carries `/ Mutable`, and so does every caller up
  to `main`, which has a default handler for it.
- **`Stderr`'s op is `eprint`**, not `print`: `Stderr.eprint(msg)`.
- **`const` names are `UPPER_SNAKE_CASE`**; `kai fmt` rejects anything
  else.
- **`main` returns the exit code**: `fn main() : Int / ...`. Prefer it to
  `process.exit`, which calls `_exit` and drops unflushed output.
- **A `String` is not a collection the map pipe walks**:
  `chars(s) | f |> from_chars`.
- Names that read as false friends: `enumerate`/`uniq`/`foldl`, not
  `range`/`unique`/`fold`; `repeat` is both `string.repeat` and
  `list.repeat`.

## Comments

- If the code is clear, no comment.
- Brief and timeless: no issue numbers, dates, or phase names.
- Document invariants and traps, not narrative.
