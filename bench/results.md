# Benchmarks: km vs km2

Measured with `bench/compare.sh`: median wall time of 10 runs after 2 warm-ups, and peak RSS from `/usr/bin/time -l`. `km` runs with `--include-tests` (and `--include-ext` where the input holds other languages), because km2 counts every file so far.

Machine: Apple M3 Max, 16 cores. km 0.49.0. km2 0.1.0, single-threaded. Inputs: `kimun/src` at `ebba255` (Rust, 416 files, 2.7 MB), the kaikai 0.196.3 stdlib (96 files), and kaikai 0.196.3 `stdlib`, `examples`, `tests` and `stage2` (6,255 files, 5,847 distinct, intentional syntax errors included).

## `loc`, complete, on kaikai 0.198.0 (current)

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
