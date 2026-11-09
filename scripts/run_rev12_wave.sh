#!/bin/bash
########################################################################
# run_rev12_wave.sh — review follow-ups of 2026-11-08 (REVIEW_SUMMARY §5: R1, R4, R5, R6).
# Stage 1: searches. New scenarios rev12_no2030, rev12_2050only, rev12_eq00/20/40 and the
#          repaired pl12_pubpoor from the model's candidate list AND warm-started from the
#          pl12 record design (data/sigma_start_rec25.csv, tag ms_rec25); R5 re-searches of
#          pl12_envcap_p05, pl12_hpcost_lo, pl12_hpcost_hi from the record design.
# Stage 2: max-σ evaluation (xe_max) of every new scenario without a feasible run.
# Stage 3: local proofs (enumerate_local.jl, ±10 pp, 2.5-pp steps) around the cheapest
#          feasible design of rev12_no2030, rev12_2050only, rev12_eq00 and the three R5
#          scenarios (skipped when the best design costs < 1 M EUR), one at a time.
# Stage 4: summaries: make_pl11_summary.py pl12 (updates the pl12 tables with the new runs)
#          and make_pl11_summary.py rev12.
# Run detached: setsid nohup scripts/run_rev12_wave.sh &   Progress: results/cert_logs/rev12_wave.log
########################################################################
set -u
source "$(dirname "$0")/pl11_common.sh"
export P4_GRB_THREADS="${PL11_GRB_THREADS:-8}"
PAR="${PL11_PAR:-6}"
WLOG="$LOG_DIR/rev12_wave.log"
NEW=(rev12_no2030 rev12_2050only rev12_eq00 rev12_eq20 rev12_eq40 pl12_pubpoor)
R5=(pl12_envcap_p05 pl12_hpcost_lo pl12_hpcost_hi)
PROOF=(rev12_no2030 rev12_2050only rev12_eq00 pl12_envcap_p05 pl12_hpcost_lo pl12_hpcost_hi)
cd "$MODEL_DIR" || exit 1
echo "=== rev12 wave started $(date) (par=$PAR, threads=$P4_GRB_THREADS) ===" | tee -a "$WLOG"
"$REPO_ROOT/scripts/run_pl11_batch.sh" --par "$PAR" --wait "${NEW[@]}" >> "$WLOG" 2>&1
"$REPO_ROOT/scripts/run_pl11_batch.sh" --par "$PAR" --starts rec25 --wait "${NEW[@]}" "${R5[@]}" >> "$WLOG" 2>&1
# the --wait of run_pl11_batch.sh returns per label; make sure no model process is left
while [ "$(ps -eo args | awk -v f="$MODEL_FILE" '$1 ~ /julia$/ && index($0, f) {n++} END {print n+0}')" -gt 0 ]; do sleep 20; done
echo "--- stage 1 (searches) done $(date) ---" | tee -a "$WLOG"

best_dir () {  # best_dir <scn> -> prints "<dir> <spending_M>" of the cheapest strictly feasible run, or nothing
  python3 -I - "$1" <<'PY'
import csv, glob, sys
s = sys.argv[1]
floor = {"rev12_eq00": None, "rev12_eq20": 0.20, "rev12_eq40": 0.40}.get(s, 0.30)
best = None
for f in glob.glob(f"out/scenarios/{s}/scenario_summary.csv") + glob.glob(f"out/scenarios/{s}__ms_*/scenario_summary.csv") + glob.glob(f"out/scenarios/{s}__strict_ms_*/scenario_summary.csv"):
    for r in csv.DictReader(open(f)):
        if r.get("feasible", "").strip().lower() != "true": continue
        eq = r.get("equity", "")
        if floor is not None and eq not in ("", "NaN", "nan") and float(eq) < floor - 1e-6: continue
        sp = float(r["spending_M"])
        if best is None or sp < best[1]: best = (f.rsplit("/", 1)[0], sp)
if best: print(best[0], f"{best[1]:.1f}")
PY
}

for s in "${NEW[@]}"; do
  if [ -z "$(best_dir "$s")" ]; then
    echo "  max-σ evaluation for $s (no feasible run)" | tee -a "$WLOG"
    "$REPO_ROOT/scripts/run_pl11_eval.sh" "$s" max xe_max >> "$WLOG" 2>&1
  fi
done
echo "--- stage 2 (max-sigma evaluations) done $(date) ---" | tee -a "$WLOG"

for s in "${PROOF[@]}"; do
  read -r d sp <<< "$(best_dir "$s")"
  if [ -z "${d:-}" ]; then echo "  proof $s skipped: no feasible design" | tee -a "$WLOG"; continue; fi
  if awk -v v="$sp" 'BEGIN { exit (v < 1.0) ? 0 : 1 }'; then echo "  proof $s skipped: best design costs $sp M EUR (zero)" | tee -a "$WLOG"; continue; fi
  [ -f "out/scenarios/$s/subsidies.csv" ] || { echo "  proof $s skipped: no batch dir" | tee -a "$WLOG"; continue; }
  cp "$d/subsidies.csv" "out/scenarios/$s/subsidies_local_center.csv"
  n0=$(grep -c "^done proof_local_$s " "$DONE_FILE" 2>/dev/null || true)
  echo "  proof $s around $d ($sp M EUR) started $(date +%H:%M)" | tee -a "$WLOG"
  "$REPO_ROOT/scripts/run_pl11_local_proof.sh" local "$s" >> "$WLOG" 2>&1
  until [ "$(grep -c "^done proof_local_$s " "$DONE_FILE" 2>/dev/null || true)" -gt "$n0" ]; do sleep 60; done
  grep "Optimal spending\|NO feasible policy\|local optimum is" "$LOG_DIR/proof_local_$s.log" | tee -a "$WLOG"
done
echo "--- stage 3 (proofs) done $(date) ---" | tee -a "$WLOG"
python3 -I make_pl11_summary.py pl12 >> "$WLOG" 2>&1
python3 -I make_pl11_summary.py rev12 >> "$WLOG" 2>&1
echo "=== rev12 wave finished $(date) ===" | tee -a "$WLOG"
echo "done rev12_wave 0 $(date '+%F %H:%M')" >> "$DONE_FILE"
