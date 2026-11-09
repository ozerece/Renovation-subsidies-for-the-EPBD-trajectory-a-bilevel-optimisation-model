# MODEL_MAP.md — where everything lives

Written before any code change (checkpoint 1 of the affordable-housing work plan).
All line numbers refer to `bilevel_model_affordable_housing.jl` (an exact copy of
`../model_bilevel_260207_CCG.jl`, the current verified model, as of 2026-09-30).

## Files in this folder

| File | Role |
|---|---|
| `bilevel_model_affordable_housing.jl` | The model: data loading, follower LP, master LP (lower bound), CCG heuristic search, result writing. Scenario name as `ARGS[1]`, default `baseline`. |
| `archetypes_v2.csv` | 6 archetypes (see below) |
| `measures_v2.csv` | 6 measures: 3 envelope depths, fossil→HP, fossil→DH, PV |
| `context.csv` | Horizon, discount rate, equity share, EPBD target + trajectory, CO₂ path |
| `enumerate_exact.jl` | Certified optimum on a σ-grid (include patched to this model file) |
| `test_invariants.jl` | 38 correctness checks T1–T8 (include patched to this model file) |
| `results/baseline/` | Frozen baseline outputs of the unmodified copy (ground rule 2) |

Run from inside this folder: `julia --project=.. bilevel_model_affordable_housing.jl baseline`
(the Julia environment lives in the parent directory).

## Where archetypes are defined

- **Data**: `archetypes_v2.csv` — 6 rows: `SFH_poor`, `SFH_rich`, `MFH_poor_dh`,
  `MFH_poor_fossil`, `MFH_rich_dh`, `MFH_rich_fossil`. Columns: dwellings, floor
  area, baseline kWh/m², annual liquidity cap, is_WPB, CO₂ intensity, PEF, PV size/cost.
  The `_dh` archetypes model the ~70% of Polish MFH already on district heat.
- **Parsing into vectors**: lines 123–138 (`inc_a`, `cap_a`, `base_a`, `dwell_a`,
  `wpb_a`, `hvac_current`, …). Income class is the string column `income`
  (`poor`/`rich`); it drives the liquidity cap (CSV), the subsidy caps
  (lines 286–302) and the σ-index mapping (lines 359–373).
- **DH incumbents**: `is_dh0_a` line 192 — no fossil ban, DH fuel price, DH base PEF.

## Where the follower (household) problem is built

`solve_follower(σ_vals)` — **lines 381–558**. One Gurobi model covering ALL
archetypes at once, but every constraint is per-archetype (separability holds;
`enumerate_exact.jl` relies on it). σ enters as fixed numbers, so `fz = σ·fy` is
linear; the only nonconvexities are the multiplicative-energy bilinears
(`NonConvex=2`).

Key blocks:
- Variables & bounds: 387–390 (`fy` new adoption, `fs` cumulative, `fz` subsidised
  fraction, `fE` site energy). `y_upper` (line 347) pre-zeroes infeasible (a,m,ti).
- State dynamics 393–395; HVAC precedence 398–399; compatibility 402–406.
- Capacity ceilings (per class + joint labor-weighted) 409–414.
- Subsidy pinning `fz == σ·fy` 418–426.
- **Liquidity** 429–430: post-subsidy capex ≤ annual cap × period length.
- Multiplicative energy + carrier splits 432–479 (E = base·(1−r_env)(1−r_hvac)(1−r_pv);
  `fE_ep_hp/dh` = carrier share × energy, for fuel/CO₂/primary accounting).
- Exclusivity 482–483; DH network caps 486–494; fossil-boiler ban ≥ `SC.ban_year` 500–512.
- **Objective 518–535**: discounted sum of (capex net of subsidy × residual-value
  factor) + period-scaled (maintenance + carrier-specific fuel cost + CO₂ cost on
  the fossil fraction). Annualisation helper `annuity_factor` exists at line 195
  (currently used only for nothing else — relevant for the affordability constraint).

## Where the leader objective and constraints are built

Two places — this matters for the plan:

1. **Master LP (lines 563–852)**: High-Point Relaxation used ONLY for the lower
   bound. Leader constraints appear here in relaxed form: spending objective
   (`TotalPublic` 728–730), equity ≥ 30% (733–736), WPB ≥ 55% (739–741, the 0.55
   is hard-coded), EPBD 2050 (801–804), trajectory (807–813). LB is currently
   vacuous (€0) — known limitation.
2. **`evaluate_σ` (lines 878–915)**: the OPERATIVE leader feasibility check.
   After each follower solve it computes spending, equity share, WPB share,
   the carrier-weighted primary-energy path, and flags feasibility against
   equity / WPB / EPBD-2050 / trajectory. **New leader-side constraints
   (Level 1a affordability) belong here** — and mirrored in
   `enumerate_exact.jl`'s `combine()` (see below).

## Where the enumeration/certification runs

`enumerate_exact.jl`:
- `side_vectors` (lines 46–55): σ-grid per income side with depth-ordering rules.
- `build_table` (75–92): one follower solve per side-vector; per-archetype
  responses stored as `Resp` (spend, savings, WPB savings, primary-energy path).
- `combine()` (117–145): arithmetic cross product of poor × rich vectors;
  applies equity, WPB, EPBD/trajectory checks and dominance pruning; returns the
  certified grid optimum. **Any new leader feasibility rule must be added BOTH
  in `evaluate_σ` and here**, and any per-archetype quantity the rule needs must
  be added to `Resp`/`arch_response` (lines 58–72). The affordability constraint
  is per-poor-archetype, so it can even be pre-filtered per poor side-vector
  (cheaper than in the cross product).

The CCG heuristic search inside the model file (Phases 2–5, lines 969–1260)
is the fast continuous-σ search; it calls the same `evaluate_σ`, so it inherits
any new feasibility rule automatically.

## Where results are written

Lines 1274–1445. `OUTDIR = out/scenarios/<scenario>` (line 77). CSVs:
`policy_kpis`, `scenario_summary`, `subsidies`, `energy_path`,
`public_spend_split`, `adoption_values`, `measure_totals`,
`subsidy_by_archetype`, `ets2_revenue_vs_subsidy`, `heating_energy_path`,
`investment_flows`. New affordability/tenant reporting goes here.

## Where parameters live (the "configuration mechanism")

There is **no single config file**. Parameters are split across:
1. The three CSVs (stock, measures, horizon/targets/CO₂/equity share).
2. The scenario NamedTuple `SCENARIO_DEFS` (lines 46–72) — the intended switch
   mechanism: every lever is a keyword with a baseline default.
3. Hard-coded constants in the model file: fuel prices (177–179), PEF paths
   (157–169), subsidy caps (286–302), capacity rates (207–216), maintenance
   rates (199), `BOILER_LIFE` (100), WPB share 0.55 (741, 893, 130 in
   enumerate_exact).

**Plan compliance note**: ground rule 3 (all new parameters config-driven,
baseline-reproducing defaults) will be implemented by extending the `scen(...)`
NamedTuple — new keys like `affordability_mode="off"`, `clawback_rate_by_class`,
`tenure_enabled=false` etc. with baseline-neutral defaults, so every scenario
(including existing ones) reproduces current behaviour unless a key is set.

## Verification harness

- `test_invariants.jl` (T1 cost monotone in σ, T2 z=σ·y, T3 spending identity,
  T4 physics recomputation, T5 constraint audit, T6 zero-σ ⇒ zero spending,
  T7 LB ≤ feasible UBs, T8 master relaxation membership).
- `../test_exact_benchmark.jl` + `../test_small_instance/`: CCG vs 256-point
  brute force on a tiny instance (not yet copied here; includes the parent
  model by name — copy + patch when needed).

## Known baseline reference numbers (parent repo, July 2026)

Baseline (Poland): feasible, spending ≈ €2.88M (search UB), E2050 = 72.4
(target 90), equity 61%, WPB 81%. Certified 10%-grid optimum €3.998M.
The frozen local rerun of this copy is in `results/baseline/`.

## Level 2 additions (2026-10-01)

- **Tenure split**: archetype DataFrame expanded right after CSV load
  (`tenure_enabled` block in `bilevel_model_affordable_housing.jl`); arrays
  `tenure_a`, `A_RENTED`, helpers `is_rented`, `pass_through_of`.
- **Instruments**: σ indices 11 (`landlord public`) / 12 (`landlord private`)
  appended to `σ_keys`/`σ_caps` only when tenure is on; mapping in `σ_index`
  and `get_subsidy_cap`.
- **Landlord follower**: inside `solve_follower` — `apply_sub` binaries,
  `rent_inc` variables with pass-through + cap bounds, landlord branch of the
  objective (no energy cost, minus rent income), Inf-aware liquidity.
- **Tenant cost**: `housing_cost_after` (bill + rent for rented, bill + own
  annuity for owners) feeds `affordability_details` / reference costs.
- **Leader**: `z_leader` returns `fr.z` for rented rows (paid = received);
  `lowmask_a` counts landlord subsidies per `landlord_subsidy_counts_as_poor`;
  master omits apply binary + rent cap (valid relaxation, commented).
- **Certification**: `enumerate_exact.jl` adds 1-D landlord tables, per-side
  affordability filters, `spend_low` in `Resp`, 4-way cross product; optional
  coarser landlord grid (3rd CLI arg) stated in the log.
- **Tests**: `test_tenure.jl` (driver + per-scenario subprocesses, 40 checks);
  model test hook `P4_SKIP_SEARCH=1` loads data/functions without the search.
- **Reporting**: `tenant_costs.csv`, `landlord_afford_rates.csv`, tenure
  columns, both floor definitions; `table2_tenure.jl` headline table;
  S3 assembly in `s3_summary.jl`; chain `run_level2.sh`.

## Level 3 additions (2026-10-01, afternoon)

- **Reference main case**: `affordability_reference` default is now
  `"zero_subsidy"`; machinery refactored to `reference_costs_for(kind)`
  (per-kind cache `AFFORD_REF_CACHE::Dict`); `affordability_reference_costs()`
  wraps the scenario's choice. Frozen-stock values unchanged (test A2 pins
  the kind explicitly).
- **Scope**: `affordability_scope` (`"all"` / `"owners_and_public_tenants"`),
  helper `afford_in_scope(a)`; enforcement in `affordability_check` and in
  the enumeration's private-side `afford_archs`; the
  `affordability_by_archetype.csv` column `enforced` is scope-aware.
- **Landlord scan**: full 0–100% scan per landlord type (no early exit) in
  the Level 2 reporting block → `landlord_rate_scan.csv` (per-rate gap €/yr
  + uptake) and extended `landlord_afford_rates.csv` (`min_gap_eur_yr`,
  `rate_at_min_gap`, `gap_at_optimum_eur_yr`, `reference`, `enforced`).
- **New outputs**: `uptake_by_group.csv` (Figure 2 data; helper
  `tenure_group(a)`), `tenure_footnotes.txt` (`TENURE_FOOTNOTE` const);
  `affordability_by_archetype.csv` gains `dwellings`, `floor_area_m2`,
  `frozen_bill_eur_yr` (Table 3 "bill before"), `reference`.
- **E1**: `run_e1.jl` — fixed-rate evaluation at the D0 certified rates with
  tenure on (`P4_SKIP_SEARCH` + `evaluate_σ`), writes a standard output set
  to `out/scenarios/E1_baseline_rates_tenure_on/`.
- **Scenarios**: `*_frozenref` sensitivities, `tenure_afford_scoped` (D5x),
  `*_shares2x` (rental shares doubled), `s2_ptr00..s2_ptr10` (S2 sweep).
- **Assembly/figures**: `table2_tenure.jl` (full plan §4 Table 2),
  `table3_tenant_costs.jl`, `s2_summary.jl`, `make_figure{2,3,4}.py`;
  chains `run_level3.sh` and `run_d4_cert.sh` (D4 = enumerate_exact 0.1
  tenure_on 0.1).
- **pv_in_passthrough_base** (2026-10-01, user order): scenario key, default
  true (German §559 reading — PV capex in the landlord's pass-through base;
  Polish status unknown). false removes PV from the base via `M_PT_BASE` in
  the follower's rent constraint. Diagnostic scenario `s2f_ptr05_nopv`.

## GUS data + rich private tenant (2026-10-08)

- SOURCED: `household_income_by_class=(poor=11560, rich=35920)` (GUS 2024,
  Q1/Q5, FX 4.30); `tenure_share_by_archetype.rented_public=0.082`
  (municipal 595,800 + TBS ≈110k approx ÷ Census-2021 MFH 8,609,900).
  OPEN: private share 0.05, `private_rich_tenant_share=0.5` (Eurostat).
- Rich private tenant: third split variant `*_rent_priv_rich` (same
  building/landlord, tenant income rich, never afford-enforced; reported
  with `cost_share_of_income`); helpers `income_of`, extended
  `A_AFFORD_REPORT`, scope-gate excludes rich tenants, `lowmask_a`
  poor-tenant-only for landlord equity credit, `tenure_group` →
  "rented_private_rich".
- Tests: `test_rentlaw.jl` cases twins + invariance
  (`tenure_oldshares_test` vs committed pins); tenure suite updated to
  3 variants per MFH. `*_shares2x` redefined (0.164/0.10). Wave chain
  `run_wave8.sh`; Table 4 gains levy-%-of-income columns.

## S4 — Polish rent law (2026-10-08)

- Keys: `pass_through_years` ("permanent" default / "recovery" = ceil(1/ρ),
  Art. 8a(4b) / integer years), `passthrough_base_net_of_grants` (default
  true; false = gross-base sensitivity). Helpers `levy_years_of`,
  `levy_coverage` (vintage windows from the period start year; rent_inc is
  the period-average annual levy; "permanent" reduces exactly to the
  committed cumulative form).
- Scenarios `s4_rule_*` / `s4f_rule_*` (PL, PL_gross, DE, none, PL_capped,
  PL_permanent × two references), test scenario `rentlaw_test_t5`.
- `test_rentlaw.jl` (unit + T5/T6 + committed-results repro gate),
  `run_s4.sh`, `table4_institutional.jl`, `make_figure6.py`.
- Sources and sourced/interpretive/open status: README rent-law key table.

## Checkpoint 6 — reproducibility (2026-10-01, late evening)

- `reproduce_all.sh`: one-command regeneration of every ledgered output
  (gates → all scenario waves → summaries, tables, figures → provenance);
  `--with-certs` adds the four exact-grid certifications (~12 h).
- Provenance: the model's `config_used.txt` writer gains `git_tree`
  (clean/DIRTY); `run_e1.jl` writes E1's own config; `stamp_provenance.jl`
  retro-stamps pre-writer run folders and writes `provenance.txt` into
  every results folder.
