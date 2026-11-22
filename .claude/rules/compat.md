---
paths:
  - "src/main.kai"
  - "src/km2/cli*.kai"
  - "src/km2/report*.kai"
  - "src/km2/config*.kai"
  - "tests/**"
---

# Compatibility with km

A `km` user sees flags, output and configuration. km2 keeps all three.

## The reference

The behaviour of each command is `../kimun`: `src/cli.rs` and
`src/options.rs` for the interface, each command's `report.rs` for the
output, `src/config.rs` for `.kimun.toml`, and the command's tests for the
edge cases. Read them before porting a command; port the behaviour, not a
guess of it. Compare against the released `km` binary
(`km --version`), not against a work-in-progress checkout.

## The rules

- **Same subcommands, flags, short flags and defaults.** A flag km2 does
  not implement yet fails with a message naming it, never silently.
- **Same formats** (`table`, `json`, `short`, `terse`, `github`,
  `codeclimate` where `km` has them) and **the same JSON schema**: field
  names, types, nesting, order of arrays, and `null` where `km` writes
  `null`. Fields are added, never renamed, retyped or removed.
- **Same exit codes**, including the gates (`--fail-below`,
  `--fail-on`, `--fail-if-worse`): CI depends on them.

## Where ahu.cli and clap differ

The command line is declared with `ahu.cli`; `km` uses clap. Known
differences, and where each is handled:

| Behaviour | km (clap) | ahu.cli | km2 |
|---|---|---|---|
| Usage error exit code | 2 | 1 | 2, in `src/km2/cli.kai` |
| No command given | help on stderr, exit 2 | help on stdout, exit 0 | as km, in `src/km2/cli.kai` |
| Short version flag | `-V` | `-v` | open: needs ahu.cli to name the short flag |
| Error message prefix | `error:` | `Error:` | `error:`, in `src/km2/cli.kai` |

A gap ahu.cli cannot express is raised upstream on ahu, not parsed
around here.
- **Same configuration**: `.kimun.toml` read with `km`'s precedence (CLI
  flag, then file, then default). New settings go in new sections or new
  keys.
- **Same file selection**: `.gitignore`, `--kind`, test exclusion,
  generated files, as `../kimun/src/walk.rs` defines them.
- **Deterministic output**: sorted as `km` sorts, ties broken as `km`
  breaks them.

## Differences

A value may differ from `km`'s only where km2 measures better (a function
`km` missed, an operator it miscounted). Each difference:

1. is pinned by a differential test that runs both binaries on a fixture
   and asserts the exact difference;
2. is listed in the README's "km vs km2" table (and in `LEEME.md`), with
   the reason;
3. never changes the schema, only values.

Every ported command has a differential test against `km` over the
fixtures and over a real repository; schemas must match exactly.
