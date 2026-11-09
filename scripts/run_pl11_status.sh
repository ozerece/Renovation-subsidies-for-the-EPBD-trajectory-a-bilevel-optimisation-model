#!/bin/bash
########################################################################
# run_pl11_status.sh — read-only status of detached runs.
#
# Usage: scripts/run_pl11_status.sh [--tail N] [label-substring]
#   Prints running julia model/proof processes (elapsed, CPU), the last
#   done-stamps, and for each matching log the last search phase / result line.
########################################################################
set -u
source "$(dirname "$0")/pl11_common.sh"
N=12; FILT=""
while [ $# -gt 0 ]; do case "$1" in --tail) N="$2"; shift 2;; *) FILT="$1"; shift;; esac; done
cd "$MODEL_DIR" || exit 1
echo "== $(date '+%F %H:%M') running julia processes =="
ps -eo pid,etime,pcpu,args | awk '$4 ~ /julia$/ && /bilevel_model_affordable_housing|enumerate_|eval_sigma_report|test_/ {printf "%s %s %s %s %s\n", $1, $2, $3, $(NF-1), $NF}' \
  | while read -r pid et cpu scr scn; do
      tag=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep '^P4_OUT_TAG=' | cut -d= -f2)
      printf "  pid %s  elapsed %s  cpu %s%%  %s %s  tag=%s\n" "$pid" "$et" "$cpu" "$scr" "$scn" "${tag:-none}"
    done
echo "== last done-stamps ($DONE_FILE) =="
[ -f "$DONE_FILE" ] && tail -n "$N" "$DONE_FILE" | grep -- "$FILT" | sed 's/^/  /'
echo "== latest log lines (results/cert_logs/*${FILT}*.log, newest first) =="
ls -t "$LOG_DIR"/*"$FILT"*.log 2>/dev/null | head -n "$N" | while read -r f; do
  last=$(grep -h "Phase [0-9]\|Round [0-9]\|Found feasible\|No feasible\|Total time\|Upper bound:\|CERTIFIED\|ERROR\|Error\|^#### spending\|VIOLATED\|BINDING" "$f" | tail -2 | tr '\n' '|')
  printf "  %-60s %s\n" "$(basename "$f")" "${last:-(no phase line yet; julia stdout is buffered)}"
done
