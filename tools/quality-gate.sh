#!/bin/sh
# Quality gate per .claude/rules/kaikai-code.md, run with the tool given:
# `km` (the reference) or `./km2` (dogfooding). A command the tool does not
# implement yet is skipped with a SKIP line, so the km2 gate grows as km2 does.
# FAIL lines break the build; WARN lines flag files drifting from the target.
set -eu

tool="${1:-km}"
command -v jq >/dev/null || { echo "quality-gate: jq not found" >&2; exit 2; }
command -v "$tool" >/dev/null || [ -x "$tool" ] || { echo "quality-gate: $tool not found" >&2; exit 2; }

SCORE_FLOOR=80        # B
SCORE_TARGET=87       # A-
LOC_CAP=800
LOC_TARGET=400
COGCOM_FN_CAP=25
COGCOM_AVG_TARGET=5

has() { "$tool" "$1" --help >/dev/null 2>&1; }

scope() {
  "$tool" "$1" . --include-ext kai --include-ext c --include-ext h \
    --exclude-dir vendor --exclude-dir tests --exclude-dir fixtures --format json
}

run() {
  if has "$1"; then scope "$1" | jq -r "$2"; else echo "SKIP  $tool $1: not implemented"; fi
}

findings=$(
  run score "
    .needs_attention[]
    | if .score < $SCORE_FLOOR then \"FAIL  \(.path)  score \(.grade) below B\"
      elif .score < $SCORE_TARGET then \"WARN  \(.path)  score \(.grade) below A-\"
      else empty end"

  run indent "
    .[]
    | if .code_lines > $LOC_CAP then \"FAIL  \(.path)  \(.code_lines) LOC above $LOC_CAP\"
      elif .code_lines > $LOC_TARGET then \"WARN  \(.path)  \(.code_lines) LOC above $LOC_TARGET\"
      else empty end"

  run cogcom "
    .[] | .path as \$p
    | (.functions[] | select(.complexity > $COGCOM_FN_CAP)
       | \"FAIL  \(\$p)  fn \(.name) cognitive complexity \(.complexity) above $COGCOM_FN_CAP\"),
      (select(.avg_complexity > $COGCOM_AVG_TARGET)
       | \"WARN  \(\$p)  average cognitive complexity \(.avg_complexity) above $COGCOM_AVG_TARGET\")"

  run dups "
    .metrics.duplicate_groups
    | if . > 0 then \"FAIL  (project)  \(.) duplicate group(s)\" else empty end"
)

[ -n "$findings" ] && printf '%s\n' "$findings"
if printf '%s\n' "$findings" | grep -q '^FAIL'; then
  echo "quality-gate ($tool): failed"
  exit 1
fi
echo "quality-gate ($tool): ok"
