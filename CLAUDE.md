# km2

Code metrics over syntax trees. km2 is the successor of `km` (Kimün, Rust, lexical analysis): it does everything `km` does, with the same interface, output and configuration, and measures better wherever a syntax tree allows. It is written in **kaikai** and parses through **tree-sitter**, vendored and reached through kaikai's C interop. `km2` is a working name; the repository is `kimun2`.

Kimün lives at `../kimun`; its `CLAUDE.md`, `README.md` and `src/cli.rs` are the reference for what each command does. The feasibility study for the `waste` rules is `../kimun/analisis-slop.md`.

## Project language

- Code, comments, commit messages, PR titles/bodies, and all documentation are **English only**, even when the briefing is in Spanish.
- `LEEME.md` is the one exception: the README in Spanish. A change to `README.md` carries the same change to `LEEME.md`.
- Conversation with the user (Spanish) is not documentation and does not appear in the repo.

## The shape of the system

| Piece | Role | Written in |
|---|---|---|
| **commands** | the CLI: the subcommands, flags and output formats of `km` | kaikai |
| **metrics** | complexity, Halstead, MI, smells, waste, dups, ... computed from one tree per file | kaikai |
| **syntax** | a pure API over a parsed file: nodes as indices, kinds, ranges, text, queries | kaikai |
| **ts** | the only module that crosses the FFI: `extern "C"` bindings to the shim | kaikai |
| **shim** | parses, flattens the tree into arrays, runs queries; hands kaikai integers, strings and opaque handles | C (`c/`) |
| **queries** | what each language calls a function, a test, an assertion, a call | tree-sitter `.scm` |
| **vendor** | the tree-sitter core and the grammars, pinned | C, generated |

## Layout

```
src/
  main.kai          entry point
  km2/              `src/km2/<dir>/<file>.kai` imports as `km2.<dir>.<file>`
    *.kai           the edges: CLI, file walk, git, output
    ts.kai          FFI bindings (the only module with `Ffi`)
    syntax.kai      the tree API
    metrics/        pure metric logic
c/                  the shim (`kts.c`, `kts.h`)
queries/<lang>/     tree-sitter queries per language
vendor/             tree-sitter core and grammars; `vendor/VERSIONS` pins them
scripts/vendor.sh   the only way `vendor/` changes
bench/              `compare.sh` (km vs km2, time and peak RSS) and `results.md`
tests/              kaikai tests, one `*_test.kai` per module; differential tests against km
fixtures/<lang>/    inputs with expected results
tools/              repo scripts: the quality gate
```

`make ci` is everything CI runs: format, lint, build, tests, the quality gate with `km` and with `km2`, and the differential tests against `km`. The kaikai version is pinned in `.kaikai-version` (0.196.3).

## Principles

Higher tier wins on conflict.

### Tier 1: load-bearing

1. **Compatible with km.** Same subcommands, flags, defaults, output formats and JSON schema, and the same `.kimun.toml`. Fields are added, never renamed or retyped. A script or CI job written for `km` runs unchanged against `km2`.
2. **Honest measurement.** A number differs from `km`'s only where km2 measures better, and every such difference is documented in the README's "km vs km2" table and pinned by a differential test. No output claims who or what wrote the code: rules are named by the defect they find, never by an assumed author.
3. **We eat our own dogfood.** Quality gates run from the first commit, with `km` and, as each command exists, with `km2` over its own source. A disagreement between the two on km2's code is a documented difference or a bug.

### Tier 2: aspirational

4. **Performance similar to km, measured.** Wall time and peak RSS within 1.5× of `km` on the same inputs. One parse per file, shared by every metric. Numbers come from `bench/compare.sh` on real repositories, never from intuition.
5. **One module crosses the FFI.** Everything above `ts.kai` is ordinary kaikai, testable without C.
6. **Languages are data.** What a language calls a function, a test or an assertion lives in its `.scm` queries; the metric code does not name languages.

### Tie-breakers

- Compatibility beats elegance: a better design that breaks a `km` user waits for a major version.
- Honesty beats speed.
- A query beats a language special case in the core.

## Detailed rules

Topic rules live in `.claude/rules/` and load by path:

- `kaikai-code.md`: writing kaikai.
- `ffi.md`: the C shim and its bindings.
- `grammars.md`: vendored grammars and queries.
- `compat.md`: anything a `km` user can see: flags, output, configuration.
- `perf.md`: benchmarks and the performance budget.
- `git.md`: commits, PRs, changelog.

## Working discipline

- **Think before acting; don't over-complicate.** Pick the direct path.
- **Use what's already in context.** Don't re-run commands for facts already known.
- **Read km before porting.** The behaviour of a command is in `../kimun/src` and its tests; port the behaviour, with its edge cases, not a guess of it.
- **Measure before optimising.** Performance claims come with numbers from a real project.

## Things to avoid

- **Do not scan source text where a tree exists.** Regexes over source text are what km2 exists to replace. The lexical path is kept only for languages without a grammar.
- **Do not depend on Kimün's code.** km2 shares behaviour with `km`, verified by differential tests, never code.
- **Do not call a model.** Every result is deterministic and reproducible in CI.
- **Do not edit `vendor/` by hand.** `scripts/vendor.sh` fetches the pinned versions; a change is a new pin.
- **Do not work around kaikai gaps here.** If km2 needs something from `kaic2`, `kai test` or the stdlib, open an issue on kaikai with a repro.
- **Do not let a `TSNode` or a raw pointer reach kaikai.** Nodes are indices; resources are `opaque` handles.
