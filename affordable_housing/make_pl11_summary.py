#!/usr/bin/env python3
"""pl11 wave summary (2026-11-06 brief). Collects every out/scenarios/pl11*/
scenario_summary.csv (batch run and every __<tag> restart), writes
  results/pl11_summary.csv            one row per run directory
  results/pl11_multistart_summary.csv one row per scenario: best feasible run
                                      (lowest spending), its source tag, and the
                                      max-σ miss per milestone where no run is
                                      feasible (from results/cert_logs/eval_<scn>_xe_max.log)
Run from affordable_housing/ (python3 -I make_pl11_summary.py)."""
import csv, glob, os, re, sys
EQUITY_FLOOR = 0.30   # strict floor applied to every run (D10, 2026-11-07)

base = os.path.dirname(os.path.abspath(__file__))
PREFIX = sys.argv[1] if len(sys.argv) > 1 else "pl11"   # pl12: python3 -I make_pl11_summary.py pl12
rows, header = [], None
for d in sorted(glob.glob(os.path.join(base, f"out/scenarios/{PREFIX}*"))):
    f = os.path.join(d, "scenario_summary.csv")
    if not os.path.exists(f):
        continue
    with open(f) as fh:
        r = list(csv.reader(fh))
    if header is None:
        header = ["run_dir"] + r[0] + ["best_infeasible_sigma_present"]
    rows.append([os.path.basename(d)] + r[1] +
                ["Y" if os.path.exists(os.path.join(d, "best_infeasible_sigma.csv")) else ""])

out = os.path.join(base, f"results/{PREFIX}_summary.csv")
with open(out, "w", newline="") as fh:
    w = csv.writer(fh); w.writerow(header); w.writerows(rows)
print(f"{len(rows)} run directories -> {out}")

# best per scenario
ih = {h: i for i, h in enumerate(header)}
best = {}
for r in rows:
    run_dir = r[0]
    scn = run_dir.split("__")[0]
    tag = run_dir.split("__", 1)[1] if "__" in run_dir else "batch"
    feas = r[ih["feasible"]].strip().lower() == "true"
    # 2026-11-07 (D10): the equity floor is strict. Runs written before the model change can carry
    # feasible=true with equity down to 0.299 (old tolerance 0.001); treat them as infeasible here.
    # 2026-11-09: the review scenarios rev12_eq20 / rev12_eq40 carry their own floor (0.20 / 0.40); rev12_eq00 has none
    floor = 0.20 if scn.endswith("_eq20") else 0.40 if scn.endswith("_eq40") else None if scn.endswith("_eq00") else EQUITY_FLOOR
    if feas and floor is not None and "equity" in ih and "equity_spending_floor" in ih and r[ih["equity_spending_floor"]].strip().lower() == "true":
        eq = r[ih["equity"]].strip()
        if eq not in ("", "NaN", "nan") and float(eq) < floor - 1e-6: feas = False
    sp = float(r[ih["spending_M"]]) if r[ih["spending_M"]] not in ("", "NaN", "Inf") else float("inf")
    b = best.setdefault(scn, {"scenario": scn, "feasible": False, "best_spending_M": "", "best_source": "",
                               "E2050": "", "equity": "", "wpb": "", "n_runs": 0, "n_feasible": 0,
                               "miss_2030": "", "miss_2035": "", "miss_2040": "", "miss_2050": "", "max_sigma_eval": ""})
    b["n_runs"] += 1
    if feas:
        b["n_feasible"] += 1
        if not b["feasible"] or sp < float(b["best_spending_M"]):
            b.update(feasible=True, best_spending_M=f"{sp:.1f}", best_source=tag,
                     E2050=r[ih["E2050"]], equity=r[ih["equity"]], wpb=r[ih["wpb"]])

# max-sigma misses for scenarios without a feasible run
for scn, b in best.items():
    log = os.path.join(base, f"results/cert_logs/eval_{scn}_xe_max.log")
    if not os.path.exists(log):
        continue
    txt = open(log, errors="replace").read()
    for yr in (2030, 2035, 2040, 2050):
        m = re.search(rf"####\s+{yr}: E=\s*([\d.]+) target=\s*([\d.]+) margin=\s*([+-]?[\d.]+)\s+(\w+)", txt)
        if m:
            b[f"miss_{yr}"] = f"{-float(m.group(3)):.2f}" if m.group(4) == "VIOLATED" else "ok"
    b["max_sigma_eval"] = "Y"

cols = ["scenario", "feasible", "best_spending_M", "best_source", "E2050", "equity", "wpb",
        "n_runs", "n_feasible", "max_sigma_eval", "miss_2030", "miss_2035", "miss_2040", "miss_2050"]
out2 = os.path.join(base, f"results/{PREFIX}_multistart_summary.csv")
with open(out2, "w", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=cols); w.writeheader()
    for scn in sorted(best):
        w.writerow({k: best[scn][k] for k in cols})
print(f"{len(best)} scenarios -> {out2}")
for scn in sorted(best):
    b = best[scn]
    if b["feasible"]:
        print(f"  {scn:24s} FEASIBLE  best {float(b['best_spending_M']):10.1f} M  ({b['best_source']}, {b['n_feasible']}/{b['n_runs']} runs feasible)")
    else:
        miss = " ".join(f"{yr}:{b[f'miss_{yr}']}" for yr in (2030, 2035, 2040, 2050) if b[f"miss_{yr}"])
        print(f"  {scn:24s} no feasible design in {b['n_runs']} runs; max-σ: {miss or 'not evaluated'}")
