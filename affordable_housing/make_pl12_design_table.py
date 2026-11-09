#!/usr/bin/env python3
"""pl12 design table of record: one column per scenario with a feasible design,
the 12 subsidy rates of its best run (results/pl12_multistart_summary.csv ->
best_source -> run dir subsidies.csv; a local-proof record dir
out/scenarios/pl12__local25_record overrides pl12 when present).
Output: results/pl12_design_table.csv. Run from affordable_housing/."""
import csv, os, sys
base = os.path.dirname(os.path.abspath(__file__)); os.chdir(base)
PREFIX = sys.argv[1] if len(sys.argv) > 1 else "pl12"
ms = list(csv.DictReader(open(f"results/{PREFIX}_multistart_summary.csv")))
KEYS = [("poor", "env_light"), ("poor", "env_medium"), ("poor", "env_deep"), ("poor", "hvac_std"), ("poor", "hvac_upg"),
        ("rich", "env_light"), ("rich", "env_medium"), ("rich", "env_deep"), ("rich", "hvac_std"), ("rich", "hvac_upg"),
        ("landlord_public", "all_non_pv"), ("landlord_private", "all_non_pv")]
def run_dir(r):
    if r["scenario"] == PREFIX and os.path.isdir(f"out/scenarios/{PREFIX}__local25_record"):
        return f"out/scenarios/{PREFIX}__local25_record", "local proof"
    tag = r["best_source"]
    return (f"out/scenarios/{r['scenario']}" if tag == "batch" else f"out/scenarios/{r['scenario']}__{tag}"), tag
cols, table = [], {k: [] for k in KEYS}
meta = {"spending_M": [], "source": [], "E2050": [], "equity": [], "wpb": []}
for r in ms:
    if r["feasible"].lower() != "true": continue
    d, src = run_dir(r)
    rates = {(x["group"], x["measure"]): float(x["rate"]) for x in csv.DictReader(open(f"{d}/subsidies.csv"))}
    cols.append(r["scenario"])
    for k in KEYS: table[k].append(f"{100*rates.get(k, 0.0):.1f}")
    sp = r["best_spending_M"]
    if src == "local proof":
        for x in csv.DictReader(open(f"{d}/scenario_summary.csv")): sp = f"{float(x['spending_M']):.1f}"
    meta["spending_M"].append(sp); meta["source"].append(src)
    for k in ("E2050", "equity", "wpb"): meta[k].append(r[k])
with open(f"results/{PREFIX}_design_table.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["group", "measure"] + cols)
    for k in meta: w.writerow(["(" + k + ")", ""] + meta[k])
    for k in KEYS: w.writerow([k[0], k[1]] + table[k])
print(f"{len(cols)} feasible scenarios -> results/{PREFIX}_design_table.csv")
for k in KEYS:
    print(f"  {k[0]:16s} {k[1]:12s} " + " ".join(f"{v:>6s}" for v in table[k][:8]))
