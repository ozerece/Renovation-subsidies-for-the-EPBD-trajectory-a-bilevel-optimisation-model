#!/bin/bash
########################################################################
# run_pl11_eval.sh — fixed-σ evaluation of a design in a scenario (no search),
# printing spending, feasibility, every milestone with its margin, and the
# 2050 uptake and subsidy by group. Runs in the foreground (1–3 min).
#
# Usage:
#   scripts/run_pl11_eval.sh [--env KEY=VAL ...] <scenario> <design> [tag]
#     design: tag of data/sigma_start_<tag>.csv (record, max, pl10cert, ...),
#             a scenario name whose out/scenarios/<scn>/subsidies.csv is used,
#             or a file with the 12 rates in canonical order.
#     tag:    output tag (default xe_<design>); outputs go to
#             out/scenarios/<scenario>__<tag>/, log to results/cert_logs/eval_<scenario>_<tag>.log
########################################################################
set -u
source "$(dirname "$0")/pl11_common.sh"
EXTRA_ENV=()
while [ $# -gt 0 ]; do
  case "$1" in
    --env) EXTRA_ENV+=("$2"); shift 2;;
    -h|--help) sed -n 2,14p "$0"; exit 0;;
    *) break;;
  esac
done
[ $# -ge 2 ] || { echo "usage: run_pl11_eval.sh <scenario> <design> [tag]" >&2; exit 2; }
SCN="$1"; DESIGN="$2"; TAG="${3:-xe_$(basename "$2" .csv)}"
cd "$MODEL_DIR" || exit 1
SF=$(resolve_sigma "$DESIGN") || exit 1
LOG="$LOG_DIR/eval_${SCN}_${TAG}.log"
env "${EXTRA_ENV[@]}" "$JULIA" --project="$ENV_DIR" "$REPO_ROOT/scripts/eval_sigma_report.jl" "$SCN" "$SF" "$TAG" > "$LOG" 2>&1
rc=$?
grep "^####\|^>>> P4\|ERROR\|Error" "$LOG"
echo "(full log: $LOG; exit $rc)"
exit $rc
