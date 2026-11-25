# km2

Code metrics over syntax trees: the successor of [km (Kimün)](https://github.com/lnds/kimun), written in [kaikai](https://github.com/lnds/kaikai) and parsing with [tree-sitter](https://tree-sitter.github.io/).

km2 aims to be a drop-in replacement for `km`: the same commands, flags, output formats, JSON schema and `.kimun.toml`, with better measurements wherever a syntax tree sees what a lexical reader cannot. Until it reaches parity, `km` remains the tool to use.

Status: `loc`, `indent`, `churn`, `age`, `authors` and `tc` are ported, with every flag and format of their `km` counterparts. `cycom` is ported for Rust, Elixir and Kaikai, which km2 parses; `km cycom` also measures some thirty other languages, which km2 leaves out until it vendors their grammars. The other commands are not implemented yet.

## Building

Requires kaikai 0.201.1 (`.kaikai-version`), `km` and `jq` for the quality gate, and `git` for `loc --by-author`, `churn`, `age` and `authors`.

```sh
make build   # ./km2
make test
make ci      # format, lint, build, tests, quality gate with km and km2, differential tests against km
make corpus  # the language corpus: fetch and compare with km (network, several GB)
```

The language corpus, `tests/corpus/repos.tsv`, lists two real repositories per language, each pinned by commit. `tools/corpus.sh` clones them into `~/.cache/km2-corpus` (`$KM2_CORPUS`), compares `loc` on each with km, and with `files OWNER/REPO` narrows a difference down to the file.

## km vs km2

Every value km2 reports differently from `km` because it measures better, and why. Each is pinned by a fixture in `fixtures/cycom/differ`; `fixtures/cycom/same` holds what both report alike.

| Command | Field | km | km2 | Reason |
|---|---|---|---|---|
| `cycom` | `complexity` | a branch for the `\|\|` of a closure without parameters (`\|\| 0`) and for `&&` in a reference pattern or type (`\|&&b\|`, `&&str`) | none | Neither is a decision: the tree tells a closure and a reference from a boolean operator. |
| `cycom` | `functions` | a function for each `fn` written inside a `macro_rules!` body | none; the macro's body counts in `<file>` | A macro body is a template, not a function of the file. |
| `cycom` | `functions`, `complexity` | the body of a function whose signature or head spans lines (Rust bounds and `where`, a kaikai `= match f(` with its arguments below) counted in `<file>` | counted in the function | The tree gives the function's extent whatever its layout. |
| `cycom` | `complexity` | no branch for the arms of a `match` in a function written on one line | its arms | km skips an arrow that follows `fn` on its line, a rule for Elixir's anonymous functions. |
| `cycom` | `complexity` | a branch for a keyword in the text of an Elixir sigil that interpolates (`~s\|path for #{x}\|`) | none | A sigil's text is a literal; only what it interpolates runs. |
| `cycom` | `name` | `r` for a function named with a raw identifier (`r#async`) | `r#async` | The name as written. |
| `cycom` | `name` | an Elixir name without its `?` or `!` (`valid`) | `valid?` | The name as written. |
| `cycom` | `complexity` | no branch for code interpolated in an Elixir string (`"#{a \|\| b}"`) | its branches | Interpolated code runs. Documentation (`@doc`, `@moduledoc`, `@typedoc`) still counts nothing. |
| `cycom` | `complexity` | an Elixir clause whose last pattern is `_` (`:exit, _ ->`) taken for a catch-all | a branch | Only a clause of the single pattern `_` matches anything. |
| `cycom` | `functions` | a kaikai `extern` declaration over several lines as a function, and the one-line functions after it missed | the functions with a body | An `extern` has no body. |

## Known gaps

Where km2 does not yet behave as `km`, because kaikai or ahu lacks something it needs. Each gap is reported upstream and closes when the release that fixes it is out.

| Behaviour | km | km2 | Upstream |
|---|---|---|---|
| A command that fails (`--since 6x`, a path outside a repository) | `error: ...` | `Error: ...` | kaikailang-org/ahu#47 |
| `churn`, `age`: a rename near the 50% similarity threshold | followed as libgit2 scores similarity | followed as `git log -M` scores it | km2 reads history through the `git` program; kaikai has no libgit2 binding. On `lnds/kaikai`, 5 of 879 files differ. |
| `authors`: `last_active` of an author whose commits share one commit time | an older commit's author date (seen in `lnds/kimun` and `phoenixframework/phoenix`, one author each) | the newest commit's author date | libgit2's time sort leaves commits with the same commit time in no set order, so km may meet an older one first. |
| An unknown element in a comma-separated `--kind` (`code,nope`) | `error: ...`, exit 2 | `Error: ...`, exit 1 | kaikailang-org/ahu#45 |
