#!/usr/bin/env bash
# The language corpus: real repositories, two per language, pinned by
# commit in tests/corpus/repos.tsv, where km and km2 are compared.
#
#   tools/corpus.sh fetch [LANGUAGE...]   clone the pinned commits (shallow)
#   tools/corpus.sh run [LANGUAGE...]     `loc --include-tests --format json`
#                                         on each repository, parsed and
#                                         compared, with both run times
#   tools/corpus.sh files REPO [ARGS...]  the same per file, for one
#                                         repository (OWNER/REPO); ARGS go
#                                         to loc, e.g. --include-ext rs
#
# Options, before the command: --km2 PATH (default ./km2).
# Clones live in $KM2_CORPUS (default ~/.cache/km2-corpus); the manifest
# is $KM2_CORPUS_MANIFEST (default tests/corpus/repos.tsv).
# Exit status: 0 when every output matches, 1 otherwise.
set -u

KM2=./km2
if [ "${1:-}" = "--km2" ]; then
  KM2=$2
  shift 2
fi
MANIFEST=${KM2_CORPUS_MANIFEST:-$(dirname "$0")/../tests/corpus/repos.tsv}
CACHE=${KM2_CORPUS:-$HOME/.cache/km2-corpus}

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

# The manifest rows (language, repository, commit) for the languages
# given, or all of them.
rows() {
  tail -n +2 "$MANIFEST" | while IFS=$'\t' read -r lang repo commit _; do
    if [ $# -eq 0 ]; then
      printf '%s\t%s\t%s\n' "$lang" "$repo" "$commit"
    else
      for want in "$@"; do
        [ "$lang" = "$want" ] && printf '%s\t%s\t%s\n' "$lang" "$repo" "$commit"
      done
    fi
  done
}

# Each repository once, with the languages it stands for.
repos() {
  rows "$@" | awk -F'\t' '
    !($2 in langs) { order[++n] = $2; commit[$2] = $3; langs[$2] = $1; next }
    { langs[$2] = langs[$2] ", " $1 }
    END { for (i = 1; i <= n; i++) printf "%s\t%s\t%s\n", order[i], commit[order[i]], langs[order[i]] }'
}

dir_of() { echo "$CACHE/${1/\//__}"; }

fetch_one() {
  local repo=$1 commit=$2 dir
  dir=$(dir_of "$repo")
  if [ "$(git -C "$dir" rev-parse HEAD 2>/dev/null)" = "$commit" ]; then
    return 0
  fi
  rm -rf "$dir" && mkdir -p "$dir" || return 1
  git -C "$dir" init -q \
    && git -C "$dir" remote add origin "https://github.com/$repo.git" \
    && git -C "$dir" fetch -q --depth 1 origin "$commit" \
    && git -C "$dir" checkout -q FETCH_HEAD
}

fetch() {
  local status=0
  while IFS=$'\t' read -r repo commit _; do
    if fetch_one "$repo" "$commit"; then
      echo "ok    $repo"
    else
      echo "FAIL  $repo"
      status=1
    fi
  done < <(repos "$@")
  return $status
}

ms() { python3 -c 'import sys,time; print(int(time.time()*1000))'; }

# The languages whose counts differ between two parsed reports.
differing() {
  jq -rn --argjson a "$1" --argjson b "$2" '
    (($a.languages // []) | map({key: .name, value: .}) | from_entries) as $x
    | (($b.languages // []) | map({key: .name, value: .}) | from_entries) as $y
    | ($x + $y) | keys[] | select($x[.] != $y[.])' 2>/dev/null | paste -sd, -
}

run() {
  local status=0 dir t0 t1 t2 a b
  while IFS=$'\t' read -r repo _ langs; do
    dir=$(dir_of "$repo")
    if [ ! -d "$dir/.git" ]; then
      echo "MISS  $repo (run: tools/corpus.sh fetch)"
      status=1
      continue
    fi
    t0=$(ms)
    a=$(km loc --include-tests --format json "$dir" 2>/dev/null | jq -S .)
    t1=$(ms)
    b=$("$KM2" loc --include-tests --format json "$dir" 2>/dev/null | jq -S .)
    t2=$(ms)
    if [ "$a" = "$b" ]; then
      printf 'SAME  %-45s km %6d ms  km2 %6d ms  (%s)\n' "$repo" $((t1 - t0)) $((t2 - t1)) "$langs"
    else
      printf 'DIFF  %-45s languages: %s\n' "$repo" "$(differing "$a" "$b")"
      status=1
    fi
  done < <(repos "$@")
  return $status
}

files() {
  local repo=${1:-}
  [ -n "$repo" ] || usage
  shift
  bash "$(dirname "$0")/diff-km.sh" --km2 "$KM2" --files "$(dir_of "$repo")" "$@"
}

cmd=${1:-}
[ -n "$cmd" ] || usage
shift
case $cmd in
  fetch) fetch "$@" ;;
  run) run "$@" ;;
  files) files "$@" ;;
  *) usage ;;
esac
