#!/usr/bin/env python3
"""pl12 paper figures 1-6 (decision record 2026-11-06), same style as make_pl10_figures.py
but reading only run directories and the pl12 summary tables (no certificate logs):
  fig1 primary-energy path (record design vs sigma=0 vs EPBD trajectory; 2026 = end of the fixed history)
  fig2 spending by group (from 2026, discounted to 2026) and envelope uptake by 2050
  fig3 scenario spending (feasible) and 2030 miss at the caps (infeasible), incl. the capacity sweep
  fig4 low-income energy-cost share of income in 2050, unrenovated vs after the programme
  fig5 envelope uptake by tenure over time
  fig6 tenant costs 2050 by rent rule (a, b) and total public spending with/without the EED (c)
Inputs: results/pl12_multistart_summary.csv (best run per scenario; out/scenarios/pl12__local25_record
overrides the standard when present), the run dirs' CSVs, out/scenarios/pl12__xe_zero/energy_path_eval.csv.
Outputs: results/figures_pl12/ (working: png+svg) or results/figures_pl12_journal/ (P4_JOURNAL=1: pdf+1000dpi png).
Run from affordable_housing/: python3 -I make_pl12_figures.py"""
import csv, os, re, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager

ROOT = os.path.dirname(os.path.abspath(__file__)); os.chdir(ROOT)
PREFIX = "pl12"
JOURNAL = os.environ.get("P4_JOURNAL") == "1"
OUT = f"results/figures_{PREFIX}_journal" if JOURNAL else f"results/figures_{PREFIX}"
os.makedirs(OUT, exist_ok=True)
MM190 = 190 / 25.4
for f in ("/usr/share/fonts/truetype/crosextra/Carlito-Regular.ttf", "/usr/share/fonts/truetype/crosextra/Carlito-Bold.ttf"):
    try: font_manager.fontManager.addfont(f)
    except Exception: pass
plt.rcParams.update({"font.family": "Carlito", "svg.fonttype": "none", "pdf.fonttype": 42})
TUW_BLUE, GREY, INK, MUTED = "#0063A6", "#8a9097", "#1f2328", "#5f6368"
DARKGREY, HAIR, LIGHTBLUE = "#4d5156", "#e3e5e8", "#7fa8cc"
TARGETS = {2030: 222.12, 2035: 211.55, 2040: 158.66, 2050: 108.42}
HIST_END = 2026

def read_csv(p):
    with open(p, newline="") as f: return list(csv.DictReader(f))
def save(fig, name):
    if JOURNAL: fig.savefig(f"{OUT}/{name}.pdf"); fig.savefig(f"{OUT}/{name}.png", dpi=1000)
    else: fig.savefig(f"{OUT}/{name}.png", dpi=300); fig.savefig(f"{OUT}/{name}.svg")
def fig_title(fig, *a, **k):
    if not JOURNAL: fig.suptitle(*a, **k)
def fig_note(fig, *a, **k):
    if not JOURNAL: fig.text(*a, **k)
def style_axes(ax):
    ax.set_axisbelow(True)
    for s_ in ("top", "right", "left"): ax.spines[s_].set_visible(False)
    ax.spines["bottom"].set_color("#c7cacd"); ax.tick_params(length=0)

MS = {r["scenario"]: r for r in read_csv(f"results/{PREFIX}_multistart_summary.csv")}
def best_dir(scn):
    r = MS[scn]
    if scn == PREFIX and os.path.isdir(f"out/scenarios/{PREFIX}__local25_record"):
        return f"out/scenarios/{PREFIX}__local25_record", "local proof"
    tag = r["best_source"]
    return (f"out/scenarios/{scn}" if tag == "batch" else f"out/scenarios/{scn}__{tag}"), ("search" if tag == "batch" else ("local proof" if tag == "local25_record" else f"search ({tag})"))   # 2026-11-09: proofs of record for other scenarios
def spending_of(scn):
    d, src = best_dir(scn)
    for x in read_csv(f"{d}/scenario_summary.csv"): return float(x["spending_M"]), src
STD_DIR, STD_SRC = best_dir(PREFIX)
STD_SPEND, _ = spending_of(PREFIX)
STD_LAB = "local proof" if STD_SRC == "local proof" else "search result"

NAME = {"pl12": "Standard run", "pl12_afford": "Cost-neutral rule",
        "pl12_s10": "Income limit 10%", "pl12_s12": "Income limit 12%", "pl12_s13": "Income limit 13%",
        "pl12_s14": "Income limit 14%", "pl12_s15": "Income limit 15%", "pl12_s20": "Income limit 20%",
        "pl12_s25": "Income limit 25%", "pl12_s30": "Income limit 30%", "pl12_s40": "Income limit 40%",
        "pl12_rule_none": "No rent increase", "pl12_rule_cap3": "Rent cap", "pl12_rule_perm": "Permanent rent increase",
        "pl12_rule_pl_gross": "Gross rule", "pl12_w05": "Public landlord w = 0.5", "pl12_w10": "Public landlord w = 1",
        "pl12_noeed": "No EED obligation", "pl12_priv16": "Private rental 16%", "pl12_pubpoor": "All public tenants low-income",
        "pl12_ban2040": "Fossil-boiler ban", "pl12_r12": "Household discount 12%", "pl12_split": "Household discount 12%/8%",
        "pl12_kprb": "KPRB demand", "pl12_hvac6": "Heating-system limit 6%", "pl12_co2half": "Carbon price ×0.5",
        "pl12_peffrozen": "Primary energy factors frozen", "pl12_elec_p20": "Electricity +20%", "pl12_elec_m20": "Electricity −20%",
        "pl12_invertprices": "Invert price level", "pl12_woodpef": "Firewood factor 0.2",
        "pl12_envcap_m20": "Envelope limits ×0.8", "pl12_hist_env075": "Envelope history 2020–25 ×0.75", "pl12_hist_env050": "Envelope history 2020–25 ×0.5", "pl12_envcap_p05": "Envelope limits ×1.05", "pl12_envcap_p10": "Envelope limits ×1.1",
        "pl12_envcap_p20": "Envelope limits ×1.2", "pl12_envcap_p30": "Envelope limits ×1.3", "pl12_envcap_p50": "Envelope limits ×1.5",
        "pl12_traj_linear": "Straight-line trajectory", "pl12_traj_soft": "Softer trajectory",
        "pl12_hpcost_lo": "Heat-pump cost low", "pl12_hpcost_hi": "Heat-pump cost high", "pl12_sav4666": "Older typology savings",
        "pl12_inclusive": "Behaviour-adjusted demand", "pl12_learn0": "No cost decline at all"}
GROUPS = ["owner_poor_wpb", "owner_poor_rest", "owner_rich_wpb", "owner_rich_rest", "rental_public", "rental_private"]
GLAB = {"owner_poor_wpb": "Low-income owner-occupiers,\nworst-performing", "owner_poor_rest": "Low-income owner-occupiers,\nrest of stock",
        "owner_rich_wpb": "High-income owner-occupiers,\nworst-performing", "owner_rich_rest": "High-income owner-occupiers,\nrest of stock",
        "rental_public": "Public-rental dwellings", "rental_private": "Private-rental dwellings"}
def group_of(arch, income):
    if "_rent_pub" in arch: return "rental_public"
    if "_rent_priv" in arch: return "rental_private"
    return f"owner_{income}_{'wpb' if '_wpb_' in arch else 'rest'}"
def weights_for(d):
    dwell, fa = {}, {}
    for r in read_csv(f"{d}/subsidy_by_archetype.csv"): dwell[r["archetype"]] = float(r["dwellings"])
    for r in read_csv(f"{d}/affordability_by_archetype.csv"): fa.setdefault(r["archetype"], float(r["floor_area_m2"]))
    for r in read_csv("archetypes_pl_mix.csv"): fa.setdefault(r["arch_id"], float(r["floor_area_m2"]))
    return dwell, fa

# ============================================================== FIGURE 1
path = {int(r["year"]): float(r["Eavg"]) for r in read_csv(f"{STD_DIR}/energy_path.csv")}
zero = {int(r["year"]): float(r["Eavg"]) for r in read_csv(f"out/scenarios/{PREFIX}__xe_zero/energy_path_eval.csv")}
with open(f"{OUT}/fig1_primary_energy_data.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["year", "record_design", "no_subsidies", "epbd_target", "note"])
    for y in sorted(path): w.writerow([y, round(path[y], 2), round(zero.get(y, float("nan")), 2), TARGETS.get(y, ""), "fixed history to 2026" if y <= HIST_END else ""])
fig, ax = plt.subplots(figsize=(MM190, 4.4) if JOURNAL else (7.2, 4.4), dpi=300)
ys = [y for y in sorted(path) if y <= 2050]
ax.axvspan(2020, HIST_END, color=HAIR, alpha=0.6, lw=0)
ax.text(2023, max(path.values()) * 1.115, "fixed history\n2020–2025", fontsize=8, color=MUTED, ha="center", va="top")
ax.plot(ys, [zero[y] for y in ys], color=GREY, lw=2, ls=(0, (5, 3)), marker="o", ms=4, label="No subsidies from 2026")
ax.plot(ys, [path[y] for y in ys], color=TUW_BLUE, lw=2.2, marker="o", ms=4.5, label=f"Cost-minimal design ({STD_LAB})")
ax.plot(list(TARGETS), list(TARGETS.values()), ls="none", marker="D", ms=6, mfc="white", mec=INK, label="EPBD trajectory (−16/−20/−40/−59 % vs 2020)")
for y in (2030, 2040):
    ax.annotate(f"{path[y]:.1f}", (y, path[y]), textcoords="offset points", xytext=(-7, -13), ha="right", fontsize=8.5, color=TUW_BLUE)
    ax.annotate(f"{zero[y]:.1f}", (y, zero[y]), textcoords="offset points", xytext=(6, 4), fontsize=8.5, color=DARKGREY)
ax.set_ylabel("Primary energy, kWh/(m²·yr), stock average", fontsize=10, color=MUTED, loc="top")
ax.set_xlabel("Year", fontsize=10, color=MUTED); ax.set_xticks([2020, 2026, 2030, 2035, 2040, 2050])
ax.yaxis.grid(True, linewidth=0.4, color=HAIR); style_axes(ax); ax.set_ylim(0, max(path.values()) * 1.12)
ax.legend(frameon=False, fontsize=8.5, loc="lower left")
fig_title(fig, "Primary energy of the stock: fixed history, then the cost-minimal design", x=0.012, ha="left", fontsize=12, fontweight="bold", color=INK)
fig_note(fig, 0.012, 0.014, f"pl12. 2020–2025 fixed from observed heating replacements and the history run; the state designs from 2026. Data: fig1_primary_energy_data.csv.", fontsize=7.4, color=MUTED, va="bottom")
fig.subplots_adjust(left=0.09, right=0.975, top=0.96 if JOURNAL else 0.9, bottom=0.12 if JOURNAL else 0.17)
save(fig, "fig1_primary_energy"); plt.close(fig); print("fig1 done")

# ============================================================== FIGURE 2
dwell, fa = weights_for(STD_DIR)
spend = {g: 0.0 for g in GROUPS}
for r in read_csv(f"{STD_DIR}/subsidy_by_archetype.csv"): spend[group_of(r["archetype"], r["income"])] += float(r["subsidy_discounted_eur"])
area = {g: 0.0 for g in GROUPS}; env = {g: 0.0 for g in GROUPS}
for r in read_csv(f"{STD_DIR}/adoption_values.csv"):
    if r["measure_class"] == "envelope" and r["year"] == "2050":
        g = group_of(r["archetype"], r["income"]); env[g] += float(r["s"]) * fa[r["archetype"]] * dwell[r["archetype"]]
for a_, d_ in dwell.items():
    inc = "poor" if (("_poor" in a_ and "_rent" not in a_) or a_.endswith("_poor")) else "rich"
    area[group_of(a_, inc)] += fa[a_] * d_
uptake = {g: env[g] / area[g] if area[g] else float("nan") for g in GROUPS}
with open(f"{OUT}/fig2_spend_uptake_groups_data.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["group", "subsidy_discounted_2026_eur", "cum_envelope_area_share_2050", "result_label"])
    for g in GROUPS: w.writerow([g, round(spend[g], 1), round(uptake[g], 5), STD_LAB])
fig, axes = plt.subplots(1, 2, figsize=(MM190, 3.6) if JOURNAL else (10.5, 4.4), dpi=300)
ypos = range(len(GROUPS) - 1, -1, -1)
axes[0].barh(list(ypos), [spend[g] / 1e9 for g in GROUPS], height=0.62, color=TUW_BLUE)
for y, g in zip(ypos, GROUPS): axes[0].annotate(f"{spend[g]/1e9:.2f}", (spend[g] / 1e9, y), textcoords="offset points", xytext=(4, 0), va="center", fontsize=8.5, color=INK)
axes[0].set_title("a   Subsidy spending 2026–2050, EUR bn", loc="left", fontsize=10, color=INK)
axes[1].barh(list(ypos), [100 * uptake[g] for g in GROUPS], height=0.62, color=GREY)
for y, g in zip(ypos, GROUPS): axes[1].annotate(f"{100*uptake[g]:.0f}%", (100 * uptake[g], y), textcoords="offset points", xytext=(4, 0), va="center", fontsize=8.5, color=INK)
axes[1].set_title("b   Envelope renovation by 2050, % of floor area", loc="left", fontsize=10, color=INK)
for ax in axes:
    ax.set_yticks(list(ypos)); style_axes(ax); ax.xaxis.grid(True, linewidth=0.4, color=HAIR)
axes[0].set_yticklabels([GLAB[g] for g in GROUPS], fontsize=9, color=INK); axes[1].set_yticklabels([""] * len(GROUPS))
axes[0].set_xlim(0, max(spend.values()) / 1e9 * 1.3); axes[1].set_xlim(0, 118)
fig_title(fig, "Who receives the money and who renovates (standard design)", x=0.012, ha="left", fontsize=12, fontweight="bold", color=INK)
fig_note(fig, 0.012, 0.014, f"pl12, {STD_LAB}. Spending from 2026 (history not included). Data: fig2_spend_uptake_groups_data.csv.", fontsize=7.4, color=MUTED, va="bottom")
fig.tight_layout(rect=(0, 0.05 if not JOURNAL else 0, 1, 0.93 if not JOURNAL else 1))
save(fig, "fig2_spend_uptake_groups"); plt.close(fig); print("fig2 done")

# ============================================================== FIGURE 3
# 2026-11-08 (paper review, figure fix M15): compact layout. Scenarios whose design
# equals the standard run's (same spending) are collapsed into one row, the
# income-limit scenarios that only violate the affordability rule into one row, and
# the two scenarios that need no subsidy are shown in panel (a) at zero. Search
# bounds that lie above the standard run although the input change cannot raise the
# minimum would be hatched (NO_HIGHER; empty, see below). The data CSV is unchanged
# (one row per scenario).
rows = list(MS.values())
ZERO_OK = ("pl12_elec_m20", "pl12_kprb")
NO_HIGHER = set()   # no hatching: with the equity floor a cheaper input (more capacity, cheaper heat pumps) CAN raise the minimum (R5 check 2026-11-08: the record design is infeasible under hpcost_lo because the low-income share falls below 30 %), so no bound is provably loose
feas_all = [r for r in rows if r["feasible"].lower() == "true"]
infe = [r for r in rows if r["feasible"].lower() != "true"]
def miss(r, yr):
    v = r.get(f"miss_{yr}", ""); return None if v in ("", "ok") else float(v)
sp_of = {r["scenario"]: spending_of(r["scenario"])[0] for r in feas_all}
with open(f"{OUT}/fig3_scenario_spending_data.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["scenario", "name", "feasible", "spending_M", "source", "miss_2030_at_caps", "miss_2035", "miss_2040", "miss_2050"])
    for r in rows:
        s = r["scenario"]; w.writerow([s, NAME.get(s, s), r["feasible"], sp_of.get(s, r["best_spending_M"]), spending_of(s)[1] if r["feasible"].lower() == "true" else "", r["miss_2030"], r["miss_2035"], r["miss_2040"], r["miss_2050"]])
SAME = [r for r in feas_all if r["scenario"] != PREFIX and abs(sp_of[r["scenario"]] - STD_SPEND) < 0.05]
feas = sorted([r for r in feas_all if r not in SAME], key=lambda r: sp_of[r["scenario"]], reverse=True)
items_a = []   # (label, value EUR bn, colour, hatch, annotation)
for r in feas:
    s = r["scenario"]; v = sp_of[s] / 1000; src = spending_of(s)[1]
    loose = s in NO_HIGHER and sp_of[s] > STD_SPEND + 0.05
    ann = f"{v:.1f}" + ("  (certified local optimum)" if src == "local proof" else "") + ("  (search bound above the standard run)" if loose else "") + ("  (milestones met without subsidies)" if s in ZERO_OK else "")
    items_a.append((NAME.get(s, s), v, TUW_BLUE if s == PREFIX else GREY, "////" if loose else None, ann))
    if s == PREFIX and SAME:
        items_a.append((f"{len(SAME)} scenarios with the standard run's design*", v, LIGHTBLUE, None, f"{v:.1f}  (= standard run)"))
SAME_NAMES = sorted(NAME.get(r["scenario"], r["scenario"]) for r in SAME)
aff = [r for r in infe if miss(r, 2030) is None and r.get("max_sigma_eval") == "Y"]
infe_b = sorted([r for r in infe if r not in aff], key=lambda r: -(miss(r, 2030) or 0.0))
items_b = []   # (label, value, annotation)
for r in infe_b:
    v = miss(r, 2030)
    if r.get("max_sigma_eval") != "Y": lab = "not evaluated"
    elif v is None:
        logf = f"results/cert_logs/eval_{r['scenario']}_xe_max.log"
        txt = open(logf, errors="replace").read() if os.path.exists(logf) else ""
        lab = "follower infeasible at the caps" if "follower INFEASIBLE" in txt else "no 2030 shortfall"
    else:
        later = [f"{yr} by {miss(r, yr):.1f}" for yr in (2035, 2040, 2050) if miss(r, yr) is not None]
        lab = f"{v:.1f}" + ("   (also misses " + ", ".join(later) + ")" if later else "")
    items_b.append((NAME.get(r["scenario"], r["scenario"]), v or 0.0, lab))
if aff:
    lims = sorted(int(m.group(1)) for m in (re.search(r"_s(\d+)$", r["scenario"]) for r in aff) if m)
    nm = f"Income limit {min(lims)}–{max(lims)}%" if lims else f"{len(aff)} affordability scenarios"
    items_b.append((nm, 0.0, f"affordability limit violated at every design ({len(aff)} scenarios); milestones met"))
h_a = 0.26 * len(items_a) + 1.2; h_b = max(1.4, 0.26 * len(items_b) + 1.0)
fig, axes = plt.subplots(2, 1, figsize=(MM190, h_a + h_b), dpi=300, gridspec_kw={"height_ratios": [h_a, h_b]})
ax = axes[0]; y = list(range(len(items_a)))[::-1]
for yi, (lab, v, col, hatch, ann) in zip(y, items_a):
    ax.barh(yi, v, height=0.62, color=col, hatch=hatch, edgecolor="white" if hatch else col, linewidth=0.6)
    ax.annotate(ann, (v, yi), textcoords="offset points", xytext=(4, 0), va="center", fontsize=8, color=INK)
ax.axvline(STD_SPEND / 1000, color=TUW_BLUE, lw=0.8, ls=(0, (4, 3)))
ax.set_yticks(y); ax.set_yticklabels([it[0] for it in items_a], fontsize=8.5, color=INK)
ax.set_xlabel("Public subsidy spending 2026–2050, EUR billion, discounted to 2026\n(standard run: certified local optimum; other bars: search results = upper bounds)", fontsize=8.5, color=MUTED)
ax.set_title("a   Scenarios with a feasible design", loc="left", fontsize=10, color=INK); ax.set_xlim(0, max(it[1] for it in items_a) * 1.45)
# the collapsed scenarios are named in the figure caption (SAME_NAMES printed below)
ax = axes[1]; y = list(range(len(items_b)))[::-1]
ax.barh(y, [it[1] for it in items_b], height=0.62, color=GREY)
for yi, (lab, v, ann) in zip(y, items_b):
    ax.annotate(ann, (v, yi), textcoords="offset points", xytext=(4, 0), va="center", fontsize=8, color=INK)
ax.set_yticks(y); ax.set_yticklabels([it[0] for it in items_b], fontsize=8.5, color=INK)
ax.set_xlabel("2030 milestone missed by, kWh/(m²·yr), with every subsidy rate at its cap", fontsize=9, color=MUTED)
ax.set_title("b   No feasible design", loc="left", fontsize=10, color=INK); ax.set_xlim(0, max([it[1] for it in items_b] + [1]) * 2.4)
for ax in axes:
    style_axes(ax); ax.xaxis.grid(True, linewidth=0.4, color=HAIR); ax.tick_params(axis="x", colors=MUTED, labelsize=8)
fig_title(fig, "Public spending across scenarios (pl12)", x=0.012, ha="left", fontsize=12, fontweight="bold", color=INK)
fig.tight_layout(rect=(0, 0, 1, 0.98 if not JOURNAL else 1))
save(fig, "fig3_scenario_spending"); plt.close(fig); print(f"fig3 done ({len(items_a)} + {len(items_b)} rows; {len(SAME)} scenarios collapsed: {', '.join(SAME_NAMES)})")

# ============================================================== FIGURE 4
P_GROUPS = ["owner_poor_wpb", "owner_poor_rest", "rental_public", "rental_private"]
PLAB = {"owner_poor_wpb": "Low-income owner-occupiers,\nworst-performing", "owner_poor_rest": "Low-income owner-occupiers,\nrest of stock",
        "rental_public": "Low-income public tenants", "rental_private": "Low-income private tenants"}
acc = {g: [0.0, 0.0, 0.0] for g in P_GROUPS}
for r in read_csv(f"{STD_DIR}/affordability_by_archetype.csv"):
    if r["year"] != "2050" or r["income"] != "poor": continue
    g = group_of(r["archetype"], r["income"]); wgt = float(r["dwellings"]); inc = float(r["income_eur_yr"])
    acc[g][0] += wgt; acc[g][1] += wgt * float(r["frozen_bill_eur_yr"]) / inc; acc[g][2] += wgt * float(r["cost_after_eur_yr"]) / inc
shares = {g: (acc[g][1] / acc[g][0], acc[g][2] / acc[g][0]) for g in P_GROUPS}
with open(f"{OUT}/fig4_poor_cost_share_2050_data.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["group", "cost_share_unrenovated", "cost_share_after_policy_avg", "result_label"])
    for g in P_GROUPS: w.writerow([g, round(shares[g][0], 4), round(shares[g][1], 4), STD_LAB])
fig, ax = plt.subplots(figsize=(MM190, 3.6) if JOURNAL else (7.2, 3.6), dpi=300)
ypos4 = range(len(P_GROUPS) - 1, -1, -1)
for yy, g in zip(ypos4, P_GROUPS):
    un, af = 100 * shares[g][0], 100 * shares[g][1]
    ax.plot([un, af], [yy, yy], color=HAIR, lw=3, solid_capstyle="round", zorder=1)
    ax.plot(un, yy, "o", color=GREY, ms=8, zorder=2); ax.plot(af, yy, "o", color=TUW_BLUE, ms=8, zorder=3)
    ax.annotate(f"{un:.1f}%", (un, yy), textcoords="offset points", xytext=(0, 9), ha="center", fontsize=8.5, color=DARKGREY)
    ax.annotate(f"{af:.1f}%", (af, yy), textcoords="offset points", xytext=(0, -14), ha="center", fontsize=8.5, color=TUW_BLUE)
for thr in (10, 15): ax.axvline(thr, color=HAIR, lw=0.8, ls=(0, (4, 3))); ax.text(thr, len(P_GROUPS) - 0.55, f"{thr}%", fontsize=7.5, color=MUTED, ha="center")
ax.set_yticks(list(ypos4)); ax.set_yticklabels([PLAB[g] for g in P_GROUPS], fontsize=9, color=INK); ax.set_ylim(-0.8, len(P_GROUPS) - 0.3)
ax.set_xlabel("Housing energy cost in 2050 as a share of household income, %", fontsize=10, color=MUTED); style_axes(ax); ax.set_xlim(0, None)
ax.plot([], [], "o", color=GREY, label="Same buildings unrenovated"); ax.plot([], [], "o", color=TUW_BLUE, label="After the programme (group average)")
ax.legend(frameon=False, fontsize=8.5, loc="lower right")
fig_title(fig, "Low-income housing energy costs in 2050", x=0.012, ha="left", fontsize=12, fontweight="bold", color=INK)
fig_note(fig, 0.012, 0.014, f"pl12, {STD_LAB}. Energy bill, carbon cost, and the annualised own share of the investment (owners) or the rent increase (tenants). Data: fig4_poor_cost_share_2050_data.csv.", fontsize=7.4, color=MUTED, va="bottom")
fig.tight_layout(rect=(0, 0.06 if not JOURNAL else 0, 1, 0.93 if not JOURNAL else 1))
save(fig, "fig4_poor_cost_share_2050"); plt.close(fig); print("fig4 done")

# ============================================================== FIGURE 5
upt = {}
for r in read_csv(f"{STD_DIR}/uptake_by_group.csv"):
    if int(r["year"]) <= 2050: upt.setdefault(r["group"], []).append((int(r["year"]), float(r["cum_envelope_area_share"])))
for g in upt: upt[g].sort()
with open(f"{OUT}/fig5_uptake_tenure_data.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["group", "year", "cum_envelope_area_share", "result_label"])
    for g, pts in upt.items():
        for yr, v in pts: w.writerow([g, yr, v, STD_LAB])
STYLE5 = {"owner_poor": dict(color=DARKGREY, linestyle="-", label="Low-income owner-occupiers"),
          "owner_rich": dict(color=GREY, linestyle="-", label="High-income owner-occupiers"),
          "rented_public": dict(color=TUW_BLUE, linestyle="-", label="Public-rental dwellings"),
          "rented_private": dict(color=TUW_BLUE, linestyle=(0, (5, 3)), label="Private-rental dwellings")}
fig, ax = plt.subplots(figsize=(MM190, 4.4) if JOURNAL else (7.2, 4.4), dpi=300)
ax.axvspan(2020, HIST_END, color=HAIR, alpha=0.6, lw=0)
placed = []
for g, st in STYLE5.items():
    if g not in upt: continue
    yrs = [2020] + [p[0] for p in upt[g]]; vals = [0.0] + [100 * p[1] for p in upt[g]]
    ax.plot(yrs, vals, linewidth=2, marker="o", markersize=4.5, **st)
    close = [pv for pv in placed if abs(vals[-1] - pv) < 4]
    dy = -3 if not close else (6 if vals[-1] >= max(close) else -14)
    placed.append(vals[-1])
    ax.annotate(f"{vals[-1]:.0f}%", (yrs[-1], vals[-1]), textcoords="offset points", xytext=(5, dy), fontsize=8.5, color=st["color"])
ax.set_ylabel("Cumulative envelope renovation, % of floor area", fontsize=10, color=MUTED, loc="top"); ax.set_xlabel("Year", fontsize=10, color=MUTED)
ax.set_xticks([2020, 2026, 2030, 2035, 2040, 2050]); ax.yaxis.grid(True, linewidth=0.4, color=HAIR); style_axes(ax); ax.set_ylim(0, None)
ax.legend(frameon=False, fontsize=8.5, loc="upper left")
fig_title(fig, "Renovation uptake by tenure under the standard design", x=0.012, ha="left", fontsize=12, fontweight="bold", color=INK)
fig_note(fig, 0.012, 0.014, f"pl12, {STD_LAB}. Shaded: fixed history 2020–2025. Polish rent rule (Art. 8a). Data: fig5_uptake_tenure_data.csv.", fontsize=7.4, color=MUTED, va="bottom")
fig.subplots_adjust(left=0.08, right=0.975, top=0.96 if JOURNAL else 0.9, bottom=0.11 if JOURNAL else 0.17)
save(fig, "fig5_uptake_tenure"); plt.close(fig); print("fig5 done")

# ============================================================== FIGURE 6
# 2026-11-08 (paper review, figure fix M24): panel (b) no longer repeats five identical
# bars (the public landlord's 2 % rule is not varied by the rent-rule scenarios); it
# shows public-rental tenants with and without the EED obligation. The data CSV gains
# the two public-tenant rows; the private-tenant rows and panel (c) are unchanged.
RULES = ["pl12_rule_none", "pl12", "pl12_rule_cap3", "pl12_rule_perm", "pl12_rule_pl_gross"]
RLAB = {"pl12_rule_none": "No rent increase", "pl12": "Polish rule (Art. 8a)", "pl12_rule_cap3": "Rent cap",
        "pl12_rule_perm": "Permanent rent increase", "pl12_rule_pl_gross": "Gross rule"}
def tenant_rows_2050(scn):
    d, src = best_dir(scn); dw, _ = weights_for(d); acc6 = {}
    for r in read_csv(f"{d}/tenant_costs.csv"):
        if r["year"] != "2050": continue
        a6 = acc6.setdefault(r["tenure"], [0.0, 0.0, 0.0]); wgt = dw[r["archetype"]]
        a6[0] += wgt; a6[1] += wgt * float(r["tenant_bill_eur_yr"]); a6[2] += wgt * float(r["rent_increase_eur_yr"])
    return {t: (b / w0, i / w0, src) for t, (w0, b, i) in acc6.items()}
rule_rows = []
for scn in RULES:
    if MS[scn]["feasible"].lower() != "true": continue
    for t, (b, i, src) in sorted(tenant_rows_2050(scn).items()): rule_rows.append((scn, RLAB[scn], t, b, i, src))
noeed_ok = MS["pl12_noeed"]["feasible"].lower() == "true"
eed_rows = [(PREFIX, "EED obligation (standard run)", "rented_public") + tenant_rows_2050(PREFIX)["rented_public"]]
if noeed_ok: eed_rows.append(("pl12_noeed", "No EED obligation", "rented_public") + tenant_rows_2050("pl12_noeed")["rented_public"])
PERIOD_START = {2026: 2020, 2030: 2026, 2035: 2030, 2040: 2035, 2050: 2040, 2060: 2050}
def landlord_own(scn):
    d, src = best_dir(scn); tot = disc_tot = 0.0
    for r in read_csv(f"{d}/investment_flows.csv"):
        yr = int(r["year"])
        if r["tenure"] == "rented_public" and 2030 <= yr <= 2050:   # periods starting 2026 and later
            v = float(r["own_payment_eur"]); tot += v; disc_tot += v * 1.03 ** -(PERIOD_START[yr] - 2026)
    return tot, disc_tot, src
ll_eed, ll_eed_d, src_eed = landlord_own(PREFIX)
if noeed_ok: ll_no, ll_no_d, src_no = landlord_own("pl12_noeed")
with open(f"{OUT}/fig6_rent_rules_data.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["scenario", "rule", "tenure", "tenant_bill_2050_eur_yr", "rent_increase_2050_eur_yr", "source"])
    for row in rule_rows: w.writerow([row[0], row[1], row[2], round(row[3], 1), round(row[4], 1), row[5]])
    for row in eed_rows: w.writerow([row[0], "Polish rule, " + ("EED on" if row[0] == PREFIX else "EED off"), row[2], round(row[3], 1), round(row[4], 1), row[5]])
    w.writerow([PREFIX, "public landlord own spending 2026-2050, EED on", "rented_public", round(ll_eed / 1e6, 1), round(ll_eed_d / 1e6, 1), "EUR million (nominal, discounted to 2026)"])
    if noeed_ok: w.writerow(["pl12_noeed", "public landlord own spending 2026-2050, EED off", "rented_public", round(ll_no / 1e6, 1), round(ll_no_d / 1e6, 1), "EUR million (nominal, discounted to 2026)"])
fig, axes = plt.subplots(1, 3, figsize=(MM190, 3.2) if JOURNAL else (11.5, 4.2), dpi=300, gridspec_kw={"width_ratios": [3, 2.4, 2.4]})
def draw_tenants(ax, sel, title, xmax=None):
    yp = range(len(sel) - 1, -1, -1); bills = [r[3] for r in sel]; incs = [r[4] for r in sel]
    ax.barh(list(yp), bills, height=0.62, color=GREY); ax.barh(list(yp), incs, left=[b + 12 for b in bills], height=0.62, color=TUW_BLUE)
    for yy, r in zip(yp, sel): ax.annotate(f"{r[3]+r[4]:,.0f}", (r[3] + 12 + r[4], yy), textcoords="offset points", xytext=(4, 0), va="center", fontsize=8.5, color=INK)
    ax.set_yticks(list(yp)); ax.set_yticklabels([r[1] for r in sel], fontsize=9, color=INK)
    ax.set_title(title, loc="left", fontsize=10, color=INK); ax.set_xlabel("EUR per dwelling and year", fontsize=9, color=MUTED); style_axes(ax); ax.xaxis.grid(True, linewidth=0.4, color=HAIR)
    ax.set_xlim(0, xmax or max(b + i for b, i in zip(bills, incs)) * 1.3); ax.set_ylim(-0.6, len(sel) + 0.45)
priv = [r for r in rule_rows if r[2] == "rented_private"]
draw_tenants(axes[0], priv, "a   Private-rental tenants, 2050, by rent rule")
xmax_pub = max(r[3] + r[4] for r in eed_rows) * 1.3
draw_tenants(axes[1], eed_rows, "b   Public-rental tenants, 2050", xmax=max(xmax_pub, axes[0].get_xlim()[1]))
from matplotlib.patches import Patch
axes[0].legend(handles=[Patch(facecolor=GREY, label="Energy bill incl. carbon cost"), Patch(facecolor=TUW_BLUE, label="Rent increase")], frameon=False, fontsize=8, loc="upper left", ncol=2, columnspacing=1.2, handlelength=1.4)
ax = axes[2]
state_on = STD_SPEND / 1000; bars = [("EED on", state_on, ll_eed_d / 1e9)]
if noeed_ok: bars.append(("EED off", spending_of("pl12_noeed")[0] / 1000, ll_no_d / 1e9))
xs = range(len(bars))
ax.bar(xs, [b[1] for b in bars], width=0.55, color=GREY, label="State subsidies"); ax.bar(xs, [b[2] for b in bars], bottom=[b[1] for b in bars], width=0.55, color=TUW_BLUE, label="Public landlords' own spending")
for x, b in zip(xs, bars): ax.annotate(f"{b[1]+b[2]:.1f}", (x, b[1] + b[2]), textcoords="offset points", xytext=(0, 4), ha="center", fontsize=8.5, color=INK)
ax.set_xticks(list(xs)); ax.set_xticklabels([b[0] for b in bars], fontsize=9, color=INK); ax.set_title("c   Total public spending 2026–2050", loc="left", fontsize=10, color=INK)
ax.set_ylabel("EUR billion, discounted to 2026", fontsize=9, color=MUTED); ax.set_ylim(0, max(b[1] + b[2] for b in bars) * 1.5)
style_axes(ax); ax.yaxis.grid(True, linewidth=0.4, color=HAIR)
ax.legend(handles=[Patch(facecolor=GREY, label="State subsidies"), Patch(facecolor=TUW_BLUE, label="Public landlords, own")], frameon=False, fontsize=7.5, loc="upper left")
fig_title(fig, "Rent rules, tenants' costs and the EED obligation", x=0.012, ha="left", fontsize=12, fontweight="bold", color=INK)
fig_note(fig, 0.012, 0.014, "pl12 search results (standard run: certified local optimum). Tenant costs dwelling-weighted; public landlords' own spending from 2026 discounted at 3 %. Data: fig6_rent_rules_data.csv.", fontsize=7.4, color=MUTED, va="bottom")
fig.tight_layout(rect=(0, 0.07 if not JOURNAL else 0, 1, 0.92 if not JOURNAL else 1))
save(fig, "fig6_rent_rules"); plt.close(fig); print("fig6 done")
print(f"figures -> {OUT}/")
