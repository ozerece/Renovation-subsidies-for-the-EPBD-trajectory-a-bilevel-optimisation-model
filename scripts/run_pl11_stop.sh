#!/bin/bash
########################################################################
# run_pl11_stop.sh — stop detached model runs started by the wrappers.
#
# Usage: scripts/run_pl11_stop.sh <pattern|--all> [--force]
#   pattern: substring of the julia command line (scenario name, P4_OUT_TAG
#            value, "enumerate_local", ...). Only julia processes running the
#            model, the proofs or the eval report are considered.
#   --all:   every such process.
#   --force: SIGKILL after 10 s if still alive.
########################################################################
set -u
source "$(dirname "$0")/pl11_common.sh"
[ $# -ge 1 ] || { sed -n 2,11p "$0"; exit 2; }
PAT="$1"; FORCE="${2:-}"
list() {
  # julia processes only (the wrappers' bash parents stay alive and write the
  # done-stamp); the output tag (P4_OUT_TAG) lives in the environment, so it
  # is appended to each line for matching
  ps -eo pid,args | awk '$2 ~ /julia$/ && /bilevel_model_affordable_housing|enumerate_|eval_sigma_report/' \
    | while read -r pid rest; do
        tag=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep '^P4_OUT_TAG=' | cut -d= -f2)
        echo "$pid $rest tag=${tag:-none}"
      done \
    | { if [ "$PAT" = "--all" ]; then cat; else grep -- "$PAT"; fi; }
}
PIDS=$(list | awk '{print $1}')
[ -n "$PIDS" ] || { echo "no matching julia process"; exit 0; }
list | awk '{print "stopping pid", $1, $(NF-1), $NF}'
kill $PIDS
if [ "$FORCE" = "--force" ]; then sleep 10; for p in $PIDS; do kill -0 "$p" 2>/dev/null && kill -9 "$p"; done; fi
sleep 1; echo "remaining: $(list | wc -l)"
