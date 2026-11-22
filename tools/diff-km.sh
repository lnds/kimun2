#!/usr/bin/env bash
# Differential test against km: runs `km <args>` and `km2 <args>` and
# compares their output byte for byte.
#
#   tools/diff-km.sh [--km2 PATH] <args...>          whole output
#   tools/diff-km.sh [--km2 PATH] --files <dir> [<loc args...>]
#                                                    `loc --format json` per file,
#                                                    listing the files that differ
#
# Exit status: 0 when every output matches, 1 otherwise.
set -u

KM2=./km2
if [ "${1:-}" = "--km2" ]; then
  KM2=$2
  shift 2
fi

if [ "${1:-}" != "--files" ]; then
  diff <(km "$@" 2>&1; echo "exit $?") <("$KM2" "$@" 2>&1; echo "exit $?") \
    && exit 0
  exit 1
fi

dir=$2
shift 2
status=0
while IFS= read -r -d '' f; do
  a=$(km loc --include-tests --format json "$@" "$f" 2>&1)
  b=$("$KM2" loc --include-tests --format json "$@" "$f" 2>&1)
  if [ "$a" != "$b" ]; then
    echo "DIFF $f"
    status=1
  fi
done < <(find "$dir" -type f -not -path '*/.git/*' -print0 | sort -z)
exit $status
