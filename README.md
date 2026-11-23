# km2

Code metrics over syntax trees: the successor of [km (Kimün)](https://github.com/lnds/kimun), written in [kaikai](https://github.com/lnds/kaikai) and parsing with [tree-sitter](https://tree-sitter.github.io/).

km2 aims to be a drop-in replacement for `km`: the same commands, flags, output formats, JSON schema and `.kimun.toml`, with better measurements wherever a syntax tree sees what a lexical reader cannot. Until it reaches parity, `km` remains the tool to use.

Status: `loc` is ported, with every `km loc` flag and format. The other commands are not implemented yet.

## Building

Requires kaikai 0.198.0 (`.kaikai-version`), `km` and `jq` for the quality gate, and `git` for `loc --by-author`.

```sh
make build   # ./km2
make test
make ci      # format, lint, build, tests, quality gate with km and km2, differential tests against km
make corpus  # the language corpus: fetch and compare with km (network, several GB)
```

The language corpus, `tests/corpus/repos.tsv`, lists two real repositories per language, each pinned by commit. `tools/corpus.sh` clones them into `~/.cache/km2-corpus` (`$KM2_CORPUS`), compares `loc` on each with km, and with `files OWNER/REPO` narrows a difference down to the file.

## km vs km2

Every value km2 reports differently from `km` because it measures better, and why. None so far: `loc` reports what `km loc` reports.

| Command | Field | km | km2 | Reason |
|---|---|---|---|---|

## Known gaps

Where km2 does not yet behave as `km`, because kaikai or ahu lacks something it needs. Each gap is reported upstream and closes when the release that fixes it is out.

| Behaviour | km | km2 | Upstream |
|---|---|---|---|
| JSON layout | indented | compact (same content) | lnds/kaikai#3521 |
| A line holding only non-ASCII whitespace (U+00A0, U+0085, U+3000), `\v` or `\f` | blank | code | lnds/kaikai#3512 |
| A directory that cannot be read | warned about, with the OS error code | warned about, without the code | lnds/kaikai#3535 |
| A file that cannot be read | `<path>: Permission denied (os error 13)` | `<path>: read_file: cannot open file` | lnds/kaikai#3535 |
| An unknown element in a comma-separated `--kind` (`code,nope`) | `error: ...`, exit 2 | `Error: ...`, exit 1 | kaikailang-org/ahu#45 |
