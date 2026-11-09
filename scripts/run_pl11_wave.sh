#!/bin/bash
########################################################################
# run_pl11_wave.sh — the pre-registered pl11 wave (CHANGELOG 2026-11-06).
# Stage 1: 38 scenarios × 4 starts (model candidates, record, pl10cert,
#          hpheavy), detached, ≤ PAR parallel, 8 Gurobi threads each.
# Stage 2: max-σ evaluation (eval tag xe_max) of every scenario without a
#          feasible run.
# Stage 3: summary tables (make_pl11_summary.py).
# Runs in the foreground and blocks until all stages are done; start it
# detached if the session may end:  setsid nohup scripts/run_pl11_wave.sh &
# Progress: results/cert_logs/pl11_wave.log and pl11_done.txt
########################################################################
set -u
source "$(dirname "$0")/pl11_common.sh"
export P4_GRB_THREADS="${PL11_GRB_THREADS:-8}"
PAR="${PL11_PAR:-6}"
WLOG="$LOG_DIR/pl11_wave.log"
SCNS=(pl11 pl11_afford
      pl11_s10 pl11_s12 pl11_s13 pl11_s14 pl11_s15 pl11_s20 pl11_s25 pl11_s30 pl11_s40
      pl11_rule_none pl11_rule_cap3 pl11_rule_perm pl11_rule_pl_gross
      pl11_w05 pl11_w10 pl11_noeed pl11_priv16 pl11_pubpoor
      pl11_ban2040 pl11_r12 pl11_split pl11_kprb pl11_hvac6 pl11_co2half pl11_peffrozen
      pl11_elec_p20 pl11_elec_m20 pl11_woodpef pl11_traj_linear pl11_traj_soft
      pl11_envcap_m20 pl11_envcap_p20 pl11_invertprices
      pl11_hpcost_lo pl11_hpcost_hi pl11_sav4666 pl11_inclusive pl11_learn0)
echo "=== pl11 wave started $(date) (${#SCNS[@]} scenarios, par=$PAR, threads=$P4_GRB_THREADS) ===" | tee -a "$WLOG"
cd "$MODEL_DIR" || exit 1

# ---- stage 1: searches ----
"$REPO_ROOT/scripts/run_pl11_batch.sh" --par "$PAR" --wait "${SCNS[@]}" >> "$WLOG" 2>&1
"$REPO_ROOT/scripts/run_pl11_batch.sh" --par "$PAR" --starts record,pl10cert,hpheavy --wait "${SCNS[@]}" >> "$WLOG" 2>&1
echo "--- stage 1 (searches) done $(date) ---" | tee -a "$WLOG"

# ---- stage 2: max-sigma evaluation where nothing feasible was found ----
for s in "${SCNS[@]}"; do
  # feasibility from scenario_summary.csv (descr contains commas: use the csv module)
  feas=$(python3 -I - "$s" <<'PY'
import csv, glob, sys
s = sys.argv[1]; feas = 0
for f in glob.glob(f"out/scenarios/{s}/scenario_summary.csv") + glob.glob(f"out/scenarios/{s}__ms_*/scenario_summary.csv"):
    for r in csv.DictReader(open(f)):
        if r.get("feasible", "").strip().lower() == "true": feas = 1
print(feas)
PY
)
  if [ "$feas" = 0 ]; then
    echo "  max-σ evaluation for $s (no feasible run)" | tee -a "$WLOG"
    "$REPO_ROOT/scripts/run_pl11_eval.sh" "$s" max xe_max >> "$WLOG" 2>&1
  fi
done
echo "--- stage 2 (max-sigma evaluations) done $(date) ---" | tee -a "$WLOG"

# ---- stage 3: summaries ----
python3 -I make_pl11_summary.py | tee -a "$WLOG"
echo "=== pl11 wave finished $(date) ===" | tee -a "$WLOG"
echo "done pl11_wave 0 $(date '+%F %H:%M')" >> "$DONE_FILE"
