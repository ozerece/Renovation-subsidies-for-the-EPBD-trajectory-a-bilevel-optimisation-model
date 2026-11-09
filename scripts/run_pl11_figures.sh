#!/bin/bash
########################################################################
# run_pl11_figures.sh — run a figure/table script of the model folder.
#
# Usage: scripts/run_pl11_figures.sh <script.py|script.jl> [args...]
#   The script must live in the model folder (affordable_housing/) and be
#   named make_*.py, make_*.jl, table*.jl or s*_summary.jl. Runs in the
#   foreground with cwd = model folder; python is started with -I.
#   Examples: run_pl11_figures.sh make_pl10_figures.py
#             run_pl11_figures.sh make_paper_tables.py
########################################################################
set -u
source "$(dirname "$0")/pl11_common.sh"
[ $# -ge 1 ] || { sed -n 2,11p "$0"; exit 2; }
S="$(basename "$1")"; shift
cd "$MODEL_DIR" || exit 1
case "$S" in
  make_*.py|make_*.jl|table*.jl|s[0-9]_summary.jl) ;;
  *) echo "refusing: $S is not a figure/table script (make_*.py, make_*.jl, table*.jl, s*_summary.jl)" >&2; exit 2;;
esac
[ -f "$S" ] || { echo "no such script in $MODEL_DIR: $S" >&2; exit 2; }
LOG="$LOG_DIR/fig_${S%.*}.log"
case "$S" in
  *.py) python3 -I "$S" "$@" 2>&1 | tee "$LOG" | tail -40;;
  *.jl) "$JULIA" --project="$ENV_DIR" "$S" "$@" 2>&1 | tee "$LOG" | tail -40;;
esac
exit "${PIPESTATUS[0]}"
