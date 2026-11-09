#!/bin/bash
########################################################################
# run_pl12_outcomes.sh — outcome measures for every feasible pl12 scenario
# at its design of record (results/pl12_multistart_summary.csv; the local-proof
# record dir overrides the standard run when present). One julia process per
# scenario (make_pl12_outcomes.jl), ≤ PAR in parallel, 8 Gurobi threads each.
# Output: results/pl12_outcome_measures.csv
# Usage: scripts/run_pl12_outcomes.sh [prefix]
########################################################################
set -u
source "$(dirname "$0")/pl11_common.sh"
export P4_GRB_THREADS="${PL11_GRB_THREADS:-8}"
PAR="${PL11_PAR:-5}"
PREFIX="${1:-pl12}"
cd "$MODEL_DIR" || exit 1
mkdir -p results/_scratch/outcomes_$PREFIX
python3 -I - "$PREFIX" <<'PY' > results/_scratch/outcomes_$PREFIX/jobs.txt
import csv, os, sys
p = sys.argv[1]
for r in csv.DictReader(open(f"results/{p}_multistart_summary.csv")):
    if r["feasible"].lower() != "true": continue
    s = r["scenario"]; tag = r["best_source"]
    d = f"out/scenarios/{s}" if tag == "batch" else f"out/scenarios/{s}__{tag}"
    if s == p and os.path.isdir(f"out/scenarios/{p}__local25_record"): d = f"out/scenarios/{p}__local25_record"
    print(s, f"{d}/subsidies.csv")
PY
N=$(wc -l < results/_scratch/outcomes_$PREFIX/jobs.txt); echo "$N feasible scenarios"
xargs -P "$PAR" -L 1 bash -c 'scn=$0; sig=$1; '"$JULIA"' --project='"$ENV_DIR"' make_pl12_outcomes.jl $scn $sig results/_scratch/outcomes_'"$PREFIX"'/$scn.csv > results/_scratch/outcomes_'"$PREFIX"'/$scn.log 2>&1; grep "^####" results/_scratch/outcomes_'"$PREFIX"'/$scn.log || echo "FAILED $scn"' < results/_scratch/outcomes_$PREFIX/jobs.txt
python3 -I - "$PREFIX" <<'PY'
import csv, glob, sys
p = sys.argv[1]; rows = []; hdr = None
for f in sorted(glob.glob(f"results/_scratch/outcomes_{p}/*.csv")):
    r = list(csv.reader(open(f)))
    if len(r) < 2: continue
    hdr = hdr or r[0]; rows.append(r[1])
with open(f"results/{p}_outcome_measures.csv", "w", newline="") as fh:
    w = csv.writer(fh); w.writerow(hdr); w.writerows(rows)
print(f"{len(rows)} rows -> results/{p}_outcome_measures.csv")
PY
