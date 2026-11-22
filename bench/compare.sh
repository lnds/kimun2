#!/bin/sh
# km vs km2 on the same input: median wall time of 10 runs after 2
# warm-ups, and peak RSS from /usr/bin/time -l.
# usage: bench/compare.sh <dir> <km args...> -- <km2 args...>
set -eu
dir=$1; shift
km_args=""; km2_args=""; side=km
for a in "$@"; do
  if [ "$a" = "--" ]; then side=km2; continue; fi
  if [ $side = km ]; then km_args="$km_args $a"; else km2_args="$km2_args $a"; fi
done
km2=$(cd "$(dirname "$0")/.." && pwd)/km2

measure() {
  python3 -I - "$@" <<'PY'
import statistics, subprocess, sys, time
cmd = sys.argv[1:]
for _ in range(2):
    subprocess.run(cmd, stdout=subprocess.DEVNULL, check=True)
runs = []
for _ in range(10):
    t = time.perf_counter()
    subprocess.run(cmd, stdout=subprocess.DEVNULL, check=True)
    runs.append(time.perf_counter() - t)
print(f"{statistics.median(runs) * 1000:8.1f} ms  (min {min(runs) * 1000:.1f}, max {max(runs) * 1000:.1f})")
PY
}
rss() { /usr/bin/time -l "$@" 2>&1 >/dev/null | awk '/maximum resident set size/ {printf "%6.1f MB", $1/1048576}'; }

# shellcheck disable=SC2086
printf 'km  time %s  peak RSS %s\n' "$(measure km $km_args "$dir")" "$(rss km $km_args "$dir")"
# shellcheck disable=SC2086
printf 'km2 time %s  peak RSS %s\n' "$(measure "$km2" $km2_args "$dir")" "$(rss "$km2" $km2_args "$dir")"
