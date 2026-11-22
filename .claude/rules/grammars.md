---
paths:
  - "vendor/**"
  - "queries/**"
  - "scripts/vendor.sh"
---

# Vendored grammars and queries

## Vendor

- `vendor/` holds the tree-sitter core (`lib/src/lib.c`, `lib/include`)
  and, per language, the grammar's generated `src/parser.c`,
  `src/scanner.c` (when it has one) and `src/tree_sitter/*.h`.
- `vendor/VERSIONS` pins each piece: repository, tag and commit. The
  build reads only what is pinned there.
- **Only `scripts/vendor.sh` changes `vendor/`.** It fetches the pinned
  versions and nothing else. Updating a grammar is a new pin in
  `vendor/VERSIONS`, the script run, and the fixtures run again, in one
  commit of its own.
- A grammar's ABI must be one the core accepts
  (`TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION` to
  `TREE_SITTER_LANGUAGE_VERSION` in `lib/include/tree_sitter/api.h`). Use
  the `parser.c` a grammar releases; generate one only for a grammar that
  publishes none (kaikai's own, from `tree-sitter-kaikai`).
- Licenses: every vendored piece keeps its `LICENSE` file beside it.

## Queries

- `queries/<lang>/<name>.scm` is where a language's knowledge lives: what
  a function is, a test, an assertion, a call, an import. The metric code
  asks for captures by name (`@function`, `@test`, `@assertion`) and does
  not name languages.
- Capture names are the same in every language for the same concept. A
  new concept gets a new capture name, documented at the top of each
  query file that provides it.
- **Every query has a fixture**: `fixtures/<lang>/` holds a file that
  exercises each pattern and the captures expected from it, checked by a
  test.
- A query is compiled once per language per run, not once per file.
- Prefer a node kind and a field over a predicate on text. A `#match?`
  or `#eq?` on identifier text is acceptable only where the language
  marks the concept by name (a `test_` prefix, an `assert` macro).
