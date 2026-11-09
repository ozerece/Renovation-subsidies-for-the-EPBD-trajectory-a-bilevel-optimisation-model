# P4 paper — open questions on the standard run pl10 (2026-11-04)

Read-only report from code, configuration and stored results. File references
are to `affordable_housing/` paths; "model" = `bilevel_model_affordable_housing.jl`,
"PROVENANCE" = `data/PROVENANCE_polish_stock.md`. Values the model does not
contain are stated as **not in model**.

## A. Model definition

**1. Periods and yearly limits.** The first period starts **2020**, not 2021:
`context.csv` `years = 2020;2030;2035;2040;2050`; the last period ends 2060
(`end_year = [2030, 2035, 2040, 2050, 2060]`, model ~1690). Yearly renovation
limits are applied per year within each period by **compounding**, not by
multiplication: `cap_from_rate(rt, len) = 1 − (1 − rt)^len` (model ~1671).

**2. Joint workforce limit.** It has its **own** rate path, not the envelope
limit: pl10 uses the KPRB capacity profile `joint_rate_path = (0.043, 0.048,
0.052, 0.055)` per year (stages <2030 / 2030–34 / 2035–39 / ≥2040;
`out/scenarios/pl10/config_used.txt:44`), giving period caps 35.6 / 21.8 /
23.5 / 43.2 / 43.2 % of the stock. Weights: envelope 1.0, heating 0.4, PV 0.2
(`W_CLS`, model ~1670). **All four limits (envelope, heating 4 %/yr, PV
4 %/yr, joint) are applied per archetype**: every constraint is indexed
`[a in A, ti in T]` (model 1995–2001). pl10's envelope path is
`env_rate_path = (0.027, 0.032, 0.036, 0.039)`, heating `hvac_rate_const = 0.04`.

**3. Residual value.** Yes — proportional to the remaining lifetime: a measure
adopted at `t` with lifetime beyond 2060 keeps `salvage_frac = 1 −
min(1, (2060 − t)/lifetime)` of its capex, credited at the horizon end and
discounted: `net_capex_factor = 1 − salvage_frac · disc(2060)/disc(t)`
(model 1772–1778; `residual_value: true` in pl10's config). **The same factor
applies to landlords' own investment** — the identical term appears in the
rented and the owner branch of the follower objective (model 2200 and 2223).
It does **not** apply to public spending (the state pays full capex). Recorded
limitation (model ~205): the factor uses the global 3 % rate even when a
scenario gives landlords a different discount rate.

**4. District-heat availability.** Yes: `dh_cap_sfh = 0.05`, `dh_cap_mfh =
0.80` (defaults, model 73; unchanged in pl10), enforced as cumulative-share
caps in the follower (model 2126–2128).

**5. Public landlord spending limit.** Yes: `liquidity_cap_by_landlord =
(public = 5000.0, private = Inf)` EUR per dwelling and year (model 211). The
code comment marks it **"PLACEHOLDER, to be discussed"** — **no source** is
recorded.

**6. Public-landlord weight w.** The tenant-cost term (tenant energy bill +
carbon cost + rent increase) is **discounted** — it sits inside the landlord's
per-period objective block, which is multiplied by `fdisc(a, years[ti])`
(model 2210–2216 and the closing `* fdisc(...)`): the landlord's own discount
rate, which defaults to the global 3 %.

**7. Rent rules.** The "capped" rule (`pl10_rule_cap3`) is the Polish rate
(10 %/yr of the owner's outlays net of grants, recovery duration) **plus an
absolute cap of 3 EUR per m² per YEAR** on the rent increase
(`rent_increase_cap_per_m2 = 3.0`, model 1117–1119) — it is **not** 3 % of the
dwelling value; no dwelling value exists in the model. (The Art. 8a(4)
3 %-of-replacement-value line is documented in the code as a justification
threshold, not a ceiling.) **Figure-label error found and fixed while
answering this**: the figure labels used to say "3 %-of-value cap"; they now
say "3 €/m² cap". The "permanent" rule (`pl10_rule_perm`): π = the Polish
pass-through rate **0.10/yr** of eligible outlays (net of grants; public
landlord 0.02), **D = ∞** (`pass_through_years = "permanent"`, the levy never
expires). For reference, the default rule_PL has D = "recovery" =
ceil(1/π) = **10 years**.

**8. Worst-performing rule (≥ 55 %).** Not evaluated at a milestone: the share
is computed on the **horizon total** of site-energy savings — Σ over all
archetypes **and all five periods** of (baseline − E[a,t]) × area, WPB rows
over all rows (model 2787–2790, same formula in the enumeration). Each term
measures the reduction from the 2020 baseline to the stock state of that
period, so the constraint is an area-weighted time-integral over 2020–2060.

**9. Affordability constraint.** Yes, exactly the Fig. 4 cost: owner-occupier
cost = annual energy bill (fuel + carbon at that period's prices, model
`annual_bill` 2618–2624) **+ annualised own payment** (`own_annualised`
2628–2637): an annuity on the household's own share (capex net of subsidy),
`ann_m = r/(1 − (1+r)^−lifetime)` with **r = 3 %** (the context discount rate,
model 1649–1652 — not household-specific) over the **measure lifetime**,
counted while the annuity still runs. Tenants: bill + rent increase, no
capex. Maintenance is excluded. Fig. 4 reads the same `cost_after_eur_yr`
column that this check writes.

**10. Search.** CCG: Phase 2 evaluates a fixed list of named σ candidates
(HPR-relaxation rounding, Poor-focused, District-focus, Deep+District, …,
model ~2896 ff.) and takes the best feasible one as the **default starting
design**; Phase 3 runs coordinate descent over the 12 rates, where each
coordinate is shrunk by **binary search for the lowest feasible rate** down to
an interval of **0.005 (0.5 pp)** (skip if the interval is already < 0.01),
up to 10 outer sweeps, with a second descent round (Phase 5); it stops when a
sweep brings no improvement. The binary-fraction rates of the pl10 design
(e.g. 0.41336669921875) are the signature of this search.

**11. Half-rate feasibility test.** It covered **only pl10_r12** (σ = caps/2
probe, 2026-11-03, `results/cert_logs/eval_paper_r12_half.log`). Carbon ×0.5
and the income limits were tested at **maximum** subsidies only
(`eval_paper_{co2half,s10..s15}_max.log`); no half-rate run exists for them.

**12. Software, hardware, tests.** Julia 1.11.6; JuMP 1.29.3; Gurobi.jl 1.8.0
with **Gurobi Optimizer 12.0.3** (linux64); CSV 0.10.15, DataFrames 1.8.1
(../Manifest.toml). BilevelJuMP 0.6.2 is in the project but is used by the
legacy root model, not by this CCG variant. Machine (all searches and proofs):
**AMD Ryzen Threadripper 3960X, 24 cores / 48 threads, 251 GB RAM**, Debian
(kernel 6.12.113). Test suites: `test_invariants.jl` (this folder) has **20
checks**, written 2026-09-30 — current for the model code but not re-run per
scenario; pl10 reproduction is instead guarded by the pinned gates
(`gate_plcosts_*`: 8 checks × 2 configurations, PASS ×2 runs;
`gate_postmerge_{baseline,tenure_on}`: 8 checks each, PASS, 2026-11-02).
`test_exact_benchmark.jl` belongs to the **legacy root model** and does not
exist in `affordable_housing/` — not applicable to pl10.

## B. Stock data

**13. Worst-performing split.** Method (PROVENANCE "Resolution and stock of
record"): Invert status-quo-2020 "exclusive SF" distributions per building
type, rescaled to census floor-area shares, merged, ranked by primary energy,
cut at 43 % of combined floor area → **threshold ≈ 275 kWh primary/(m²·yr)**;
shares **52.5 % SFH / 7.1 % MFH** (user-delivered; later re-derivation:
274.6 / 52.9 % / 7.9 % — verified, flag closed). The realized cut is
**42.52 %**, 0.5 pp below 43, because the later rural-split decision (14 % of
rural dwellings in multi-dwelling buildings) moved the SFH area share from
79.4 % to 78.0 % after the cut had been fixed at pre-decision weights
(PROVENANCE "UPDATED CHECKS" table).

**14. Behaviour-adjusted (inclusive) sensitivity.** Confirmed. The stock file
`archetypes_pl_inclusive_mix.csv` gives exactly **50.5 % / 17.2 %** WPB shares
(SFH/MFH) and stock-average primary **257.0** (paper: ≈256.8). The paper's
averages are primary energy: SFH **377/175** (= file final energy 342.7/159.1
× PEF 1.1), MFH **288/165**. These are the user-delivered "INCL check" values
(PROVENANCE table); the independent re-derivation gives threshold 266.1,
50.7 %, 378.6/175.7, 15.9 %, 291.5/167.0, avg 258.3 — agreement ≈1 %, largest
gap the MFH share (15.9 vs 17.2 %), documented.

**15. Heat-pump cost.** SFH **€8,721 = 37,500 PLN ÷ 4.30** — the user-given
2026 market level incl. installation, which is the midpoint of the
30,000–45,000 PLN market range (sensitivities €6,977/€10,465); gross, no VAT
added. MFH **€4,272 = 37,500 × 53.2/108.6 PLN ÷ 4.30** — area-scaled from the
SFH value (PROPOSED + FLAGGED: cascade-system economies assumed to offset the
small-unit premium; no Polish MFH HP cost series; Ciepłe Mieszkanie caps
conflict between calls). MFH envelope component areas per dwelling
(12-dwelling, 4-storey block, 638.4 m² heated, perimeter-minimal footprint):
walls **38.66 m²**, top ceiling/flat roof **13.30 m²**, windows **6.65 m²**,
doors 0.167 m² (PROVENANCE "Derived per-dwelling costs").

**16. District-heat connection cost.** Legacy stylised assumption, kept when
the Czyste Powietrze costs were introduced ("KEPT" in the PROVENANCE table):
**15 €/m² + €4,000 fixed** (measures_v2.csv) → SFH 15×108.6+4,000 = **5,629**,
MFH 15×53.2+4,000 = **4,798**. Cross-check recorded: the annex's highest DH
grant, 22,250 PLN = €5,174, brackets both values (−8 %/+8 %).

**17. Gas price.** €0.0707/kWh: Eurostat `nrg_pc_202`, PL, band **D2
(20–200 GJ)**, all taxes, **2023 annual average** (S1 0.0683 / S2 0.0730).
No conversion to 2024 was applied: PL is confidential in the series from
2024, and household tariffs were frozen at the 2023 level (200.17 PLN/MWh
net) through mid-2024, so the 2023 value is carried as the 2024 price
(PROVENANCE, carrier-price table).

**18. Electricity PEF 2020 = 3.0.** The pre-2023 Polish certificate value: the
code comment (model 1506–1513) cites Dz.U. 2023 poz. 697 as setting wi = 2.5
"today, 3.0 before 2023"; the path starts at 3.0 in 2020 and the `pef_frozen`
lever pins the **2023** values (electricity 2.5, DH 0.85) — **not** the 2020
ones. No separate source document for the 3.0 is in `data/` — stated from the
code comment only (flag).

## C. Results (pl10)

**19. Spending by measure and group, discounted €bn** (from
`investment_flows.csv`, discount 3 % at period-start years; reconciles exactly
to the €10.3974bn of record and to `public_spend_split.csv`):

| measure | low-income | high-income | total |
|---|---|---|---|
| envelope deep | 2.602 | 4.557 | 7.159 |
| envelope medium | 1.192 | 0.676 | 1.868 |
| heat pump | 0 | 1.371 | 1.371 |
| envelope light | 0.000 | 0.000 | 0.000 |
| district-heat connection | 0 | 0 | 0 |
| PV (never subsidised) | 0 | 0 | 0 |
| **total** | **3.793** | **6.604** | **10.397** |

**20. Nominal public subsidy 2020–2050: €14.631bn** (sum of
`subsidy_paid_eur`; the subsidy horizon ends 2050, so 2050–60 adoption
receives nothing).

**21. Proven design on the list (€11,586.8M) — all 12 rates.** The
**low-income heat-pump rate is 0 %**; the 90 % goes to the district-heat
connection: envelope poor light/medium/deep **40/50/60 %**, envelope rich
**0/0/10 %**, heat pump poor **0 %**, district-heat connection poor **90 %**,
heat pump rich **25 %**, district-heat rich **5 %**, landlord public/private
**0/0 %**. (Carrier flip vs pl9, where the certificate gave the poor the heat
pump at 90 % — open finding.)

**22. Which limit binds for low-income owners.** The **envelope capacity
limit binds with equality in all four periods to 2050** under pl10's KPRB
envelope path: adoption per period 23.94/15.01/16.75/32.82 % = exactly the
period caps; their sum is **88.52 %** — precisely the 88.5 % uptake by 2050
(so the envelope limits alone do *not* allow more than 88.5 % by 2050 under
the pl10 capacity profile; the >89 % figure holds only under other rate
paths). The **joint workforce limit additionally binds in 2035–40 and
2040–50** (envelope + 0.4×heating + 0.2×PV activity fills it to within
rounding of the caps 23.45/43.16 %), while in 2020–30 and 2030–35 it is
slack. In 2050–60 the envelope is slack (11.5 of 29.97 %) and the **heating
limit binds** (33.5 % = its cap).

**23. Decomposition of the WPB-SFH low-income owner cost in 2050** (search
design, per dwelling and year, `eval_cross_search_at_pl10.log`): energy bill
**€935.4 fuel + €456.5 carbon**, annualised own payment **€559.7** → total
**€1,951.6/yr = 20.3 %** of the €9,635 income for the SFH_wpb_poor archetype
(the paper's 19.6 % is the dwelling-weighted WPB-owner group average
including the smaller MFH WPB rows). **A renovated/unrenovated split is not
in model** — the model tracks archetype averages (adoption shares), not
dwelling-level assignment; this is the recorded Fig. 4 limitation. Heating
state 2050 of this archetype: envelope 88.5 % done; **heat pump 18.7 %,
district heat 0 %, fossil boilers 81.3 %** of dwellings — the fossil mix
being coal 37.0 %, wood 34.5 %, gas 27.5 %, oil 1.0 % (stock file).

**24. Private tenants by income (Fig. 6, 2050, record designs).** Low- and
high-income private tenants are **identical in euros by construction** (same
building state, same rent rule; the twins differ only in income):

| rule | bill €/yr | rent increase €/yr | total | share of income poor/rich |
|---|---|---|---|---|
| No rent increase | 861.4 | 0 | 861.4 | 8.9 % / 3.6 % |
| Polish Art. 8a (net) | 722.8 | 170.0 | 892.8 | 9.3 % / 3.8 % |
| Art. 8a + 3 €/m²/yr cap | 731.3 | 159.6 | 890.9 | 9.2 % / 3.7 % |
| Permanent rent increase | 394.9 | 735.9 | 1,130.9 | 11.7 % / 4.8 % |
| Art. 8a, gross outlays | 722.8 | 170.0 | 892.8 | 9.3 % / 3.8 % |

**25. Older-typology sensitivity (€8.72bn).** Value of record €8,724.0M from
the hp-heavy restart (the batch's €13,590.7M is a recorded search failure).
It is cheaper than the standard because the 1946–66 typology sheets make the
expensive envelope stages **save more per euro**: reduction factors SFH
0.093/0.468/0.629 vs standard 0.134/0.367/0.576 (**medium +27.5 %, deep
+9.2 %**, light −31 %); MFH 0.082/0.304/0.480 vs 0.054/0.333/0.490 (light
+52 %, medium −9 %, deep −2 %). The record design needs far less poor
envelope subsidy (7.5/21.3/21.3 %) plus a 74 % poor heat-pump rate, and lands
at E2050 98.1 — much closer to the 108.4 target than the standard's 91.1,
i.e. less over-delivery. Caveat: warm-start re-runs are in progress for all
scenarios; this value may still move.

**26. (a) 2050 vs the milestones.** Yes — across every feasible record
design the 2050 slack is large (+10 to +37 kWh/m²; smallest: electricity
+20 % at +3.8, PEF frozen at +5.1) while **2030 binds at the 0.1-tolerance
edge in 15 scenarios** (margin −0.068) and 2040 is within ±0.1 in most. The
binding milestones are 2030 and 2040 everywhere; the 2050 end target is
comparatively easy. **(b) Landlord rates.** Zero in every feasible scenario
of record **except three**: electricity −20 % (private 53.0 %), electricity
+20 % (private 77.2 %, public 0.3 %), behaviour-adjusted demand (private
96.3 %, public 0.4 %) — exactly the suspicious search bounds now under
warm-start re-examination.

**27. Proof status** (hybrid-grid exact enumeration; as of 2026-11-04 ~01:00):

| scenario | status | proven value | proven design |
|---|---|---|---|
| standard (pl10) | **DONE** | €11,586.838M on the list; search €10,397.4M stays value of record | rates in Q21 |
| no EED | **DONE** | €11,586.838M — **identical σ to pl10**; value of record (search was €16.3bn) | = Q21 |
| boiler ban 2040 | **DONE** | €11,217.794M; value of record (search €13.4bn) | env poor 30/50/60, rich 0/0/10, DH poor 5 %, HP rich 25 %, landlords 0 |
| carbon ×0.5 | running (serial merge ~17 h CPU) | certified infeasibility expected | — |
| discount 12/8 % (split) | running (~13 h) | — | — |
| electricity +20 % | running (~13 h) | — | — |
| electricity −20 % | shard wave resumed 22:25; parallel merge next | — | — |
| behaviour-adjusted demand | same wave | — | — |
| older typology (1946–66) | shards queued (follow-on); 24-thread parallel merge | — | — |
| local proof around the pl10 search design (2.5 % steps, ±10 pts) | armed, gated on the merges freeing the cores | — | — |

Note the discount-12 % scenario (pl10_r12, all households 12 %) has **no
proof queued**; its infeasibility evidence is the search + the max-σ
diagnostic (missed 2040 by 0.22 kWh/m² at full caps).

**28. Appendix table.** Written:
`results/paper/pl10_archetypes_appendix.csv` — 44 archetypes × (group,
tenure, tenant income, dwellings, floor area, discounted subsidy €bn,
envelope uptake by 2050). Checks: dwellings sum 8,847,407; subsidy sum
€10.397bn.

## D. Figures

Journal set delivered to `results/figures_pl10_journal/` (fig1–fig6 as
**vector PDF + 1,000-dpi PNG**, 190 mm full width, all fonts ≥ 8 pt; the
working set in `results/figures_pl10/` is unchanged): no in-figure titles or
footnotes; no file names or run codes; relabelled per order (owner-occupiers;
No rent increase; Permanent rent increase; Public landlord weight on tenants'
costs, w = 0.5/1; Cost-minimal design; Public-/Private-rental tenants;
"proven on the list of subsidy rates"); Fig. 3 standard bar reads
"10.4 — search; proven on the list: 11.6", certified bars "(proven on the
list)", * and ‡ kept, "no feasible design" wording. The cap3 label fix (Q7)
is in both sets. The figures will be regenerated once the warm-start sweep
finishes (values of record may change for the scenarios in Q26b).

## Addendum (2026-11-04, follow-up questions)

**WPB "site energy".** Yes — delivered (final) energy at the building:
the savings basis is `fr.E = fE = base × (1−r_env)(1−r_hvac)(1−r_pv)`
(model 2085–2094), i.e. final energy after the heating-system conversion
gains and PV, not useful heat and not primary energy. And yes, the pl10
value 78.68 % is the WPB share of exactly that **horizon total**
(Σ over all archetypes and all five periods of (baseline − E) × area;
model 2787–2790).

**Public-landlord €2.9bn.** Nominal. Under the proven (certified) design
the public landlord's own investment is **€2,910.3M nominal / €1,822.9M
discounted at 3 %** (eval_cross_cert_at_pl10.log; EED on). Under no-EED
both are €0.

**2015 regulation and wi = 3.0.** Confirmed by secondary sources: the
2015 methodology regulation (Dz.U. 2015 poz. 376) used **wi = 3.0** for
grid electricity, and the 2023 amendment (Dz.U. 2023 poz. 697, in force
28 Apr 2023) lowered it to 2.5 — e.g. rynekinstalacyjny.pl's reviews of
the methodology change state the 3.0 → 2.5 revision explicitly. Caveat:
the Annex 1 table of the 2015 original is published only as a PDF scan
(the ELI/Sejm HTML text says "patrz oryginał"), so the 3.0 is verified
from the trade-press descriptions of the regulation, not from the annex
table itself.

**Paper %% STATUS lines / Table 7**: not in this repository (no file
contains "%% STATUS"; the only paper-like .tex, `bilevel_main.tex`, is
the legacy model paper). The post-warm-start update will deliver the new
values (electricity ±20 %, behaviour-adjusted demand, older typology,
no-EED), the re-run Fig. 3 and summary CSVs; the STATUS lines and
Table 7 need the paper draft, which lives outside this repo.

---

## Addendum (2026-11-04): wood primary-energy-factor sensitivity (pl10_woodpef) — KEY SENSITIVITY

Wording of record (user ruling, for results + discussion): **wood
primary energy factor sensitivity (0.2 instead of 1.1 for the wood
share): 2020 baseline 195.3 instead of 264.4 kWh/(m²·yr) (targets
164.0 / 156.2 / 117.2 / 80.1); spending €9.0bn instead of €10.4bn
(−13.5 %, search); design shifts to the cheaper family (low-income
envelope medium/deep ≈48 %, high-income heat pumps ≈21 %, landlords 0).
Treat as a key sensitivity in results and discussion: the national
primary energy factor for biomass changes how demanding the EPBD
trajectory is.**

Mechanics: mix-weighted fossil PEF per archetype (coal/gas/oil 1.1,
wood 0.2 → SFH mix 0.79, MFH mix 0.87), applied to the baseline and the
trajectory accounting; relative targets follow the new baseline; Invert
WPB shares unchanged. Values of record: €8,997.5M (warm start from the
pl10 certified design; from the search design €12,216.4M); E2050 67.8
vs target 80.1, equity 52.0 %, WPB 79.4 %. Search bounds, no
certificate. Runs: `out/scenarios/pl10_woodpef__ms_*` (multistart
worktree), logs `run_pl10_woodpef_ms_*.log`.

**%% CHECK (stays open):** whether the STANDARD run should use 0.2 —
depends on the Polish certificate method (rozporządzenie wi ≈ 0.2 for
biomass) and on the factor Invert used for the stock file. The pl10
standard is unchanged; pl10_woodpef is the named sensitivity.

**RESOLVED 2026-11-04 (user ruling):** the standard keeps wi = 1.1 for
the wood share. The recast EPBD requires total primary energy; the
Commission's biomass default is 1.0 renewable + 0.2 non-renewable
≈ 1.2 total, and Poland is moving its certificate method to total
primary energy (draft regulation of May 2025). The 0.2 of the current
Polish method (Dz.U. 2015 poz. 376, amended 2023) counts only
non-renewable primary energy — pl10_woodpef is the named sensitivity
for that convention. The %% CHECK above is closed.

## Addendum (2026-11-04): paper-analysis wave — trajectory, envelope
## capacity, outcome measures, design table

All values are CCG search bounds (warm starts from the two pl10
designs); no certificates were ordered for this wave. Files:
`results/design_table_of_record.csv`,
`results/outcome_measures_summary.csv` (31 scenarios),
`results/outcome_measures_periods.csv` (per period, incl. the 2060
period, excluded from the cumulative 2020–2050 numbers), summary rows
in the worktree `pl10_multistart_summary.csv`.

**(1) Trajectory sensitivity.** `pl10_traj_linear` keeps 2030/2035
(−16 %/−20 %) and puts 2040/2050 on the straight line from the 2035
target to −59 % in 2050: the new 2040 target is **177.2** kWh/(m²·yr)
(−33 %; the standard's −40 % gives 158.7). `pl10_traj_soft` uses
−35 %/−55 % (171.9/119.0). Both land at **€8,926.0M with the identical
design**: the pl10 record design minus the high-income heat-pump
subsidy (21.56 % → 0.34 %). Readings: (i) the 2040 milestone costs
≈ €1.47bn, and that money buys exactly one thing — high-income
heat-pump adoption before 2040; (ii) once 2040 is at ≈ −33 % it stops
binding, and 2050 never binds (the optimum sits at E2050 101.6 against
a 108.4 target); the standard trajectory's binding milestones are 2030
and 2040 only.

**(2) Envelope capacity (yearly envelope limits ×0.8 / ×1.2, heating
limit unchanged, joint cap = env + 0.4×hvac).** `envcap_m20`: **no
feasible subsidy design found** — at MAXIMUM subsidies the stock
reaches 224.95 at 2030 vs the 222.12 target (all later milestones
reachable); with 2.16 %/yr envelope capacity before 2030, −16 % by
2030 is physically out of reach (search + max-σ evidence, not a
certificate). `envcap_p20`: **€5,358.8M, −48.5 % vs the standard** —
the largest single-lever effect in the pl10 family; the crash-programme
rates collapse (low-income envelope 41.3 % → 13.2/24.5 %), equity
33.9 % (near the 30 % floor). Together with the 2030-repair results:
the standard's €10.4bn is largely the price of pushing renovation
throughput to the capacity ceiling before 2030; KPRB's 2.7 %/yr sits
at the knife's edge between infeasible (×0.8) and half the cost
(×1.2). Both the trajectory and the capacity sensitivity therefore
point at the same object — the 2030 milestone × capacity interaction
sets the bill.

**(3) Outcome measures** (per scenario: value-of-record σ vs σ = 0;
CO₂ = the model's fossil-fraction accounting; money = discounted
spending, the value of record). σ = 0 is EPBD-infeasible in every
scenario except pl10_kprb (whose record is €0 — natural adoption meets
its absolute targets). Standard pl10: cumulative 2020–2050 CO₂ 630.2 Mt
without vs 593.2 Mt with the programme → **37.0 Mt avoided (5.9 %)**,
**€281/tCO₂**, 4.80 TWh/yr primary saved at 2050, **€2.17 per annual
kWh**. Spending splits (pl10, discounted): deep envelope €7.16bn (69 %),
medium envelope €1.87bn, heat pumps €1.37bn, DH/PV/landlords €0;
low-income owners €3.79bn vs high-income €6.60bn; nominal per period
3.6/2.4/2.6/6.0 €bn (2030/2035/2040/2050). Range across scenarios:
€138/t (elec_m20) to €1,078/t (peffrozen); hpcost_hi avoids the most
CO₂ (98.4 Mt, €149/t) because its no-programme counterfactual is the
dirtiest; the w>0 / rule_perm family sits at €180/t. **FINDING: under
the relaxed trajectories and envcap_p20 the programme's 2050 primary
energy is WORSE than σ = 0** (traj: 79.5 vs 76.1 TWh/yr; the free
optimum reaches E2050 97.3 vs the relaxed record's 101.6), so € per
kWh-saved-2050 is undefined there — those programmes buy milestone
TIMING (cumulative CO₂ still falls by 9.7 Mt), not end-state savings,
and the capacity caps make early subsidised envelope displace later
own-initiative renovation. Cost-per-tonne comparisons across scenarios
must be read against each scenario's own σ = 0 baseline (they differ).

**(4) Design table** (`design_table_of_record.csv`): σ per measure and
group for standard / no-EED / ban-2040 / discount-12-8 / elec−20 % /
w 0.5 / w 1.0 / permanent-rent / wood-0.2 side by side. w 0.5, w 1.0
and permanent-rent carry the identical 8,302.6-family design (landlords
0 everywhere except elec_m20's 53.0 % private-landlord rate, the one
structurally different record: subsidy shifts to low-income heat pumps
39.2 % + private landlords).

## Addendum (2026-11-04): Invert carrier-price sensitivity
## (pl10_invertprices) — NO FEASIBLE DESIGN

All six carrier prices replaced by Invert's Poland "const" values
(elec 166.55, gas 47.45, coal 35.28, firewood 29.07, oil 75.24, DH
56.87 €/MWh — 29–51 % below the standard's; source file
`616_pol__const__energy_price.csv` named by the user, not yet in the
repo; price year and VAT unknown, to be confirmed by the Invert team).
Mixes, efficiencies and the ETS2 path unchanged; gas on the same HHV/GCV
basis.

**Result: no feasible subsidy design exists** (both warm-started
searches fail; at MAXIMUM subsidies — €35.9bn — the stock reaches 233.6
at 2030 against the 222.1 target, missed by 11.5 kWh/(m²·yr), the worst
infeasibility measured in the family; 2035, 2040 and 2050 all remain
reachable). Without a programme (σ = 0) cumulative 2020–2050 CO₂ is
669.2 Mt (standard prices: 630.2), and σ = 0 interestingly MEETS the
2050 target (106.9 vs 108.4) while failing 2030/2035/2040 — cheap
energy delays renovation, it does not prevent it. Low-income 2050 cost
shares are lower than the standard's by construction (cheaper bills;
e.g. the worst archetype SFH_wpb_poor at max σ averages 10.3 % of
income vs 20.2 % at the standard's record design); no record-design
comparison exists. Spending, design and cost-effectiveness: not
defined (no feasible design).

**Reading**: before 2030 the model carries no carbon price (ETS2's
2028 start is represented as zero through the 2020–30 period), so fuel
savings are the only pre-2030 renovation incentive. At the Invert
price level those savings are too small to reach −16 % by 2030 at any
subsidy rate. Together with the envelope-capacity result (×0.8 also
kills 2030 alone), the 2030 milestone emerges as the model's fragile
point: its feasibility rests jointly on the assumed energy-price level
and on renovation capacity, both within ±20–40 % of their standard
values. Candidate KEY SENSITIVITY for the discussion, pending the
Invert team's confirmation of price year and VAT.
