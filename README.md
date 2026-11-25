# km2

Code metrics over syntax trees: the successor of [km (Kimün)](https://github.com/lnds/kimun), written in [kaikai](https://github.com/lnds/kaikai) and parsing with [tree-sitter](https://tree-sitter.github.io/).

km2 aims to be a drop-in replacement for `km`: the same commands, flags, output formats, JSON schema and `.kimun.toml`, with better measurements wherever a syntax tree sees what a lexical reader cannot. Until it reaches parity, `km` remains the tool to use.

Status: `loc`, `indent`, `churn`, `age`, `authors` and `tc` are ported, with every flag and format of their `km` counterparts. The other commands are not implemented yet.

## Building

Requires kaikai 0.199.2 (`.kaikai-version`), `km` and `jq` for the quality gate, and `git` for `loc --by-author`, `churn`, `age` and `authors`.

```sh
make build   # ./km2
make test
make ci      # format, lint, build, tests, quality gate with km and km2, differential tests against km
make corpus  # the language corpus: fetch and compare with km (network, several GB)
```

The language corpus, `tests/corpus/repos.tsv`, lists two real repositories per language, each pinned by commit. `tools/corpus.sh` clones them into `~/.cache/km2-corpus` (`$KM2_CORPUS`), compares `loc` on each with km, and with `files OWNER/REPO` narrows a difference down to the file.

## km vs km2

Every value km2 reports differently from `km` because it measures better, and why. None so far: the ported commands report what their `km` counterparts report.

| Command | Field | km | km2 | Reason |
|---|---|---|---|---|

## Known gaps

Where km2 does not yet behave as `km`, because kaikai or ahu lacks something it needs. Each gap is reported upstream and closes when the release that fixes it is out.

| Behaviour | km | km2 | Upstream |
|---|---|---|---|
| A line whose only content is an invalid UTF-8 byte that kaikai decodes as whitespace (a stray `0x85`, a truncated `0xE9`) | code | blank | lnds/kaikai#3555 |
| A command that fails (`--since 6x`, a path outside a repository) | `error: ...` | `Error: ...` | kaikailang-org/ahu#47 |
| `churn`, `age`: a rename near the 50% similarity threshold | followed as libgit2 scores similarity | followed as `git log -M` scores it | km2 reads history through the `git` program; kaikai has no libgit2 binding. On `lnds/kaikai`, 5 of 879 files differ. |
| `authors`: `last_active` of an author whose commits share one commit time | an older commit's author date (seen in `lnds/kimun` and `phoenixframework/phoenix`, one author each) | the newest commit's author date | libgit2's time sort leaves commits with the same commit time in no set order, so km may meet an older one first. |
| A directory that cannot be read | warned about, with the OS error code | warned about, without the code | lnds/kaikai#3535 |
| A file that cannot be read | `<path>: Permission denied (os error 13)` | `<path>: read_file: cannot open file` | lnds/kaikai#3535 |
| An unknown element in a comma-separated `--kind` (`code,nope`) | `error: ...`, exit 2 | `Error: ...`, exit 1 | kaikailang-org/ahu#45 |
| Telling generated files by a source map named at their end | reads the last 512 bytes | reads the whole file (same result, more I/O) | lnds/kaikai#3562 |
| `indent` over a text file with a stray UTF-8 continuation byte (some Latin-1 sources) | measures it | stops with a `string.slice` panic | lnds/kaikai#3565 |
| `churn`, `authors` over a repository holding a binary file that starts with a UTF-8 continuation byte (`gohugoio/hugo`) | measured | stops with a `string.slice` panic | lnds/kaikai#3573 |
