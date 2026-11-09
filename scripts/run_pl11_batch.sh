#!/bin/bash
########################################################################
# run_pl11_batch.sh — launch model searches, detached, with a job limit.
#
# Usage:
#   scripts/run_pl11_batch.sh [--starts tag1,tag2,...] [--par N] [--tag T]
#                             [--env KEY=VAL ...] [--wait] scenario [scenario ...]
#
#   --starts   warm-start designs: tags of data/sigma_start_<tag>.csv, scenario
#              names (their subsidies.csv is converted) or files. Without
#              --starts the model's own candidate list is used (one run per
#              scenario). With k starts, k runs per scenario are launched,
#              output tag "ms_<start>" (as in the pl10 wave).
#   --par N    at most N julia processes at once (default 6; Gurobi uses up to
#              GRB threads each — see gurobi.env in the model folder if present)
#   --tag T    extra output tag prefix (P4_OUT_TAG = T or T_ms_<start>)
#   --env      extra environment for the model (e.g. P4_SEED=7); repeatable
#   --wait     block until all launched runs finish (default: return at once;
#              completion is recorded in results/cert_logs/pl11_done.txt)
#
# Logs: results/cert_logs/run_<scenario>[_<tag>][_ms_<start>].log
# Outputs: out/scenarios/<scenario>[__<outtag>]/
########################################################################
set -u
source "$(dirname "$0")/pl11_common.sh"
STARTS=""; N_PAR=6; TAG=""; WAIT=0; EXTRA_ENV=()
while [ $# -gt 0 ]; do
  case "$1" in
    --starts) STARTS="$2"; shift 2;;
    --par) N_PAR="$2"; shift 2;;
    --tag) TAG="$2"; shift 2;;
    --env) EXTRA_ENV+=("$2"); shift 2;;
    --wait) WAIT=1; shift;;
    -h|--help) sed -n 2,24p "$0"; exit 0;;
    --*) echo "unknown option $1" >&2; exit 2;;
    *) break;;
  esac
done
[ $# -ge 1 ] || { echo "no scenario given" >&2; exit 2; }
cd "$MODEL_DIR" || exit 1

launch_one() {  # scenario start_tag start_file
  local scn="$1" st="$2" sf="$3" outtag="$TAG" label logname
  if [ -n "$st" ]; then outtag="${TAG:+${TAG}_}ms_$st"; fi
  label="${scn}${outtag:+_$outtag}"; logname="$LOG_DIR/run_${label}.log"
  # count julia model processes only (not the detached bash parents, whose
  # command line also contains the model file name)
  while [ "$(ps -eo args | awk -v f="$MODEL_FILE" '$1 ~ /julia$/ && index($0, f) {n++} END {print n+0}')" -ge "$N_PAR" ]; do sleep 20; done
  local envs=("${EXTRA_ENV[@]}")
  [ -n "$outtag" ] && envs+=("P4_OUT_TAG=$outtag")
  [ -n "$sf" ] && envs+=("P4_SIGMA_START=$sf")
  detach "$label" "$logname" env "${envs[@]}" "$JULIA" --project="$ENV_DIR" "$MODEL_FILE" "$scn"
  sleep 5   # let the julia process appear before the next job-limit check (launch race seen 2026-11-06)
}

LAUNCHED=()
for scn in "$@"; do
  if [ -z "$STARTS" ]; then
    launch_one "$scn" "" ""; LAUNCHED+=("$scn${TAG:+_$TAG}")
  else
    IFS=, read -r -a starts <<< "$STARTS"
    for st in "${starts[@]}"; do
      sf=$(resolve_sigma "$st") || exit 1
      launch_one "$scn" "$st" "$sf"; LAUNCHED+=("${scn}_${TAG:+${TAG}_}ms_$st")
    done
  fi
done
echo "${#LAUNCHED[@]} run(s) launched; done-stamps in $DONE_FILE"
if [ "$WAIT" = 1 ]; then
  for l in "${LAUNCHED[@]}"; do
    until grep -q "^done $l " "$DONE_FILE" 2>/dev/null; do sleep 30; done
    grep "^done $l " "$DONE_FILE" | tail -1
  done
fi
