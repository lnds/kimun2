# Benchmarks: km vs km2

Measured with `bench/compare.sh`: median wall time of 10 runs after 2 warm-ups, and peak RSS from `/usr/bin/time -l`. `km` runs with `--include-tests` (and `--include-ext` where the input holds other languages), because km2 counts every file so far.

Machine: Apple M3 Max, 16 cores. km 0.49.0. km2 0.1.0, single-threaded. Inputs: `kimun/src` at `ebba255` (Rust, 416 files, 2.7 MB), the kaikai 0.196.3 stdlib (96 files), and kaikai 0.196.3 `stdlib`, `examples`, `tests` and `stage2` (6,255 files, 5,847 distinct, intentional syntax errors included).

## `hal` over tree-sitter, Rust, Elixir and Kaikai, on kaikai 0.201.3 (out of budget on memory)

`bench/compare.sh` (median of 10 warm runs, peak RSS from `/usr/bin/time -l`), `km hal --include-ext rs`, `ex` or `kai` and the same for km2. Inputs: `lnds/kimun` at `8bb7886` (`src`, 261 files), `rust-lang/cargo` at `9b87fe4` (`src`, 253 files), `phoenixframework/phoenix` at `37d3421` (`lib`, 73 files), `plausible/analytics` at `e83d0ba` (`lib`, 536 files), the kaikai stdlib at `0990eea3e` (94 files) and km2's own `src`.

| Input | km time | km RSS | km2 time | km2 RSS | time | RSS |
|---|---|---|---|---|---|---|
| `kimun/src` | 294 ms | 13.2 MB | 342 ms | 20.7 MB | 1.16× | 1.57× |
| `cargo/src` | 586 ms | 14.7 MB | 534 ms | 28.2 MB | 0.91× | 1.92× |
| `phoenix/lib` | 109 ms | 12.3 MB | 125 ms | 24.3 MB | 1.14× | 1.98× |
| `plausible/lib` | 429 ms | 12.9 MB | 392 ms | 24.0 MB | 0.91× | 1.86× |
| kaikai stdlib | 96 ms | 12.6 MB | 124 ms | 21.0 MB | 1.29× | 1.67× |
| km2 `src` | 54 ms | 11.5 MB | 77 ms | 14.9 MB | 1.42× | 1.30× |

Time is within budget; memory is not. On the same input `cycom` is within it (`cargo/src`: km 396 ms and 15.2 MB, km2 323 ms and 20.4 MB, 1.34×), so the excess is `hal`'s own: the query captures nearly every token, and each file's captures are a list of records many times longer than `cycom`'s.

The first version sorted each file's captures by position to walk them beside the line kinds; on the kaikai stdlib that sort was 0.9 G of 2.97 G instructions retired and put time at 1.63×. The captures are now kept by looking each one's row up in an array of the code rows, in any order: 2.03 G.

## `cycom` over tree-sitter, on kaikai 0.201.0 (current, out of budget on memory)

`/usr/bin/time -l`, the median of three runs, on a machine under load (load average 6), so instructions retired are the steadier figure. `km cycom` with `--include-ext` for the languages km2 parses. Inputs: ten copies of ripgrep's crates (`rg10`, 780 Rust files), ripgrep, phoenix (Elixir) and the kaikai 0.200.2 stdlib with km2's own `src`.

km2 parses the walk in two parts, each on a fiber of its own with its own queries, at the default thread count:

| Input | km time | km RSS | km2 time | km2 RSS | time | RSS |
|---|---|---|---|---|---|---|
| `rg10` | 1.67 s | 20.2 MB | 1.56 s | 49.2 MB | 0.93× | 2.44× |
| ripgrep | 0.18 s | 18.0 MB | 0.20 s | 34.6 MB | 1.11× | 1.92× |
| phoenix | 0.10 s | 12.7 MB | 0.13 s | 21.1 MB | 1.30× | 1.66× |
| kaikai | 0.11 s | 12.7 MB | 0.10 s | 16.3 MB | 0.91× | 1.28× |

Time is within budget; memory is not. Single-threaded km2 fits the memory budget and not the time one. With two parts, memory also grows with the threads the runtime starts, though only two fibers parse: on `rg10`, 28.9 MB at `KAI_THREADS=1`, 39.4 MB at 2, 49.9 MB at 16 (the default here). A kaikai program whose two fibers only build lists gains 1.3 MB from 4 to 16 threads, so most of that growth is km2's, likely the allocator's per-thread caches that tree-sitter's allocations leave behind as fibers move between threads; not yet measured.

| `rg10`, four parts | time | RSS |
|---|---|---|
| `KAI_THREADS=1` | 2.68 s (1.71×) | 29.9 MB (1.49×) |
| `KAI_THREADS=2` | 1.69 s (1.08×) | 36.6 MB (1.82×) |
| `KAI_THREADS=4` | 1.28 s (0.82×) | 48.8 MB (2.43×) |

Where the time goes, in instructions retired on `rg10`: km's whole `cycom` is 17.1 G; tree-sitter parsing every file is 19.7 G of km2's 31.1 G, and the query adds 1.7 G. Flattening the tree only on demand saved 14% on Rust and 31% on Elixir; it is no longer done for a query. Compiling a query costs about 90 M instructions, so each fiber compiles only the queries of the grammars its part holds: with 64 parts, compiling alone took more than the parse.

## `loc` over the language corpus, on kaikai 0.199.2

`tools/corpus.sh run`, single warm runs. Output equals km's on 82 repositories. The other 2 are lnds/kaikai#3555: `trim` and `is_blank`, now Unicode-aware, read some invalid UTF-8 bytes as whitespace (a stray `0x85` as NEL, a truncated `0xE9` as TAB), so a Big5 file in helix-editor/helix and a one-byte Latin-1 JSON file in erlang/otp count lines as blank that km counts as code. WordPress and osiris, which differed through #3512, now match.

Total: km 107.4 s, km2 103.1 s, 0.96×. 55 repositories at or below km's time, 27 between 1× and 1.5×, none above; microsoft/vcpkg 1.31×.

Changes: the toolchain moves to 0.199.2 (`last_index_of` in one runtime call, `starts_with` / `ends_with` with one `memcmp`, short strings inside their cell); UTF-8 is validated over the `String` with `utf8.is_valid_string` instead of a `[Byte]` list; the content hash is the runtime's FNV-1a (`string.string_hash`) instead of a kaikai loop.

| vcpkg, median of 5 warm runs | km | km2 on 0.198.0 | km2 on 0.199.2 |
|---|---|---|---|
| `loc` | 1.01 s | 1.39 s | 1.33 s |

User CPU is still the gap on vcpkg (km2 0.86 s, km 0.44 s; system time 0.51 s and 0.58 s): freeing records, the lexer's per-step record, and field access.

| Peak RSS, `/usr/bin/time -l` | km | km2 on 0.198.0 | km2 on 0.199.2 |
|---|---|---|---|
| a 522 KB C++ header (`stage0/runtime.h` with a `namespace` line) | 11.5 MB | 36.8 MB | 8.6 MB |
| `kaikai` repository | 12.7 MB | 10.9 MB | 10.8 MB |

## `loc` over the language corpus, with ignore rules indexed by suffix (superseded)

`tools/corpus.sh run`, as below (a few repositories ran beside a microbenchmark, which slows km and km2 alike). Output equals km's on 81 repositories; the other 3 are lnds/kaikai#3512.

Total: km 109.2 s, km2 107.9 s, 0.99×. 44 repositories at or below km's time, 37 between 1× and 1.5×, none above; microsoft/vcpkg 1.37×.

The gap on vcpkg is user CPU (km2 0.89 s, km 0.44 s); system time is the same (0.45 s, 0.53 s). Three changes to the ignore matching, median of 3 warm runs:

- a path's characters are built only when a general pattern passed its literal prefilter, not on every query of a matcher holding one;
- a suffix with a dot (`*_i.c`, `*.VC.db`) is filed under the extension it requires and tested only on paths with that extension, instead of an `ends_with` per path;
- the frames above the root (its ancestors' ignore files) build a path's absolute form only when they hold rules.

| vcpkg, `--include-tests` | km2 before | km2 now | km |
|---|---|---|---|
| walk only (`--include-ext zzz`) | 0.38 s | 0.28 s | 0.12 s |
| `loc` | 1.49 s | 1.35 s | 0.98 s |

What remains is kaikai's: `dir.list_entries` is a quarter of the walk; `string.last_index_of` (lnds/kaikai#3548) and `starts_with` / `ends_with` (#3553) copy a slice per call; the lexer allocates a record per step; and the per-file line list and FNV hash are kaikai loops. Computing a path's last component once for every frame instead of once per matcher was tried and gained nothing measurable.

## Peak memory on the `kaikai` repository (superseded)

The 38 MB peak on the `kaikai` repository was one file: `stage0/runtime.h` (522 KB) took km2 to 35.9 MB on its own. Deciding whether a `.h` header is C or C++ checked that its text is valid UTF-8 first, through `utf8.is_valid(string.bytes(src))`, and `string.bytes` builds a list of one cell per byte (about 48 bytes of heap each, lnds/kaikai#3550). The check now runs only once a line only C++ writes is found; a C header never pays it.

| `/usr/bin/time -l` | km | km2 before | km2 now |
|---|---|---|---|
| `stage0/runtime.h` | 11.1 MB | 35.9 MB | 9.0 MB |
| `kaikai` repository at `0990eea3e` | 12.7 MB | 38.5 MB | 11.7 MB |
| a 396 KB C++ header | 11.0 MB | 28.4 MB | 28.4 MB |

A large C++ header still pays the list until #3550 gives a validation over the `String` itself.

## `loc` over the language corpus, with a required-literal prefilter (superseded)

`tools/corpus.sh run`, as below. Output equals km's on 81 repositories; the other 3 are lnds/kaikai#3512.

Total: km 109.9 s, km2 114.5 s, 1.04×. 35 repositories at or below km's time, 45 between 1× and 1.5×, 1 above: microsoft/vcpkg, 1.58× in that single run.

On vcpkg the gap was the walk, not the counting: `--include-ext zzz` (the walk and the ignore rules, nothing counted) took km2 0.83 s against km's 0.12 s. Two changes close most of it. A glob keeps the longest literal run every match contains and rejects a path without it through `string.contains` before backtracking; a query computes a path's last component once, instead of once per pattern through `string.last_index_of`, which the stdlib runs as a kaikai loop. Median of 3 warm runs:

| vcpkg, `--include-tests` | km2 before | km2 now | km |
|---|---|---|---|
| walk only (`--include-ext zzz`) | 0.83 s | 0.38 s | 0.12 s |
| `loc` | 1.92 s | 1.49 s | 0.98 s |

What remains of the walk is spread out: listing directories (`dir.list_entries`, about a quarter), allocation and the ignore stack. Reading only a file's first line to look for a shebang, as km does, was tried and gained nothing: the second read of those files is not a measurable cost.

## `loc` over the language corpus, after the glob strategies (superseded)

`tools/corpus.sh run` over the 84 repositories of `tests/corpus/repos.tsv` (`loc --include-tests --format json`, one warm run each, a rough guide). Output equals km's on 81; the other 3 are lnds/kaikai#3512.

Total: km 108.6 s, km2 117.6 s, 1.08×. 27 repositories at or below km's time, 49 between 1× and 1.5×, 5 above: microsoft/vcpkg 1.98×, felangel/bloc 1.65×, flame-engine/flame 1.64×, files-community/Files 1.54×, ghostty-org/ghostty 1.52×.

The glob matcher used to dominate repositories with long `.gitignore` files. It now picks a strategy per pattern when it compiles it (literal, base name, suffix, prefix, a pattern within the last component, general), converts a path to characters once per query and only when a general pattern needs it, and the ignore matcher looks whole-path, base-name and extension rules up in maps. Median of 5 warm runs, `--include-tests`:

| Repository | km | km2 before | km2 now |
|---|---|---|---|
| microsoft/vcpkg | 992 ms | 5,750 ms (5.80×) | 1,867 ms (1.88×) |
| files-community/Files | 278 ms | 1,899 ms (6.82×) | 436 ms (1.57×) |
| microsoft/vscode-dev-containers | 201 ms | 1,009 ms (5.01×) | 259 ms (1.28×) |
| dotnet/fsharp | 2,041 ms | 6,899 ms (3.38×) | 2,118 ms (1.04×) |
| metabase/metabase | 5,802 ms | 17,053 ms (2.94×) | 6,001 ms (1.03×) |

What remained on vcpkg is in the section above.

## `loc`, complete, on kaikai 0.198.0 (superseded)

kaikai 0.198.0 and ahu 0.5.0. Inputs: `kimun` at `ef36c30`, `kaikai` at `0990eea3e`, `minerva` at `e71a58c`. Same session, median of 10 runs after 2 warm-ups; peak RSS from `/usr/bin/time -l`. "km2 before" is the 0.197.0 source built with 0.198.0; "km2 now" adds the canonical root and the registry as a plain `const`.

| Input | km time | km2 before | km2 now | ratio | km RSS | km2 RSS |
|---|---|---|---|---|---|---|
| `kimun/src` | 82.1 ms | 117.8 ms | 117.8 ms | 1.43× | 12.5 MB | 7.4 MB |
| `kimun/src`, `--include-tests` | 106.0 ms | 104.7 ms | 106.0 ms | 1.00× | 11.0 MB | 6.8 MB |
| kaikai stdlib | 32.2 ms | 31.7 ms | 33.5 ms | 1.04× | 10.9 MB | 6.6 MB |
| `minerva` | 45.9 ms | 52.6 ms | 50.8 ms | 1.11× | 11.5 MB | 7.8 MB |
| `kaikai` repository | 698.1 ms | 918.8 ms | 919.8 ms | 1.32× | 12.4 MB | 38.0 MB |
| `kimun` repository | 97.3 ms | 130.6 ms | 128.0 ms | 1.32× | 12.5 MB | 8.0 MB |

Within the 1.5× time budget on every input, and below km's memory on all but the `kaikai` repository, whose 38 MB peak (3.1×) is the one number out of budget. The gain is the compiler's: the same source went from 2.0×–2.5× on 0.197.0 to 1.0×–1.4× on 0.198.0, with field reads by slot (lnds/kaikai#3504), scalar-replaced records and unboxed `Int` fields (#3505, #3506), `Option` on the native backend (#3507), `math.bits` as instructions (#3522) and a computed `const` evaluated once (#3524). Dropping the registry's per-entry thunk, a concession to #3524 and #3525, costs nothing measurable now.

## `loc`, complete, on kaikai 0.197.0 (superseded)

kaikai 0.197.0 and ahu 0.4.0. The walk now prunes: it reads each directory with `dir.list_entries` (lnds/kaikai#3511) and does not open a directory that `.gitignore`, `.git`, `--exclude-dir` or test exclusion leaves out. Output is km's on every case of `tests/diff/loc.args`, as before.

| Input | km time | km2 time | ratio | km RSS | km2 RSS |
|---|---|---|---|---|---|
| `kimun/src` | 59.8 ms | 137.3 ms | 2.3× | 12.0 MB | 9.0 MB |
| `kimun/src`, `--include-tests` | 78.0 ms | 157.8 ms | 2.0× | 11.1 MB | 10.5 MB |
| kaikai stdlib | 23.5 ms | 45.0 ms | 1.9× | 10.9 MB | 6.9 MB |
| `minerva` | 32.0 ms | 71.7 ms | 2.2× | 11.4 MB | 11.1 MB |
| `kaikai` repository | 513.3 ms | 1,259.2 ms | 2.5× | 12.5 MB | 51.5 MB |
| `kimun` repository | 73.6 ms | 152.9 ms | 2.1× | 12.4 MB | 9.6 MB |

Where the change comes from, same session, median of 10 runs (3 for the old walk on `kimun`):

| Input | km2 before, 0.196.3 | km2 before, 0.197.0 | km2 now, 0.197.0 |
|---|---|---|---|
| `kimun/src` | 157.0 ms | 140.5 ms | 137.9 ms |
| kaikai stdlib | 45.1 ms | 46.2 ms | 44.2 ms |
| `minerva` | 83.5 ms | 78.8 ms | 72.1 ms |
| `kaikai` repository | 1,673.5 ms | 1,599.5 ms | 1,260.8 ms |
| `kimun` repository | 3,381.1 ms | 3,254.3 ms | 155.2 ms |

The compiler and stdlib of 0.197.0 (lnds/kaikai#3508's `string.lines` work, #3509) give 3% to 10%; the pruning walk gives the rest: 21× on the `kimun` repository, whose 247,000 files are nearly all in an ignored `target/`, and peak RSS there from 261.6 MB to 9.6 MB. Still out of the 1.5× budget, for the causes below that remain open: the content hash (#3522), the lexer's aggregates (#3505–#3507; #3504 is fixed after 0.197.0) and the language registry (#3524, #3525). lnds/kaikai#3504 is measured again on the release that ships it.

## `loc`, complete: 64 languages, km's walk and filters, on kaikai 0.196.3 (superseded)

Output is byte for byte km's on every case of `tests/diff/loc.args` (`make diff-km`), JSON aside: km2's is compact, km's indented (lnds/kaikai#3521); parsed, they are equal on all eight repositories tried.

| Input | km time | km2 time | ratio | km RSS | km2 RSS |
|---|---|---|---|---|---|
| `kimun/src` | 83.6 ms | 209.5 ms | 2.5× | 12.1 MB | 8.9 MB |
| `kimun/src`, `--include-tests` | 104.6 ms | 230.7 ms | 2.2× | 11.1 MB | 9.8 MB |
| kaikai sources (`.kai` only) | 727.0 ms | 1,528.7 ms | 2.1× | 13.3 MB | 28.8 MB |
| `minerva` | 45.8 ms | 109.7 ms | 2.4× | 11.4 MB | 10.8 MB |
| `kaikai` repository | 699.3 ms | 2,226.2 ms | 3.2× | 12.5 MB | 61.1 MB |
| `kimun` repository | 96.1 ms | 4,394.5 ms | 46× | 12.1 MB | 261.6 MB |

Out of the 1.5× budget. Where the time goes, measured:

- **The walk cannot prune** (lnds/kaikai#3511): `dir.walk` lists every file, ignored trees included, before the ignore files are applied. The `kimun` repository holds 247,000 files on disk, nearly all in `target/`, and counts 276.
- **The content hash** (lnds/kaikai#3522): FNV-1a costs about 350 instructions per byte, because `bit_xor` is a runtime call and the product on its result is boxed.
- **The lexer**: about 105 ms on `kimun/src`, 10% more than the two-language lexer, built of tuples, records and variants (lnds/kaikai#3504–#3507).
- **The language registry**: each entry builds its `Spec` on demand, because a computed `const` is evaluated at every reference (lnds/kaikai#3524) and a `const` built by record spread does not compile in reasonable time (lnds/kaikai#3525).

## `loc`, lexical, idiomatic, Rust and kaikai only (superseded)

Counts are identical to km's on all three inputs:

| Input | Files | Blank | Comment | Code |
|---|---|---|---|---|
| `kimun/src` | 416 | 7,542 | 7,553 | 67,908 |
| kaikai stdlib | 96 | 2,580 | 5,619 | 12,715 |
| kaikai sources | 5,847 | 35,972 | 53,394 | 253,493 |

| Input | km time | km2 time | ratio | km RSS | km2 RSS | ratio |
|---|---|---|---|---|---|---|
| `kimun/src` | 106.1 ms | 124.6 ms | 1.17× | 11.1 MB | 4.5 MB | 0.41× |
| kaikai stdlib | 32.3 ms | 30.9 ms | 0.96× | 10.8 MB | 4.4 MB | 0.41× |
| kaikai sources | 716.1 ms | 696.9 ms | 0.97× | 13.2 MB | 13.6 MB | 1.03× |

The lexer is written the way kaikai is meant to be written: the state is a variant, a literal a `Delim` record, a step a `Step` record, and the source is split with `string.lines`. Within the 1.5× budget everywhere.

## `loc`, lexical, scalar scan (experiment, reverted)

A rewrite that avoided every aggregate in the hot loop, to measure what kaikai's aggregates cost. It was reverted because it works around kaikai instead of measuring it: km2 is written idiomatically, and a kaikai performance gap is reported upstream and measured again on the release that fixes it. The gaps are lnds/kaikai#3504 (field reads by name in patterns), #3505 (non-escaping aggregates allocated), #3506 (boxed `Int` fields), #3507 (`Option` on the native backend) and #3508 (`string.lines`).

| Input | km time | km2 time | ratio | km RSS | km2 RSS | ratio |
|---|---|---|---|---|---|---|
| `kimun/src` | 107.5 ms | 67.6 ms | 0.63× | 11.2 MB | 3.9 MB | 0.35× |
| kaikai stdlib | 30.6 ms | 18.4 ms | 0.60× | 10.7 MB | 3.8 MB | 0.36× |
| kaikai sources | 695.3 ms | 469.7 ms | 0.68× | 13.2 MB | 10.8 MB | 0.82× |

Instructions retired (`/usr/bin/time -l`, one run), which move less than wall time between sessions:

| Input | km | km2, idiomatic | km2, scalar scan |
|---|---|---|---|
| `kimun/src` | 1.16 G | 1.60 G | 0.76 G |
| kaikai sources | 8.17 G | 8.92 G | 4.77 G |

The scan reads the source in place by offset instead of splitting it into lines, and its state functions tail-call each other with scalar parameters only: the state is an `Int` code, a literal is an `Int` (`PLAIN`, `TRIPLE`, `RAW + hashes`), and a line's kind is the highest rank seen (blank < comment < code). No tuple, record, `Option` or variant is built per byte or per line. Grouping what is fixed per file (spec, text, length) into one record, read by field in the loop, cost 12% on `kimun/src` (0.68 G with every value a parameter).

Most of the memory difference is fixed cost: km's binary is 15.5 MB and links Security, CoreFoundation, SystemConfiguration, libz and iconv for its other commands; km2's is 0.76 MB and links libSystem only. What grows with the input grows faster in km2 (the walk holds every path), so the gap narrows on large inputs and will narrow further as km2 gains commands.

### What an aggregate costs in kaikai 0.196.3

Measured with 10-million-iteration tail-recursive loops, native backend, instructions per iteration:

| Loop body | instructions |
|---|---|
| `Int` arithmetic only | 13 |
| return `Option[Int]` and `??` it | 191 to 247 |
| return a variant and match it | 274 |
| return a two-field record and read both fields | 933 |
| return a pair and destructure it | 1,055 |
| destructure a pair literal in place, `let (a, b) = (x, y)` | 1,054 |

Every aggregate is heap-allocated and reference-counted, even when it never escapes the expression (#3505). Pair destructuring reads each field through `kaix_field(rec, name)`, a lookup by name with `strcmp` (#3504). An `Int` read back from an aggregate is boxed, and arithmetic on it goes through the generic `kaix_add` (#3506). Mutual tail calls are eliminated on both backends: a 100-million-step ping-pong runs in constant memory.

## How the idiomatic lexer got within budget

A version that built a step record per byte ran 6× km; skipping plain bytes without allocating brought it to 1.13×.

## `loc` over tree-sitter (discarded)

The first spike classified lines from the syntax tree. Counts matched km after the same fixes, but time did not: 1,104 ms on `kimun/src` (5×). The tree-sitter parse alone took ~470 ms single-threaded and the flattening ~200 ms, with ~430 ms more of FFI calls per node on the kaikai side. Line classification does not need a tree; tree-sitter stays for the metrics that need structure. The shim, its query support and its tests remain for those.
