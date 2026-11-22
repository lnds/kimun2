#!/usr/bin/env bash
# Runs tools/diff-km.sh over a list of argument sets, one per line on
# stdin, and prints SAME or DIFF for each; the -v timing line is ignored.
KM2=${1:-./km2}
status=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  read -r -a args <<< "$line"
  if diff <(km "${args[@]}" 2>&1 | grep -v '^T=') <("$KM2" "${args[@]}" 2>&1 | grep -v '^T=') > /dev/null; then
    echo "SAME  $line"
  else
    echo "DIFF  $line"
    status=1
  fi
done
exit $status
