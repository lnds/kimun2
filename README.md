# km2

Code metrics over syntax trees: the successor of [km (Kimün)](https://github.com/lnds/kimun), written in [kaikai](https://github.com/lnds/kaikai) and parsing with [tree-sitter](https://tree-sitter.github.io/).

km2 aims to be a drop-in replacement for `km`: the same commands, flags, output formats, JSON schema and `.kimun.toml`, with better measurements wherever a syntax tree sees what a lexical reader cannot. Until it reaches parity, `km` remains the tool to use.

Status: setup. No command is implemented yet; every command fails naming itself.

## Building

Requires kaikai 0.196.3 (`.kaikai-version`), `km` and `jq` for the quality gate.

```sh
make build   # ./km2
make test
make ci      # format, lint, build, tests, quality gate with km and km2
```

## km vs km2

Every value km2 reports differently from `km`, and why. Empty until the first command is ported.

| Command | Field | km | km2 | Reason |
|---|---|---|---|---|
