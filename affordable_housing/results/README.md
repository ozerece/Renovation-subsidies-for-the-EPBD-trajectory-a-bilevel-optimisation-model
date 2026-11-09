# P4 results — research questions and output ledger

Every output file in `results/` must be listed in the ledger below under exactly
one research question. Anything that does not answer one of them is not reported
(debug material goes to `results/_scratch/`, out of this README).

> **Fossil-boiler ban label (2026-10-27).** ALL results in this ledger as of
> 2026-10-27 — every table, figure, certificate, run output and sweep below —
> were produced **with the fossil-boiler ban ON** (forced end-of-life
> replacement of fossil boilers with HP/DH from `ban_year`, default 2040;
> `early_ban` 2030). On 2026-10-27 the ban became a scenario switch
> (`fossil_boiler_ban`, **default OFF for new runs**; kept available as the
> named scenario `boiler_ban`), because EPBD 2024/1275 states a phase-out AIM
> for 2040 but no binding Polish ban exists. Nothing below was changed or
> deleted; re-running any scenario under the new default will NOT reproduce
> these results unless `fossil_boiler_ban=true` is set (the pinned
> reproduction gates pin the WITH-ban behaviour).

## Research questions

**Main question (P4).** What is the minimum public spending needed to bring a
residential building stock onto its EPBD primary-energy trajectory when the
actors who decide on renovation — owner-occupiers and landlords — adopt
voluntarily, and the subsidy scheme must keep housing energy costs affordable
for low-income households, whether they own or rent — and how should subsidy
rates be differentiated across measures, income groups and tenure types to
achieve it?

**Sub-question 1 — money-based vs outcome-based equity.** Does a spending-based
equity rule (at least 30% of subsidy money to low-income households) select the same subsidy
design as an outcome-based one (the low-income household's housing energy cost must
not rise)? What does it cost when they differ?
→ answered by **Table 1, Figure 1**.

**Sub-question 2 — who decides vs who pays.** Which of the instruments that
make the owner-occupied case cheap — carbon price, boiler ban, falling primary
energy factors — still work when the decision-maker does not pay the energy
bill, and what subsidy does it take to close the gap for public and private
landlords?
→ answered by **Table 2, Figures 2, 3, 4**.

**Sub-question 3 — institutional coherence.** How far does the cost-minimal,
EPBD-compliant design depend on the subsidy actually reaching the household,
i.e. on the absence of tax and benefit clawback?
→ answered by **Figure 5**.

## Output ledger

| Output file | Question answered | Run(s) it comes from | Rent rule / afford. reference | Certified / search bound | Placeholder data |
|---|---|---|---|---|---|
| `out/scenarios/pl11*/` (160 run dirs), `results/pl11_summary.csv`, `results/pl11_multistart_summary.csv`, `cert_logs/run_pl11*.log`, `cert_logs/eval_pl11_*_xe_max.log`, `cert_logs/pl11_wave.log`, `figures_pl11{,_journal}/fig_pl11_feasibility.*` (2026-11-06, 18:06–18:58; branch `pl11`) | **pl11 wave (review brief 2026-11-06: no PV, HP learning 2.5%/yr only, envelope/DH learning 0, +0.3 rule kept, landlord cap 1.0 in rent-rule scenarios)**: **38 of 40 scenarios have NO feasible design** from 4 starts; at all subsidy caps 2030 is missed by 3.5–16.2 kWh/(m²·yr) (standard 8.26). Feasible: `pl11_elec_m20` €4,168.1M (pure heat-pump design) and `pl11_kprb` €0. Local proof not possible (no standard design). Hypotheses H-pl11-1..6 scored in CHANGELOG | 152 CCG searches (8 Gurobi threads each) + 38 max-σ evaluations | pl11 family (base11 = base10 + pv_enabled=false + learning_rates override), rule_PL, zero_subsidy reference | search bounds + max-σ evidence — NO certificates; infeasibility NOT proven | N (pl10 data of record; PV removed by decision) |
| `results/paper/pl11_phase2_realism_check.md`, `cert_logs/realism_pl10.log`, `cert_logs/realism_pl11.log`, `../experiments/2026-11-06_review_checks/phase2/` (2026-11-06, ~18:40) | **Phase 2 realism check** vs `data/observed_2020_2025_poland.md`: model replaces 0 SFH heating systems before 2030 in every configuration (observed ≈ 0.6 M by 2025); envelope of the right order; PV (pl10) right order. **Biomass boiler option does not exist**; scratch estimate: best reachable 2030 at caps 230.39 → 226.11 (η 0.87), still infeasible; lock-in for 2040/2050 under PEF 1.1 (O-pl11-4, O-pl11-5) | fixed-σ evaluations (production model + scratch copy) | pl10 / pl11 | evaluations — not bounds; production model untouched | N |
| `test_pl12_pins.jl` (11 pins, `scripts/run_pl11_tests.sh pl12`), `cert_logs/test_pl12.log`, `out/scenarios/pl10__gate_pl12_pl10/`, `out/scenarios/pl11__gate_pl12_pl11/`, `data/history_heating_pl12.csv`, `data/history_adoption_pl12.csv`, `data/history_2020_2025_pl12.md`, `data/sigma_history_pl12.csv` (2026-11-06, ~20:30; branch `pl12`) | **pl12 Phase 1** — decisions D1–D8 of `results/paper/P4_decisions_2026-11-06.md` implemented (periods 2020/2026/2030/2035/2040/2050, fixed 2020–2025 history, leader from 2026, CO₂ 22.5 EUR/t 2026–30, counting/discounting from 2026). Gates: pl10 record (10,233.54 / 222.19 / 158.58 / 92.06) and pl11 caps (49,186.2 / 230.39 / 75.14) reproduced bit-identically with every pl12 switch off; history pins 243.88 / 224.05 / 73.39 / 5,021.7 | 3 gate runs + history evaluations | pl10 / pl11 / pl12 | tests, not bounds | N (history: NFOŚiGW/CP mix for SFH heating, 550k replacements — estimate, O-pl12-1) |
| `out/scenarios/pl12_history*/`, `out/scenarios/pl12__xe_zero/`, `out/scenarios/pl12_diag_envonly__xe_zero/`, `out/scenarios/pl12_diag_noboiler__xe_zero/`, `cert_logs/eval_pl12*_xe_zero.log` (2026-11-06, ~20:45) | **pl12 Phase 2 — history run and 2026 state**: 2026 primary intensity **243.88 kWh/(m²·yr)** (2020: 264.5); envelope history −17.3, heating history −3.3; SFH boiler-mix update lowers the σ = 0 value in 2030 from 231.66 to 227.10 (−4.6); 2030 needs −8.9 % in four years. H-pl12-1 half-refuted (heating + boiler > 3) | fixed-σ evaluations | pl12 | evaluations — not bounds | N (O-pl12-2 constant-rate foresight, O-pl12-3 history exempt from caps, O-pl12-4 MFH heating = model, O-pl12-5 envelope history is a capacity-bound value) |
| `out/scenarios/pl12__xe_max/`, `out/scenarios/pl12_envcap_*__xe_max/`, `cert_logs/eval_pl12*_xe_max.log` (2026-11-06, ~20:50) | **pl12 Phase 3 — D4**: 2030 REACHABLE from 2026 at all caps (**221.39**, slack +0.73 vs 222.12; spending at the caps €49.5bn) → 2030 stays a HARD constraint. Capacity sweep at the caps ×1.05…×1.50: 220.76 → 216.49; smallest uniform envelope-capacity increase needed **0 %**. H-pl12-2 refuted, H-pl12-3 moot | fixed-σ evaluations at the subsidy caps | pl12 and `pl12_envcap_p05…p50` | evaluations — not bounds | N |
| `out/scenarios/pl12*/` (≈ 220 run dirs incl. `__ms_*`, `__xe_*`, `__local25_record`), `results/pl12_summary.csv`, `results/pl12_multistart_summary.csv`, `results/pl12_design_table.csv`, `results/pl12_outcome_measures.csv`, `data/sigma_pl12_local25_record.csv`, `cert_logs/run_pl12*.log`, `cert_logs/eval_pl12_*_xe_*.log`, `cert_logs/proof_local_pl12*.log` (+ `_center27422/_center25142/_center25162` archives), `out/enum_shards/pl12_local25*/`, `figures_pl12{,_journal}/fig1–fig6` (2026-11-06 20:06 → 2026-11-07 ~15:00; branch `pl12`) | **pl12 Phase 4 — results of record.** Standard design **CERTIFIED LOCAL OPTIMUM €24,974.1M** (discounted 2026–2050; ±10-pp box, 2.5-pp grid, strict 30 % equity floor; fixed point after four re-centred proofs 27,422 → 26,630 → 25,142/25,186 → 25,162 → 24,974). Design: low-income envelope 44.2 % all depths, low-income heat pump 95.4 %, high-income envelope 22.8/37.15/37.15 %, landlords 0; equity 30.0 % (binding), WPB 74.5 %; 2030 221.88 (slack 0.24), 2040 158.09 (slack 0.57), 2050 97.57. Outcomes: 30.7 Mt CO₂ avoided (6.8 %), 813 EUR/t, 5.32 TWh/yr saved 2050. 31 of 44 scenarios feasible (search bounds, 5 starts); 13 infeasible (`co2half`, `peffrozen`, `envcap_m20`, `woodpef`, `r12`, `invertprices`, `elec_p20`, `s10–s15`). H-pl12-4 refuted on cost, H-pl12-5 partly refuted, H-pl12-6 refuted, H-pl12-7 confirmed (+6 unforeseen) | wave 44 × 4 starts + extra starts + 28 warm starts from the proof design + 4 local proofs (8 shards × 8 threads) + outcome evaluations | pl12 family (base11 + D1–D8), rule_PL, zero-subsidy reference | **standard: certified local optimum (box only)**; every other scenario: search bound; infeasibility: max-σ evidence | N (modelled 2020–2025 envelope history, O-pl12-5/O-pl12-10) |
| `out/scenarios/pl12_hist_env075*/`, `out/scenarios/pl12_hist_env050*/`, `data/history_adoption_pl12_env075.csv`, `data/history_adoption_pl12_env050.csv`, `cert_logs/eval_pl12_hist_env0*_xe_max.log`, `cert_logs/run_pl12_hist_env0*.log` (2026-11-07, 14:30–14:45) | **SENS-pl12-hist-env (user request)**: 2020–2025 envelope history × 0.75 / × 0.50 (heating unchanged). 2026 stock 247.89 / 251.90 (record 243.88); 2030 at all caps 225.24 / 229.10 = **miss 3.12 / 6.97 → 2030 NOT reachable**; searches (1 start): no feasible design. 2035–2050 slack at the caps. 2030 is reachable only if the envelope history is ≥ ≈ 95 % of the modelled level (interpolation) | 2 max-σ evaluations + 2 searches | pl12 variants | evaluations + search evidence; not certified | N (history scaled from the modelled value) |
| `out/scenarios/pl12_*__strict_ms_cur_*/` (17), `out/scenarios/pl12__local25_record/` (24,936.2; `_cert4` = 24,974.1, `_cert2` = 25,186.5 kept), `data/sigma_pl12_local25_record.csv`, `data/sigma_start_cur_*.csv`, `cert_logs/run_pl12_*_strict_ms_cur_*.log`, `cert_logs/proof_local_pl12*.log` (final + `_center24974` archive), `cert_logs/test_pl12.log` (2026-11-07, 15:40 → ~17:30) | **D10 strict equity floor (acceptance test 0.001 → 1e-6; summary script filters old tolerance-feasible runs).** 17 scenarios re-run from their own designs: identity group 25,148 → **24,936.2** (30.04 %), priv16 24,608, envcap_p05 26,318, hvac6 26,603, learn0 29,171, inclusive 42,049, hpcost_hi 28,563 (loose). **Standard re-certified: €24,936.2M** (proof #5, fixed point; same energy path as 24,974.1). D9: 2030 reachability presented as conditional on the modelled history | 17 warm-start searches + 1 local proof (8 shards × 8 threads) + record run + outcome evaluations | pl12 family | standard: certified local optimum (strict floor, box only); others: search bounds | N |
| `table1_equity_rules.csv` (+ Table 1 below) | Sub-question 1 | certs `cert_logs/cert_D0_baseline.log`, `cert_D2_afford_only.log`, `cert_D3_afford_neutral.log` (**re-certified 2026-10-10 on sourced data**; first 2026-10-01, archived) + `eval_certified.jl` | no landlords; D0 afford off, D2 frozen_stock (pre-decision stamp), D3 zero_subsidy | **certified on the 10% grid** (search bound shown alongside) | N |
| `figures/figure1_*` (+ `figure1_data.csv`) | Sub-question 1 | certified design via `eval_certified.jl` | no landlords; zero_subsidy (regenerated under the main reference) | certified on the 10% grid | N |
| `_scratch/incshare_sweep_summary.csv` | Sub-question 1 (diagnostic) | `afford_incshare*` sweeps, rerun 2026-10-11 (wave 9, Tablica-2 incomes 9,635 / 23,761) | no landlords; income_share mode (reference unused) | search bound | N (incomes sourced) |
| `_scratch/diag_s10_sfh_split.csv` | Sub-question 1 (diagnostic) | `diag_sfh_split.jl`, rerun 2026-10-08 | no landlords; income_share mode (reference unused) | search bound | N (incomes sourced) |
| `_scratch/s2_private_landlord_mix.csv` | Sub-question 2 (diagnostic: hump-shaped private uptake, cap/ρ mechanism — CHANGELOG finding) | S2 runs (2026-10-01, old shares — historical diagnostic) | rule_DE frame (ρ swept); zero_subsidy | search bound | **Y** (tenure shares, pre-0.082) |
| `s1_clawback_sweep.csv` | Sub-question 3 | S1: `afford_neutral` + `claw_p10..p50`, `claw_p50_returns` (2026-10-01) | no landlords; frozen_stock (pre-decision) | search bound | N (frozen_stock reference — pre-decision) |
| `figures/figure5_clawback_sweep.{png,svg}` | Sub-question 3 | S1 sweep | no landlords; frozen_stock (pre-decision) | search bound | N |
| `s3_clawback_incshare_sweep.csv` | Sub-question 3 | S3: `afford_incshare_s15` + `s3_claw{25,50}_incshare15`, rerun 2026-10-11 (wave 9; both clawback points now INFEASIBLE at s = 0.15 — CHANGELOG finding) | no landlords; income_share mode (reference unused) | search bound | N (incomes sourced) |
| `table2_tenure_headline.csv` (Table 2) | Main question + sub-question 2 | D0/D3/D4/D5/E1/D5x + reference and share sensitivities, rerun 2026-10-11 (wave 9 data: incomes 9,635 / 23,761; shares 0.082/0.08; split 0.16/0.84; zero_subsidy main) | all tenure rows rule_PL (wave-9 reruns); zero_subsidy main + frozen_stock rows marked | search bound; **D0/D2/D3 + D4-under-rule_PL certified on the 10% grid 2026-10-10; D4 re-certified 2026-10-12 on the wave-9 shares (identical certificate)** | **Y** (public landlord ρ 0.02 open; private share DERIVED + split AROP-based, flagged; incomes + public share sourced) |
| `table3_tenant_cost_decomposition.csv` (Table 3) | Sub-question 2 | `tenure_afford` (D5) + E1, rerun 2026-10-11 (wave 9; incl. `rented_private_rich` row) | rule_PL; zero_subsidy | search bound | **Y** (public ρ 0.02 open; private share derived + split AROP-based, flagged) |
| `s2_passthrough_sweep.csv` (+ `_frozenref` sensitivity) | Sub-question 2 | S2: `s2_ptr*` / `s2f_ptr*`, rerun 2026-10-11 (wave 9) | rule_DE frame PINNED (cap 3 €/m², permanent, net; ρ swept); zero_subsidy / frozen_stock (_frozenref). NOT paper-reportable under the Poland-only order; Polish-frame re-pin queued for the next run round (2026-10-12) | search bound | **Y** (public ρ 0.02 open; private share derived, flagged) |
| `figures/figure2_*` (+ `figure2_data.csv`) | Sub-question 2 | E1 + `tenure_afford` (D5), regenerated 2026-10-11 (wave 9) | rule_PL; zero_subsidy | panel a: evaluation at certified D0 rates; panel b: search bound | **Y** (public ρ 0.02 open; private share derived, flagged) |
| `figures/figure3_*` (+ `figure3_data.csv`) | Sub-question 2 | `tenure_afford` (D5) + E1, regenerated 2026-10-11 (wave 9; incl. high-income-tenant bar) | rule_PL; zero_subsidy | search bound | **Y** (public ρ 0.02 open; private share derived + split AROP-based, flagged) |
| `figures/figure4_*` (+ `figure4_data.csv`) | Sub-question 2 | S2 (+ frozen-stock sensitivity), regenerated 2026-10-11 (wave 9) | rule_DE frame pinned (S2); zero_subsidy + frozen sensitivity. NOT paper-reportable under the Poland-only order; to be rebuilt from the Polish-frame S2 re-pin queued for the next run round (2026-10-12) | search bound | **Y** (public ρ 0.02 open; private share derived, flagged) |
| `out/scenarios/E1_baseline_rates_tenure_on/` | Sub-question 2 | `run_e1.jl`, rerun 2026-10-11 (wave 9) | rule_PL; zero_subsidy (affordability reported, not enforced) | evaluation at the certified D0 rates (no search) | **Y** (public ρ 0.02 open; private share derived, flagged) |
| `table4_institutional_scenarios.csv` (Table 4) | Sub-question 2 (institutional rent-rule scenarios, Poland frame) | S4: `s4_rule_*` / `s4f_rule_*` (10 of the 12 wave-9 runs; the two `*_rule_de` runs dropped from the table 2026-10-12, Poland-only order — run outputs untouched) | rule per row (PL / PL_gross / none / PL_capped / PL_permanent); zero_subsidy (s4_) + frozen_stock (s4f_) | search bound | **Y** (rule_PL sourced, netting/PV interpretive, public ρ 0.02 open; private share derived + split AROP-based, flagged) |
| `figures/figure6_tenant_cost_rules.{png,svg}` (+ `figure6_data.csv`) | Sub-question 2 (institutional) | S4 zero_subsidy runs, regenerated 2026-10-12 (Poland-only order): `s4_rule_pl`, `s4_rule_none` (rule_DE line dropped) | rules PL / none; zero_subsidy | search bound | **Y** (same as Table 4) |
| `household_structure.csv` (+ Markdown copy below) | All questions (model structure reference) | `household_structure.jl` on the loaded `tenure_afford` config (wave 9, 2026-10-11; regenerates in `reproduce_all.sh` stage 7) | config export of tenure_afford (rule_PL default); zero_subsidy | exact export of the loaded config/data (no solve) | **Y** (derived/AROP flags per row; public ρ 0.02 open) |
| `_scratch/e2_landlord_grant_response.csv` | Sub-question 2 (diagnostic E2: does the landlord accept a grant at fixed σ 30/60%, rule × netting? — CHANGELOG findings 2026-10-09: net base → acceptance only where costless, zero effect; gross base → accepted, and under rule_PL it buys renovation 44% → 70% at 2050) | E2 follower evaluations (2026-10-09): `s4_rule_pl(_gross)`, `s4_rule_de`, `e2_rule_de_gross` | rules PL + DE × net/gross; follower-only (no reference used) | heuristic follower evaluation (no leader, no bound claim) | **Y** (same as Table 4) |
| `_scratch/cert_design_eval_summary.csv` | Sub-question 1 (WPB share of the certified D0 design: 81.4%) | follower-only evaluation at the certified rates, baseline config (2026-10-09) | see row text | evaluation of the certified design (no search) | N |
| `cert_logs_worktree/gate_multistart_{baseline,tenure_on}.log` + `smoke_sigma_start_{pl9cert,hpheavy}.log` (worktree branch `worktree-multistart-search`) | Multistart search hooks (2026-11-02 order, on the pl9-certificate finding that the heuristic missed the HP basin by 12.8%): `P4_SIGMA_START=<file>` forces the CCG search to start from a given σ (replaces the Phase-2 candidate list; clamped/ordered; infeasible starts use the upward-adjustment fallback), `P4_OUT_TAG=<tag>` writes to `out/scenarios/<scn>__<tag>/`. Start vectors `data/sigma_start_pl9cert.csv` (certified pl9 σ) + `data/sigma_start_hpheavy.csv` (HP poor at cap, envelope poor 0.30 flat). Runner `run_pl10_multistart.sh`: 34 pl10 scenarios × 2 starts, waits for the batch marker | gates 8/8 PASS ×2 (defaults bit-identical); both smokes parse + validate (12 rates) | n/a | n/a — mechanism only; multistart results pending (H38–H40 pre-registered in main-tree CHANGELOG) | N |
| `cert_logs_worktree/gate_plcosts_{baseline,tenure_on}.log` + `gate_plcosts_vat_*.log` (cost branch, merged into master 2026-11-02 after the pl9 certificate) | Polish investment costs + review changes (2026-10-29 orders): Czyste Powietrze annex od 20.07.2026 100%-tier unit costs × 1.08 VAT + documented geometry → `measure_costs` / MEASURE_COSTS_PL2026 (SFH light/med/deep/HP 3,663/9,918/19,463/8,721 €; MFH 735/2,670/5,725/4,272 €; DH kept); component-consistent envelope savings → `measure_reductions` / MEASURE_REDUCTIONS_PL2026 (SFH 0.134/0.367/0.576; MFH 0.054/0.333/0.490 vs legacy 0.25/0.45/0.70; NAPE/TABULA PL before-U, WT 2021 after-U). Tables: data/PROVENANCE_polish_stock.md "Investment costs" + "Review changes" | gates only — NO scenario uses the new values yet (defaults legacy, bit-identical; **both gates 8/8 PASS ×2**) | n/a | n/a — implementation + sources only; phase 2 approved; pl10 batch pre-registered | **Y** (MFH HP proposed/flagged; ventilation n=0.5 assumption; MFH light cost–saving scope now consistent by construction; deep-saves-less trajectory flag) |
| `cert_logs/cert_pl10_sav4666_hybrid.log` (+ 8 shard logs); updated `figures_pl10*/` (2026-11-05, ~15:30) | **sav4666 CERTIFIED €9,519.727M** (24-thread parallel merge after the interceptor killed the serial merge; certificate written to the canonical log) vs search record €8,724.0M (ms_hpheavy) → **search stays value of record** (ruling (a)); certificate alongside; joint re-eval feasible + matching — no stop. Certified σ: poor env 15/20/20, rich deep 20, poor hvac 80/80. **LAST grid proof — all nine done, no ‡ marks remain**; local-proof gate met (driver launches next) | 8-shard enumeration + parallel merge (interception) | pl10_sav4666 | **CERTIFIED (hybrid grid)** — search bound remains record per ruling (a) | **Y** (as pl10) |
| `out/scenarios/pl10__local25_record/` (full run-dir reporting at the design of record); updated `figures_pl10*/` (2026-11-05, ~17:00) | **Per-archetype reporting regenerated at the certified local optimum** (run_e1.jl pattern: σ fixed, follower evaluation, leader not re-optimised; €10,233.542M reproduced). Figures 1/2/4/5 now show the design of record in both modes — one design everywhere. Group spending sums exactly to the record; low-income owner groups equal by construction; fig4 headline carries over (WPB owners 40.5%→19.6%, private tenants 8.9%→9.3%) | fixed-σ follower evaluation (scratchpad/run_record_pl10_local.jl) | pl10 (design of record) | evaluation of the certified local optimum (no new bound) | **Y** (as pl10) |
| `cert_logs/cert_pl10_local25.log` (+ `local25_shard*.log`, `local_proof_driver.log`); `cert_logs/eval_cert_pl10_local.log`; `cert_logs/record_dir_pl10_local25/subsidies.csv`; `cert_design_kpis.csv` (key `pl10__local25`); `outcome_measures_{summary,periods}.csv` (pl10 rows RECOMPUTED); `design_table_of_record.csv` (standard column rebuilt); updated `figures_pl10*/` (2026-11-05, 16:10–16:30) | **LOCAL PROOF: pl10 VALUE OF RECORD IMPROVES €10,397.4M → €10,233.540M (−1.576%) — certified minimum on the 2.5%-step box ±10 points around the search design; PROOF CHAIN COMPLETE.** Joint re-eval matched (€0.002M rounding); center re-evaluates feasible (arithmetic check passed). Improvement bought with cheap LIGHT-envelope rates (poor +10 pp → 10.27%, rich +7.5 pp → 7.86%) + poor hvac upgrade +2.5 pp; all other rates at center. Binding milestones unchanged (2030 −0.07, 2040 +0.08); KPIs of record E2050 92.06, equity 37.1%, WPB 78.9%. Outcome measures of record now: 35.90 Mt avoided, €285.1/t, €2.508/kWh. Grid certificate €11,586.8M stays alongside (proven optimum on the 5-pp list). Fig1/2/4/5 per-archetype detail still shows the search design (noted in figure notes; full regeneration at the record design available on order) | 8 local shards (18,630 solves) + 12-thread parallel merge over the 2.0bn-combination box; fixed-σ joint evaluations | pl10 | **CERTIFIED LOCAL OPTIMUM = value of record**; grid certificate + search bound reported alongside | **Y** (as pl10) |
| `cert_logs/cert_pl10_sav4666_hybrid.log` (+ 8 shard logs, `pl10_sav4666_followon_driver.log`, `parallel_merge_interceptor.log`); updated `figures_pl10*/` (2026-11-05, 15:37) | **sav4666 CERTIFIED €9,519.727M — GRID-PROOF PROGRAMME COMPLETE (9/9: 8 optima + co2half certified infeasible)**. Certificate ABOVE the search record (ms_hpheavy €8,724.0M) → search stays value of record (ruling (a)), certificate alongside (+9.1%, grid-resolution effect). Joint re-eval feasible + matching — no stop. Certified grid design: poor env 15/20/20, rich env 0/0/20, poor hvac 80/80, rich hvac 0/5, landlords 0. Chain notes: follow-on driver printed "SAV4666 FOLLOWON DONE" PREMATURELY at 13:59 (interceptor killed its serial merge; the 24-thread parallel replacement wrote the certificate to the canonical log at 15:37); session watchers died ~14:20 and were re-armed (user order) — nothing missed. Zero ‡ rows remain; local proof gate passed, deadline 2026-11-06 12:00 | 8 shards (13,206 poor + 1,248 rich solves each) + 24-thread parallel merge on the canonical log | pl10_sav4666 | **CERTIFIED (hybrid grid)** — search bound remains record per ruling (a) | **Y** (as pl10) |
| `cert_logs/cert_pl10_elec_p20_hybrid_par.log` + `cert_pl10_co2half_hybrid_par.log`; `cert_logs/eval_cert_elec_p20.log`; `cert_design_kpis.csv` (+elec_p20 row); `cert_logs/record_dir_elec_p20_cert/subsidies.csv`; `outcome_measures_{summary,periods}.csv` (elec_p20 rows RECOMPUTED); `optionA_guard.log`; updated `figures_pl10*/` (2026-11-05, 04:57–10:50) | **elec_p20 + co2half CERTIFICATES (Option A: parallel merges beat serial; guard killed both serial merges, no mismatch). elec_p20 certified €28,281.982M < search €29,617.5M → CERTIFICATE BECOMES VALUE OF RECORD** (first pl10 scenario where the proof beats the search, −4.5%; design poor env 30/70/70, rich env 40/40/40, poor hvac 90/100, rich hvac 5/20, landlords 0; fixed-σ re-eval exact; E2050 107.29, equity 31.4%, WPB 73.9%; 2040 margin +0.65 nearly binding; outcome rows under the new record: 76.98 Mt avoided, €367.4/t, €1.370/kWh). **co2half CERTIFIED INFEASIBLE on the grid** — search was also infeasible → expected confirmation per the amended stop rule, NOT a stop. Figure script: certified infeasibility now ends `proof_pending` ("not feasible (proven)" / label "certified infeasible"); both figure modes re-run; sav4666 is the only remaining ‡ | shard enumeration + PARALLEL merges; fixed-σ joint evaluations | pl10_elec_p20, pl10_co2half | **CERTIFIED (hybrid grid)**: elec_p20 certificate = value of record; co2half = certified grid infeasibility | **Y** (as pl10) |
| `cert_logs/cert_pl10_inclusive_hybrid.log` (landed 2026-11-04 11:02; first recorded 2026-11-05) | **inclusive CERTIFIED €30,553.023M** vs search record €27,176.3M (batch) → search stays value of record (ruling (a)); certificate alongside in `certified_grid_optimum_M`. Joint re-eval feasible + matching — no stop. Largest grid-resolution gap so far (certificate 12.4% above the continuous search). Found unrecorded during the 2026-11-05 wave (its watcher also waits on sav4666); its value had already been flowing into the figures since the 2026-11-04 afternoon re-runs | shard enumeration + serial merge (canonical log) | pl10_inclusive | **CERTIFIED (hybrid grid)** — search bound remains record per ruling (a) | **Y** (as pl10) |
| `results/cert_logs/diag_invertprices_richcap.log` (2026-11-04, ~15:50) | **invertprices rich-cap diagnostic (user order, evaluation only)**: rich-owner caps raised 40/40/50/40/40 → 100% on all five instruments. 2030 improves 233.61 → **225.17 but stays MISSED by 3.05** (spending €90.8bn, diagnostic only). Pre-2030 classification: poor owners **capacity-bound** (env at the 23.9% cap 6/6 both runs); rich owners **partly subsidy-cap-bound** (12.5% → cap 6/6 at 100%); public landlords **willingness-bound** (12.0% env at σ=100% both runs); private landlords **0.0% at 100% subsidy** (recovery-levy economics). Once both owner groups hit the envelope capacity ceiling, no owner-subsidy design reaches 2030 under Invert prices — the only remaining pre-2030 lever is landlord renovation. (First run was an enforce_ordering! clamp artifact — recorded + fixed) | 2 fixed-σ evaluations | pl10_invertprices | diagnostic evidence, not a bound | **Y** (as pl10) |
| worktree `out/scenarios/pl10_invertprices__ms_pl10{search,cert}/`, `results/paperwave_logs/pl10_invertprices__ms_*.log`, summary row; PROVENANCE entry (2026-11-04, ~14:30) | **pl10_invertprices (user order)**: all six carrier prices replaced by Invert's Poland "const" values (29–51% below the standard; source file named `616_pol__const__energy_price.csv`, NOT in repo — values from the order verbatim; price year/VAT = open %% CHECK). **NO FEASIBLE DESIGN**: at MAX subsidies 2030 misses by **11.5** kWh/(m²·yr) (worst measured; all later milestones reachable). σ=0 cumulative CO₂ 669.2 Mt (standard 630.2); σ=0 MEETS the 2050 target (106.9) and fails 2030/35/40. Mechanism of record: ETS2 is 0 pre-2030, so only fuel savings drive pre-2030 renovation — the Invert price level kills the −16% 2030 milestone at any σ. H-inv-1/2/3 refuted, H-inv-4 half-confirmed, H-inv-5 directional (CHANGELOG) | CCG warm starts ×2 + max-σ diagnostic + σ=0 eval, multistart worktree, nice 19 | pl10_invertprices | search + max-σ evidence — NOT certified infeasibility | **Y** (as pl10; Invert price year/VAT flag OPEN) |
| `results/outcome_measures_summary.csv` + `results/outcome_measures_periods.csv` (31 scenarios × record/σ=0; 2026-11-04, ~14:00); report addendum in `results/paper/P4_open_questions_report.md` | **Outcome measures (paper-analysis item 3)**: per-period + cumulative 2020–2050 CO₂ with/without programme, €/tCO₂ avoided, €/kWh primary saved 2050, spending per period/measure/group. pl10: **37.0 Mt avoided (5.9% of σ=0), €281/t, €2.17/kWh**, deep env 69% of spending, landlords €0. σ=0 EPBD-infeasible everywhere except kprb. Range €138/t (elec_m20) – €1,078/t (peffrozen). **FINDING: traj_linear/soft + envcap_p20 end 2050 ABOVE σ=0 primary (programme buys milestone timing, not end-state savings; €/kWh undefined)**. H-out-1/H-out-2 each half-refuted (CHANGELOG) | fixed-σ follower evaluations (evaluate_σ), one model load per scenario | all 31 record scenarios | diagnostics/evidence on record designs — NOT bounds | **Y** (as pl10) |
| worktree `out/scenarios/pl10_{traj_linear,traj_soft,envcap_m20,envcap_p20}__ms_pl10{search,cert}/`, `results/paperwave_logs/*.log`, 4 summary rows (2026-11-04, ~14:00) | **Paper-analysis wave (items 1+2)**: `traj_linear` (2040 target 177.2 from the straight 2035→2050 line) and `traj_soft` (−35%/−55%) BOTH land at **€8,926.0M** with the SAME design = pl10 batch σ minus the rich HP subsidy (21.56→0.34%) → **the 2040 milestone costs ≈ €1.47bn, entirely rich heat pumps; 2035/2050 never bind**. `envcap_m20` (envelope capacity ×0.8): **NO feasible design** — max-σ diagnostic: 2030 misses by 2.8 kWh/m² at MAXIMUM subsidies (physically unreachable), all later milestones fine. `envcap_p20` (×1.2): **€5,358.8M, −48.5% vs pl10** (poor env rates 41%→13/25%, equity 33.9% near floor) → **pl10's cost is renovation-capacity rent at the 2030 bottleneck**; KPRB 2.7%/yr sits at the knife's edge. H-trl-1, H-trs-1, H-env-1, H-env-2 refuted; H-trl-2 confirmed (CHANGELOG scoring) | CCG warm starts ×2 seeds, multistart worktree, nice 19 | pl10_traj_linear, pl10_traj_soft, pl10_envcap_m20, pl10_envcap_p20 | search bounds (no certificates ordered); m20 infeasibility is search + max-σ evidence, NOT certified | **Y** (as pl10) |
| `results/design_table_of_record.csv` (2026-11-04, ~13:40) | **Design table of record (paper-analysis order item 4)**: σ per measure and group, side by side, for pl10 / noeed / ban2040 / split (12/8%) / elec_m20 / w05 / w10 / rule_perm / woodpef, each from its value-of-record run dir (source + record spending in the header rows). Confirms w05 = w10 = rule_perm = the identical 8,302.6-family σ; elec_m20's record shifts subsidy to poor HP 39.2% + private landlords 53.0% | read-only extract from stored run dirs | the 9 named scenarios | designs of the search/record bounds (no new runs) | **Y** (as pl10) |
| worktree `out/scenarios/pl10_woodpef__ms_{pl10search,pl10cert}/`, `results/cert_logs/run_pl10_woodpef_ms_*.log`, summary row (2026-11-04, ~11:20) | **pl10_woodpef (user order)**: wood PEF 0.2 in the fossil-mix PEF (coal/gas/oil 1.1), baseline + trajectory; WPB shares unchanged; other scenarios verified bit-identical (pl10 re-loads at 264.4). New baseline **195.3** (was 264.4), targets 164.0/156.2/117.2/80.1. Value of record **€8,997.5M** (warm start from the pl10 certified design; from the search design 12,216.4). Design = the 8,302.6 family (poor env med/deep 47.55%, rich deep 10.6%, rich HP 20.7%, landlords 0). **FINDING: the wood-PEF assumption is MATERIAL — headline cost −€1.4bn (−13.5%) vs pl10**; H-wood-1/2 refuted (scored in CHANGELOG) | CCG warm starts, multistart worktree (model edit there only: wood_pef lever) | pl10_woodpef | search bounds (no certificate ordered) | **Y** (as pl10; wood-PEF flag now QUANTIFIED) |
| `cert_logs/eval_repair2030_dr1821_sr216.log` (+ `eval_repair2030_dr1821.log`, scratchpad `repair_scan_*/repair_fine_*/repair2_*` ~60 evals); worktree `out/scenarios/pl10__ms_pl10repair/`, `results/run_pl10_ms_pl10repair.log`, summary `ms_pl10repair` columns (2026-11-04, ~10:05) | **2030-REPAIR + WARM START (user-authorized)**: single-rate repair of the €8,302.6M design is IMPOSSIBLE — only rich env deep flips 2030 (discrete threshold 18.21%) and that flip breaks 2040 (HVAC postponed); poor-DH raises up to 90% never move 2030. Minimal FEASIBLE repair is two-rate (rich deep 18.21% + rich HP 21.6%) at **€11,086.8M** — ABOVE the record; warm start from it converges at the seed, **no improvement → pl10 record STANDS at €10,397.4M (batch)**; local proof NOT re-centred (condition unmet). **INTERPRETATION OF RECORD (item 3, hold lifted)**: the pl10 vs w>0/rule_perm divide (10,397.4 vs 8,302.6) = early landlord renovation closing 2030 — w>0 public landlord renovates pre-2030 (margin +0.368 vs −0.123 at same σ), rule_perm private landlords reach 20% envelope by 2030; institutions substitute for ≈ €2.1bn of subsidy. H-repair-1/2 both REFUTED (scored in CHANGELOG) | fixed-σ evaluations + 1 CCG warm start (worktree, nice −19) | pl10 (+ evidence from w10, rule_perm runs) | search bounds; pl10 certificate €11,586.8M alongside; no w/rule_perm certificates | **Y** (as pl10) |
| `cert_logs/cert_pl10_split_hybrid.log`, `cert_logs/cert_pl10_elec_m20_hybrid.log`; updated `figures_pl10*/` (2026-11-04, ~02:15) | **split + elec_m20 CERTIFICATES**: split certified grid optimum **€12,885.852M** vs warm-start search €11,916.3M → search stays value of record (ruling (a)); elec_m20 certified **€5,655.706M** vs search €5,493.8M → search stays record. Both joint re-evaluations feasible and matching — no stop. Certificates reported alongside in `certified_grid_optimum_M`; `proof_pending` False. Both figure sets re-run | shard enumeration + merge (split/elec_p20 serial; elec_m20 parallel-merge interception) | pl10_split, pl10_elec_m20 | **CERTIFIED (hybrid grid)** — search bound remains record per ruling (a) | **Y** (as pl10) |
| worktree `results/pl10_multistart_summary.csv` (REBUILT; pre-sweep backup `.pre_warmstart_2026-11-04.csv`), `out/scenarios/<scn>__ms_pl10{search,cert}/`, logs `run_*_ms_pl10*.log`; updated `figures_pl10*/` (2026-11-04, 00:10) | **WARM-START SWEEP** (68 runs from the pl10 search + certified designs): 11 bounds improved — noeed 16.28→**10.86bn** and ban2040 13.44→**10.60bn** (both now BELOW their certificates → records flip back to "search", certificates reported alongside); w10 & rule_perm → **8,302.6M** (identical owner-side σ, verified), and w05 joined at **8,302.6M** after the authorised extra start (ms_pl10cheap) — real divide is w=0 vs w>0; the 8,302.6 σ is INFEASIBLE under plain pl10 by only −0.123 at 2030 (eval_cross_8302_at_pl10.log) → pl10's own bound likely improvable, OPEN; split 15.8→11.9; priv16 12.0→10.8; hvac6, hpcost_lo, s20, cap3, pubpoor improved; elec_p20/inclusive/peffrozen transfers infeasible (bounds stand); s10–s15/r12/co2half stay infeasible. **FINDINGS**: EED obligation now RAISES total public-sector spending (11.92 vs 10.86bn; grid basis 13.11 vs 11.59) — fig6 v2 message reversed; w ordering now monotone decreasing (10.40/8.75/8.30) — H-w noise verdict superseded in part. Hypotheses pre-registered + scored; 3 OPEN items in CHANGELOG | CCG warm starts (P4_SIGMA_START), multistart worktree, nice -19 | all 34 pl10-family scenarios | search bounds (heuristic); proofs unchanged | **Y** (as pl10) |
| `cert_logs/cert_pl10_ban2040_hybrid.log`; `cert_logs/eval_cross_*.log`; `results/cert_design_kpis.csv`; `figures_pl10_journal/*` (PDF + 1000-dpi PNG); `results/paper/pl10_archetypes_appendix.csv` + `results/paper/P4_open_questions_report.md` (2026-11-03/04 night) | **ban2040 CERTIFIED €11,217.794M** (−16.5% vs search €13,440.8M → value of record; σ: env poor 30/50/60, DH poor 5% — the ban replaces the 90% DH subsidy; KPIs E2050 83.65, equity 59.0%; like-for-like grid comparison: ban SAVES €369M vs pl10's certificate — replaces the "+€3bn" search-bound reading). **Cross-evals**: pl10 search design INFEASIBLE under noeed (2030 −0.455, 2040 −1.270) → EED has real continuous-space value despite €0 grid value; certified design feasible under both with recorded KPIs; summary rows of certificate-record scenarios now carry the certified design's KPIs (cert_design_kpis.csv). Journal figure set per order D (no titles/footnotes, journal wording, 190 mm, ≥8 pt). 28-question paper report + 44-archetype appendix CSV | fixed-σ evaluations + serial merge | pl10_ban2040, pl10, pl10_noeed | ban2040 CERTIFIED; cross-evals are evidence, not bounds | **Y** (as pl10 + wood-PEF) |
| `cert_logs/cert_pl10_noeed_hybrid.log` + shards; updated `figures_pl10/*` (2026-11-03, 22:19) | **pl10_noeed CERTIFICATE**: certified grid optimum **€11,586.838M** — IDENTICAL value and σ to the pl10 grid certificate (owner tables don't see EED; landlord rates 0 in both optima; the design stays trajectory-feasible without the EED renovations). **BELOW the noeed search bound €16,281.6M by 28.8%** → certificate = value of record, label "certified (serial merge)". On the grid the EED obligation is worth €0 at the optimum; the €5.9bn "EED saving" from search bounds does not survive certification (recorded reading: noeed's search bound was a poor local optimum). Caveat: summary-row E2050/equity/wpb still describe the search design. Joint re-eval feasible at same value; no stop (amended rule). Full entry in CHANGELOG | serial merge from 8 shards | pl10_noeed | **CERTIFIED (hybrid grid)** | **Y** (as pl10) |
| `cert_logs/eval_paper_{r12_max,r12_half,s10..s15_max,co2half_max,gross_ll10/20/30,w05_search,w10_search}.log` (2026-11-03 night, user paper questions, read-only) | Max-σ infeasibility evidence + mechanisms: **r12 max-σ infeasible ONLY at 2040 (−0.221)**, co2half ONLY at 2040 (−3.66); **s10–s15 fail only the income-share check at 2050** (violating share 32–34%; SFH_wpb_poor owners + private-rental DH WPB tenants); r12 caps/2 probe worse at every milestone → monotone in practice (no proof — argmin caveat recorded); **gross rule: landlords accept at 10%** (private envelope 0.328→0.688; spending +223/+461/+806M at 10/20/30%) → 0% optimum is cost-minimality; **w05/w10 feasible exactly at stored values, both binding at 2030** — €8.75 vs €10.0bn ordering = CCG search noise (restarts infeasible; w touches only 2.9% public-rental stock at €0 subsidy). Wood-PEF flag added to PROVENANCE. Hypotheses pre-registered + scored in CHANGELOG | fixed-σ follower evaluations (evaluate_σ), no search, no model change | pl10_r12, pl10_s10–s15, pl10_co2half, pl10_rule_pl_gross, pl10_w05, pl10_w10 | diagnostics/evidence — NOT bounds; proofs where queued stay the verdicts of record | **Y** (as pl10 + NEW wood-PEF flag) |
| `cert_logs/eval_pl10_search_design.log`; updated `figures_pl10/*` + `pl10_scenarios_summary.csv` (new column `certified_grid_optimum_M`); queued: `cert_logs/cert_pl10_local25.log` (2026-11-03 evening, user ruling (a)) | **Ruling on certificate-above-search**: value of record = cheapest feasible design known, labelled by source; grid certificate reported alongside as "proven optimum on the rate list". (1) pl10 search design re-evaluated at fixed σ: **FEASIBLE, €10,397.419M exactly**; equity +6.5 pp, WPB +23.7 pp slack; **binding at 2030 (−0.068, inside the +0.1 tolerance) and 2040 (+0.080)** — the continuous design sits on the milestone boundary, strengthening the grid-resolution reading. (2) LOCAL proof (2.5% steps, ±10 pts around the search design; box 6,750×11,880×5×5 = 2.0e9) implemented (`enumerate_local.jl`, worktree) and ARMED behind the gate "noeed + 3 intercepted merges certified" (driver log `cert_logs/local_proof_driver.log`). (3) hvac_upg = district-heat connection (hvac_fossil_to_district). Hypotheses for (1)+(2) pre-registered in CHANGELOG | fixed-σ follower evaluation (evaluate_σ, read-only) | pl10 | re-evaluation of the stored search design; local proof PENDING (gated) | **Y** (as pl10) |
| `cert_logs/cert_pl10_hybrid.log` + `cert_pl10_shard*.log` (2026-11-03, 21:10) | **pl10 CERTIFICATE — STOP rule fired**: certified grid optimum (hybrid σ-grid) **€11,586.838M**, σ: env poor 40/50/60, rich 0/0/10, heat pump poor 0, **district-heat connection poor 90%** (hvac "upgrade" = fossil→district_heat), HP rich 25%, DH rich 5%, landlords 0/0 (carrier flip vs pl9's HP-poor-90% — finding, open); joint re-evaluation feasible at same value; cross product 2.067e11 in 69,488.7 s. **ABOVE the search bound €10,397.4M by +11.4%** → stop-and-report per standing rule; figures re-run HELD pending user verdict. Reading (recorded, not resolved): the CCG search design is CONTINUOUS and off-grid (env poor 41.34% etc.) — the grid enumeration cannot bound it; precedent fast_reno 2026-07 (continuous 4.4% better than 10%-grid). €10,397.4M stands as best feasible design; €11,586.8M certifies the grid only. Multistart: both pl10 restarts infeasible → batch bound stands. Full entry: CHANGELOG "pl10 CERTIFICATE LANDED" | serial merge from 8 shards (P4_ENUM_MERGE=8), P4_SKIP_SEARCH load | pl10 | **certificate of the GRID minimum; does NOT certify (or invalidate) the continuous search bound** | **Y** (as pl10) |
| `../out/scenarios/pl10*/`, `results/pl10_summary.csv` (2026-11-02; logs `cert_logs/run_pl10*.log`, `diag_sigma0_pl10.log`, driver `pl10_batch_driver.log`, post-merge gates `gate_postmerge_*.log`) | **NEW STANDARD pl10** = pl9 + Polish investment costs (VAT gross) + component-consistent savings: **€10,397.4M** (search bound, default start; E2050 91.1, equity 36.5%, WPB 78.7%; design poor env 41/41 med/deep, poor HP 0, rich HP-std 22%). σ=0 infeasible (2030 −9.1 / 2040 −12.3; 2050 met naturally). **STOP: pl10_co2half INFEASIBLE at max σ (unexpected — recorded, proof running)**; r12 + s10–s15 infeasible (SQ1 edge moved DOWN to (0.15,0.20]); kprb €0.0 (absolute targets met naturally on the KPRB stock); elec sign FLIP (+20% €29.6bn / −20% €9.1bn — inverse of pl9); noeed 16.3; ban2040 13.4; split 15.8; inclusive 27.2 (2.6×); peffrozen 34.3; sav4666 13.6 (+31%, mechanism open); hpcost_lo 10.8 / hi 14.6. Hypotheses H32–H37 scored in CHANGELOG | CCG searches seed 42, 2026-11-02 | pl10 family (base10 = base9 + measure_costs/measure_reductions PL2026) | search bounds, heuristic — multistart restarts + 8 proofs RUNNING detached | **Y** (as pl9 + MFH HP proposal, n=0.5 ventilation, deep-saves-less) |
| `figures_pl10/fig1..fig6_*.{svg,png,csv}`, `pl10_design_table.csv`, `pl10_scenarios_summary.csv` (2026-11-03; script `make_pl10_figures.py`) | Paper/slide figures 1–6 on the pl10 family, **best available result per scenario** (multi-start best; certificate where one exists — every value carries `result_label` search/certified; at export time ALL pl10 values are search bounds, no pl10 certificate landed yet). Fig1 σ=0 vs standard vs EPBD trajectory (σ=0 misses 2030/2040); Fig2 spending/uptake per income×WPB group + rentals (rentals get €0 — landlord rates 0); Fig3 all-scenario spending vs standard w/ feasible-infeasible; Fig4 poor 2050 cost share unrenovated vs after-policy stock average (per-dwelling renovated-only bill NOT IN MODEL — archetype-average accounting; **private rental after-policy 9.3% > unrenovated 8.9%, a finding, stated in the figure title**); Fig5 uptake by tenure; Fig6 tenant bill+rent increase per rent rule (rule_perm from ms_pl9cert restart) + public landlord own spend EED on/off (€2.18bn vs €0). Re-run the script after certificates land — it ingests `cert_*_hybrid.log` automatically | pl10 batch + multistart winners (ms dirs in worktree until merge) | per Fig6: all five rent rules; afford off | search bounds (labelled per value) | **Y** (as pl10) |
| (scratchpad `est_merge_{pl9,pl10,pl10_noeed}.log`; numbers of record in CHANGELOG entry "Merge-time estimate for pl10/noeed", 2026-11-03) | **Merge-time estimate, read-only sampled replication** (user order): cross product identical for pl9/pl10/noeed (105,644 poor × 9,984 rich × 14 × 14 = 2.067e11). Validation on pl9: estimate 24,427 s vs true 22,074.8 s (+10.7%). Calibrated solo-equivalent cross product **pl10 ≈ 13.2 h, noeed ≈ 14.5 h** (≈ 2.2–2.4× pl9's inner work; spend3 prune 66% → 27%/20%). ETA from 18:04: pl10 ≈ 0–2.5 h, noeed ≈ 0.5–4 h remaining → **"> ~6 h" condition NOT met, parallel merge NOT launched for pl10/noeed**; parallel combine() implemented in `worktree-parallel-merge` (exact-reproduction design), pl9 verification run in progress for the three remaining merges | shard .jls tables + 28 landlord follower solves, byte-identical arithmetic, 1-in-64 stride | pl9 / pl10 / pl10_noeed | timing estimate only — NOT results; sample best values are not bounds of record | n/a |
| `../out/scenarios/pl9*/`, `pl8_*/` (phase 2, 2026-10-27/29; logs `cert_logs/run_pl9*.log`, `run_pl8_*.log`, diagnostics `diag_sigma0_pl9.log`, `diag_maxsigma_*.log`, `diag_cross_elecp20_design.log`) | **NEW STANDARD pl9** — corrected carrier prices (elec 2025 avg 0.2634), fossil mixes, seasonal efficiencies η, subsidy horizon 2050: **CERTIFIED grid optimum €10,094.8M** (2026-10-29, `cert_logs/cert_pl9_hybrid.log` + `cert_pl9_shard1..8.log`; σ: env poor 15/25/25, rich 0/5/15, HP-standard poor 90%; heuristic bound €11.384bn was +12.8% above — see CHANGELOG certificate entry); search history: €11.384bn (best of seeds 42/7; equity 41–43%, E2050 ~106 vs target 108.4 — 2050 target now the tight margin); σ=0 infeasible (2030 −6.1 / 2040 −12.7 / 2050 −10.1). Sweeps: SQ1 income-share INFEASIBLE up to s=0.20 (finding; edge between €1,927–2,409/yr; private-rental tenants + the capacity-bound unrenovated remainder bind — max-σ diagnostic), feasible and slack from s=0.25; r12 INFEASIBLE even at max subsidies (2030 −5.5, 2040 −2.0 — myopia bound); no-EED 14.83 (EED saves €3bn); ban2040 14.22 (**ban now COSTS ~€2.8bn**: forced switching saturates the joint labour cap and crowds out envelope); elec+20% 10.84 / −20% 11.86 (REAL behavioural effect — cheap electricity induces renovation delay; cross-check: the elec+20% design is infeasible under pl9); CO₂×0.5 24.35; PEF frozen 17.37; hvac6 9.64; KPRB@absolute targets 0.79 | CCG searches (both seeds noted in CHANGELOG) | pl9 family + pl8_* re-derived from base9 | **pl9 CERTIFIED (hybrid grid) 2026-10-29**; sweeps remain search bounds (heuristic) | **Y** (firewood price, MFH mix, η table citation, oil — all flagged in PROVENANCE_polish_stock.md) |
| `../out/scenarios/pl_r8{,_eqoff,_eq20,_eq40,_all12,_split}/` (+ `cert_logs/run_pl_r8*.log`, `diag_sigma0_pl_r8.log`) | Household discount rate separated from the state's (owners + private landlords 8% calibrated to the ≈1%/yr observed EU renovation pace, public landlord 3%; PROVENANCE_polish_stock.md): σ=0 now INFEASIBLE (2030/2040 milestones) → optimum **€5.257bn** with the 2030+2040 milestones binding and the **equity floor SLACK at every level (64.4% natural)** — the r=3% floor-binds finding inverts; all-12% €13.45bn, split 12/8 €7.52bn; design regime change (light envelope in, poor heat pumps out) | CCG searches 2026-10-27 | pl_r8 family | search bounds, heuristic (plain ordering, zero-envelope designs reachable) | **Y** (as pl_standard; 8% calibrated, literature context Schleich et al. 2016, Kubiak 2016) |
| `../out/scenarios/pl_eq{off,20,40}/` | Equity-floor sweep on the PL standard (2026-10-27): spending €5.762 / 6.116 / 8.152bn at floor off/20%/40% (30% standard: €6.989bn); natural equity share 15.0%; the floor's price is +21% (30%) / +41% (40%) vs no floor, spent entirely on poor-owner heating subsidies (HP uptake 6.7→41.9%); rented sector invariant (EED pins public at 72%) | CCG searches 2026-10-27 | pl_standard + equity_floor_value lever | search bounds, heuristic | **Y** (as pl_standard) |
| `../out/scenarios/pl_{standard,kprb,pubpoor,hvac6}/` (full run outputs; logs `cert_logs/run_pl_*.log`) | NEW STANDARD MODEL — Polish census stock, 2026-10-27 (8.85M dwellings, national absolute EUR; Invert WPB cut at census weights, workbook verification OPEN; EED on, rule_PL, ban off, relative EPBD trajectory, KPRB capacity). Searches: spending €6.989bn (standard) / €5.701bn (KPRB demand) / €6.988bn (all public tenants low-income; near-tie design paying landlords 31/50%) / €6.517bn (6%/yr heating); trajectory + 2050 target met in all; WPB rule slack; **the 30% equity floor BINDS in all four (29.9%)** — headline finding vs the stylised stock; public rental hits the EED requirement exactly (72% deep by 2050) | `bilevel_model_affordable_housing.jl` CCG (2026-10-27) | pl_standard + 3 sensitivities; stock data/PROVENANCE_polish_stock.md | **search bounds, heuristic — no certificates yet** (hybrid-grid proof defined, not run: 140,176 solves ≈ 88 h serial) | **Y** (ρ_public 0.02 open; Invert workbook verification OPEN; costs/prices/PEF paths assumed-to-be-replaced) |
| `../out/scenarios/E3_publandlord/{pub_w00,pub_w05,eed_pub_w00,eed_pub_w05}_{eval,run}.csv` | Sub-question 2 (E3 public-landlord institutions, 2026-10-27: EED Art. 6 nZEB obligation × tenant-cost weight w, at the certified D0 rates, fossil-boiler ban FORCED ON). nZEB-proxy share 2050: 0% without the obligation (w 0 and 0.5 — no deep envelope at these rates), 71.2% with it (capacity-clipped requirement, fossil 69.5% / DH 72%); public-landlord discounted outlay €0.22M → €0.68M (w=0.5) → €3.48M/€3.59M (EED); public tenants under EED pay €189–270/yr levy but bills fall more (poor-fossil 966→403), so net tenant cost FALLS; leader spending €3.998M and trajectory verdict unchanged in all four | `run_eval_pub.jl` (2026-10-27; follower evaluations, leader not re-optimised) | scenarios pub_w00/05, eed_pub_w00/05; ban forced via P4_FORCE_BOILER_BAN | heuristic follower evaluation at the certified D0 rates (no bound claim) | **Y** (ρ_public 0.02 open + derived private share; EED requirement capacity-clipped per CHANGELOG correction) |
| `_scratch/e1_rule_pl_summary.csv`, `_scratch/e1_rule_pl_uptake_by_group.csv` | Sub-question 2 (E1 under the Polish rent rule: envelope 2050 public 5.4% / private 43.6% / low-income owners 43.5% of dwellings) | follower-only evaluation at the certified D0 rates, s4_rule_pl config (2026-10-09) | see row text | evaluation at the certified rates (no search) | **Y** (private share + tenant split open) |
| `paper_tables/{measures,parameters,model_structure}.{csv,tex}` | Methods section (values as loaded + stored source strings) | `make_paper_tables.py` (regenerated 2026-10-11, wave-9 incomes incl. Q2–Q5 mean; reads measures_v2/archetypes_v2/context CSVs and the model file) | see row text | exact export (no solve) | N (source strings missing are marked "not in model") |
| `paper_figures/fig2_heating_mix_pe`, `fig3_spending_vs_income_share`, `fig4_uptake_by_tenure`, `fig5_clawback_sweep` (.pdf/.png + `_data.csv`) | Paper figures 2–5 | `make_paper_figures.py` (regenerated 2026-10-11) from stored wave-9 runs: baseline, income-share sweep, E1 + tenure_afford, S1 + S3 | see row text | as the underlying runs (search bounds; Fig 4a evaluation at certified rates) | Fig 4: **Y** (private share derived + split AROP-based, flagged) |
| `table5_rent_rule_choice.csv` (+ grid `_scratch/l3lite_grid.csv`) | Sub-question 2 (institutional: rule as leader choice, H11) | L3 lite, Polish-frame subset since 2026-10-12: 8 of the 48 `l3_*` runs (`l3_r10_capn_*`; rerun 2026-10-11, wave 9) + collector; the other 40 run outputs untouched on disk | the rule IS the choice variable (ρ 0.10, no cap; recovery/permanent × net/gross); zero_subsidy + frozen_stock blocks | search bound | **Y** (public ρ 0.02 open; private share derived + split AROP-based, flagged) |
| `cert_logs/cert_D4_tenure_on.log` (certificate of record for D4) | Main question + sub-question 2 | `enumerate_exact.jl 0.1 tenure_on 0.1` (2026-10-10, 00:11–04:43) | **rule_PL** (default pinned in the run config); afford off | **certified 10% grid + landlord 10% grid**: optimum €3.998M = D0 design + landlord rates 0/0 | certificate pins the WAVE-8 shares (0.082/0.05, split 0.5) — predates wave 9 |

Update this table every time an output is written.

**Provenance (checkpoint 6).** Every run folder under `out/scenarios/`
carries `config_used.txt` (full config, git commit, tree state; the two
pre-writer runs are stamped retroactively and say so). Every results
folder carries `provenance.txt`. `./reproduce_all.sh` regenerates all
ledgered outputs (`--with-certs` adds the ~12 h exact-grid
certifications). **The working tree is dirty and `affordable_housing/`
is untracked at stamp time — the recorded hash does not pin this code;
commit before citing results.**

## Table 1 — equity rule comparison (sub-question 1) — CERTIFIED (10% grid, 2026-10-01; re-certified 2026-10-10 on sourced data, same optimum €3.998M / same design)

**Reference update (2026-10-01 afternoon, zero_subsidy main case).** The
certified design re-evaluated under the zero_subsidy reference remains
feasible: low-income stock-weighted cost €1,425/yr vs reference €1,464/yr at 2050
(margin 2.7% — much tighter than the €2,442 frozen-stock threshold, but
slack). Since the certified D0 optimum satisfies the added constraint, it
remains the certified optimum for D2/D3 under the main reference — the table
below carries over unchanged; only the "low-income cost before" column reading
depends on the reference (frozen-stock values shown). D3 re-run heuristically
under both references returns the same €2.9M search bound. Figure 1 is
regenerated under the main reference (no-subsidy response decomposed into
bill + own contribution).

All three designs coincide: neither the spending floor nor the cost-neutral
affordability constraint binds at the Polish cost-minimum (**H1 confirmed**).
The regression gate passed: D0 on the new code path returned the parent
repository's €3.998M exactly. The search column shows the grid-granularity
gap (continuous rates reach €2.9M; "optimal" below means optimal on the grid).

| Row | Spending (certified) | (search bound) | Δ vs D0 | Rates (low-income/high-income) | E2050 | Share to low-income | Low-income cost before | after | Status |
|---|---|---|---|---|---|---|---|---|---|
| Reference (no programme) | — | — | — | none | — | — | €2,442/yr | €2,442/yr | income 10%: **violated** (27% of income; SFH_poor 39%) |
| D0 = D1 floor only | **€4.0M** | €2.9M | 0 | env_med 10/10, env_deep 10/10, HP 0/0, DH 0/0 | 72.4 | 44% | €2,442 | €1,425 | floor slack (44% > 30%) |
| D2 affordability only | **€4.0M** | €2.9M | 0 | same | 72.4 | 44% | €2,442 | €1,425 | affordability slack (worst margin 6.6%, SFH_poor 2030) |
| D3 both | **€4.0M** | €2.9M | 0 | same | 72.4 | 44% | €2,442 | €1,425 | both slack |

Low-income cost = stock-weighted mean annual housing energy cost per dwelling across
the three low-income archetypes at the 2050 end state (bill + annualised own
contribution); per-archetype detail in each run's `affordability_by_archetype.csv`.

**Energy-poverty pre-check (income-share indicator — HISTORICAL, computed
2026-10-01 with the OLD €9,000 placeholder income; shares scale by factor
9,000/11,560 ≈ 0.78 under the sourced income, the qualitative picture
stands).**
In the reference (no-programme) case low-income households already violate the 10% indicator:
SFH_poor spends 20% of income on heating in 2030, rising to 39% by 2050 as the
CO₂ price grows; MFH_poor_fossil reaches 17%; only MFH_poor_dh stays under 10%.
The reference case becomes feasible under the indicator only at s ≈ 0.39 (2050)
— far beyond the swept range {0.10, 0.15, 0.20}. This is a finding, not a bug:
by the classic 10% indicator, the low-income coal-heated stock starts in energy
poverty before any policy. The income-share constraint is therefore applied to
the END STATE (period ending 2050) and asks whether the programme can LIFT
households out of energy poverty, which the cost-neutral rule cannot ask.

**Income-share rows (search bounds, heuristic — SOURCED incomes, rerun
2026-10-08, wave 8).** Same model, affordability as an income-share cap s
on the 2050 end state instead of the cost-neutral rule; low-income household income
€11,560/yr (GUS 2024 Q1). Δ is taken against D0's €2.9M search bound (like
for like — none of these rows is certified). Data:
`out/scenarios/afford_incshare*`; sweep summary
`_scratch/incshare_sweep_summary.csv`. The 2026-10-01 placeholder-income
values (first feasible s = 0.14 at €32.9M; s = 0.15 €28.9M; s = 0.20 €7.4M;
capacity-relaxed €52.3M) are SUPERSEDED — kept in the CHANGELOG.

| s (share of income) | € limit (s × €11,560) | Feasible | Spending (search bound) | Δ vs D0 (search) | Equity share to low-income | E2050 | Status |
|---|---|---|---|---|---|---|---|
| 0.10 | €1,156/yr | **no** | — | — | — | — | infeasible: failing tag is affordability, never the energy trajectory |
| 0.11 | €1,272/yr | yes | €32.3M | +€29.4M | 97% | 71.1 | first feasible point |
| 0.12 | €1,387/yr | yes | €29.7M | +€26.8M | 96% | 71.3 | |
| 0.13 | €1,503/yr | yes | €19.4M | +€16.6M | 88% | 66.0 | |
| 0.14 | €1,618/yr | yes | €13.3M | +€10.5M | 91% | 71.0 | |
| 0.15 | €1,734/yr | yes | €9.1M | +€6.2M | 88% | 71.1 | |
| 0.20 | €2,312/yr | yes | €2.9M | +€0.0M | 61% | 72.4 | indicator slack at the unconstrained cost minimum |
| 0.10 (capacity relaxed) | €1,156/yr | yes | €27.1M | +€24.2M | 92% | 54.1 | DIAGNOSTIC (reno_scale=100) |

**H10 verdict (pre-registered 2026-10-08: "the s = 0.10 threshold rises
from €900 to ≈ €1,156/yr, so feasibility at s = 0.10 may change").**
The threshold rose exactly as expected; s = 0.10 nevertheless stays
infeasible — €1,156/yr still sits below the infeasibility edge, which under
both income vintages lies in the same EURO band (old: between €1,170 =
0.13×9,000 and €1,260 = 0.14×9,000; new: between €1,156 = 0.10×11,560 and
€1,272 = 0.11×11,560). What the sourced income moves is the SHARE at which
feasibility starts (s = 0.14 → s = 0.11) and the price of every feasible
point (s = 0.15: €28.9M → €9.1M; s = 0.20 now sits at the €2.9M
unconstrained floor). This confirms the 2026-10-01 capacity finding: the
binding quantity is the euro cost cap (capacity-limited renovation of the
coal-heated low-income stock), not the share itself — the capacity-relaxed
diagnostic again makes s = 0.10 feasible (€27.1M).

## Table 2 — headline design-case table (main question, sub-question 2) — search bounds; wave-9 data, 2026-10-11

Spending in €M (1 d.p.); envelope renovation shares at 2050 in % (0 d.p.,
dwelling-weighted); E2050 in kWh/m²a (1 d.p.). All tenure rows rerun
2026-10-11 (wave 9): incomes 9,635 (Q1) / 23,761 (Q2–Q5 mean), public
share 0.082 (sourced), private share 0.08 (derived), tenant split
0.16/0.84 (AROP-based), rule_PL default; shares-doubled sensitivity now
0.164/0.16. **Certificates:** D0, D2, D3 each re-certify (2026-10-10)
the grid optimum €3.998M at the D0 design; **D4 is certified UNDER
rule_PL** (10% owner grid × 10% landlord grid): optimum €3.998M = D0
design + landlord rates 0/0 — landlord instruments are certifiably not
part of the cost-minimal design under the Polish rule. The D4
certificate was re-run 2026-10-12 on the wave-9 inputs (shares
0.082/0.08, split 0.16/0.84) and is character-identical to the wave-8
one (same optimum, same σ, same −38.6% heuristic gap); the old
certificate is archived as `cert_D4_tenure_on_wave8shares_20261010.log`.
€2.9M vs €4.0M is grid granularity (env_med 5% lies between grid
points), not a contradiction. *E1 in italics: evaluation at the
certified D0 rates, leader not re-optimised.*

| Case | Spending | Δ vs D0 | Landlord rates pub/priv | E2050 | Env 2050 own-low-income / own-high-income / rent-pub / rent-priv | Afford own-low-income / pub-ten / priv-ten | Status |
|---|---|---|---|---|---|---|---|
| D0 baseline (floor only) | €2.9M | +0.0M | n/a/n/a | 72.4 | 42% / 33% / n/a / n/a | Y / n/a / n/a | certified 10% grid (re-certified 2026-10-10) |
| D3 + affordability (cost-neutral) | €2.9M | +0.0M | n/a/n/a | 72.4 | 42% / 33% / n/a / n/a | Y / n/a / n/a | certified 10% grid (2026-10-10) |
| D4 + tenure (landlords; no affordability) [rule_PL] | €2.9M | +0.0M | 0/0 | 73.8 | 44% / 35% / 5% / 44% | Y / Y / Y | **certified 10% grid under rule_PL (re-certified 2026-10-12 on wave-9 shares)** |
| D5 + tenure + affordability [rule_PL] | €2.9M | +0.0M | 0/0 | 73.8 | 44% / 35% / 5% / 44% | Y / Y / Y | search bound |
| *E1 baseline rates (no re-optimisation)* [rule_PL] | €4.0M | +1.1M | 0/0 | 73.8 | 44% / 35% / 5% / 44% | Y / Y / Y | evaluation at D0 certified rates |
| D5x affordability for owners + public tenants [rule_PL] | €2.9M | +0.0M | 0/0 | 73.8 | 44% / 35% / 5% / 44% | Y / Y / Y | search bound |
| D3 sensitivity: frozen-stock reference | €2.9M | +0.0M | n/a/n/a | 72.4 | 42% / 33% / n/a / n/a | Y / n/a / n/a | search bound |
| D5 sensitivity: frozen-stock reference [rule_PL] | infeasible | — | —/— | — | n/a / n/a / n/a / n/a | — / n/a / n/a | search bound |
| D5x sensitivity: frozen-stock reference [rule_PL] | €2.9M | +0.0M | 0/0 | 73.8 | 44% / 35% / 5% / 44% | Y / Y / N | search bound |
| D4 sensitivity: rental shares doubled (0.164/0.16) [rule_PL] | **€10.7M** | **+7.8M** | 0/0 | 74.8 | 64% / 37% / 5% / 44% | Y / Y / Y | search bound |
| D5x sensitivity: rental shares doubled (0.164/0.16) [rule_PL] | **€10.7M** | **+7.8M** | 0/0 | 74.8 | 64% / 37% / 5% / 44% | Y / Y / Y | search bound |

Owner rates are identical in the €2.9M rows (env 0/5/10 low-income and
high-income, HVAC 0; E1 uses the certified 0/10/10) — full strings in the
CSV. **Wave 9 changed no design and no verdict in the main cases**: D4,
D5, D5x and D5x-frozen all stay at €2.885M with landlord rates 0/0;
D5-frozen stays infeasible; E2050 73.7 → 73.8 and the env columns shift
≤1 pp (archetype re-weighting under the new shares/split). The
`d5_inc_signalnote` sensitivity (old signal-note incomes 11,560/35,920)
is IDENTICAL to D5 at €2.885M — the income choice does not move the
cost-neutral designs. **The one mover is the shares-doubled sensitivity:
€2.9M → €10.7M** (E2050 74.8; owner-low-income envelope 44% → 64%). NOT
a like-for-like comparison with the old €2.9M row: the rerun doubles the
NEW shares (0.164/0.16 vs 0.164/0.10), runs rule_PL instead of rule_DE
and carries the 0.84 split — with a third of the MFH stock rented, the
EPBD target can no longer be met from the (smaller) owner stock at the
old rates and the leader pays for deep owner renovation. Recorded as
found (CHANGELOG wave 9); no decomposition run. **D5 remains feasible
under the zero-subsidy MAIN reference and infeasible under the
frozen-stock sensitivity** (CHANGELOG, H5). No landlord ever accepts a
grant in any run; both landlord rates are 0 in every optimum.
*Incomes (low-income = Q1, high-income = Q2–Q5 mean) and the public
share sourced; private share 0.08 derived (assumes market-rent tenants
live in MFH); split 16/84 AROP-based; public landlord ρ 0.02 open.*

## Table 3 — tenant cost decomposition at 2050 (sub-question 2) — search bounds; wave-9 rerun 2026-10-11, rule_PL

€/yr per dwelling (per-m² columns in the CSV). 'Total before' = the
zero-subsidy reference (own response at σ = 0, incl. any voluntary
renovate-and-levy); 'bill before' = un-renovated building at 2050 prices.
D5 and E1 rows coincide because low-income owners adopt only deep envelope,
whose rate is 10% in both designs. The `rented_private_rich` row
(2026-10-08 decision) carries the high-income tenant — since wave 9 the
**Q2–Q5 mean income €23,761** (correction 2026-10-11; was Q5 €35,920);
indicators only, affordability NOT enforced. Its € columns are identical
to the low-income private tenant's BY CONSTRUCTION (same building, same
landlord, same levy — confirmed as the twins gate); only the
cost-to-income indicator differs.

| Case | Group | Bill before | Bill after | Rent increase | Own contribution | Total before | Total after | Change | Cost/income 2050 |
|---|---|---|---|---|---|---|---|---|---|
| D5 (tenure + affordability) | owner-occupier (low-income) | €2552 | €922 | €0 | €566 | €1530 | €1488 | -2.7% | 15.4% |
| D5 (tenure + affordability) | public rental (low-income tenant) | €862 | €695 | €16 | €0 | €711 | €711 | 0.0% | 7.4% |
| D5 (tenure + affordability) [rule_PL] | private rental (low-income tenant) | €862 | €494 | €563 | €0 | €1057 | €1057 | 0.0% | **11.0%** |
| D5 (tenure + affordability) [rule_PL] | private rental (high-income tenant, Q2–Q5) | €862 | €494 | €563 | €0 | €1057 | €1057 | 0.0% | **4.4%** |
| E1 (baseline rates; no re-optimisation) | owner-occupier (low-income) | €2552 | €922 | €0 | €566 | €1530 | €1488 | -2.7% | 15.4% |
| E1 (baseline rates; no re-optimisation) | public rental (low-income tenant) | €862 | €695 | €16 | €0 | €711 | €711 | 0.0% | 7.4% |
| E1 (baseline rates; no re-optimisation) [rule_PL] | private rental (low-income tenant) | €862 | €494 | €563 | €0 | €1057 | €1057 | 0.0% | 11.0% |
| E1 (baseline rates; no re-optimisation) [rule_PL] | private rental (high-income tenant, Q2–Q5) | €862 | €494 | €563 | €0 | €1057 | €1057 | 0.0% | 4.4% |

(Cost/income = stock-weighted 2050 total ÷ sourced income: owner
€1,488/9,635, low-income tenants /9,635, high-income tenant /23,761.)
**Wave 9 left the euros essentially unchanged** (owner row ±€12 from
archetype re-weighting; tenant rows identical) — what moved are the
RATIOS, re-based to the Tablica-2 incomes: private tenant 9.1% → 11.0%
of the low income (income −17%), 2.9% → 4.4% of the high income (Q5 →
Q2–Q5 mean). Under the frozen-stock sensitivity the private DH tenant
violates warm-rent neutrality in every period (min gap €123/yr; no rate
≤ 100% fixes it). *Same data footnotes as Table 2.*

## Table 4 — institutional rent-law scenarios (S4, sub-question 2) — search bounds, wave-9 rerun 2026-10-11; Poland-only table since 2026-10-12

*Poland-only order (2026-10-12): the two rule_DE rows were dropped from the
reported table and Figure 6; the `s4_rule_de` / `s4f_rule_de` run outputs
are untouched on disk and their wave-9 values remain recorded in the H9
paragraph below (historical finding record).*

Data: `table4_institutional_scenarios.csv`; tenant cost paths in
`figures/figure6_tenant_cost_rules.{png,svg}` (+ `figure6_data.csv`).
All runs are the D5 configuration with the rule-specific private
pass-through (public landlord 0.02 open throughout). Levy and deltas are
stock-weighted low-income-private-tenant values; levy % income at the peak year.

| Rule | Reference | Feasible | Spending | Env 2050 private | Levy peak €/yr | Levy % income low-income / high-income | Tenant Δ vs own ref (peak / 2050) | Landlord takes grant |
|---|---|---|---|---|---|---|---|---|
| rule_PL (10%, uncapped, ~10 y recovery) | zero_subsidy | yes | €2.9M | 44% | €563 | 5.8% / 2.4% | €0 / €0 | N |
| rule_PL_gross (grants NOT netted) | zero_subsidy | yes | €2.9M | 44% | €563 | 5.8% / 2.4% | €0 / €0 | N |
| rule_none (no pass-through) | zero_subsidy | yes | €2.9M | 5% | €0 | 0 / 0 | €0 / €0 | N |
| rule_PL_capped (10% + 3 €/m² cap) | zero_subsidy | yes | €2.9M | 15% | €190 | 2.0% / 0.8% | €0 / €0 | N |
| rule_PL_permanent (10%, uncapped, no expiry) | zero_subsidy | yes | €2.9M | 71% | €1,788 | 18.6% / 7.5% | €0 / €0 | N |
| rule_PL | frozen_stock | **no** | — | — | — | — | — | n/a |
| rule_PL_gross | frozen_stock | **no** | — | — | — | — | — | n/a |
| rule_none | frozen_stock | yes | €2.9M | 5% | €0 | 0 / 0 | €0 / −€167 | N |
| rule_PL_capped | frozen_stock | **no** | — | — | — | — | — | n/a |
| rule_PL_permanent | frozen_stock | **no** | — | — | — | — | — | n/a |

**Reading.** Under the main (zero_subsidy) reference every rule is feasible
at the €2.9M floor and the subsidy-induced tenant delta is zero everywhere:
the optimum never uses the landlord instruments, so what differs across
rules is the VOLUNTARY renovate-and-levy equilibrium, which the reference
absorbs. The rule decides how much the private stock renovates and what the
tenant pays for it: Polish 10% uncapped → 44% of private dwellings
renovated by 2050 at a €563/yr peak levy (5.8% of the low-income tenant's
income under the wave-9 Tablica-2 incomes); with a 3 €/m² cap added → 15%
at €190/yr; no pass-through → 5% and no levy. The € values are unchanged
from wave 8 (the data load re-based only the income ratios: 4.9 → 5.8%
etc.). The cap, not the rate, is the binding lever (rule_PL_capped drops
uptake 44% → 15%), and the Art. 8a expiry is what keeps the Polish
rule tolerable (permanent 10% → 71% renovated at €1,788/yr = 18.6% of
the low income). Figure 6 (tenant cost paths, PL vs none since 2026-10-12):
the Polish-rule tenant peaks at €1,057/yr in 2050 vs €695 (no rule) —
€361/yr above no-rule at 2050 — and only by 2060, when the last big
vintages expire, does the Polish path fall back (€787/yr).
Under the frozen-stock reference EVERY rule with a positive private
pass-through is infeasible (as D5-frozen already was under the German
placeholder): the levy itself breaks warm-rent neutrality against a frozen
reference and no instrument can compensate.

**H9 verdict (pre-registered 2026-10-08, verbatim: "Under the Polish rule
(10%, uncapped, temporary) the private tenant's peak-year harm is larger
than under the German rule, but the 2050 harm is zero because the levy has
expired; landlords still refuse grants when the base is net of grants, and
accept them when it is gross.")** *(Historical finding record — the rule_DE
numbers here stay although rule_DE left the reported table 2026-10-12.)*
Part 1 CONFIRMED: peak harm vs rule_none
is €361/yr (PL) vs €119/yr (DE, 2040). Part 2 CONTRADICTED — recorded as a
finding, parameters NOT tuned: 2050 is the Polish PEAK, not zero, because
renovation keeps producing fresh levy vintages through the horizon (44% of
the stock renovates, 3× the German level) and the 2040–2050 vintages are
still inside their ~10-year windows at 2050; expiry only shows at 2060.
The hypothesis implicitly assumed a single early renovation wave. Part 3
HALF-CONFIRMED, half not testable at the optimum: no grant flows under
EITHER netting rule (rows identical) — but not because landlords refuse;
the leader never offers a landlord rate > 0, since the EPBD target is met
without the private stock. Grant acceptance is never tested at the
optimum; the netting question would only bind in a design forced to use
landlord grants.

*rule_PL values sourced (Art. 8a, rent-law key table); grants-netted and
PV-in-base interpretive; public rate 0.02 open; private share 0.08
derived, split 16/84 AROP-based (wave 9, flagged).*

## Table 5 — rent rule as a leader choice (L3 lite, sub-question 2) — search bounds, wave-9 rerun 2026-10-11; Polish-frame candidate set since 2026-10-12

Data: `table5_rent_rule_choice.csv`; grid per block in
`_scratch/l3lite_grid.csv`. Candidate set since the 2026-10-12 Poland-only
order: rate 0.10, no cap, duration {recovery, permanent} (the rule_DE-style
candidates ρ 0.05/0.08 and the 3 €/m² cap are no longer collected; the 48
run outputs all remain on disk). Leader subsidy rates re-optimised per rule
(CCG heuristic — search bounds); choice = minimum spending, ties broken by
lowest low-income-tenant peak levy, then lexicographic (pre-registered).

| Reference | Base | Chosen rule | Spending | Tied at min | Env 2050 private | Levy peak | % of low-income tenant income | Landlord subsidy enters |
|---|---|---|---|---|---|---|---|---|
| zero_subsidy | net | **ρ 0.10; no cap; recovery (= rule_PL)** (levy tie-break over permanent) | €2.9M | 2 (recovery, permanent) | 44% | €563/yr | 5.8% | N |
| zero_subsidy | gross | **ρ 0.10; no cap; recovery (= rule_PL)** (levy tie-break over permanent) | €2.9M | 2 (recovery, permanent) | 44% | €563/yr | 5.8% | N |
| frozen_stock | net | **none feasible** | — | 0 | — | — | — | n/a |
| frozen_stock | gross | **none feasible** | — | 0 | — | — | — | n/a |

*Pre-2026-10-12 record (full 12-rule grid): all 12 rules tied at €2.9M;
the pre-registered tie-break then selected ρ 0.05 + 3 €/m² cap + recovery
(28% env 2050, €190/yr, 2.0%) — kept here as the H11 history; within the
Polish frame the same tie-break selects exactly rule_PL.*

**H11 verdict** (pre-registered: "a capped, permanent rule is chosen;
under gross base a landlord subsidy enters the optimum"): HALF-SUPPORTED
at best. Spending cannot distinguish the rules — all 12 tie at the €2.9M
floor under the main reference — so "capped" is selected only by the
pre-registered levy tie-break, and "permanent" is not selected (recovery
wins the final lexicographic step; a capped permanent rule is
levy-identical). The landlord-subsidy clause is CONTRADICTED (finding):
no landlord euro flows in any of the 48 optima, gross base included —
the leader meets the EPBD target without the private rental stock, so it
never pays landlords (consistent with the D4 certificate and E2). Under
the frozen-stock reference no rule in the grid is feasible: the smallest
rate 0.05 already breaks warm-rent neutrality and grants cannot repair
it (E2 mechanism). **Wave-9 rerun (2026-10-11): choice, tie structure and
verdicts identical** — only the levy ratio re-based (1.6 → 2.0% of the
Tablica-2 low income).

## Household structure (exported from the loaded model, wave 9, 2026-10-11)

Generated by `household_structure.jl` from the model's own globals after
the `tenure_afford` (D5, wave-9 data of record) config is applied — not
from documentation; regenerates with every `reproduce_all.sh` run. CSV:
`results/household_structure.csv`. Shares are DWELLING shares of the
total stock (dwellings in thousands, `archetypes_v2.csv` convention).
**Rented variants are split from ALL FOUR MFH owner archetypes** (both
income groups, both heating systems); note the literal "rich/poor" in
the archetype KEY refers to the parent BUILDING's owner-income class,
while the tenant's own income group is set by the variant (public and
private-poor variants carry low-income tenants; the `_rent_priv_rich` twin
high-income).

| Archetype | Group | Bldg | Heating at start | Renovation decider | Bill payer | Income group (€/yr) | Parent | Dwelling share | Share source | Liquidity cap €/yr | Affordability enforced |
|---|---|---|---|---|---|---|---|---|---|---|---|
| SFH_poor | owner-occupier | SFH | fossil_boiler | owner | owner | low-income (9,635) | — | 0.15000 | (a) | 5,000 | yes |
| SFH_rich | owner-occupier | SFH | fossil_boiler | owner | owner | high-income (Q2–Q5) (23,761) | — | 0.30000 | (a) | 12,000 | no |
| MFH_poor_dh | owner-occupier | MFH | district_heat | owner | owner | low-income (9,635) | — | 0.05866 | (a) | 5,000 | yes |
| MFH_poor_fossil | owner-occupier | MFH | fossil_boiler | owner | owner | low-income (9,635) | — | 0.02514 | (a) | 5,000 | yes |
| MFH_rich_dh | owner-occupier | MFH | district_heat | owner | owner | high-income (Q2–Q5) (23,761) | — | 0.26397 | (a) | 12,000 | no |
| MFH_rich_fossil | owner-occupier | MFH | fossil_boiler | owner | owner | high-income (Q2–Q5) (23,761) | — | 0.11313 | (a) | 12,000 | no |
| MFH_poor_dh_rent_pub | public rental | MFH | district_heat | public landlord | tenant | low-income (9,635) | MFH_poor_dh | 0.00574 | (b) | 5,000 | yes |
| MFH_poor_dh_rent_priv | private rental | MFH | district_heat | private landlord | tenant | low-income (9,635) | MFH_poor_dh | 0.00090 | (c) | none | yes |
| MFH_poor_dh_rent_priv_rich | private rental | MFH | district_heat | private landlord | tenant | high-income (Q2–Q5) (23,761) | MFH_poor_dh | 0.00470 | (c) | none | no |
| MFH_poor_fossil_rent_pub | public rental | MFH | fossil_boiler | public landlord | tenant | low-income (9,635) | MFH_poor_fossil | 0.00246 | (b) | 5,000 | yes |
| MFH_poor_fossil_rent_priv | private rental | MFH | fossil_boiler | private landlord | tenant | low-income (9,635) | MFH_poor_fossil | 0.00038 | (c) | none | yes |
| MFH_poor_fossil_rent_priv_rich | private rental | MFH | fossil_boiler | private landlord | tenant | high-income (Q2–Q5) (23,761) | MFH_poor_fossil | 0.00202 | (c) | none | no |
| MFH_rich_dh_rent_pub | public rental | MFH | district_heat | public landlord | tenant | low-income (9,635) | MFH_rich_dh | 0.02583 | (b) | 5,000 | yes |
| MFH_rich_dh_rent_priv | private rental | MFH | district_heat | private landlord | tenant | low-income (9,635) | MFH_rich_dh | 0.00403 | (c) | none | yes |
| MFH_rich_dh_rent_priv_rich | private rental | MFH | district_heat | private landlord | tenant | high-income (Q2–Q5) (23,761) | MFH_rich_dh | 0.02117 | (c) | none | no |
| MFH_rich_fossil_rent_pub | public rental | MFH | fossil_boiler | public landlord | tenant | low-income (9,635) | MFH_rich_fossil | 0.01107 | (b) | 5,000 | yes |
| MFH_rich_fossil_rent_priv | private rental | MFH | fossil_boiler | private landlord | tenant | low-income (9,635) | MFH_rich_fossil | 0.00173 | (c) | none | yes |
| MFH_rich_fossil_rent_priv_rich | private rental | MFH | fossil_boiler | private landlord | tenant | high-income (Q2–Q5) (23,761) | MFH_rich_fossil | 0.00907 | (c) | none | no |

Share sources: **(a)** residual of the raw stock row after the tenure
split (`archetypes_v2.csv` dwellings); **(b)** SOURCED — 595,800
municipal (GUS 2024) + TBS/SIM ≈ 110k approximate ÷ 8,609,900 MFH
dwellings (Census 2021) = 0.082 of each MFH archetype; **(c)** DERIVED —
private share 0.08 = 0.05 × 14.1M households ÷ 8.61M MFH dwellings
(Eurostat ilc_lvho02 RENT_MKT 5.0% of persons; GUS household count;
Census 2021 MFH count; assumes market-rent tenants live in MFH) ×
SOURCED 16/84 low-/high-income split (Eurostat EU-SILC, AROP-based, not
quintile-based). Incomes SOURCED (GUS HBS 2024 tables: low-income = Q1
€9,635; high-income = Q2–Q5 mean €23,761, weighted by household count
∝ 1/size; FX 4.30; wave 9, 2026-10-11). Liquidity caps: owner values from
`archetypes_v2.csv`; public landlord €5,000/dwelling/yr and private
"none" are the plan §4 settings (placeholder table: "to be discussed").
Affordability enforcement: cost-neutral mode, low-income archetypes in
scope (`afford_in_scope`); the high-income private tenant is reported,
never enforced.

## Reference run

`results/baseline/` — tenure off, affordability off, clawback 0. **
CERTIFICATION STATUS (updated 2026-10-11):** the outputs stored here are
the CCG **search upper bound** (€2.885M). The 10%-grid optimum €3.998M
was first certified on this code path 2026-10-01 and **re-certified
2026-10-10 on the sourced wave-8 data** (certification wave 2: D0, D2,
D3, and D4 under rule_PL with a 10% landlord grid; logs in
`results/cert_logs/`, pre-sourced certificates archived under
`archive_pre_sourced/`). The D0 enumeration doubles as the regression
gate — it returned €3.998M at the same design both times. The heuristic
€2.885M lies BELOW the grid optimum (continuous rates between grid
points): design-case spending comparisons use the search bound and say
so. The 2026-10-10 D0/D2/D3 certificates pin the wave-8 shares/split;
D4 was re-certified 2026-10-12 on the wave-9 inputs with a
character-identical certificate (owner designs are income-/share-
independent at these rates), which closes the wave-9 staleness flag.
D0/D2/D3 wave-9 re-certification remains open (not ordered).

## Placeholder keys (to be filled from sources before final results)

| Key | Value | Status / source |
|---|---|---|
| `household_income_by_class` | low-income (Q1) €9,635 / high-income (Q2–Q5) €23,761 per household per year | **SOURCED, wave 9 (2026-10-11)**: GUS HBS 2024 tables (Tabl. 2 household sizes 3.00/2.63/2.50/2.26/1.97; per-person income table), FX 4.30. Low-income = Q1: 1,151 × 3.00 × 12 ÷ 4.30. High-income = mean of Q2–Q5 (16,332/19,802/22,693/33,378), weighted by household count ∝ 1/size (each quintile holds 20% of PERSONS); check Σ(inc/size)/Σ(1/size) = 23,761 ✓ (user correction 2026-10-11, supersedes Q5 = 33,378). Signal-note values (sizes 3.60/2.12 → 11,560/35,920; sizes not in the publication) kept as `d5_inc_signalnote` sensitivity — identical design, €2.885M |
| `tenure_share_by_archetype.rented_public` | **0.082** of each MFH archetype | **SOURCED** (2026-10-08): 595,800 municipal dwellings under rental contract end-2024 (GUS, Gospodarka mieszkaniowa w 2024 r.) + TBS/SIM ≈ 110,000 **approximate** (range 93,000–120,000; KZN "over 120k"; money.pl/GUS-BGK "over 93k since 1996") ÷ 8,609,900 dwellings in multi-dwelling buildings (GUS NSP Census 2021, prelim., 31 Mar 2021) = 8.2%; sensitivity 8.1–8.3% as given (TBS bounds compute to 8.0–8.3%). Context: stock 15.97 M; 2020: municipal 5.4% / cooperatives 13.2% / natural persons 80.0% |
| `tenure_share_by_archetype.rented_private` | **0.08** of each MFH archetype | **DERIVED, LOADED wave 9 (2026-10-11)**: 0.05 × 14.1M households ÷ 8.61M MFH dwellings (Eurostat EU-SILC ilc_lvho02 PL 2025 RENT_MKT 5.0% of persons, `eurostat_tenure_income_PL.csv`; GUS household count; Census 2021 MFH count). FLAGGED "derived, assumes market-rent tenants live in MFH". Replaces the 0.05 placeholder |
| `private_rich_tenant_share` | **0.84** of the private-rental stock | **SOURCED, LOADED wave 9 (2026-10-11)**: Eurostat EU-SILC (ilc_lvho02 + ilc_li02, PL 2025: 16% of market-rent tenants below 60% of median income → 16/84 split, `eurostat_tenure_income_PL.csv`). FLAGGED "AROP-based, not quintile-based". Replaces the 0.50 placeholder |
| cooperatives (13.2% of stock) | treated as owner-occupied MFH | **ASSUMPTION** (cooperative renovates with member consent; member charge, not a levy); source string updated 2026-10-09: "EU-SILC counts cooperative ownership as owner-occupancy for Poland (OECD Affordable Housing Database, HM1.3)"; split sensitivity to be decided with Lukas |
| `pass_through_rate_by_landlord.public` | 0.02 — **OPEN** | Weber & Wolff 2018 (0.8–2.8%); Polish municipal rents are council-set under Art. 7–8, no pass-through rule found yet (source note 2026-10-08) |
| `clawback_rate_by_class` | low-income 0.0 default, swept to 0.5 | Martín-Consuegra et al. 2026; Polish tax/benefit treatment of grants to be checked |
| `liquidity_cap_by_landlord` | public €5,000/dwelling/yr, private none | to be discussed |

## Rent-law keys — SOURCED / INTERPRETIVE (user source note 2026-10-08)

Statute: Art. 8a ustawy z 21.06.2001 o ochronie praw lokatorów (Dz.U. 2023
poz. 725); sources: statute text (lexlege.pl/ochr-pr-lok/art-8a; arslege.pl),
TENLAW brochure Poland (Panek, ZERP 2014), Constitutional Tribunal on
Art. 8a(4a–4b) (prawo.pl 2010), Sejm interpellation answer
(orka2.sejm.gov.pl). Values loaded as given; nothing researched or inferred
by the model side.

| Key | Polish value (rule_PL) | German value (rule_DE) | Status |
|---|---|---|---|
| `pass_through_rate_by_landlord.private` | 0.10 | 0.08 | **sourced** — Art. 8a(4b)(b): 10%/yr of the owner's outlays for a permanent improvement raising use value |
| `pass_through_years` | "recovery" = ceil(1/ρ) = 10 y at 0.10 | "permanent" | **sourced** (structure: until outlays recovered, Art. 8a(4b)); duration derived; fair profit (godziwy zysk) not tied to the investment, ignored |
| `rent_increase_cap_per_m2` | none (1.0e6 sentinel) | 3 €/m²/yr (§559) | **sourced** — the Art. 8a(4) 3%-of-replacement-value line is a justification threshold, not a ceiling |
| `passthrough_base_net_of_grants` | true | true (§559a explicit) | **interpretive** — "nakłady poniesione przez właściciela": a grant-financed share is not borne by the owner; false sensitivity in rule_PL_gross |
| `pv_in_passthrough_base` | true | true | **interpretive** — "permanent improvement raising use value" plausibly includes PV; not explicit |

Model default for `pass_through_years` is **"recovery"** since the
2026-10-09 rule_PL-default decision (the 2026-10-08 "permanent" deviation
is RESOLVED; the repro-gate scenarios pin their historical configs
explicitly — recorded in CHANGELOG). The optional `rent_cap_replacement_value_share`
regime (free increase below 3% of replacement value) was not implemented,
as the note allows.

Any output using placeholder or flagged values carries a footnote naming
them. Since the wave-9 rerun (2026-10-11) the standard footnote is:
incomes sourced (GUS; low-income = Q1, high-income = Q2–Q5 mean), public
share sourced (0.082); private share 0.08 DERIVED (assumes market-rent
tenants live in MFH); split 16/84 AROP-based, not quintile-based; public
landlord ρ 0.02 open. Outputs dated 2026-10-08 carry the wave-8 footnote
(private share/split placeholders); outputs dated 2026-10-01 the older,
fully-placeholder footnote.

## Modelling decision — RESOLVED 2026-10-01

`affordability_reference = "zero_subsidy"` (the follower's own response at
σ = 0) is the MAIN case (user decision 2026-10-01); `"frozen_stock"` is
reported as a sensitivity for D3 and D5x. Level 2 consequence: a landlord's
voluntary renovate-and-levy happens at σ = 0 too, so under the main case it
is part of the tenant's reference — the constraint asks what the SUBSIDY
changes, not what the renovation changes.

**Provenance of stored outputs:** everything produced BEFORE 2026-10-01
afternoon (Table 1 certifications, Figure 1, S1, S3, the morning Level 2
runs) used the frozen_stock reference. Affected rows are labelled. Table 1's
certified designs carry over if D3 re-run under zero_subsidy picks the same
design with the constraint slack (checked in the Level 3 chain).

## Tenure-output footnote (applies to every output of a tenure run)

*Since 2026-10-09 the DEFAULT rent rule is the sourced Polish Art. 8a
(rule_PL: private 10%/yr, uncapped, levy until recovery, base net of
grants; public 0.02 open); German §559 values apply only where a scenario
pins rule_DE explicitly. Outputs produced before 2026-10-09 used the
German placeholder as default and say so in their config_used.txt.*

Since 2026-10-08 the Polish rule is sourced (Art. 8a, see the rent-law key
table above) and reported as institutional scenarios (S4, Table 4): the
German rule is a named row (rule_DE), no longer a silent placeholder. The
footnote on outputs produced before that date remains historically correct.
