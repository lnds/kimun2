---
paths:
  - "bench/**"
  - "c/**"
  - "src/km2/syntax.kai"
  - "src/km2/files.kai"
  - "src/km2/metrics/**"
---

# Performance and memory

## The budget

On the same inputs, km2 stays within **1.5× of `km`** in wall time and in
peak resident memory. Being faster is not a goal yet; being similar is.
A change that takes a benchmark out of the budget does not merge until it
is explained and recorded in `bench/results.md`.

## Measuring

- `bench/compare.sh <command> <dir>` runs `km <command>` and
  `km2 <command>` on the same directory: `hyperfine` (warm, at least 10
  runs) for time, `/usr/bin/time -l` for peak RSS.
- Inputs are real repositories, not fixtures: `../kimun/src`,
  `../kaikai/stdlib`, and one large TypeScript repository. Record the
  commit of each input with the numbers.
- `bench/results.md` keeps one row per command per milestone: machine,
  `km` and `km2` versions, time and RSS for both, and the ratio.
- Claims about speed come with these numbers. "Should be faster" is not
  a measurement.

## What keeps km2 within budget

- **One parse per file.** Every metric a command computes reads the same
  tree; `report` and `score` parse each file once for all their metrics.
- **Trees are short-lived.** A file's tree is freed as soon as its
  metrics are computed; only results are retained.
- **Queries are compiled once** per language per run.
- **Parallelism is bounded.** Workers raise peak memory; their number is
  capped, and RSS is measured with the cap in place.
- Allocation in the per-node path of the shim is a bug: flattening fills
  arrays sized once from the node count.
