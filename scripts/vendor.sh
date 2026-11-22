#!/bin/sh
# Fetches the pinned tree-sitter core and grammars into vendor/.
# The only way vendor/ changes; pins live in vendor/VERSIONS.
# KM2_GRAMMAR_<NAME>=<dir> takes a grammar from a local checkout instead.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fetch() {
  name=$1 repo=$2 ref=$3
  local_var=$(printf 'KM2_GRAMMAR_%s' "$name" | tr 'a-z-' 'A-Z_')
  local_dir=$(eval "printf '%s' \"\${$local_var:-}\"")
  if [ -n "$local_dir" ]; then
    printf '%s\n' "$local_dir"
  else
    git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$ref" "$repo" "$work/$name"
    printf '%s\n' "$work/$name"
  fi
}

grep -v '^#' "$root/vendor/VERSIONS" | while read -r name repo ref; do
  [ -n "$name" ] || continue
  src=$(fetch "$name" "$repo" "$ref")
  if [ "$name" = tree-sitter ]; then
    dest="$root/vendor/tree-sitter"
    rm -rf "$dest"
    mkdir -p "$dest/lib"
    cp -R "$src/lib/src" "$src/lib/include" "$dest/lib/"
    cp "$src/LICENSE" "$dest/"
  else
    dest="$root/vendor/grammars/$name"
    rm -rf "$dest"
    mkdir -p "$dest/src"
    cp "$src/src/parser.c" "$dest/src/"
    [ -f "$src/src/scanner.c" ] && cp "$src/src/scanner.c" "$dest/src/"
    cp -R "$src/src/tree_sitter" "$dest/src/"
    cp "$src/LICENSE" "$dest/"
  fi
  commit=$(git -C "$src" rev-parse HEAD 2>/dev/null || echo unknown)
  printf '%-12s %s %s\n' "$name" "$ref" "$commit"
done
