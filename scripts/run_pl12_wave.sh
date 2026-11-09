#!/bin/bash
########################################################################
# run_pl12_wave.sh — the pre-registered pl12 wave (CHANGELOG 2026-11-06).
# Stage 1: scenarios × 4 starts (model candidates, record, pl10cert, hpheavy),
#          detached, ≤ PAR parallel, 8 Gurobi threads each.
# Stage 2: max-σ evaluation (tag xe_max) of every scenario without a feasible run.
# Stage 3: summary tables (make_pl11_summary.py pl12).
# Blocks until done; run detached: setsid nohup scripts/run_pl12_wave.sh &
# Progress: results/cert_logs/pl12_wave.log and pl11_done.txt
########################################################################
set -u
source "$(dirname "$0")/pl11_common.sh"
export P4_GRB_THREADS="${PL11_GRB_THREADS:-8}"
PAR="${PL11_PAR:-6}"
WLOG="$LOG_DIR/pl12_wave.log"
SCNS=(pl12 pl12_afford
      pl12_s10 pl12_s12 pl12_s13 pl12_s14 pl12_s15 pl12_s20 pl12_s25 pl12_s30 pl12_s40
      pl12_rule_none pl12_rule_cap3 pl12_rule_perm pl12_rule_pl_gross
      pl12_w05 pl12_w10 pl12_noeed pl12_priv16 pl12_pubpoor
      pl12_ban2040 pl12_r12 pl12_split pl12_kprb pl12_hvac6 pl12_co2half pl12_peffrozen
      pl12_elec_p20 pl12_elec_m20 pl12_woodpef pl12_traj_linear pl12_traj_soft
      pl12_envcap_m20 pl12_envcap_p20 pl12_invertprices
      pl12_hpcost_lo pl12_hpcost_hi pl12_sav4666 pl12_inclusive pl12_learn0
      pl12_envcap_p05 pl12_envcap_p10 pl12_envcap_p30 pl12_envcap_p50)
echo "=== pl12 wave started $(date) (${#SCNS[@]} scenarios, par=$PAR, threads=$P4_GRB_THREADS) ===" | tee -a "$WLOG"
cd "$MODEL_DIR" || exit 1
"$REPO_ROOT/scripts/run_pl11_batch.sh" --par "$PAR" --wait "${SCNS[@]}" >> "$WLOG" 2>&1
"$REPO_ROOT/scripts/run_pl11_batch.sh" --par "$PAR" --starts record,pl10cert,hpheavy --wait "${SCNS[@]}" >> "$WLOG" 2>&1
echo "--- stage 1 (searches) done $(date) ---" | tee -a "$WLOG"
for s in "${SCNS[@]}"; do
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
python3 -I make_pl11_summary.py pl12 | tee -a "$WLOG"
echo "=== pl12 wave finished $(date) ===" | tee -a "$WLOG"
echo "done pl12_wave 0 $(date '+%F %H:%M')" >> "$DONE_FILE"
