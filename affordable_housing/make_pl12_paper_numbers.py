#!/usr/bin/env python3
"""Paper numbers sheet for pl12: results/paper/pl12_paper_numbers.csv
(name, value, unit, status, source_file). Every number the paper quotes is read from
the files of record; nothing is typed in by hand. Run from affordable_housing/."""
import csv, os
base = os.path.dirname(os.path.abspath(__file__)); os.chdir(base)
REC = "out/scenarios/pl12__local25_record"
OUT = "results/paper/pl12_paper_numbers.csv"
CERT = "certified local optimum (±10 pp box, 2.5-pp grid, strict 30 % floor)"
EVAL = "fixed-σ evaluation at the record design"
rows = []
def add(name, value, unit, status, src):
    rows.append((name, value if isinstance(value, str) else f"{value:.6g}", unit, status, src))
rd = lambda f: list(csv.DictReader(open(f)))

# ---------------------------------------------------------------- standard run
ss = rd(f"{REC}/scenario_summary.csv")[0]
add("standard_spending_discounted_2026", float(ss["spending_M"]), "M EUR (discounted to 2026, 2026–2050)", CERT, f"{REC}/scenario_summary.csv")
add("standard_equity_share_low_income", 100 * float(ss["equity"]), "% of spending (floor 30 %, binding)", CERT, f"{REC}/scenario_summary.csv")
add("standard_wpb_share", 100 * float(ss["wpb"]), "% of the energy savings 2026–2060 (delivered energy, floor-area weighted, vs the 2026 state) from worst-performing buildings; NOT a spending share (see standard_spending_share_wpb_buildings) [label corrected 2026-11-08]", CERT, f"{REC}/scenario_summary.csv")
sba = rd(f"{REC}/subsidy_by_archetype.csv")
add("standard_spending_nominal", sum(float(r["subsidy_nominal_eur"]) for r in sba) / 1e6, "M EUR (undiscounted, 2026–2050)", EVAL, f"{REC}/subsidy_by_archetype.csv")
inv = sum(float(r["investment_eur"]) for r in rd(f"{REC}/measure_totals.csv"))
add("standard_total_investment_nominal", inv / 1e6, "M EUR (all renovation investment 2026–2050, households + state)", EVAL, f"{REC}/measure_totals.csv")
# design
sub = {(r["group"], r["measure"]): float(r["rate"]) for r in rd(f"{REC}/subsidies.csv")}
MEASURE_NAME = {"env_light": "envelope_light", "env_medium": "envelope_medium", "env_deep": "envelope_deep",
                "hvac_std": "heat_pump", "hvac_upg": "district_heat", "all_non_pv": "all_measures"}   # 2026-11-08: readable names (hvac_std = heat pump, hvac_upg = district-heat connection)
for (g, m), v in sub.items():
    if m == "pv": continue
    add(f"design_rate_{g}_{MEASURE_NAME.get(m, m)}", 100 * v, "% of investment cost", CERT, f"{REC}/subsidies.csv")
# milestones
targets = {2030: 222.12, 2035: 211.55, 2040: 158.66, 2050: 108.42}
path = {int(r["year"]): float(r["Eavg"]) for r in rd(f"{REC}/energy_path.csv")}
for y in (2020, 2026, 2030, 2035, 2040, 2050):
    add(f"standard_primary_energy_{y}", path[y], "kWh/(m²·yr), stock average", EVAL, f"{REC}/energy_path.csv")
    if y in targets:
        add(f"epbd_target_{y}", targets[y], "kWh/(m²·yr) (−16/−20/−40/−59 % vs 2020)", "input (relative EPBD trajectory)", "bilevel_model_affordable_housing.jl")
        add(f"standard_slack_{y}", targets[y] - path[y], "kWh/(m²·yr) (target − value; + = met)", EVAL, f"{REC}/energy_path.csv")
# spending by group (discounted and nominal) and by measure
def grp(a, inc):
    if "_rent_pub" in a: return "tenant_public"
    if "_rent_priv" in a: return "tenant_private"
    return ("owner_low_wpb" if "_wpb_" in a else "owner_low_rest") if inc == "poor" else ("owner_high_wpb" if "_wpb_" in a else "owner_high_rest")
GROUPS = ("owner_low_wpb", "owner_low_rest", "owner_high_wpb", "owner_high_rest", "tenant_public", "tenant_private")
gd = {g: 0.0 for g in GROUPS}; gn = {g: 0.0 for g in GROUPS}; gN = {g: 0.0 for g in GROUPS}
for r in sba:
    g = grp(r["archetype"], r["income"]); gd[g] += float(r["subsidy_discounted_eur"]); gn[g] += float(r["subsidy_nominal_eur"]); gN[g] += float(r["dwellings"])
for g in GROUPS:
    add(f"spending_discounted_{g}", gd[g] / 1e6, "M EUR", EVAL, f"{REC}/subsidy_by_archetype.csv")
    add(f"spending_nominal_{g}", gn[g] / 1e6, "M EUR", EVAL, f"{REC}/subsidy_by_archetype.csv")
    add(f"dwellings_{g}", gN[g] / 1e6, "million dwellings", "input (census stock, tenure split wave 9)", f"{REC}/subsidy_by_archetype.csv")
add("spending_discounted_low_income_owners", (gd["owner_low_wpb"] + gd["owner_low_rest"]) / 1e6, "M EUR", EVAL, f"{REC}/public_spend_split.csv")
add("spending_discounted_high_income_owners", (gd["owner_high_wpb"] + gd["owner_high_rest"]) / 1e6, "M EUR", EVAL, f"{REC}/public_spend_split.csv")
add("spending_discounted_landlords", (gd["tenant_public"] + gd["tenant_private"]) / 1e6, "M EUR", EVAL, f"{REC}/subsidy_by_archetype.csv")
add("standard_spending_share_wpb_buildings", 100 * (gd["owner_low_wpb"] + gd["owner_high_wpb"]) / sum(gd.values()), "% of discounted spending 2026–2050 to owner-occupiers in worst-performing buildings [added 2026-11-08]", EVAL, f"{REC}/subsidy_by_archetype.csv")
oc = {r["scenario"]: r for r in rd("results/pl12_outcome_measures.csv")}
o = oc["pl12"]
add("spending_discounted_envelope", float(o["spend_envelope_M"]), "M EUR", EVAL, "results/pl12_outcome_measures.csv")
add("spending_discounted_heat_pumps", float(o["spend_hvac_M"]), "M EUR", EVAL, "results/pl12_outcome_measures.csv")
mt = {r["measure"]: r for r in rd(f"{REC}/measure_totals.csv")}
for m in ("envelope_medium", "envelope_deep", "hvac_fossil_to_hp", "hvac_fossil_to_district"):
    add(f"spending_nominal_{m}", float(mt[m]["subsidy_eur"]) / 1e6, "M EUR (undiscounted)", EVAL, f"{REC}/measure_totals.csv")
    add(f"dwellings_adopting_{m}_2050", float(mt[m]["dwellings_adopting"]) / 1e6, "million dwellings (cumulative to 2050)", EVAL, f"{REC}/measure_totals.csv")
    add(f"stock_share_{m}_2050", float(mt[m]["stock_share_pct"]), "% of stock", EVAL, f"{REC}/measure_totals.csv")
# outcomes
for k, unit in (("co2_record_Mt", "Mt CO₂ cumulative 2026–2050 with programme"), ("co2_zero_Mt", "Mt CO₂ cumulative 2026–2050 at σ = 0"),
                ("co2_avoided_Mt", "Mt CO₂ avoided"), ("co2_avoided_pct", "% of σ = 0 emissions"), ("eur_per_t", "EUR per t CO₂ avoided (discounted spending)"),
                ("pe_saved_2050_TWh", "TWh/yr primary energy saved in 2050 vs σ = 0"), ("eur_per_kwh_2050", "EUR per kWh/yr saved in 2050"),
                ("E2050_zero", "kWh/(m²·yr) in 2050 at σ = 0")):
    add(f"standard_{k}", float(o[k]), unit, EVAL + " and at σ = 0", "results/pl12_outcome_measures.csv")
# energy-cost shares with / without the programme (2050, dwelling-weighted, low-income groups)
for g in ("owner_low_wpb", "owner_low_rest", "tenant_public", "tenant_private"):
    add(f"cost_share_2050_{g}_with_programme", 100 * float(o[f"share_{g}_2050"]), "% of income (energy + own annuity + rent increase)", EVAL, "results/pl12_outcome_measures.csv")
    add(f"cost_share_2050_{g}_no_programme", 100 * float(o[f"share_{g}_2050_zero"]), "% of income at σ = 0", EVAL + " (σ = 0)", "results/pl12_outcome_measures.csv")
for r in rd("results/figures_pl12/fig4_poor_cost_share_2050_data.csv"):
    add(f"cost_share_2050_{r['group']}_unrenovated_reference", 100 * float(r["cost_share_unrenovated"]), "% of income (unrenovated 2050 reference)", EVAL, "results/figures_pl12/fig4_poor_cost_share_2050_data.csv")
# uptake by group 2026 / 2030 / 2050
N = {r["archetype"]: float(r["dwellings"]) for r in rd(f"{REC}/state_after_history.csv")}
agg = {}; W = {}
for r in rd(f"{REC}/adoption_values.csv"):
    y = int(r["year"])
    if y not in (2026, 2030, 2050): continue
    g = grp(r["archetype"], r["income"]); k = (g, y, r["measure"])
    agg[k] = agg.get(k, 0) + N[r["archetype"]] * float(r["s"]); W[k] = W.get(k, 0) + N[r["archetype"]]
for g in GROUPS:
    for y in (2026, 2030, 2050):
        env = sum(agg.get((g, y, m), 0) for m in ("envelope_light", "envelope_medium", "envelope_deep")) / W[(g, y, "envelope_deep")]
        add(f"uptake_envelope_{g}_{y}", 100 * env, "% of the group's dwellings renovated (cumulative, any depth)", EVAL, f"{REC}/adoption_values.csv")
        add(f"uptake_envelope_deep_{g}_{y}", 100 * agg.get((g, y, "envelope_deep"), 0) / W[(g, y, "envelope_deep")], "% of the group's dwellings, deep", EVAL, f"{REC}/adoption_values.csv")
        add(f"uptake_heat_pump_{g}_{y}", 100 * agg.get((g, y, "hvac_fossil_to_hp"), 0) / W[(g, y, "hvac_fossil_to_hp")], "% of the group's dwellings on a heat pump", EVAL, f"{REC}/adoption_values.csv")
for r in rd(f"{REC}/uptake_by_group.csv"):
    if r["year"] in ("2030", "2050"): add(f"uptake_envelope_area_share_{r['group']}_{r['year']}", 100 * float(r["cum_envelope_area_share"]), "% of the group's floor area renovated", EVAL, f"{REC}/uptake_by_group.csv")
# ETS2 revenue vs subsidy
for r in rd(f"{REC}/ets2_revenue_vs_subsidy.csv"):
    if r["period_end"] in ("2030", "2035", "2040", "2050"):
        add(f"ets2_revenue_period_to_{r['period_end']}", float(r["ets2_revenue_eur"]) / 1e6, f"M EUR (nominal, CO₂ price {r['co2_price_eur_t']} EUR/t)", EVAL, f"{REC}/ets2_revenue_vs_subsidy.csv")
        add(f"subsidy_paid_period_to_{r['period_end']}", float(r["subsidy_paid_eur"]) / 1e6, "M EUR (nominal)", EVAL, f"{REC}/ets2_revenue_vs_subsidy.csv")
# ---------------------------------------------------------------- history
sh = rd(f"{REC}/state_after_history.csv")
add("history_state_2026_primary_energy", path[2026], "kWh/(m²·yr) stock average after the fixed 2020–2025 history", "fixed history (modelled envelope + observed SFH heating)", f"{REC}/energy_path.csv")
add("history_state_2020_primary_energy", path[2020], "kWh/(m²·yr)", "input", f"{REC}/energy_path.csv")
hs = rd(f"{REC}/history_spending.csv")
add("history_spending_2020_2025_nominal", sum(float(r["spending_nominal_eur"]) for r in hs) / 1e6, "M EUR (Czyste Powietrze rates 0.70 / 0.40; reported, outside the objective)", "fixed history", f"{REC}/history_spending.csv")
add("history_spending_2020_2025_discounted_2026", sum(float(r["spending_disc_eur"]) for r in hs) / 1e6, "M EUR (compounded to 2026)", "fixed history", f"{REC}/history_spending.csv")
def hist_dw(pred, key):
    return sum(float(r["dwellings"]) * float(r[key]) for r in sh if pred(r["archetype"]))
add("history_sfh_envelope_renovations", hist_dw(lambda a: a.startswith("SFH"), "env_share") / 1e6, "million SFH dwellings 2020–2025 (modelled, cap-bound)", "fixed history", f"{REC}/state_after_history.csv")
add("history_mfh_owner_envelope_renovations", hist_dw(lambda a: a.startswith("MFH") and "_rent_" not in a, "env_share") / 1e6, "million MFH owner dwellings 2020–2025", "fixed history", f"{REC}/state_after_history.csv")
add("history_public_rental_envelope_renovations", hist_dw(lambda a: "_rent_pub" in a, "env_share") / 1e6, "million public-rental dwellings 2020–2025", "fixed history", f"{REC}/state_after_history.csv")
add("history_sfh_heat_pumps", hist_dw(lambda a: a.startswith("SFH"), "hp_share") / 1e6, "million SFH dwellings switched to a heat pump 2020–2025 (observed, NFOŚiGW/CP)", "observed", "data/history_heating_pl12.csv")
add("history_sfh_envelope_share", 100 * hist_dw(lambda a: a.startswith("SFH"), "env_share") / sum(float(r["dwellings"]) for r in sh if r["archetype"].startswith("SFH")), "% of SFH dwellings", "fixed history", f"{REC}/state_after_history.csv")
add("history_period1_envelope_cap", 100 * (1 - (1 - 0.027) ** 6), "% of each archetype (6 years at 2.7 %/yr)", "input (KPRB capacity)", "bilevel_model_affordable_housing.jl")
# decomposition of the 2020→2026 fall and the boiler-update effect (Phase 2 diagnostics, σ = 0) [added 2026-11-08]
def _path(d):
    f = f"out/scenarios/{d}/energy_path_eval.csv"
    return {int(r["year"]): float(r["Eavg"]) for r in rd(f)} if os.path.exists(f) else {}
pz, pe, pn = _path("pl12__xe_zero"), _path("pl12_diag_envonly__xe_zero"), _path("pl12_diag_noboiler__xe_zero")
if pz and pe and pn:
    add("history_decomp_envelope_2026", pz[2020] - pe[2026], "kWh/(m²·yr) fall 2020→2026 from the modelled envelope history alone", "fixed-σ evaluation (σ = 0, diagnostic scenario)", "out/scenarios/pl12_diag_envonly__xe_zero/energy_path_eval.csv")
    add("history_decomp_heat_pumps_dh_2026", pe[2026] - pn[2026], "kWh/(m²·yr) further fall 2020→2026 from the observed heat pumps and district-heat connections", "fixed-σ evaluation (σ = 0, diagnostic scenario)", "out/scenarios/pl12_diag_noboiler__xe_zero/energy_path_eval.csv")
    add("history_decomp_boiler_update_2030_sigma0", pn[2030] - pz[2030], "kWh/(m²·yr) lower 2030 value at σ = 0 from the 2025 boiler update (acts from 2026 on)", "fixed-σ evaluation (σ = 0)", "out/scenarios/pl12__xe_zero/energy_path_eval.csv")
# search before the proofs and the search's resolution [added 2026-11-08]
_b = rd("out/scenarios/pl12/scenario_summary.csv")[0]
add("standard_search_before_proofs", float(_b["spending_M"]), "M EUR (discounted to 2026): the search from the model's candidate list, before the chain of local proofs", "search bound (batch start)", "out/scenarios/pl12/scenario_summary.csv")
add("search_binary_search_tolerance", 0.5, "percentage points (the coordinate descent stops when hi − lo ≤ 0.005)", "input (model code)", "bilevel_model_affordable_housing.jl")
# ---------------------------------------------------------------- scenarios
ms = rd("results/pl12_multistart_summary.csv")
for r in ms:
    s = r["scenario"]
    if r["feasible"].lower() == "true":
        sp = float(ss["spending_M"]) if s == "pl12" else float(r["best_spending_M"])
        st = CERT if s == "pl12" or r["best_source"] == "local25_record" else f"search bound (best of {r['n_runs']} starts: {r['best_source']})"   # 2026-11-09: local proofs of record for envcap_p05, hpcost_lo, hpcost_hi
        add(f"scenario_spending_{s}", sp, "M EUR (discounted to 2026)", st, "results/pl12_multistart_summary.csv")
        add(f"scenario_E2050_{s}", path[2050] if s == "pl12" else float(r["E2050"]), "kWh/(m²·yr)", st, "results/pl12_multistart_summary.csv")
        if r["equity"] not in ("", "NaN", "nan"): add(f"scenario_equity_{s}", 100 * float(r["equity"]), "% low-income share of spending", st, "results/pl12_multistart_summary.csv")
        if s in oc:
            add(f"scenario_co2_avoided_{s}", float(oc[s]["co2_avoided_Mt"]), "Mt CO₂ 2026–2050", "fixed-σ evaluation at the scenario's design", "results/pl12_outcome_measures.csv")
            add(f"scenario_eur_per_t_{s}", float(oc[s]["eur_per_t"]), "EUR/t", "fixed-σ evaluation at the scenario's design", "results/pl12_outcome_measures.csv")
    else:
        miss = "; ".join(f"{y} miss {r['miss_' + y]}" for y in ("2030", "2035", "2040", "2050") if r.get("miss_" + y, "ok") not in ("ok", ""))
        add(f"scenario_spending_{s}", "no feasible design", miss or "affordability limit violated at every start", f"max-σ evidence, {r['n_runs']} starts (not certified)", "results/pl12_multistart_summary.csv")
# tenants' cost shares and rent rules (SQ2)
for r in rd("results/figures_pl12/fig6_rent_rules_data.csv"):
    if r["rule"].startswith("public landlord own spending"):
        add(f"public_landlord_own_spending_{r['scenario']}_nominal", float(r["tenant_bill_2050_eur_yr"]), "M EUR 2026–2050 nominal", "fixed-σ evaluation", "results/figures_pl12/fig6_rent_rules_data.csv")
        add(f"public_landlord_own_spending_{r['scenario']}_discounted", float(r["rent_increase_2050_eur_yr"]), "M EUR discounted to 2026", "fixed-σ evaluation", "results/figures_pl12/fig6_rent_rules_data.csv")
    else:
        add(f"tenant_bill_2050_{r['scenario']}_{r['tenure']}", float(r["tenant_bill_2050_eur_yr"]), "EUR/yr energy bill per tenant dwelling 2050", r["source"], "results/figures_pl12/fig6_rent_rules_data.csv")
        add(f"tenant_rent_increase_2050_{r['scenario']}_{r['tenure']}", float(r["rent_increase_2050_eur_yr"]), "EUR/yr renovation-related rent increase 2050", r["source"], "results/figures_pl12/fig6_rent_rules_data.csv")
# ---------------------------------------------------------------- history-envelope sensitivity
for sfx, mult in (("env075", 0.75), ("env050", 0.50)):
    p2 = {int(r["year"]): float(r["Eavg"]) for r in rd(f"out/scenarios/pl12_hist_{sfx}__xe_max/energy_path_eval.csv")} if os.path.exists(f"out/scenarios/pl12_hist_{sfx}__xe_max/energy_path_eval.csv") else {}
    if p2:
        add(f"sens_hist_{sfx}_state_2026", p2[2026], "kWh/(m²·yr)", f"fixed history × {mult} (envelope only)", f"out/scenarios/pl12_hist_{sfx}__xe_max/energy_path_eval.csv")
        add(f"sens_hist_{sfx}_2030_at_caps", p2[2030], "kWh/(m²·yr) with every subsidy rate at its cap", "max-σ evaluation", f"out/scenarios/pl12_hist_{sfx}__xe_max/energy_path_eval.csv")
        add(f"sens_hist_{sfx}_2030_miss", p2[2030] - targets[2030], "kWh/(m²·yr) above the 2030 target", "max-σ evaluation", f"out/scenarios/pl12_hist_{sfx}__xe_max/energy_path_eval.csv")
    add(f"sens_hist_{sfx}_spending", "no feasible design", "—", "search, 1 start + max-σ evidence", f"results/cert_logs/run_pl12_hist_{sfx}.log")
add("sens_hist_env100_2030_at_caps", 221.39, "kWh/(m²·yr) (record history, slack +0.73)", "max-σ evaluation", "results/cert_logs/eval_pl12_xe_max.log")
with open(OUT, "w", newline="") as f:
    w = csv.writer(f); w.writerow(["name", "value", "unit", "status", "source_file"]); w.writerows(rows)
print(f"{len(rows)} numbers -> {OUT}")
