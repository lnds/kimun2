---
paths:
  - "c/**"
  - "src/km2/ts.kai"
  - "src/km2/syntax.kai"
---

# The C shim and its bindings

kaikai reaches tree-sitter through `c/kts.c` and nothing else. Read
`kai info ffi` before changing either side of the boundary.

## The boundary

- **Only `src/km2/ts.kai` declares `extern "C"`.** Every other module sees
  `syntax.kai`'s pure API and carries no `Ffi` in its rows.
- **Only scalars, `String` and `opaque` handles cross.** A `TSNode` holds
  pointers and never crosses; a node is an `Int`, its index in the
  flattened tree. A `TSLanguage *`, `TSTree *` or `TSQuery *` is wrapped
  in a handle the shim owns.
- **No out-parameters.** kaikai has none: the shim absorbs them
  (`ts_query_new`'s error offset becomes `kts_query_error(q)`).
- **Strings come back copied** (kaikai copies a returned `const char *`).
  A string the shim returns must stay valid until the call returns, and
  no longer: point into the document's own source or a buffer owned by
  the handle, never a `static` buffer.
- **Integer widths are explicit.** tree-sitter speaks `uint32_t`; the
  bindings use `U32` (or `Int` where the shim widens on purpose), and an
  absent node is `-1`.

## Ownership

`opaque` handles have no Drop: kaikai frees the box, never the C resource.

- Every handle type has exactly one `kts_free_*`, and it accepts a handle
  already freed by being idempotent on its own state, never by guessing.
- `syntax.kai` acquires handles in a handler's `initially` and frees them
  in its `finally`, so every path out of the scope releases them
  (`kai info effects`, book ch. 12.8). No kaikai code outside `syntax.kai`
  sees a raw handle.
- A freed handle is never used again; the shim marks it and a use is a
  panic with a message naming the call, not undefined behaviour.

## Concurrency

Files are parsed in parallel fibers.

- **No mutable `static` or global state in the shim.** One `TSParser` per
  parse (or per worker), never shared.
- A `Doc` is used by the fiber that created it; nothing in the shim locks.
- Language objects (`tree_sitter_rust()` and friends) are immutable and
  safe to share.

## Checking the shim

- The shim compiles warning-free with `-Wall -Wextra -Wpedantic` on both
  backends (`kai build` and `kai build --backend=c`).
- Every change to `c/` runs the tests under AddressSanitizer and a
  `leaks` pass over `km2` on a real directory; both are clean.
- A new accessor gets a kaikai test that compares it against a fixture
  whose tree is known (`fixtures/<lang>/`).
