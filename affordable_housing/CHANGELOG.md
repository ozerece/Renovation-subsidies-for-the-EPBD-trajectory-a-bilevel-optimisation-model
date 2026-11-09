# CHANGELOG — affordable-housing model variant

## Review follow-ups (paper review of 2026-11-08, REVIEW_SUMMARY §5): R1, R4, R5, R6, E1–E4, the 37 % check, housekeeping, two figure fixes (2026-11-08 22:58 → 2026-11-09 ~01:00; branch `pl12`, wrappers, detached)

**Order.** User order of 2026-11-08 (Part A of the brief): run the proposals of the paper review that need
model runs or evaluations, on branch `pl12`, detached through the wrappers; report in one table.

**Model changes (additive; the record re-evaluates to €24,936.2M under the edited file,
`results/cert_logs/eval_pl12_chk_rev12.log`).**
- New scenarios with prefix `rev12` (kept OUT of the pl12 tables; `make_pl11_summary.py rev12` writes
  `results/rev12_summary.csv`, `results/rev12_multistart_summary.csv`): `rev12_no2030`
  (`traj_reductions=(-3.0, 0.20, 0.40, 0.59)`: the 2030 milestone can never bind, 2035/2040/2050 keep
  the standard's exact relative values), `rev12_2050only` (only 2050 kept), `rev12_eq00`
  (`equity_spending_floor=false`), `rev12_eq20`, `rev12_eq40` (`equity_floor_value`).
- `pl12_pubpoor` repaired: the scenario creates no rich public-tenant twin, but the history file carried
  those rows → `history_adoption_file = data/history_adoption_pl12_pubpoor.csv` (the standard file
  without the `_rent_pub_rich` rows; values of the poor twin unchanged).
- Housekeeping (methods review F1): `σ_lower_bound` aligned with the PLAIN ordering of
  `enforce_ordering!` (was still medium ≥ light + 5 pp, deep ≥ light + 10 pp from the superseded spread
  rule). Affects searches launched from now on; no value of record came from the search's lower bound.
- `make_pl11_summary.py`: per-scenario strict floor for `rev12_eq00/eq20/eq40` (none / 0.20 / 0.40).
- `data/sigma_start_rec25.csv` = the pl12 record design as a warm start (`--starts rec25`).

**Wave `scripts/run_rev12_wave.sh` (log `results/cert_logs/rev12_wave.log`).** Searches: the six new/repaired
scenarios from the candidate list and from `rec25`; R5 re-searches of `pl12_envcap_p05`, `pl12_hpcost_lo`,
`pl12_hpcost_hi` from `rec25` (8 Gurobi threads, 6 parallel, 22:58–23:04). Local proofs (±10 pp, 2.5-pp
steps, strict floor; `enumerate_local.jl`, 8 shards + merge) around the cheapest strictly feasible design,
one at a time, 23:04–00:20; record dirs `out/scenarios/<scn>__local25_record` written with `P4_FIXED_SIGMA`
from `data/sigma_<scn>_local25.csv`.

| scenario | search (M EUR, start) | certified local optimum | design of record (low-income env l/m/d, HP; high-income env l/m/d, HP; DH) |
|---|---|---|---|
| `rev12_no2030` (R1) | **2,476.9** (batch); 24,141.6 (rec25, stuck near the record) | **2,476.9** (= centre) | envelope 0 everywhere; low-income HP 31.4 %, DH 35.0 %; high-income HP 14.7 % |
| `rev12_2050only` (R1) | **0.0** (σ = 0 is feasible: 2050 is met without subsidies) | not needed | — |
| `rev12_eq00` (R4) | 23,908.5 (batch, equity 25.3 %); 24,504.1 (rec25) | **23,391.0** (equity **23.6 %**) | env 0 / 24.7 / 25.1 %, HP 92.1 %, DH 5.4 %; high-income env 36.5 / 38.0 / 38.0 % |
| `rev12_eq20` (R4) | 23,908.5 (= eq00's batch design, equity 25.3 % ≥ 20 %) | not run (floor not binding) | = eq00 batch |
| `rev12_eq40` (R4) | batch infeasible; **29,087.2** (rec25, equity 40.0 %) | not run | search bound |
| `pl12_pubpoor` (R6) | 27,396.0 (batch); **24,936.2** (rec25 = the standard's record design, equity 30.0 %) | — | = standard: landlords get 0, so the tenants' income split does not touch the state's problem |
| `pl12_envcap_p05` (R5) | 26,103.9 (rec25; was 26,317.5) | **26,038.8** | 15.8 / 41.7 / 46.7 %, HP 100 %; high-income 30.7 / 37.1 / 37.1 % |
| `pl12_hpcost_lo` (R5) | rec25 start INFEASIBLE (equity floor: cheaper heat pumps cut the low-income share below 30 %); batch 28,331.5 | **27,230.2** (equity 33.3 %) | 2.8 / 39.4 / 68.4 %, HP 59.5 %; high-income 27.2 / 40 / 40 % |
| `pl12_hpcost_hi` (R5) | 25,464.8 (rec25; was 28,563.0) | **24,924.1** | 32.9 / 32.9 / 35.7 %, HP 99.0 %, DH 5 %; high-income 30.4 / 37.1 / 37.1 % |

**Readings.** (R1) The 2030 milestone is the programme: without it the cheapest design costs €2.5bn and
buys heat pumps only (no envelope subsidy); with only 2050 kept, σ = 0 is feasible. The price of the 2030
milestone is therefore ≈ €22.5bn of the €24.9bn; 2035–2040 cost ≈ €2.5bn; 2050 costs nothing.
(R4) The 30 % floor costs €1.5bn (+6.6 %): without it the certified design spends 23.6 % on low-income
households; a 20 % floor is not binding; a 40 % floor costs +€4.2bn (search bound). (R5) The three loose
bounds are replaced by certified local optima: `envcap_p05` 26,039 (still above the standard — with the
equity floor more capacity CAN cost more: the record design is infeasible on the floor under `hpcost_lo`,
and the ×1.05 search from the record lands at 26,104), `hpcost_lo` 27,230, `hpcost_hi` 24,924 (0.05 %
below the standard: a different local basin, not a contradiction). The claim "more capacity / cheaper heat
pumps cannot cost more" is therefore NOT provable in this model and the figure no longer marks such bars.
(R6) `pl12_pubpoor` ≡ standard.

**Evaluations (`make_pl12_review_evals.jl`, `results/review_2026-11-08/`).** E1 incidence 2026–2050
(discounted): low-income owner groups receive more in subsidies than they pay in ETS2 (−2.6 / −2.5 bn);
high-income owners pay more ETS2 than they receive (+6.0 / +5.8 bn); every owner group's total outlay
(bills + own investment) is lower than at σ = 0; tenants and landlords are unaffected (no landlord
subsidy). E2 free-ridership: 47.5 % of the subsidised envelope adoption and 75 % of the heat-pump adoption
2026–2050 also occur at σ = 0 in the same period; the subsidy paid on that overlap is €18.4bn nominal /
€14.2bn discounted of €32.0bn / €24.9bn (57 %), rising to 94 % of heat-pump subsidies in 2040–2050.
E3 marginal channels around the record: low-income envelope −10 pp saves €1.06bn with no change in 2030
(the low-income rates are set by the equity floor, not by the milestone: equity falls to 26.9 %);
high-income envelope −10 pp saves €6.4bn but misses 2030 by 1.85 (≈ €3.5bn per kWh/(m²·yr) in 2030);
low-income heat pump −10 pp saves €0.9bn, 2030 worse by 0.9 (≈ €1.0bn per kWh/(m²·yr)) and equity 27.4 %;
high-income heat pump 0 → 20 % raises 2030 by 1.85 (heat pumps displace envelope renovation under the
joint cap) while lowering 2035–2050 by 10–20; public landlord 0 → 50/100 % costs €0.9 / 1.8bn with no
energy effect (pure windfall: the EED obligation already makes them renovate); private landlord 0 → 50/100 %
changes nothing (no take-up before 2040 under the net rule). E4 decomposition of the cut (design): 2030
−29.9 envelope, −8.7 heating system, −4.0 PEF; 2050 −116.4 / −20.7 / −29.8 (σ = 0: −96.5 / −26.1 / −37.5).
**M13 (the 37.09 % rate):** scanning the high-income medium/deep rate shows a THRESHOLD, not a cap: at
0.3708 the group renovates 8.8 % of its dwellings in 2026–2030 and 2030 is missed by 0.60; at 0.37085
(the record) and above it fills the 10.4 % four-year cap and 2030 has +0.24; above 0.375 equity falls below
30 %. The label "cap of the +0.3 rule" in the final report and in Phase 4 was wrong: the +0.3 rule is not
involved; the rate is the all-or-nothing switching point of the high-income group's envelope response.

**Housekeeping and figures.** `make_pl12_paper_numbers.py`: `standard_wpb_share` relabelled (it is the
share of ENERGY SAVINGS, `wpb_sav/total_sav`, not of spending; the paper had quoted 74.5 % as a spending
share — the spending share to owners in worst-performing buildings is 59.4 %, new row
`standard_spending_share_wpb_buildings`); design-rate rows renamed (`heat_pump`, `district_heat` instead of
`hvac_std`, `hvac_upg`); new rows for the 2020→2026 decomposition (17.3 envelope, 3.3 heat pumps/DH,
boiler update −4.6 on the 2030 σ = 0 value), the search value before the proofs (27,422.3) and the
binary-search tolerance (0.5 pp); scenarios with a `local25_record` dir carry the certified status.
`make_pl12_figures.py`: fig3 compact (scenarios with the standard run's design collapsed into one row,
income-limit scenarios into one row, zero-cost scenarios in panel a; the 29.7-cm figure no longer
overflows the page); fig6 panel b shows public-rental tenants with and without the EED obligation instead
of five identical bars (CSV gains two rows). Final report: 14 (not 13) of 44 scenarios had no feasible
design; counts updated to the 45-scenario set incl. `pl12_pubpoor`.

**OPEN.** O-rev12-1: `rev12_eq40` and `rev12_eq20` are search bounds (no proof). O-rev12-2: the R1
decomposition is by scenario (local optima), not a certified difference. O-rev12-3: `pl12_envcap_p05`
above the standard is now a certified local optimum of a different basin; a global statement remains open.

## Hypotheses (written before results) — recorded 2026-09-30

If a run contradicts one of these, the contradiction is recorded as a finding;
parameters are not tuned to recover the hypothesis.

- **H1**: In Poland the 30% spending floor is slack (baseline ≈ 61%). We expect
  the outcome-based affordability constraint to be slack as well for
  owner-occupiers, because poor coal-heated houses are the cheapest savings anyway.
- **H2**: Under the baseline subsidy rates, landlords renovate later and less
  than owner-occupiers, because the carbon price and the energy savings sit with
  the tenant, not with the landlord. We expect the cost-minimal design to satisfy
  the affordability constraint for tenants of public landlords (pass-through 0.02)
  and to violate it for tenants of private landlords (pass-through 0.08).
- **H3**: Public spending rises and poor-class uptake falls monotonically with
  the clawback rate; the affordability constraint breaks before the spending
  floor does.

*Transparency note*: H1 was recorded 2026-09-30, AFTER the first Level 1a
heuristic runs of the same day (runs: `out/scenarios/{baseline, afford_neutral,
afford_only, no_floor}`, produced by `run_scenarios.jl` in background task
`ba4bwxbos`, log `level1a_tests.log`). For those runs H1 is a registered
expectation only with respect to the still-pending certified (enumeration)
results and the income_share variant. H2 and H3 precede any Level 1b / Level 2
implementation and are genuinely pre-registered.

## Level 2 — landlord/tenant tenure archetypes (2026-10-01)

**What was added.** With `tenure_enabled=true`, every MFH archetype row is
split at load time: the owner keeps (1 − rented shares) of the dwellings;
`_rent_pub` and `_rent_priv` variants are added with the parent's building
physics and a POOR tenant (user decision: tenant always poor, no rich-tenant
archetype). Totals (dwellings, floor area, baseline energy) are preserved by
the split. The landlord's follower problem replaces the household objective
for rented rows: investment net of received subsidy + maintenance MINUS rent
income; energy costs stay with the tenant (split incentive). Rent income =
pass-through rate × cumulative eligible investment (net of subsidy received,
grants deducted before pass-through per German law), capped at
`rent_increase_cap_per_m2 × floor area`; both the pass-through base and the
cap are applied at the archetype-average level — the same aggregation
convention the model already uses for liquidity. Subsidy uptake is a BINARY
landlord choice per archetype and period (apply / not apply — Öko-Institut
2021 mechanism; applying cuts the investment cost but also the pass-through
base). The tenant decides nothing; tenant cost = energy bill at the
landlord's chosen building state + rent increase, and enters the Level 1a
affordability check exactly like an owner-occupier's cost.

**Leader changes.** Two new instruments σ₁₁/σ₁₂ (one rate per landlord type,
all non-PV measures; PV stays unsubsidised). Public spending includes
landlord subsidies (paid = received: no household clawback, nothing when the
landlord does not apply). The ≥30% floor counts landlord subsidies for
poor-tenant buildings iff `landlord_subsidy_counts_as_poor` (default true);
the summary reports the share under BOTH definitions. The master LP omits
the apply binary and the rent cap — both only restrict the follower, so the
master remains a valid relaxation (its LB holds). `enumerate_exact.jl`
confirms the separable decomposition still holds (each rented archetype
responds only to its own landlord rate) and adds one small 1-D table per
landlord type to the cross product, with an optional coarser landlord
sub-grid (3rd CLI argument) that is stated in the log. Certification method
unchanged.

**Config keys** (defaults baseline-neutral): `tenure_enabled` (false),
`tenure_share_by_archetype` (PLACEHOLDER public 0.10 / private 0.05 of each
MFH archetype — GUS to replace), `pass_through_rate_by_landlord`
(public 0.02, private 0.08), `rent_increase_cap_per_m2` (3 €/m²/yr),
`liquidity_cap_by_landlord` (PLACEHOLDER public €5,000/dwelling/yr,
private none), `landlord_subsidy_cap` (1.0),
`landlord_subsidy_counts_as_poor` (true).
New scenarios: `tenure_on`, `tenure_afford`, two TEST-ONLY scenarios, and
the S3 pair (`s3_claw25_incshare15`, `s3_claw50_incshare15`).

**How tested** (`test_tenure.jl`, 40 checks, all passing 2026-10-01):
T1 baseline reproduction stays the A1 gate (plus a structural half: default
scenario adds no archetypes/instruments); T2 zero pass-through + no landlord
subsidy ⇒ rented adoption ≡ 0 (asserted; the test scenario pushes the boiler
ban beyond the horizon, because the ban is regulation that would otherwise
FORCE landlord HVAC swaps from 2040 and mask the no-return result — a
test-setup choice, not a model change); T3 very high pass-through without
cap ⇒ landlords renovate at least as much as the parent owner archetypes
(sanity, passed with rented 0.97–1.0 vs owner 0.0–0.7); T4 tenant cost at
zero pass-through = energy bill only (asserted per rented archetype). Extra:
100% landlord subsidy with zero return still buys nothing (maintenance > 0).

**Reporting added.** `tenant_costs.csv` (bill, rent increase, landlord
applied?, uptake per rented archetype × period), `landlord_afford_rates.csv`
(minimum landlord rate on a 10% scan making each rented type's tenants
affordability-feasible — search bound), tenure column in adoption/heating/
investment outputs, both floor definitions in `scenario_summary.csv`,
headline table builder `table2_tenure.jl` (baseline / +affordability /
+tenure / +tenure+affordability). Schema note: output CSVs gained columns
(tenure, rent_increase); the frozen `results/baseline/` files keep the old
schema — the regression gates compare KPI VALUES, which are unchanged.

## Level 2 + S3 results (2026-10-01, late morning — search bounds)

**Chain** `run_level2.sh`: all three gates passed (A1 baseline reproduction
on the Level 2 code path, 40 tenure checks, 38 invariants) before any run.

**S3 — the conditional reading of H3 is CONFIRMED: clawback bites exactly
where subsidies are not residual.** Income-share s = 0.15 [PLACEHOLDER
incomes]: at clawback 0 feasible at €28.9M (poor env share 68.4%); at
clawback 0.25 and 0.5 NO feasible design exists — every search candidate
fails on the `afford` tag (never the energy trajectory), including
all-rates-at-cap (€57–66M). Mechanism: the income-share limit needs the
poor's RECEIVED subsidy near the cap; clawback lowers the received ceiling
(deep envelope effective max 0.75 at clawback 0.25), and the €900→€1,350
limits cannot be met. So clawback flips feasibility, not just cost.

**Level 2 runs [PLACEHOLDER tenure shares].**
- `tenure_on` (no affordability): spending €2.885M — identical to baseline;
  the cost-minimum sets BOTH landlord rates to 0 (the EPBD trajectory does
  not need landlords). **H2 part 1 CONFIRMED**: landlords renovate less and
  later than owners (env by 2050: public 5.4%, private 15.2%, vs poor
  owners 43.7%). NO landlord ever applies for a subsidy in any run or scan
  (keeping the full pass-through base beats free capex — the Öko-Institut
  mechanism operating as implemented).
- Tenant affordability at the cost-minimum (cost-neutral threshold,
  reported): public tenants PASS everywhere (fossil-building tenants end
  €1,015 vs reference €1,513); **private tenants FAIL**, and the violator
  is the DH-building private tenant: the landlord voluntarily does light
  envelope (14%), charges the CAPPED rent increase (€165–195/yr = 3 €/m²),
  while the bill falls only ~€70/yr (cheap DH heat, no CO₂ on it) →
  €672/yr vs reference €575/yr, violated in EVERY period. **H2 part 2
  CONFIRMED** (public Y / private N), with the mechanism refined: it is
  not underinvestment that hurts private tenants but PROFITABLE
  cap-limited renovation whose levy exceeds the energy saving.
- `tenure_afford` (affordability enforced incl. tenants): **INFEASIBLE —
  no subsidy design on offer can fix it**, including 100% landlord rates
  (fail tag always `afford`). Reason: private landlords simply DECLINE the
  grant (binary uptake) and keep levying; the leader has no instrument
  against voluntary renovate-and-levy. Min landlord rate for tenant
  affordability: public 0%, private NONE ≤ 100% (`landlord_afford_rates.csv`).
  Regulating the pass-through rule itself is Level 3 and out of scope by
  plan §7. Recorded as a finding; parameters NOT tuned.
- Headline table → `results/table2_tenure_headline.csv` (Table 2).
- Bookkeeping: poor-OWNER uptake reads 43.7% under tenure vs 41.9% in
  baseline only because the MFH owner stock shrank by the rented carve-out
  (reweighting, not behaviour). The 30% floor is unchanged at 61.4% under
  both counting definitions (no landlord subsidies are paid).

## Level 3 run wave — E1, D4 cert, S2, D5x, sensitivities (2026-10-01, afternoon)

**User decisions recorded (2026-10-01).**
1. `affordability_reference = "zero_subsidy"` is the MAIN case from now on
   (model default flipped); `frozen_stock` is reported as a sensitivity for
   D3 and D5x. Level 2 consequence, noted BEFORE re-running: at σ = 0 a
   landlord still renovates-and-levies voluntarily, so under zero_subsidy
   that levy is part of the tenant's REFERENCE. The morning's D5
   infeasibility was established under frozen_stock; it does NOT carry over
   and D5 is re-run under both references. All stored outputs produced
   before this entry (Table 1 certifications, S1, S3, the morning Level 2
   runs) used frozen_stock; their ledger rows say so.
2. D5 is reported as infeasible BY MECHANISM under frozen_stock (landlords
   decline grants and levy; no leader instrument ≤ 100% helps; pass-through
   regulation is Level 3, out of scope by plan §7).
3. New heuristic-only cases: **D5x** = D5 with affordability enforced for
   owners and PUBLIC tenants only (`affordability_scope =
   "owners_and_public_tenants"`), private tenant's minimum affordability
   gap reported in €/yr (minimum over the 10% landlord-rate scan of the
   worst-period shortfall); **tenure-share sensitivity** with rental shares
   doubled (public 0.20 / private 0.10) for D4 and D5x.
4. Footnote on every tenure output: the grant-deduction rule and the
   3 €/m²/yr cap are German (§559 BGB) placeholders pending Polish rent law
   (`TENURE_FOOTNOTE` constant, `tenure_footnotes.txt` per run, figure and
   table footnotes).
5. Tenant is always poor; no rich-tenant archetype (re-confirmed).

**Hypotheses for this wave (written before the runs).**
- **H4 (E1)**: at the D0 certified rates with tenure on and the leader not
  re-optimising, owner adoption matches the owner-only model and landlord
  adoption stays at the tenure_on levels (public ≈ 5%, private ≈ 15% by
  2050), since the landlord rates are 0 in both; the EPBD 2050 target is
  missed slightly because the rented stock renovates less than the owner
  stock it replaced.
- **H5 (D5 under zero_subsidy)**: FEASIBLE at ≈ tenure_on spending — the
  voluntary renovate-and-levy is in the reference, so the constraint only
  forbids subsidy-induced worsening, which rate-0 landlord instruments
  trivially satisfy. If it is still infeasible, that contradicts H5 and is
  recorded as a finding.
- **H6 (D5x)**: feasible at ≈ D3 spending under either reference; the
  private tenant's minimum gap ≈ €100/yr under frozen_stock (the morning's
  €672 vs €575) and ≈ €0 under zero_subsidy.
- **H7 (shares ×2)**: spending unchanged to first order (landlords take no
  subsidies; the owner carve-out shrinks the subsidised stock, so spending
  falls slightly); E2050 compliance unchanged; same affordability verdicts.
- **H8 (S2)**: there is a threshold pass-through rate below which rate-0
  already keeps the private tenant affordable (renovation unprofitable or
  levy below savings) and above which NO landlord rate ≤ 100% does
  (landlord declines the grant); the threshold lies between 0.02 and 0.08
  under frozen_stock thinking, but under the zero_subsidy MAIN reference
  the gap at every point should be ≈ 0 (reference moves with the levy).
  Public spending is ≈ flat across the sweep (landlord rates end at 0).

**What was implemented (all switchable, defaults baseline-neutral).**
- `affordability_reference` default → `"zero_subsidy"`; reference machinery
  refactored to `reference_costs_for(kind)` (cached per kind) so tests pin
  the frozen_stock branch explicitly (test_affordability A2 updated — the
  hand-computed values are unchanged, only pinned).
- New key `affordability_scope` = `"all"` (default) /
  `"owners_and_public_tenants"`; enforcement in `affordability_check` and
  in the enumeration's private-side pre-filter; reporting always covers
  all poor archetypes (`enforced` column says which rows bind).
- Landlord-rate scan upgraded: full 0–100% scan (no early exit), writes
  per-rate `landlord_rate_scan.csv` (gap €/yr, uptake) and extends
  `landlord_afford_rates.csv` with `min_gap_eur_yr`, `rate_at_min_gap`,
  `gap_at_optimum_eur_yr`, `reference`, `enforced`.
- New per-run outputs when tenure is on: `uptake_by_group.csv` (Figure 2
  data, floor-area-weighted cumulative envelope share by tenure group),
  `tenure_footnotes.txt`; `affordability_by_archetype.csv` gains
  `dwellings`, `floor_area_m2`, `frozen_bill_eur_yr` (Table 3's "bill
  before"), `reference` columns.
- New scenarios: `afford_neutral_frozenref`, `tenure_afford_frozenref`,
  `tenure_afford_scoped` (D5x), `tenure_afford_scoped_frozenref`,
  `tenure_on_shares2x`, `tenure_afford_scoped_shares2x`,
  `s2_ptr00..s2_ptr10` (private pass-through swept {0, .01, .02, .03, .05,
  .08, .10}, public fixed at 0.02, leader re-optimises, private tenant
  reported-not-enforced so every point yields an optimum — plan §3 allows
  holding parts fixed when stated; this is stated in the Figure 4 footnote).
- `run_e1.jl`: E1 fixed-rate evaluation (D0 CERTIFIED rates env med+deep
  10/10, landlord rates 0, tenure on, follower solves only) writing the
  standard output set to `out/scenarios/E1_baseline_rates_tenure_on/`.
- `table2_tenure.jl` rebuilt to the full plan §4 Table 2 (rows D0, D3, D4,
  D5, E1, D5x + sensitivities; columns incl. Δ vs D0, rates, E2050, uptake
  and affordability by group, certification, placeholder flags);
  `table3_tenant_costs.jl` (Table 3, per dwelling AND per m², 2050);
  `s2_summary.jl`; `make_figure2.py`, `make_figure3.py`, `make_figure4.py`.
- `run_level3.sh` chain: 3 gates → E1 → D3 both references → tenure wave
  (D5 both references, D5x both references, shares×2) → S2 (7 points) →
  summaries, tables, figures. D4 certification runs in parallel:
  `enumerate_exact.jl 0.1 tenure_on 0.1` (landlord grid at the SAME 10%
  step — no coarser sub-grid needed, the landlord tables are 1-D).

**Schema note.** Existing output CSVs gained columns; the frozen baseline
keeps the old schema — gates compare KPI VALUES, not schemas (same
convention as the Level 2 entry).

## Level 3 results (2026-10-01, afternoon — search bounds unless stated)

Chain `run_level3.sh` 14:14–14:45 + S2 frozen-stock sensitivity 14:47–15:02
(user-confirmed mid-run); gates passed BEFORE any run (A1 baseline
reproduction after the reference flip + scope key, 40 tenure checks, 38
invariants); zero WARNINGs. D4 certification separate (below).

- **Certified Table 1 carries over to the zero_subsidy main case.** The
  certified D0/D2/D3 design re-evaluated under zero_subsidy stays feasible:
  poor cost €1,425 vs reference €1,464/yr at 2050 — slack, but the margin
  tightens from 42% (frozen) to 2.7%. A slack added constraint preserves
  the certified optimum. Figure 1 regenerated under the main reference.
- **E1 (fixed D0 certified rates, tenure on): H4 half-contradicted.**
  Uptake as predicted (landlords at the split-incentive levels: public
  5.4%, private 15.2%, owners ≈ unchanged), but the EPBD side of H4 is
  WRONG: E1 stays policy-feasible (E2050 74.3 ≤ 90, trajectory OK) — the
  rented carve-out does not break compliance. Spending €3.998M ≈ the D0
  certificate because MFH owners take almost no subsidy at those rates.
  Also structural: with landlord rates 0, E1's landlord response IS the
  σ = 0 response, so tenant cost ≡ reference exactly.
- **D5 (tenure + cost-neutral affordability): H5 CONFIRMED — feasible
  under zero_subsidy at €2.885M** (= baseline; landlord rates 0; all
  tenant gaps €0). Under the frozen-stock sensitivity it remains
  INFEASIBLE (morning mechanism intact). THE reference choice decides
  whether the full problem is solvable. The warm-rent reading penalises
  what the landlord does voluntarily; the zero-subsidy reading only
  forbids subsidy-induced worsening, which rate-0 instruments satisfy.
- **D5x: H6 CONFIRMED.** Feasible at €2.885M under both references. The
  private tenant's minimum affordability gap (10% landlord-rate scan):
  €0 under zero_subsidy; **€123/yr under frozen_stock** (rich-parent DH
  building's poor tenant, violated in EVERY period), attained at landlord
  rate 0 and closable by NO rate ≤ 100% (grants refused — Öko-Institut
  mechanism). Predicted ≈ €100/yr.
- **Tenure shares ×2 (D4, D5x): H7 CONFIRMED.** Spending €2.885M
  unchanged, E2050 74.3 → 76.2 (still ≤ 90), same affordability verdicts,
  landlord rates 0.
- **S2 (private pass-through sweep, leader re-optimising): H8 CONFIRMED
  in both halves.** Main case: required landlord rate 0% and gap €0 at
  every point BY CONSTRUCTION; spending flat €2.885M. Frozen-stock
  sensitivity (user-ordered): affordable at rate 0% for ρ ≤ 0.03 (levy on
  the ban-forced package stays below the bill saving); from ρ = 0.05 NO
  landlord rate ≤ 100% restores warm-rent neutrality, gap €69 → €123 →
  €144/yr at ρ = 0.05/0.08/0.10. Threshold in (0.03, 0.05]. Figure 4
  shows the frozen curve; the main-case flat result is stated in the
  caption (user instruction).
- Outputs: Tables 2 and 3 (CSV + README markdown), Figures 1–4
  regenerated and visually checked; `s2_passthrough_sweep{,_frozenref}.csv`;
  uptake-mix diagnostic in `_scratch` (see FINDING below); ledger updated.

## FINDING — hump-shaped private-landlord uptake across the pass-through
## rate (2026-10-01, S2; user-ordered verification)

Private rented envelope share at 2050 (floor-area weighted) is NON-MONOTONE
in the pass-through rate ρ: 5.4% (ρ ≤ 0.03) → 23.4% (ρ = 0.05) → 15.2%
(ρ ≥ 0.08). Per-archetype mix and cap status in
`results/_scratch/s2_private_landlord_mix.csv`. Three regimes:

1. **ρ ≤ 0.03 — levy on the forced package only.** The adoption mix is
   IDENTICAL to ρ = 0 (fossil buildings: 47.9% ban-driven switch to DH +
   17.9% light envelope; DH buildings: nothing): voluntary renovation is
   unprofitable, the landlord merely levies the ban-forced investment
   (€25–79/yr, cap slack).
2. **ρ ≈ 0.05 — profitable, cap still partly slack: maximum uptake.** The
   DH landlord does DEEP envelope (21.3%) and additionally installs PV
   (33.5%) — PV is in the pass-through base (all measures, as the German
   rule is implemented) but gets no landlord subsidy, so it is pure
   base-pumping for the levy; the fossil landlord expands light envelope
   to 28.2% with rent still below the cap (€144–154).
3. **ρ ≥ 0.08 — the 3 €/m²/yr cap binds everywhere: uptake falls ∝ cap/ρ.**
   The investment volume that still earns rent is cap/ρ per dwelling
   (€3,300 → €2,060 → €1,650 as ρ goes 0.05 → 0.08 → 0.10), so volume
   SHRINKS; the mix shifts to deeper measures per m² (DH: deep 14%, PV cut
   to 9–12% at 0.08, dropped at 0.10; fossil: light+medium+deep mix),
   NOT to light-only.

The user's conjecture ("cap binds at 0.08 → stops at light renovation") is
confirmed in its first half — the cap binds for the DH building from
ρ = 0.05 and for every private building from ρ = 0.08 — and corrected in
the second: at high ρ the landlord downsizes VOLUME (∝ 1/ρ) and goes
DEEPER per renovated m², it does not downgrade to light. The §559-style
cap therefore caps the tenant's levy AND the landlord's renovation volume
at once — the same placeholder cap drives both. [PLACEHOLDER tenure
shares; German §559 cap and grant-deduction rule pending Polish rent law.]

**PV-exclusion check (user order 2026-10-01, run s2f_ptr05_nopv; gates A1 +
tenure re-passed after the edit).** New config key `pv_in_passthrough_base`
(default true = German §559 reading, all modernisation in the base; POLISH
STATUS UNKNOWN — flagged in the placeholder table). With PV excluded at
ρ = 0.05 (frozen_stock), **the uptake spike SURVIVES and grows slightly**:
private envelope area share 23.4% → 25.8%; the DH landlord replaces the PV
base-filler with MORE deep envelope (21.3% → 24.1/24.9%) to reach the same
capped rent (€165/€195); fossil buildings unchanged (they used no PV). So
the spike is the cap-slack profitability regime, not a PV artifact — PV
was merely the cheapest base filler. Side effect worth noting: the
tenant's frozen-stock gap WORSENS without PV (€69 → €95/yr), because the
same capped levy now buys the tenant a smaller bill cut (the PV's bill
reduction was larger per euro of base). Diagnostic rows appended to
`_scratch/s2_private_landlord_mix.csv`.

## D4 certificate landed (2026-10-01, evening)

**Certified.** `enumerate_exact.jl 0.1 tenure_on 0.1` — 39,688 follower
solves (38,677 poor + 1,000 rich + 11 + 11 landlord), 4.80 bn grid
combinations, log `results/cert_logs/cert_D4_tenure_on.log`. First attempt
was killed at the session's 2 h background limit at 66% (no checkpointing
in the enumerator); rerun detached (`setsid nohup`) finished in 3 h 26 min.
Run pre-dates nothing: the `pv_in_passthrough_base=true` default is
behaviour-identical to the code the certificate ran on.

**Result: certified 10%-grid optimum €3.998M** — exactly the D0 certified
owner design (env_med/env_deep 10/10 both income groups, HVAC 0) with
**both landlord rates 0**. The tenure split and the two landlord subsidy
instruments change NOTHING at the grid optimum; landlord subsidies are
certifiably useless on the grid (H-level confirmation of the search-bound
observation that no landlord ever accepts a grant). The joint
re-evaluation consistency check passed (feasible, €3.998M). The CCG
heuristic's €2.885M remains a genuine continuous-rate improvement below
the grid (env_med 5% between grid points) — same grid-granularity pattern
as D0/Table 1, not a contradiction. Side output: per-grid-point
affordability report (`out/scenarios/tenure_on/affordability_grid_report.csv`,
unenforced) — 1,053/39,688 poor-side and 7/11 private-landlord grid points
would violate the cost-neutral check. Table 2 (CSV + README block) and the
ledger updated to "certified".

[Tenure shares and incomes are placeholders; to be regenerated with GUS
data. Grant-deduction rule and the 3 €/m²/yr cap are German (§559 BGB)
placeholders pending Polish rent law.]

## Checkpoint 6 — reproducibility (2026-10-01, late evening)

**Added (no model behaviour changed; gates re-run).**
- `reproduce_all.sh`: regenerates every ledgered output from scratch —
  gates → core designs → income-share wave (+ sweep summary) → S1 →
  S3 → tenure wave (incl. E1) → S2 sweeps → certified-design
  evaluation, Tables 2–3, Figures 1–5 → provenance stamps. Heuristic
  pipeline ≈ 2–3 h; `--with-certs` adds the four exact-grid
  certifications (D0 gate at €3.998M first, then D2, D3, D4; ~12 h,
  run detached). Ad-hoc `_scratch` diagnostics are NOT regenerated
  (documented here instead); stored `results/cert_logs/` remain the
  certificates of record without `--with-certs`.
- `config_used.txt` writer in the model gains a `git_tree` line (clean
  vs DIRTY with path count) — a commit hash alone does not pin
  uncommitted code. `run_e1.jl` now writes E1's own `config_used.txt`
  (base config = tenure_on, σ fixed at the D0-certified rates).
- `stamp_provenance.jl`: retro-stamps `config_used.txt` into the two
  pre-writer run folders (`no_floor`, E1) with an explicit
  "stamped retroactively" note, and writes `provenance.txt` (git
  commit, tree state, versions, pointers) into `results/`,
  `results/baseline/`, `results/figures/`, `results/_scratch/`,
  `results/cert_logs/`.
- Income-share rows added to the Table 1 section of `results/README.md`
  (search bounds, placeholder incomes): s = 0.10–0.13 infeasible,
  s = 0.14 first feasible €32.9M, s = 0.15 €28.9M, s = 0.20 €7.4M,
  s = 0.10 capacity-relaxed diagnostic €52.3M — with the
  capacity-not-money finding stated under the table.

**Caveat recorded**: at stamp time the repository working tree is dirty
and `affordable_housing/` is untracked, so the recorded hash does NOT
pin this code. The `git_tree: DIRTY` line says so in every stamp;
commit before citing results.

## S4 — Polish rent law (2026-10-08, user source note)

**Sourced values loaded as given (no own research, per the note).**
Statute: Art. 8a ustawy z 21.06.2001 o ochronie praw lokatorów (Dz.U.
2023 poz. 725); sources cited next to the values: statute text
(lexlege.pl/ochr-pr-lok/art-8a; arslege.pl), TENLAW brochure Poland
(Panek, ZERP 2014), Constitutional Tribunal on Art. 8a(4a–4b)
(prawo.pl 2010), Sejm interpellation answer (orka2.sejm.gov.pl).

**Config keys (status per the note).**
- `pass_through_rate_by_landlord.private` 0.10 in rule_PL scenarios —
  SOURCED (Art. 8a(4b)(b): 10%/yr of outlays for a permanent
  improvement raising use value). Default stays 0.08 German.
- `pass_through_years` NEW — "permanent" / "recovery" (= ceil(1/ρ),
  until outlays recovered, Art. 8a(4b); 10 y at ρ = 0.10) / integer.
  SOURCED (structure), duration derived. **Deviation from the note,
  chosen and reported:** the note names "recovery" as the default; the
  implemented default is "permanent" so the committed (and D4-certified)
  scenarios are not silently redefined — the note's own §3 gate demands
  exactly this reproduction; the Polish scenarios set "recovery"
  explicitly.
- `rent_increase_cap_per_m2` — rule_PL scenarios use the 1.0e6 sentinel:
  SOURCED, the Art. 8a(4) 3%-of-replacement-value line is a
  justification threshold, not a ceiling. (The optional
  `rent_cap_replacement_value_share` regime was NOT implemented, as the
  note allows.)
- `passthrough_base_net_of_grants` NEW, default true — INTERPRETIVE
  (nakłady poniesione przez właściciela: a grant-financed share is not
  borne by the owner); false sensitivity in rule_PL_gross.
- `pv_in_passthrough_base` true — INTERPRETIVE for Poland (permanent
  improvement raising use value plausibly includes PV; not explicit).
- `pass_through_rate_by_landlord.public` 0.02 — stays OPEN placeholder
  (municipal rents council-set under Art. 7–8; no pass-through rule
  found yet).

**Model change — levy duration.** Investment booked at the period's
start year earns rent for `pass_through_years` years, then stops
(`levy_years_of`, `levy_coverage`; rent_inc is the period-average
annual levy, pro-rated for partially covered periods; the €/m² cap
binds that average). With "permanent" the constraint is algebraically
identical to the committed cumulative form. Fair profit (godziwy zysk)
ignored per the note. Follower is UNDISCOUNTED, so under "recovery"
the levy exactly repays the base — noted before running: the
landlord's gain from a levy is then only maintenance/timing, which is
the point of the exercise.

**Scenarios.** `s4_rule_{pl, pl_gross, de, none, pl_capped,
pl_permanent}` (zero_subsidy MAIN) + `s4f_*` (frozen_stock
sensitivity), all D5 configuration, leader re-optimising. rule_DE =
the committed D5 configuration re-run under its named row.

**Tests/gates (all BEFORE S4 runs).** `test_rentlaw.jl`: unit checks on
the window arithmetic; T5 (1-year window at ρ = 1 repays the base
exactly within the period); T6 (expired vintage absent from later
bounds — tenant cost back at the no-levy level); repro gate (default
"permanent" reproduces the committed tenure_on / tenure_afford /
s2f_ptr05 at rtol 1e-7, pinned from commit 2b5f3fa). Plus the standing
A1 + tenure + invariant suites.

**H9 (written before the runs, verbatim from the note):** "Under the
Polish rule (10%, uncapped, temporary) the private tenant's peak-year
harm is larger than under the German rule, but the 2050 harm is zero
because the levy has expired; landlords still refuse grants when the
base is net of grants, and accept them when it is gross." Report
against it either way.

[Tenure shares and incomes remain placeholders (GUS pending); the
public landlord rate is an open placeholder.]

## Public-landlord share UNBLOCKED and loaded (2026-10-08, user message)

The two missing numbers arrived: denominator **8,609,900** dwellings in
multi-dwelling buildings (GUS NSP Census 2021, preliminary results,
31 March 2021); numerator **595,800** municipal dwellings under rental
contract end-2024 (GUS, Gospodarka mieszkaniowa w 2024 r.) plus
**TBS/SIM ≈ 110,000, FLAGGED APPROXIMATE** (range 93,000–120,000; KZN
statement "over 120k"; money.pl/GUS-BGK "over 93k built since 1996").
Loaded: `tenure_share_by_archetype.rented_public = 0.082`
(705,800 / 8,609,900 = 8.198%), sensitivity given as 8.1–8.3%.
**Arithmetic check reported, value loaded as given:** the TBS bounds
compute to 8.0–8.3% (595.8+93 = 688.8k → 8.00%; 595.8+120 = 715.8k →
8.31%); the note's lower bound 8.1% does not match the 93k bound.
Private-rental share stays 0.05 OPEN (Eurostat pending).

Consequences recorded:
- `*_shares2x` sensitivities REDEFINED as doubling the current values:
  public 0.164 (2× sourced), private 0.10 (2× placeholder).
- The 3-scenario default-config repro gate (pins from commit 2b5f3fa)
  is SUPERSEDED: the sourced share legitimately changes the data of
  record, so current defaults no longer match the old pins. It is
  replaced by the old-shares invariance case (`tenure_oldshares_test`:
  D5 config at 0.10/0.05, rich twin ON, must reproduce the committed
  tenure_afford exactly) — which simultaneously is the user-ordered
  "landlord problem unchanged" confirmation — plus the twin-equivalence
  case. New default-config pins will be set from the wave-8 outputs
  once they are the data of record.
- Wave 8 extended per the order to the full D4/D5/S2 reruns (E1, the
  tenure wave incl. scoped and shares2x, both S2 sweeps) with the
  sourced share, on top of income-share + S3 + S4.

## Wave 8 landed (2026-10-08, 14:35–16:02) — results of record

One false start: the first launch stopped at the tenure gate because
test_tenure.jl's T3 parent matcher did not know the `_rent_priv_rich`
suffix (test-side omission; one line added, suite green, relaunched).
Second launch ran through: all gates OK (t5t6 13/13, twins 37/37,
invariance — the full-CCG old-shares run reproduced the COMMITTED
tenure_afford €2.884618M / E2050 74.28039 at rtol 1e-7, which is the
user-ordered "landlord problem unchanged" confirmation), ~40 runs,
Tables 2–4, Figures 2/3/4/6, provenance restamped. All search bounds.
Ledger and tables updated in results/README.md; the 2026-10-01
income-share rows there are SUPERSEDED (placeholder-income values
preserved in this file, "Overnight results" + "s = 0.10 diagnostics").

**H10 (sourced incomes) — threshold rose as expected, feasibility edge
unmoved in euro terms.** s = 0.10 stays infeasible (€1,156/yr); first
feasible point moves s = 0.14 → s = 0.11 (€1,272/yr vs €1,260/yr old) —
the infeasibility edge lives in the same euro band under both income
vintages, confirming the capacity finding (the euro cap binds, not the
share). Feasible points get much cheaper: s = 0.15 €28.9M → €9.1M;
s = 0.20 €7.4M → €2.9M (now AT the unconstrained floor, indicator
slack); capacity-relaxed s = 0.10 €52.3M → €27.1M. S3 rerun at s = 0.15:
clawback 25% +€4.6M, 50% +€11.7M (steeper in relative terms off the
cheaper base — the qualitative S3 verdict stands).

**Sourced public share 0.082 — no design or verdict changed.** Spending,
rates, all affordability verdicts identical to 2026-10-01 across
D4/D5/E1/D5x/S2; E2050 74.28 → 74.04 (shares2x 76.17 → 75.67). The D4
certificate formally pins only the pre-0.082 configuration; the wave-8
heuristic returns the identical design (recorded in README Table 2).

**S4 / Table 4 / Figure 6 (Polish rent law).** Main reference: all six
rules feasible at the €2.9M floor, subsidy-induced tenant delta 0, no
landlord grant under ANY rule. The rule decides the voluntary
renovate-and-levy equilibrium: env-2050 private 44% (rule_PL, levy peak
€563/yr = 4.9% of poor income) vs 15% (rule_DE, €190 = 1.6%) vs 5%
(rule_none); rule_PL_capped collapses onto rule_DE (the CAP is the
binding difference, not the 8-vs-10% rate); rule_PL_permanent: 71% and
€1,788/yr = 15.5% of poor income (the Art. 8a expiry is what keeps the
Polish rule tolerable). Frozen-stock reference: EVERY positive
pass-through rule infeasible, only rule_none feasible — the D5 frozen
infeasibility is not a German-placeholder artifact.

**H9 verdict (parameters NOT tuned):**
- Part 1 (PL peak harm > DE) CONFIRMED: peak tenant-cost gap vs
  rule_none €361/yr (PL, 2050) vs €119/yr (DE, 2040).
- Part 2 (2050 harm zero under PL) **CONTRADICTED — finding**: 2050 is
  the Polish PEAK (€1,057/yr vs €695 no-rule). The hypothesis assumed
  one early renovation wave whose levies expire by 2050; instead the
  uncapped 10% rule keeps renovation (and fresh levy vintages) coming
  through 2040–2050, and those windows are still open at 2050. Expiry
  shows at 2060: PL €787 falls BELOW permanent-levy DE €813.
- Part 3 (refuse grants net, accept gross) half-confirmed / not
  testable: no grant flows under either netting rule, but because the
  LEADER never offers a landlord rate (EPBD met without the private
  stock) — acceptance is never reached at the optimum; rule_PL vs
  rule_PL_gross rows are identical in every reported quantity.

**D5 feasibility under rule_PL:** unchanged under the main reference
(feasible at the floor, affordability gap 0); frozen-stock reference
infeasible — same verdict pattern as the German placeholder.

**Repro gate re-pinned (documented plan executed).** New scenario
`tenure_newshares_test` (identical to the tenure_afford default config,
own output dir so the gate never clobbers the results-of-record folder)
added to the model; test_rentlaw.jl invariance case now runs BOTH full-CCG
pins: old-shares vs committed 2b5f3fa AND current defaults vs wave-8
tenure_afford (€2.884618424124881 / E2050 74.03638964535507, rtol 1e-7).
Verified 2026-10-08 evening: INVARIANCE 8/8 passed.

## E2 — landlord grant-acceptance diagnostic (2026-10-09, user order)

Order: "fix the landlord subsidy rate at 30% and 60% and evaluate the
landlord follower only, under rule_PL and rule_DE, net and gross base.
Report whether the landlord accepts the grant and what it does to
renovation and the levy. This is the only way to see whether the Polish
recovery levy makes grants acceptable, as predicted." Design: follower
solves at fixed σ (no leader), σ private-landlord ∈ {0, 0.30, 0.60},
public-landlord rate kept at 0 (recorded choice — the question is the
private rule; H9 part 3 was about private landlords). 4 configs:
s4_rule_pl, s4_rule_pl_gross, s4_rule_de, and NEW scenario
e2_rule_de_gross (German §559 values + gross base — counterfactual,
diagnostic only). Acceptance read off the model's explicit binary
`apply_sub` + grant euros received (fz). Output:
`results/_scratch/e2_landlord_grant_response.csv`.

**Hypotheses recorded BEFORE the runs:**
- **User prediction under test (H9 part 3):** landlords refuse grants
  when the base is net of grants, accept when gross; the Polish recovery
  levy is expected to make grants acceptable.
- **Model-side arithmetic, written down a priori (2026-10-09):** the
  follower discounts at r = 0.03 (context.csv), so net-base acceptance
  is a strict trade, not a tie. Taking a grant g under the NET base
  forgoes future levy of ρ·g/yr over the levy window. Under rule_PL
  (recovery, ~10 y) the forgone levy sums to g NOMINALLY but less than g
  discounted → accepting should be strictly profitable — i.e. the
  recovery duration itself, combined with discounting, should make
  grants acceptable under the net base, which would CONFIRM the user's
  headline prediction while contradicting the refuse-when-net half of
  H9 part 3. Under rule_DE (permanent, capped) the forgone levy runs to
  the horizon (up to ~2.4×g nominal for early vintages) → refuse where
  the 3 €/m² cap is slack; where the cap already binds, netting costs
  nothing → accept. GROSS base: accept everywhere (pure transfer).
- Renovation volume: grants should raise private renovation only
  modestly under rule_PL (the levy already finances it) and more under
  rule_DE (where the cap throttles levy finance); under the net base an
  accepted grant lowers the levy (smaller base), under gross it does not.

If the runs contradict any of this, the contradiction is recorded as a
finding; parameters are not tuned.

## E2 results (2026-10-09, afternoon — follower evaluations, heuristic)

Output: `results/_scratch/e2_landlord_grant_response.csv` (12 rows =
4 configs × σ_priv {0, 0.30, 0.60}). Sanity anchor: every σ = 0 row
reproduces its S4 full-run equilibrium exactly (env2050 0.436 PL / 0.152
DE; levy peak €563 / €190). Two script bugs fixed before the final
numbers (2050 column initially read the 2060 end state; then
`findfirst(==(2050), years)` hit the period START year — `years` are
start-of-period, reporting uses `end_year`; both fixes are indexing
only, no model change).

**Findings:**
- **NET base (both rules): grants are accepted only where accepting is
  costless, and they buy NOTHING.** Renovation and levy are bit-identical
  to σ = 0 at both 30% and 60%. rule_PL net: 3 archetype-periods accept,
  €7.6k/€15.2k total grant across the whole private stock (vs €1.3–2.8M
  under gross). rule_DE net: 8–12 archetype-periods, €59k/€119k.
- **Mechanism, PL-net (explains the near-tie):** the levy is booked
  period-average at the period's single discount node. A vintage whose
  10-year recovery window sits inside one 10-year model period repays
  its base at the SAME discount factor as the grant → netting the grant
  is an EXACT PV wash → acceptance is value-neutral (solver-arbitrary).
  Only vintages in the 5-year periods (2030–35, 2035–40) spill their
  window into later, more-discounted periods, making acceptance strictly
  (but marginally) profitable — exactly the 3 accepted cases. This
  CONTRADICTS the pre-registered model-side arithmetic (which predicted
  strict acceptance under PL-net from r = 0.03) — recorded as a finding:
  the a-priori reasoning ignored that period-average booking collapses
  within-period cash flows onto one discount node. In continuous time a
  10-y recovery at 3% discount WOULD make net-base grants strictly
  acceptable; the indifference is partly a period-granularity artifact
  (flagged for the paper, not patched).
- **Mechanism, DE-net:** acceptance happens exactly where the 3 €/m²
  cap already binds — there the base cut costs no levy, the grant is
  free money; the levy stays capped at €190, renovation unchanged.
- **GROSS base: accepted broadly, and under the Polish rule grants now
  BUY renovation.** PL-gross: 40/40 archetype-periods accept; env2050
  0.436 → 0.701 (30%) → 0.717 (60%), full private stock enveloped by
  2060; levy peak €563 → €606 at 60% while the 2060 levy falls €460 →
  €440 (earlier, deeper vintages). DE-gross: almost no response (env2050
  0.152 → 0.160 only at 60%) — the cap throttles levy finance, so even
  free capex barely moves the German-rule landlord.
- **Verdict on the user prediction / H9 part 3:** "accept when gross"
  CONFIRMED (and under PL-gross effective, not just accepted). "Refuse
  when net" confirmed IN SUBSTANCE (no meaningful grant flow, zero
  behavioural response) though not literally (the binary accepts in
  tie/costless cases). "The Polish recovery levy makes grants
  acceptable": PARTLY — recovery makes net-base grants acceptance-
  NEUTRAL instead of value-destroying (the German permanent uncapped
  levy would be forgone for up to the whole horizon), but under the
  interpretive grants-netted reading acceptance stays economically
  empty; grants only become a working instrument under the GROSS
  (rule_PL_gross) reading.
- Caveat: follower-only heuristic at fixed σ, public landlord rate 0;
  search bounds nowhere claimed. New diagnostic-only scenario
  `e2_rule_de_gross` (German values, gross base) added to the model;
  `e2_landlord_grant.jl` added.

## L3 lite landed + H11 verdict (2026-10-09, 15:34)

48/48 runs + collector OK. `results/table5_rent_rule_choice.csv`;
full grid `results/_scratch/l3lite_grid.csv`. All search bounds.
- **zero_subsidy (net AND gross): ALL 12 rules tie** at the €2.8846M
  floor — spending cannot distinguish the rent rule, because the
  optimum never uses the private rental stock for EPBD and the
  affordability constraint is slack at every rule's own equilibrium.
  The pre-registered tie-break (lowest low-income-tenant peak levy)
  then selects **ρ 0.05 + 3 €/m² cap + recovery** (peak levy €190/yr
  = 1.6% of income; env-2050 private 27.7%); a capped PERMANENT rule
  has the identical levy and spending, so duration is decided only by
  the last lexicographic step.
- **frozen_stock: NO rule in the grid is feasible** (both bases) —
  the grid's minimum rate 0.05 already breaks warm-rent neutrality
  and landlord grants cannot repair it (E2 mechanism).
- **H11 verdict:** "a capped, permanent rule is chosen" —
  HALF-SUPPORTED, with the honest caveat that CAPPED is selected only
  by the tie-break (all 12 rules tie on spending) and PERMANENT is
  not selected (recovery wins the final lexicographic step; capped-
  permanent is levy-identical). "Under gross base a landlord subsidy
  enters the optimum" — **CONTRADICTED — finding**: landlord rates
  are 0 and no landlord euro flows in any of the 48 optima, gross
  included; consistent with the D4 certificate and E2 (the leader
  meets EPBD without private landlords, so it never pays them).

## rule_PL reruns landed (2026-10-09, ~15:50) — all expectations met

Gates after the flip: tenure all passed; rentlaw t5t6 + twins +
BOTH pinned full-CCG invariance runs passed (the pinned rule_DE gate
scenarios reproduce the committed 2b5f3fa and wave-8 pins at rtol
1e-7) — the default flip is proven non-destructive. Reruns (heuristic,
search bounds): D4-PL €2.884618M, landlord rates 0/0 ✓; D5-PL
zero_subsidy feasible €2.884618M, E2050 73.666 ✓ (= s4_rule_pl, as
pre-registered); D5-PL frozen_stock INFEASIBLE ✓; E1-PL €3.998M
evaluation, equity 44.3%, uptake 2050 public 5.4% / private 43.6% /
low-income owners 49.2% (pre-registration quoted ≈43% for owners —
that was the D5-design figure; E1 evaluates the CERTIFIED 0/10/10
rates, hence 49.2%; private and public exactly as expected). Tenant
cost (Table 3, D5, private tenant 2050): bill €494 + levy €563 =
€1,057/yr (rule_DE was €636 + €190 = €825) — 9.1% of the low-income
tenant's income (was 7.1%), 2.9% of the high-income tenant's (was
2.3%). Tables 2/3 + Figures 2/3 regenerated; Table 2 now carries the
rent rule in every case label (rule_PL rerun rows vs rule_DE
pre-decision sensitivity rows not yet rerun: D5x, scoped-frozen,
shares2x ×2) and D4's status reads "search bound — rule_PL 10% grid
certification running 2026-10-09". P4_SKIP_SEARCH config-write
suppression active; model log strings relabeled; lldisc4_rule_pl/_de
scenarios added for §3d (runs pending).

## §3d landlord discount-rate sensitivity 4% landed (2026-10-09, ~16:05)

New switchable key `landlord_discount_rate` (default nothing = global
r — gates proved bit-identity before any run); scenarios
lldisc4_rule_pl / lldisc4_rule_de (heuristic, search bounds). Note:
expectations for §3d were NOT separately pre-registered (the order
arrived in the 2026-10-09 packet; the E2 entry's discount mechanics
are the closest prior) — results recorded as found:
- rule_PL at 4%: feasible, €2.8846M, private env-2050 **43.6% → 29.9%**,
  E2050 73.67 → 73.84. The Polish recovery levy repays the base
  nominally-exactly, so its profitability hinges on discounting: at a
  higher landlord rate the repayment stream is worth less and
  voluntary renovate-and-levy drops by a third.
- rule_DE at 4%: €2.8846M, private env-2050 15.19% → 15.19%
  (unchanged; E2050 74.036 → 74.038). The capped permanent stream's
  margin is apparently not at a 3-vs-4% knife edge.
- Spending and landlord rates unchanged in both (landlords never
  needed for EPBD). Consistent with E2: the levy-financing channel,
  not grants, is what the discount rate modulates.

## Certification wave 2 LANDED (2026-10-10, 04:43; recorded 2026-10-11)

All four enumerations finished clean (log `results/cert_logs/cert_wave2.log`;
per-case logs `cert_D0_baseline / cert_D2_afford_only / cert_D3_afford_neutral
/ cert_D4_tenure_on.log`; old certificates archived under
`results/cert_logs/archive_pre_sourced/`). These certificates pin the
wave-8 data of record (sourced incomes 11,560/35,920, shares 0.082/0.05,
rich split 0.5) and, for D4, the rule_PL default — they supersede the
2026-10-01 certificates that pinned the old placeholder data.

- **D0 baseline** (13:52–16:58, 2026-10-09): certified grid optimum
  **€3.998M**, σ = env 0/10/10 both groups, HVAC 0 — same design as
  2026-10-01. Regression gate passed. Heuristic UB €2.885M is −38.6%
  BELOW the grid optimum (continuous rates between grid points).
- **D2 afford_only** (16:58–20:32): certified **€3.998M**, same design;
  the cost-neutral filter excludes 1,053 of 39,688 poor σ-vectors,
  optimum unaffected (affordability certifiably free at the optimum).
- **D3 afford_neutral** (20:32–00:11): certified **€3.998M**, same
  design — D3's Table 2 label upgraded from "search bound" to certified.
- **D4 tenure_on under rule_PL** (00:11–04:43, landlord step 0.1):
  certified grid optimum **€3.998M = D0 design + landlord rates 0/0**.
  Pre-registered expectation (rule_PL decision entry) CONFIRMED: the
  Polish rule does not change the certified conclusion that landlord
  subsidies are not part of the cost-minimal design. This satisfies the
  user order "Add D4 to tonight's certification queue" and the order
  that the paper not cite certificates pinning the old data.

Table 2 labels updated accordingly (D0 re-certified 2026-10-10; D3
certified; D4 "certified 10% grid under rule_PL (2026-10-10)" with the
pre-registered staleness note that the certificate pins wave-8 shares).

## PHASE 2 APPROVED — rerun list PRE-REGISTERED (2026-10-27, before any phase-2 run)

All phase-2 runs use the corrected prices + efficiencies (base9): the
pl8_* family is RE-DERIVED from base9 (the uncommitted legacy-price
step-1 outputs are superseded before ever being committed); the
committed pl_r8/pl_r8_* keep their legacy defs for reproducibility; the
NEW STANDARD is `pl9`. KPRB runs on the STANDARD's absolute targets
(222.12/211.55/158.66/108.42 — ruling (a); new kwarg
traj_values_override). Run list (28 searches + 1 evaluation):
pl9; SQ1 pl8_afford, pl8_s10..s20 (6), pl8_s10_caprelax; SQ2
pl8_rule_none/pl/cap3/perm, pl8_rule_pl_gross, pl8_w05, pl8_w10,
pl8_noeed (public-landlord OWN spending reported next to the state's),
pl8_priv16; pl8_ban2040; sens pl8_r12, pl8_split, pl8_kprb(absolute),
pl8_hvac6, pl8_co2half, pl8_peffrozen, pl8_pubpoor; pl9_elec_p20,
pl9_elec_m20; σ=0 evaluation of pl9.
**Hypotheses, recorded before the runs:** H29 — the corrected η + 2025
electricity price make heat pumps bill-saving (bill check: WPB boiler
€3,053→HP €2,668 in 2030), so σ=0 natural adoption is FASTER than under
phase-1 pricing; whether it clears the 2030/2040 milestones at r=8% is
OPEN (register both directions). H30 — the SQ1 feasibility edge moves
DOWN (deep env + HP now reaches ≈€800/yr for the worst-performing SFH,
below the s=0.10 limit €964), possibly making the whole sweep feasible.
H31 — lower CO₂ intensities (0.18-0.19 vs 0.30) weaken the carbon-price
lever: natural pace slows on that channel even as HP economics improve;
net spending effect uncertain, registered open. Expected
infeasibilities: none registered — ANY infeasibility stops the batch.

## Sharding equivalence PASSED; pl9 PROOF LAUNCHED (2026-10-29)

Equivalence test (pl9, uniform 0.5 grid): serial vs 2-shard+merge
certificates IDENTICAL to the cent (€51,532.298M, identical σ; logs
cert_logs/enum_shardtest_{serial,merge}_pl9_05.log). Phase-2 batch
committed as 66e39f4 beforehand. PROOF of the new standard pl9 launched
2026-10-29: hybrid rate list, plain ordering, 115,656 follower solves
(105,644 poor + 9,984 rich + 28 landlord), 8 shard workers
(P4_ENUM_SHARD k/8) then merge; logs cert_logs/cert_pl9_shard*.log,
certificate cert_pl9_hybrid.log. Measured solo solve rate 0.38 s →
expected ≈2–4.5 h wall (8-way contention-adjusted), i.e. completion the
same day; cross product ≈2×10¹¹ (minutes). Search bound to beat:
€11.384bn (seed 7). Certificate entry follows on landing.

## pl9 PROOF CERTIFICATE LANDED (2026-10-29 22:42; recorded 2026-11-02)

**CERTIFIED GRID OPTIMUM pl9 = €10,094.809M** (hybrid rate list, both
levels; log cert_logs/cert_pl9_hybrid.log). Joint re-evaluation
feasible, spending matches to the euro. Certified σ: envelope poor
light/medium/deep **15/25/25%**, rich 0/5/15%; **hvac standard (HP)
poor 90%**, all other hvac 0%; landlord public/private 0/0.
Merge mechanics: 105,644 poor + 9,984 rich responses assembled from the
8 on-disk shards + 28 landlord solves; cross product 206,730,940,416
combinations checked in 22,074.8 s (≈6.1 h); 51 feasible improvements
over the incumbent. Affordability (off, reported only): 3,009 of
105,644 poor σ-vectors would violate; per-grid-point report
out/scenarios/pl9/affordability_grid_report.csv. Shard responses
(out/enum_shards/pl9_hybrid/, 335 MB .jls) stay uncommitted — binaries,
never tracked; shard logs cert_pl9_shard1..8.log committed.

**Gap to the search:** seed-7 CCG bound €11,384.056M → the heuristic
was **€1,289.2M (+12.8%) ABOVE the certified grid optimum**. Measured
heuristic gap in line with earlier certifications (high_co2 +8%,
all_levers +48%). **pl9 of record is now €10.095bn CERTIFIED (grid).**
FINDING, recorded as-is: the certified design is structurally different
from the heuristic's — the seed-7 search landed on a pure-envelope
programme (HP zero through 2050; basis of anomaly explanation (a)
below, which described the HEURISTIC design), while the certified
optimum subsidises poor standard HVAC (heat pumps) at 90% alongside
moderate envelope rates. The coordinate-descent heuristic stuck in a
pure-envelope local optimum; statements about "pl9's optimum" dated
2026-10-29 and earlier refer to the heuristic design.

Session note: the Claude session ended while the merge ran; the
detached backstop confirmed the landing (ntfy ping). Certificate
recorded and committed on reconnect 2026-11-02.

## Anomaly explanations + CORRECTION of the seed-7 numbers (2026-10-29)

**CORRECTION (bookkeeping, 2026-10-29):** the seed-7 values recorded on
2026-10-27 were the Round-2 "After perturbation" lines, not the finals.
Final seed-7 results (policy_kpis of record, on disk): **pl9 €11.384bn**
(eq 42.5%), **pl9_elec_p20 €11.393bn**, **pl8_ban2040 €14.220bn**.
Best-known bounds: pl9 ≤ 11.384 (seed 7), elec_p20 ≤ 10.839 (seed 42),
ban2040 ≤ 14.220 (seed 7). Search noise on the standard ≈ 2–4%.
NOTE: the machine restarted 2026-10-28; the session scratchpad (seed-7
logs, first diagnostic logs) was wiped — the max-σ diagnostics were
REGENERATED into results/cert_logs/diag_maxsigma_{pl9,pl8_r12}.log
(numbers match the recorded ones).

**(a) Why the fossil-boiler ban RAISES spending (+€2.8bn, robust to
seeds).** From the stored outputs (extraction in the session report):
pl9's optimum is a pure-envelope programme — heat pumps are ZERO through
2050 (hvac capacity use 0%), envelope capacity binds 100% in every
period, joint cap 86–96%. The ban forces end-of-life replacement from
2040: HP 18.1% + DH 9.6% of all dwellings in 2040–50, hvac capacity
100%, which saturates the JOINT labour cap (100% in P4) and crowds the
envelope flow from 28.9% down to 24.9% — so the trajectory-constrained
envelope programme must extend to the high-income stock at roughly
doubled rates (rich env 18–23% vs 8–16%) and deepen the poor rates.
The ban also overshoots E2050 to 86.0 (target 108.4): it buys
unneeded late decarbonisation at the price of scarce mid-horizon labour.
**(b) elec+20% cheaper than pl9 — REAL, not search noise.** Cross-check
(diag_cross_elecp20_design.log): the seed-42 elec_p20 design (€10.839bn
there) evaluated under pl9 prices is **INFEASIBLE** — 2030/2040/2050
all violated, spending only €9.383bn, i.e. the SAME rates induce ~13%
LESS adoption when electricity is cheap. Mechanism: cheap electricity
raises the option value of the late unsubsidised heat-pump path, so
forward-looking households DELAY envelope renovation (the recorded
delay mechanism); +20% electricity locks households into fossil bills,
envelope is their only lever, natural adoption accelerates and the
leader's acceleration bill falls. So the pl9 search missed nothing;
pl9 ≤ 11.384 and elec_p20 ≤ 10.839 are consistent bounds on DIFFERENT
behavioural regimes. Policy reading, recorded: the electricity price
freeze (cheap power) makes the subsidy programme MORE expensive.

## Polish investment costs — IMPLEMENTED IN WORKTREE, gated, STOPPED for review (2026-10-29, user order; NO runs, NO merge; pl9 proof untouched)

Isolation: all work on branch `worktree-polish-investment-costs`
(worktree under .claude/worktrees/, base commit 66e39f4); the running
pl9 proof (8 shards + merge, main tree) shares no file with it.

Sources (stored in data/, full table + geometry in
PROVENANCE_polish_stock.md "Investment costs"): Czyste Powietrze
Załącznik nr 2 **od 20.07.2026** (official czystepowietrze.gov.pl file;
TLS chain repaired via the leaf's AIA intermediate, verified against
system roots) + the KPO/FEnIKS "Tabela kosztów jednostkowych"
(MKiŚ/NFOŚiGW, June 2025). Tiers 40/70/100% — eligible unit cost =
highest-tier amount: roof/attic 220, walls 275, windows 1,320, doors
2,750 zł/m²; envelope cap 83,000 zł (NOT binding: SFH deep bundle
77,490 zł). FINDING: the current annex has only the higher-efficiency
air-water HP row (35,200 zł eligible); the standard-class 30,000 row
was removed on 20.07.2026.

Geometry (documented assumption): SFH 108.6 m² two-storey kostka →
net walls 143.6 m², roof 66.3 m², windows 13.58 m² (1:8 WT), door 2 m²;
MFH 12-dwelling 4-storey block → per dwelling walls 38.66, top ceiling
13.30, windows 6.65 m². EUR at 4.30 (house convention), annex values
are NET of VAT (flagged, not grossed up per the order's "eligible
cost").

New per-dwelling EUR (legacy in brackets): SFH light 3,391 (5,687),
medium 9,183 (12,360), deep 18,021 (24,720), HP 8,721 (15,258) with
sensitivities 6,977/10,465; MFH light 680 (3,194), medium 2,473
(6,820), deep 5,301 (13,640), HP 4,272 (13,596) — MFH HP PROPOSED
(floor-area scaling of the 37,500 PLN market value), FLAGGED,
sensitivities 3,418/5,127. DH connection KEPT (5,629/4,798; annex
highest grant 22,250 zł = 5,174 € brackets both). Every new cost is
LOWER than the stylised legacy value; MFH envelope falls hardest
(top-ceiling share replaces a whole-dwelling light retrofit — the
0.25 reduction factor is now mismatched for MFH light, FLAGGED for
the user's decision).

Structure: the €/m² + fixed form does NOT fit (two-point fit ⇒
negative fixed costs: light −1,923, medium −3,971, deep −6,914 €) —
costs scale with envelope area, not floor area. Implemented instead as
scen kwarg `measure_costs` (Dict (btype, m_id) → EUR per dwelling;
nothing = legacy, bit-identical) + constant MEASURE_COSTS_PL2026;
override sits in base_inv_cost, learning multipliers unchanged. Old
costs stay pinned on every scenario of record (default = legacy); NO
scenario uses the new costs yet — phase 2 (rerun + new proof) awaits
the user's OK.

Bill & payback check (SFH_wpb_poor, 41,561 kWh/yr, new costs, learning
applied; investment / yearly saving vs boiler / simple payback):
2030 — HP 6,770 € / 385 €/yr / 17.6 yr (legacy 30.8); deep 17,140 € /
2,137 €/yr / 8.0 yr (11.0); both 23,910 € / 2,253 €/yr / 10.6 yr
(15.7). 2050 — HP 4,080 € / 2,523 €/yr / 1.6 yr (2.8); deep 15,505 € /
3,634 €/yr / 4.3 yr (5.9); both 19,585 € / 4,390 €/yr / 4.5 yr (6.5).

Gate (in the worktree): test_switches_off baseline + tenure_on →
results/cert_logs_worktree/gate_plcosts_*.log — **8/8 PASS ×2**. NO
runs, NO commit, NO merge — stopped for the user's review.

## Review changes (1) VAT + (2) component-consistent savings — IMPLEMENTED IN WORKTREE, gated, STOPPED again (2026-10-29, user order)

**(1) VAT ×1.08** on the annex-based envelope costs (net → gross; 8%
reduced rate on residential renovation); HP market price already gross,
unchanged; MFH HP accepted as flagged. MEASURE_COSTS_PL2026 now: SFH
3,663/9,918/19,463 (light/med/deep), HP 8,721; MFH 735/2,670/5,725,
HP 4,272; DH kept.

**(2) Saving factors from the SAME components and geometry as the
costs.** Current (legacy) factors: light 0.25 / medium 0.45 / deep
0.70, all archetypes. New: r = Σ_renovated A·ΔU / (Σ_all A·U_before +
ventilation 0.34·0.5·V), U before from the NAPE/TABULA PL 1967–1985
catalogue sheets (SFH.03: walls 1.4, roof 1.1, windows 3.3; MFH.03:
1.16/0.60/2.60; doors 2.6), U after = WT 2021 U_max (0.20/0.15/0.90/
1.30 — the standard the annex itself requires), floor + ventilation
unrenovated in the balance. **SFH 0.134/0.367/0.576; MFH
0.054/0.333/0.490** (vs 0.25/0.45/0.70). Deep plausibility: 83.5%/77.4%
of the renovated-component loss; after-deep WPB SFH final 162 kWh/m² ≈
the NAPE "modernizacja standardowa" level — plausible for an
envelope-only package. Sources + geometry + period sensitivity:
PROVENANCE "Review changes". CONSEQUENCE FLAG (recorded, not tuned):
deep saves less while costing less — trajectory feasibility under the
new calibration is an open phase-2 question.

Implementation: scen kwarg `measure_reductions` (nothing = legacy,
bit-identical) + MEASURE_REDUCTIONS_PL2026; redfac_am now carries
envelope overrides and the follower r_env / master mr_env sums read
redfac_am (identical at defaults); validation keeps overrides ≤
r_env_max_val 0.70 so the E bounds stay valid. test_invariants.jl's
hand recomputation stays legacy-only (pre-existing since the η change).
Source stored: data/nape_tabula_typologia_budynkow_podrecznik.pdf.

Payback check REPEATED (SFH_wpb_poor, VAT costs + new r_deep 0.576;
investment / saving / payback): 2030 — HP 6,770 € / 385 €/yr / 17.6 yr;
deep 18,511 € / 1,758 €/yr / 10.5 yr; both 25,282 € / 1,921 €/yr /
13.2 yr. 2050 — HP 4,080 € / 2,523 €/yr / 1.6 yr; deep 16,745 € /
2,989 €/yr / 5.6 yr; both 20,826 € / 4,059 €/yr / 5.1 yr. (Deep's
payback barely moves vs the pre-review check — +8% cost ≈ the saving
lost to r 0.70→0.576 in 2030; "both" worsens ~2.5 yr.)

Gate rerun after the changes: gate_plcosts_vat_{baseline,tenure_on}.log
— **8/8 PASS ×2**. NO runs, NO commit, NO merge before the pl9
certificate is recorded — stopped for the user's review.

## Merge-time estimate for pl10/noeed — read-only sampled replication (2026-11-03, user order)

Order: from the pl9/pl10 shard outputs, count feasible σ-vectors per
side and the cross-product size, compare with pl9, and estimate the
expected total merge time for pl10 and pl10_noeed — read-only, without
touching the running merges. Also: can future merges print progress and
run on several cores?

Counts from the shard logs (grid identical by construction across pl9
and the whole pl10 family, spec = hybrid): poor side 105,644 σ-vectors,
rich side 9,984, landlord sides 14 × 14. Nominal cross product
105,644 × 9,984 × 14 × 14 = 206,730,940,416 combinations — the same
for pl9, pl10 and pl10_noeed. pl9's certified merge checked exactly
this product in 22,074.8 s (6.13 h); affordability mode "off" (3,009
poor vectors violate but are reported only, never excluded), so no
side is thinned before the cross product.

HYPOTHESIS (before the estimation runs): the pl10/noeed merges are
slower than pl9's 6.13 h not because of grid size (identical) but
because pruning bites later — under Polish gross costs the spending
distribution is flatter near the optimum, so more (poor, landlord)
triples pass the spend3 dominance prune and more rich iterations reach
the deep feasibility checks. Expected: the sampled replication
reproduces pl9's 22,075 s within roughly ±30%, and predicts pl10 and
noeed well above their already-spent ~14.4 h CPU. If the estimator
instead predicts pl10 FASTER than pl9, that contradicts the hypothesis
and is recorded as a finding, not tuned away.

Method (read-only): scratchpad script estimate_merge_time.jl —
P4_SKIP_SEARCH=1 model include (loads data/functions, writes nothing),
deserializes the existing shard .jls tables, rebuilds the two 14-point
landlord tables exactly like the merge (28 follower solves), then runs
the byte-identical combine() arithmetic on a 1-in-64 stride of the
poor (outer) index with progress prints and stage-survival counters;
full-merge estimate = sample time × 64, calibrated against pl9's known
22,074.8 s. Runs nice-19 on idle cores; the six running merges and the
frozen wave-4 shards are untouched.

RESULTS (landed 18:04, logs est_merge_{pl9,pl10,pl10_noeed}.log in the
session scratchpad):
* Validation on pl9: estimate 24,427 s vs true 22,074.8 s → +10.7%
  error, calibration κ = 0.904. Sample best €10,094.811M ≈ the
  certified €10,094.809M (the sample contains a near-optimal vector).
* pl10:  raw 52,609 s → calibrated ≈ 47,600 s ≈ 13.2 h solo-equivalent
  cross product. noeed: raw 57,876 s → ≈ 52,300 s ≈ 14.5 h.
* WHY (hypothesis check): the pruning part is CONFIRMED — the spend3
  partial prune kills 66.0% of (poor, landlord) triples in pl9 but only
  26.9% (pl10) / 19.5% (noeed); sampled rich iterations 1.10e9 (pl9)
  vs 2.36e9 / 2.60e9 — ≈ 2.2–2.4× the inner work; deep feasibility
  checks 9.25e7 vs 2.47e8 / 2.87e8 (2.7–3.1×). The MAGNITUDE part of
  the hypothesis is NOT confirmed: expected was "well above the spent
  14.4 h CPU", measured is 13.2 h / 14.5 h solo-equivalent — at or
  BELOW the CPU already spent. The merges are slow mainly because ~6 h
  of their life ran under the 310-load shard contention (CPU share
  ~0.76 plus per-cycle productivity loss), not because the remaining
  work is large. Recorded as measured; the hypothesis text stands.
* ETA: with 10–30% productivity loss during the contended phase,
  pl10 has ≈ 0–2.5 h and noeed ≈ 0.5–4 h of wall time left (as of
  18:04) — both certificates expected TONIGHT (pl10 ≈ 18:30–20:30,
  noeed ≈ 19:00–22:00).
* DECISION per the conditional order (threshold "> ~6 further hours"):
  condition NOT met → the parallel merge is NOT launched for
  pl10/pl10_noeed. The pl9 verification run of the parallel merge
  (started while the raw, pre-calibration projections still said
  ~35 h) is left to finish — it validates the implementation for the
  three merges still to come (elec_m20, inclusive, sav4666 follow-on),
  each ≈ 13 h serial vs ≈ 25 min on 36 threads. Its outcome is
  recorded under the implementation entry below when it lands.

## pl12 — D9 recorded; D10 STRICT EQUITY FLOOR: model test tightened, 17 scenarios re-run, standard re-certified at €24,936.2M (2026-11-07, 15:40 → ~17:30; branch `pl12`)

**D9 (closes O-pl12-10).** The reachability of 2030 (D4) is presented as CONDITIONAL on the
modelled 2020–2025 envelope history; the record stays the central case, the × 0.75 history
variant (2030 miss 3.12 at the caps) is the lower bracket. Recorded in
`results/paper/P4_decisions_2026-11-06.md`.

**D10 (closes O-pl12-6) — strict floor.** `bilevel_model_affordable_housing.jl`: both
acceptance tests `equity >= equity_min_eff - 0.001` → `- 1e-6` (the master constraint
`PublicLow >= 0.30·TotalPublic` was always exact; the tolerance sat only in the evaluation
that accepts a design). `make_pl11_summary.py`: runs written before the change with
`feasible = true` but equity < 0.30 − 1e-6 are now counted as infeasible (`EQUITY_FLOOR`).
Pins `test_pl12_pins.jl` 11/11 PASS after the change (the pl10/pl11/history gates do not touch
the tolerance). The standard record (30.01 %) re-evaluated under the new test: unchanged.

**Re-runs (warm start from each scenario's own previous design, tag `strict_ms_cur_<scn>`,
17 scenarios with equity < 30.05 %; `pl12_split` at 30.08 % needed none).** Old → new best
(M EUR, equity):
- identity group `rule_none`, `rule_cap3`, `rule_pl_gross`, `s20`–`s40`, `traj_linear`,
  `traj_soft`, `w05`, `w10`: 25,147.6 (29.92 %) → **24,936.2 (30.04 %)** — the strict search
  left the tolerance basin and found a cheaper strictly feasible design;
- `priv16` 24,823.4 → 24,607.9 (30.02 %); `envcap_p05` 26,269.6 → 26,317.5 (30.04 %);
  `hvac6` 26,558.4 → 26,603.2; `learn0` 29,124.9 → 29,171.3; `inclusive` 41,986.1 → 42,049.4;
- `hpcost_hi` 24,940.1 (29.93 %) → 28,563.0 (38.8 %): the only feasible strict run lands in a
  far worse basin; the earlier value is not a valid design any more. Search bound, visibly loose
  (O-pl12-7).

**Standard re-certified (proof #5).** The identity group's strict design evaluated on `pl12`:
€24,936.2M, feasible, equity 30.04 % — cheaper than the certified 24,974.1. Local proof
re-centred on it (`proof_local_pl12.log`; proof #4 archived as `*_center24974`): **certified
box minimum = the centre, €24,936.163M** (difference 0.005 M = noise; only the flat high-income
light rate moves). **Design of record: low-income envelope 42.9 / 42.9 / 45.1 %, low-income
heat pump 94.7 %, high-income envelope 20.4 / 37.09 / 37.09 %, landlords 0**
(`data/sigma_pl12_local25_record.csv`; record dir `out/scenarios/pl12__local25_record`;
previous record dirs kept as `_cert4` (24,974.1) and `_cert2` (25,186.5)). The energy path is
identical to the 24,974.1 design (2030 221.88, 2035 197.41, 2040 158.09, 2050 97.57): the
last 38 M come from re-allocating rates at unchanged adoption. Equity 30.04 % (binding),
WPB 74.5 %. Full proof chain: 27,422 → 26,630 → 25,142 (tol.) / 25,186 → 25,162 → 24,974 →
**24,936**.

**Regenerated:** `results/pl12_summary.csv`, `results/pl12_multistart_summary.csv`,
`results/pl12_design_table.csv`, `results/pl12_outcome_measures.csv`,
`results/paper/pl12_paper_numbers.csv`, `results/paper/pl12_final_report.md`, both figure sets
(with the six layout fixes requested by the user: fig1 label/history-text positions, fig2 panel
titles, fig3 bar labels without search tags, fig4 bottom-row label room, fig5 end-label offsets,
fig6 legend patches/positions and panel-c title). Journal set copied to
`writing/bilevel_opt_paper/figures/pl12/`.

**OPEN status.** O-pl12-6 CLOSED (D10), O-pl12-10 CLOSED (D9). O-pl12-7 (start dependence)
remains and is now illustrated twice: the strict re-run of a neighbour scenario moved the
standard's record by −0.15 %, and `hpcost_hi` moved by +15 % between starts.

## pl12 Phase 4 LANDED — standard design CERTIFIED on the local box at €24,974.1M after four re-centred proofs; full scenario set (44), outcome measures, design table, both figure sets; hypotheses scored (2026-11-06 20:06 → 2026-11-07 ~15:00; branch `pl12`)

**What ran.** (1) Wave `scripts/run_pl12_wave.sh`: 44 scenarios × 4 starts (batch = the
model's candidate list, `ms_record` = pl10 record, `ms_hpheavy`, `ms_pl10cert`) + the max-σ
evaluation of every scenario (20:06–20:57, 6 parallel, 8 Gurobi threads each). (2) Extra
starts for the standard: `ms_max` (all caps), `ms_p05design` (design of `pl12_envcap_p05`;
the first launch was SCRAMBLED by the `resolve_sigma` order bug, see "Fixes"; relaunched
corrected as `v2_ms_p05design`, 22:10–22:12). (3) Local-box proofs (`enumerate_local.jl`,
±10 pp in 2.5-pp steps, 8 shards × 8 threads + 24-thread merge), re-centred whenever a
cheaper strictly feasible design appeared (re-centring hook
`out/scenarios/pl12/subsidies_local_center.csv`; archived logs
`proof_local_pl12*_center<value>.log`, shards `out/enum_shards/pl12_local25_center<value>/`).
(4) Warm starts from the proof #2 design for the 28 other feasible scenarios
(`ms_pl12record`, 2026-11-07 14:05–14:12) and fixed-σ evaluations of five of their designs on
the standard (`pl12__xe_from_*`). (5) Record dir of the final certified design via the new
`P4_FIXED_SIGMA` mode (`out/scenarios/pl12__local25_record`). (6) `scripts/run_pl12_outcomes.sh`,
`make_pl12_design_table.py`, `make_pl12_figures.py` (working `results/figures_pl12/`, journal
`results/figures_pl12_journal/`).

**Standard `pl12` — design of record = CERTIFIED LOCAL OPTIMUM €24,974.1M (discounted,
2026–2050; strictly feasible, equity 30.01 %).** Chain of values (M EUR): batch search
27,422.3 (the only feasible of the 4 wave starts; `ms_max` 29,836.9) → proof #1 around it
26,629.5 (−2.9 %) → corrected ×1.05-design warm start `v2_ms_p05design` 25,141.7 (equity
29.90 %, i.e. 0.10 pp BELOW the 30 % floor but inside the model's feasibility tolerance of
0.001) → proof #2 around 25,141.7: 25,186.5 with the floor applied strictly (`spend_low ≥
0.30·spend − 1e-6`; the centre fails the strict test, hence "optimum ABOVE the centre by
0.18 %" — expected, see O-pl12-6) → the `pl12_afford` warm start from that design, evaluated
on the standard, 25,162.4 (strict, equity 30.5 %, off-grid) → proof #3 around it 24,974.1
(−0.75 %; optimum on the box edge, rich light +10 pp) → proof #4 around 24,974.1:
**24,974.1** (the centre itself is the box minimum — the listed optimum differs by 0.02 M EUR = numerical noise, and only in the high-income light rate, a flat direction; a FIXED POINT of the re-centring, so the chain stops here). Proof logs: final `proof_local_pl12*.log` (centre 24,974.1), archived `*_center27422`, `*_center25142`, `*_center25162`. Record dir re-evaluation:
€24,974.115M, feasible, equity 30.01 %, WPB 74.5 %; milestones 2030
**221.88** (target 222.12, slack +0.24), 2035 197.41 (slack +14.1),
2040 **158.09** (target 158.66, slack +0.57), 2050 97.57 (target 108.42).
Each proof moved the design to a different corner of a nearly flat spending surface: designs
with low-income envelope rates 10/42/45 % and 44/44/44 % differ by < 1 % in spending.
Search values of this model are therefore start-dependent at the 10 % level (27,422 → 24,974
over the chain) and the certificate covers the final ±10-pp box only (O-pl12-7).

**Record design (subsidy rates).** Low-income owners: envelope light / medium / deep **44.17 % each**, heat pump standard **95.4 %**, upgrade 0. High-income owners: envelope light 22.8 % (flat direction — 32.8 % gives the same spending), medium and deep **37.15 %** (the +0.3-rule cap), heat pumps 0. Landlords (public, private) 0. File `data/sigma_pl12_local25_record.csv`; record dir `out/scenarios/pl12__local25_record`. Compared with the batch design
(low-income envelope 0.4 / 10.4 / 64.9 %, heat pump 76.5 %; high-income 4.7 / 37.5 / 37.5 %)
the proofs flatten the low-income envelope rates across depths, raise the low-income heat-pump
rate towards the cap and keep high-income medium/deep at the +0.3-rule cap. Landlords 0 throughout.

**Outcome measures of the record (`results/pl12_outcome_measures.csv`, row `pl12`; fixed-σ
re-evaluation at the record and at σ = 0).** Spending **24,974 discounted / 32,025 nominal M EUR**. Cumulative CO₂ 2026–2050: 420.9 Mt with the programme vs 451.6 Mt at σ = 0 → **30.7 Mt avoided (6.8 %), 813 EUR/t**. Primary energy saved in 2050: 5.32 TWh/yr (4.70 EUR per kWh/yr). Spending by class: envelope 20,991 / heat pumps 3,984 M EUR; by group: low-income owners 7,495 / high-income owners 17,479 / landlords 0. Low-income energy-cost share of income in 2050: WPB owners **18.2 %** (24.7 % at σ = 0), other low-income owners 8.0 % (11.1 %), public tenants 6.3 %, private tenants 9.5 % (both unchanged — no landlord subsidy). E2050 97.57 vs 104.37 at σ = 0.

**Scenario results (`results/pl12_multistart_summary.csv`, `results/pl12_design_table.csv`,
`results/pl12_outcome_measures.csv`; search bounds, best of 5 starts unless stated).**
Spending M EUR (start) · CO₂ avoided 2026–2050 Mt · EUR/t · E2050:
- Identity group, 25,147.6 (`ms_pl12record`, equity 29.9 % = tolerance): `rule_none`,
  `rule_cap3`, `rule_pl_gross`, `s20`, `s25`, `s30`, `s40`, `traj_linear`, `traj_soft`, `w05`,
  `w10` — the rent rule, the income-share limit ≥ 20 %, the trajectory shape and the
  savings weight do not move the design (landlord rates are 0; 30.6 Mt; 822 EUR/t). They sit
  0.7 % ABOVE the standard's record only because their warm start was the proof #2 design
  (25,186.5) before the chain descended; the final record design is feasible for them too.
- `afford` 25,162.4 (cost-neutral check satisfied by the standard design itself).
- `rule_perm` 23,994 (equity 32.1 %; 27.8 Mt; 863 EUR/t) — permanent rent increase lets
  private landlords renovate unsubsidised; `split` 24,998; `priv16` 24,823; `hpcost_hi`
  24,940 / `hpcost_lo` 28,332 (above the standard although heat pumps are cheaper: its only
  feasible start spends 27,170 M on envelope and 1,161 M on heat pumps — a loose search bound,
  O-pl12-7);
  `hvac6` 26,558 (40.5 Mt); `ban2040` 26,733 (44.3 Mt, 604 EUR/t, E2050 86.5); `w10` = identity.
- `learn0` 29,125 — without heat-pump learning the design avoids 114 Mt at 255 EUR/t because
  the σ = 0 reference then installs far fewer heat pumps (the counterfactual moves, not the
  policy). `noeed` 35,927 (EED off: public landlords renovate nothing on their own; with EED on
  they spend €1.8bn discounted themselves — fig 6c). `inclusive` 41,986 (52 Mt).
- Capacity (D4): `envcap_p05` 26,270 · `p10` 21,284 · `p20` 8,465 (249 EUR/t) · `p30` 3,806
  (heat pumps only) · `p50` 604 — the envelope capacity cap, not the subsidy budget, is what
  makes 2030/2040 expensive. `sav4666` 10,785; `elec_m20` 0; `kprb` 0 (targets met at σ = 0).
- NO feasible design (max-σ evaluation, miss in kWh/(m²·yr)): `co2half` 2030 3.34 and 2040
  14.35; `peffrozen` 2030 2.46 and 2040 2.60; `envcap_m20` 2030 3.31 (after the EED fix, see
  below); `woodpef` 2030 2.10; `r12` 2030 1.79; `invertprices` 2030 1.56; `elec_p20` 2030 0.93;
  `s10`, `s12`, `s13`, `s14`, `s15` affordability (income-share cap) violated at every start.
- Warm starts from the proof #2 design improved 19 of 28 scenarios (by 0.1–15 %), left the
  capacity scenarios unchanged (that design is a poor start when capacity is loose: `p20` 19,989
  vs 8,465) and were infeasible in `ban2040`, `hpcost_lo`, `inclusive`, `noeed`.

**Hypotheses scored.**
- H-pl12-4 (soft 2030; feasible; 2035 slack; 2040 binds; €4–9bn): **REFUTED on cost** —
  the 2030 milestone stayed HARD (D4, Phase 3) and the standard costs €25.0bn (2.4× pl10's
  €10.2bn), because the fixed 2020–2025 history leaves the stock at the envelope cap for the
  archetypes that renovate and the remaining 2026–2030 and 2035–2040 gaps need near-cap
  renovation at near-cap rates. Feasible ✓, 2035 slack ✓, 2040 within one grid step of
  binding ✓ (exactly binding at the batch design).
- H-pl12-5 (HP shift, high-income HP ≥ 20 %; landlords 0; equity floor non-binding):
  **PARTLY REFUTED** — the heat-pump shift is real but entirely low-income (95.4 % at the
  record; high-income HP 0 %); landlords 0 ✓; the 30 % equity floor is **BINDING** at the
  record (30.01 %; 35.7 % and slack at the batch design).
- H-pl12-6 (proof improves by < 2 %): **REFUTED** — proof #1 −2.9 %, and the re-centred
  chain took the value from 27,422 to 24,974.1 (−8.9 %).
- H-pl12-7 (infeasible: `co2half`, `peffrozen`, `elec_p20`, `envcap_m20`): **CONFIRMED**,
  plus six not predicted: `r12`, `invertprices`, `woodpef` (all 2030 misses < 2.1) and
  `s10`–`s15` (affordability).

**Fixes made in Phase 4 (model + tooling).**
- `_eed_hist_bound` in `_eed_max_path`: the EED required public-rental path ignored the
  fixed 2020–2025 history, so `pl12_envcap_m20` was follower-infeasible at every σ. The path
  is now bounded by the minimum fixed public-rental adoption in the history periods. The
  standard batch design is unchanged by the fix (re-checks `pl12__chk_eedfix{,2}`: identical
  spending and milestones); `envcap_m20` becomes evaluable (2030 miss 3.31).
- `P4_FIXED_SIGMA=<file>`: fixed-design evaluation with the full output folder (record dirs).
- `scripts/pl11_common.sh::resolve_sigma`: converting a run dir's `subsidies.csv` into a
  start file used the run-dir row order, not the model's canonical σ order (env poor ×3,
  env rich ×3, hvac poor ×2, hvac rich ×2, landlords). Now mapped by (group, measure) key.
  **Correction note:** the pl10 shared-capacity experiment of 2026-11-06
  (`experiments/2026-11-06_review_checks/`, start `pl10shared`) and the first `ms_p05design`
  start of this wave were launched from SCRAMBLED designs; their infeasible outcomes say
  nothing about those starts. `sigma_start_pl12batch.csv`, `sigma_start_p05design.csv`
  regenerated; `ms_p05design` relaunched as `v2_ms_p05design` (which found the 25,141.7).
- Figure 3 label logic reads the max-σ evaluation log to mark "no feasible design" bars.

**History run 2020–2025 — dwelling counts vs the caps and vs the realism estimate (user
question 2026-11-07; from `state_after_history.csv` and
`out/scenarios/pl12_history__hist/adoption_eval.csv`, dwelling-weighted).** Caps of period 1
(6 years at the KPRB rates 0.027 / 0.040 / 0.043 per year, compounding): envelope **15.15 %**
of each archetype, heating 21.72 %, joint (envelope + 0.4 × heating) 23.18 %.

| stock group | dwellings | light | medium | deep | envelope | share | at cap | heat pumps | DH |
|---|---|---|---|---|---|---|---|---|---|
| SFH owners | 5.618 M | 0 | 0.064 M | 0.447 M | **0.511 M** | 9.1 % | 0.851 M | 0.174 M (3.10 %) | 1,100 |
| MFH owners | 2.539 M | 0 | 0.192 M | 0.007 M | **0.199 M** | 7.8 % | 0.384 M | 0 | 0 |
| MFH public rental | 0.433 M | 0 | 0 | 0.007 M | 0.007 M | 1.6 % | 0.066 M | 0 | 0 |
| MFH private rental | 0.258 M | 0 | 0 | 0 | 0 | 0 | 0.039 M | 0 | 0 |
| all | 8.847 M | 0 | 0.256 M | 0.461 M | **0.717 M** | 8.1 % | 1.340 M | 0.174 M | 1,100 |

(a) **No archetype exceeds a cap.** The archetypes that renovate sit exactly AT the envelope
cap (15.15 %: `SFH_wpb_poor/rich` deep, `SFH_rest_poor` medium, five MFH owner archetypes
medium/deep); two owner archetypes renovate NOTHING in 2020–2025 (`SFH_rest_rich`, 2.244 M
dwellings — the largest archetype — and `MFH_rest_fossil_poor`), because at 0.40 / 0.70 with
an 8 % discount rate no envelope class pays for them; heating 3.12 % vs the 21.72 % cap;
joint 16.4 % vs 23.18 %. The condition for a re-run ("history exceeds the limits") is
therefore NOT met and Phases 2/3 were not re-run. **Correction to the Phase 2 entry:** "every
owner archetype at the cap" and "SFH envelope 0.85 million (15.15 % of 5.62 M)" were wrong —
0.85 M is the cap-bound maximum; the history renovates **0.511 M SFH** (9.1 %).
(b) Against the realism-check figure of 0.35–0.40 million SFH envelope renovations by 2025
(`results/paper/pl11_phase2_realism_check.md` §2 — the pl10/pl11 model's own 2020–2025 value
without / with the record subsidies, NOT an observed number; no observed envelope-only count
exists), the history run is **1.3–1.5× higher**; against the 0.6 million Czyste Powietrze
completed projects of any scope it is 0.85×. The excess over the pl10/pl11 value comes from the
6-year first period at the KPRB rate (15.15 %) versus the 10-year period at the same rate in
pl10/pl11, where the early-period response was spread over 2020–2030.
→ The user then ordered the sensitivity below (SENS-pl12-hist-env); O-pl12-10 records its consequence.

**SENS-pl12-hist-env — 2020–2025 envelope history scaled to 75 % and 50 % (user request
2026-11-07, run 14:30–14:45).** Scenarios `pl12_hist_env075`, `pl12_hist_env050`
(`data/history_adoption_pl12_env075.csv`, `_env050.csv`: every envelope row × 0.75 / × 0.50,
heating history unchanged, everything else = `pl12`). Fixed-σ evaluation at all caps
(`cert_logs/eval_pl12_hist_env0*_xe_max.log`) and one search each (batch start,
`cert_logs/run_pl12_hist_env0*.log`):

| envelope history | SFH envelope 2020–25 | 2026 stock kWh/(m²·yr) | 2030 at all caps (target 222.12) | 2030 reachable | minimum spending (1 start) |
|---|---|---|---|---|---|
| ×1.00 (record) | 0.511 M | 243.88 | 221.39 (slack +0.73) | yes | 24,974.1 (certified local) |
| ×0.75 | 0.383 M | **247.89** | **225.24 (miss 3.12)** | **NO** | none — search: no feasible design |
| ×0.50 | 0.256 M | **251.90** | **229.10 (miss 6.97)** | **NO** | none — search: no feasible design |

2035, 2040 and 2050 stay slack at the caps in both variants (2035 +25.5 / +22.1, 2040 +14.2 /
+11.4, 2050 +34.1 / +32.3). Each 25 % of the envelope history is worth ≈ 4.0 kWh/(m²·yr) in
2026 and ≈ 3.9 in 2030. By linear interpolation the 2030 milestone is reachable at the caps
only if the 2020–2025 envelope history is at least ≈ 95 % of the modelled cap-bound level
(≥ 0.49 M SFH renovations); the ×0.75 variant is the realism-band value of the pl10/pl11
model. **Consequence for D4:** "2030 reachable, hard constraint" holds for the modelled history
only; with any materially smaller history, 2030 is unreachable at the caps and the paper needs
the soft/penalty 2030 variant or the capacity sensitivity (at ×1.05 capacity the slack at the
caps is +1.36, which by the same interpolation absorbs a history of ≈ 0.91 × the modelled
level).

**O-pl12-3 and O-pl12-5 explained.**
- O-pl12-3 — *history classes exempt from liquidity and caps in the history period.* In the
  2020–2025 period the adoption of every class listed in `history_fix_classes` is pinned to the
  file values (`y = y_hist`), so the follower's capacity caps (`adopt_cap_*`, joint cap) and the
  liquidity constraint are switched off for those classes in that period: a pinned value cannot
  also be a decision, and the constraints would otherwise either be redundant (values inside the
  caps) or make the problem infeasible (values outside). The pinned values satisfy the caps by
  construction (table above), so the exemption changes nothing numerically today; it matters
  only if a future history file carries observed values above a cap. Recommendation: keep.
- O-pl12-5 — *no observed envelope figure; the 15.15 % is a capacity-bound model value.* The
  envelope history was not taken from data (none exists for 2020–2025) but from a model run at
  the Czyste Powietrze rates 0.70 / 0.40; in that run the renovating archetypes hit the
  6-year cap, so the "history" is the cap for them and zero for the two archetypes where the
  rates do not pay. The 2026 state (243.88) and the 2030 slack (+0.73 at the caps) inherit this
  assumption directly (see O-pl12-10). Recommendation: keep as the central case, state it in
  the paper as a modelled history, and bracket it with the `pl12_hist_realism` variant.

**OPEN (decision 8 of the brief).**
- O-pl12-6 (equity tolerance): the search accepts equity ≥ 0.30 − 0.001; the certificate
  applies the floor strictly. The 25,141.7 and 25,147.6 search designs (29.90 %) are
  tolerance-feasible only; `envcap_p05`, `hpcost_hi`, `hvac6`, `learn0`, `priv16`, `inclusive`
  records (29.9 %) sit on the same tolerance. **Recommendation:** report the strictly feasible
  certified design as the standard of record (done), state the tolerance in the methods, and
  tighten it to 1e-6 in the next wave (expected effect < 0.2 % on any value).
- O-pl12-7 (start dependence): the standard's search value fell from 27,422 to 24,974.1
  only through designs borrowed from neighbouring scenarios and re-centred proofs; the
  certificate covers the final ±10-pp box; a cheaper basin elsewhere is not excluded. The
  ledger states "search bound" for every non-standard scenario; `hpcost_lo` (28,332 > standard)
  and `envcap_p05` (26,270 > standard) are visibly loose. Recommendation: accept for the paper,
  state the certificate's scope, and give every scenario a start at the final record design in
  the next wave.
- O-pl12-8 (2030/2040 near-binding at the record): slack +0.24 and +0.57
  kWh/(m²·yr); a 2.5-pp grid cannot sit exactly on a constraint. D4 unaffected. Accept.
- O-pl12-9 (`pl12_afford` ≡ standard): the standard design satisfies the cost-neutral check,
  so the affordability scenario adds no constraint; its 25,162.4 design became proof #3's centre.
- O-pl12-10 (history-conditional 2030): the D4 conclusion rests on the modelled 2020–2025
  envelope history (SENS-pl12-hist-env: at ×0.75 the 2030 miss at the caps is 3.12). No observed
  envelope-only count exists to settle it. **Recommendation:** state 2030 reachability as
  conditional in the paper, report the ×0.75 case as the lower bracket, and keep the record
  (modelled history) as the central case. User decision whether the central case should move.

## pl12 Phase 3 — 2030 REACHABLE from 2026 at the caps: hard constraint kept (D4); capacity sensitivity (2026-11-06, ~20:50; fixed-σ evaluations, no search)

**Result.** `pl12` at ALL subsidy caps: 2030 = **221.39 kWh/(m²·yr), slack +0.73** against
222.12; 2035 +28.8, 2040 +17.0, 2050 +35.8 (spending at the caps €49.5bn, not a design).
**D4 → the 2030 milestone stays a HARD constraint; no `traj_values_override` is set.**
H-pl12-2 (not reachable, miss 1–4) **REFUTED**; H-pl12-3 (needs +10–25 % capacity) **MOOT**
(reachable at ×1.0). Why pl12 reaches 2030 and pl11 does not (miss 8.26): the fixed 2020–2025
history at the Czyste Powietrze rates puts every owner archetype at the 6-year envelope cap
(15.15 %) before 2026 — pl11's own period-1 response at the caps was 23.9 % for 10 years —
plus the observed heat pumps (3.1 % of SFH) and the boiler update; the remaining 2026–2030
gap (243.88 → 222.12, −8.9 % in four years) is within the 4-year envelope cap (10.4 %) plus
heat pumps.

**Capacity sensitivity (D4, "in either case"): 2030 value at the caps vs envelope limits.**
×1.00 221.39 (+0.73) · ×1.05 220.76 (+1.36) · ×1.10 220.14 (+1.99) · ×1.15 219.51 · ×1.20
218.89 · ×1.25 218.28 · ×1.30 217.66 · ×1.40 216.55 · ×1.50 216.49. The smallest uniform
increase that makes the EPBD 2030 value reachable is **0 %**; the minimum spending at each
capacity level comes from the Phase 4 searches (`pl12_envcap_p05/p10/p20/p30/p50`).

## pl12 Phase 2 — HISTORY RUN and the 2026 state (2026-11-06, ~20:45; fixed-σ evaluations)

**2026 state (end of the fixed history).** Stock primary energy **243.88 kWh/(m²·yr)**
(2020: 264.43; −7.8 %). Decomposition at σ = 0 (diagnostic scenarios `pl12_diag_envonly`,
`pl12_diag_noboiler`): envelope history alone 264.43 → **247.14** (−17.3); + the observed
heat pumps/DH (3.12 % of SFH dwellings) → **243.88** (−3.3); the boiler update changes
nothing in 2026 by construction (it applies from the first design period) but lowers the
σ = 0 value in 2030 from 231.66 to **227.10** (−4.6). H-pl12-1 **half-refuted**: the
heating history contributes 3.3, not < 3, and the boiler update acts after 2026.

**Heating mix of the SFH dwellings after the history (per archetype, identical by
allocation):** heat pumps 3.10 %, district heat 0.02 %; of the dwellings still on an own
boiler: coal (old) 33.0 %, firewood (old) 30.7 %, gas (old) 28.4 %, oil (old) 1.1 %, gas_cond 3.2 %, biomass 3.0 %, coal5 0.6 %, electric 0.1 %, oil 0.0 %. Incumbent seasonal efficiency 0.731 → 0.749, fossil-mix price 0.0606 → 0.0613
EUR/kWh, CO₂ 0.184 → 0.180 kg/kWh. Owner-occupied MFH and SFH: 15.15 % envelope renovated
2020–2025 (= the 6-year cap; deep for the worst-performing SFH, medium for the rest and for
most MFH); public landlords 1.6 %; private landlords 0.

**Remaining gap to 2030.** From 243.88 to 222.12 = 21.8 kWh/(m²·yr) (−8.9 %). Without
subsidies (σ = 0) the stock reaches **227.10** in 2030 (miss 4.98) and 209.74 in 2035
(slack 1.8), misses 2040 by 16.9 and meets 2050 (104.4). History subsidy spending
2020–2025: **€5,021.7M nominal** (€5,996.1M discounted to 2026) — reported, not in the
state's objective (D3/D7).

**Realism of the history run (vs `results/paper/pl11_phase2_realism_check.md`).** SFH
envelope renovations 2020–2025 = 0.85 million (15.15 % of 5.62 M) against 0.645 million
Czyste Powietrze completed projects of any scope — of the right order, likely high (the
cap binds). OPEN O-pl12-5: no observed envelope figure; the 15.15 % is a capacity-bound
model value, not data.

## pl12 Phase 1 — D1–D7 IMPLEMENTED on branch `pl12`; gates PASS; hypotheses for Phases 2–4 PRE-REGISTERED (2026-11-06, ~20:30, decision record `results/paper/P4_decisions_2026-11-06.md`)

**What changed (model file, all defaults = committed behaviour; the period-dependent
incumbent arrays equal the legacy scalars in every period unless `fuel_mix_update` is
set, so every pl10/pl11 scenario is bit-identical — gates below).**
- D1 `period_years` (scenario key; pl12: 2020;2026;2030;2035;2040;2050, last period to
  2060) and D6 `co2_price_path` (0, 22.5, 70, 120, 200, 350 EUR/t) override `context.csv`;
  a length check ties the carbon path to the period count.
- D1 fixed history: `history_adoption_file` (archetype, measure, y, period) fixes the
  adoption of the listed measure classes (`history_fix_classes`, default envelope+hvac)
  in the periods before `subsidy_horizon_start` (follower and master mirror); those
  classes are exempt from their capacity caps and from the liquidity constraint in the
  history periods (the history is data, not a budget choice — recorded). `y_upper` in
  the history periods equals the fixed value.
- D3 `history_subsidy=(sfh_poor=0.70, sfh_rich=0.40)`: the subsidy fraction pinned to
  the history adoption of SFH owner-occupiers (`σ_hist`); it enters the household's sunk
  cost, liquidity and the affordability annuity, never the state's objective.
  `history_spending.csv` + console line report it separately (nominal and discounted).
- D7 `subsidy_horizon_start=2026`: `z_leader` returns 0 before it; the master's
  TotalPublic/PublicLow, the equity share and the WPB rule sum over periods from the
  design start; the WPB savings reference is the state at the end of the history
  (`E_sav_ref`) — also patched into `enumerate_local.jl` / `enumerate_exact.jl`.
  `discount_base_year=2026`: the state's `disc()` is based there (follower `fdisc`
  keeps 2020; its optimum is base-year invariant; `net_capex_factor` is a ratio).
- D2 `fuel_mix_update` (SFH, hpdh_share 0.03123, boiler_share 0.06668, new_mix gas
  condensing 31.2 % / biomass 29.2 % / class-5 coal 6.4 % / electric 1.2 % / oil 0.1 %
  of the boiler replacements, η 0.95 / 0.87 / 0.85 / 1.0 / 0.85): from the first design
  period the four SFH archetypes carry the post-replacement incumbent mix. Implemented
  as per-period arrays `base_at` (= base × η_2020/η_new, useful heat unchanged),
  `remain_hp_at`, `remain_dh_at`, `redfac_amt`, `pfuel_at`, `co2_int_at`,
  `pef_fossil_at` (electric share × the period's electricity PEF), `Δp_*_at`,
  `c_prim_*_at`, `pef_base_at`; used in the follower, the master, `annual_bill`, the
  frozen reference, the ETS2 revenue writer and `primary_intensity`. SFH incumbent
  efficiency 0.731 → 0.749, mix price 0.0606 → 0.0613 EUR/kWh, CO₂ 0.184 → 0.180 kg/kWh.
  Derivation and sources: `data/history_2020_2025_pl12.md` (count 550,000 = NFOŚiGW
  603,000 by July 2026 − ≈31,000 completions in 2026 − ≈20,000 before 2020; lower
  bound by decision; gas-condensing 0.95, class-5 coal 0.85 and oil 0.85 ASSUMED).
- Reporting: `state_after_history.csv` (per-archetype primary and delivered energy,
  shares, incumbent η/price before and after) in search runs; the eval report
  (`scripts/eval_sigma_report.jl`) dumps `adoption_eval.csv`, `energy_path_eval.csv`
  and prints the history spending and the SFH incumbent update.
- Scenario family `pl12*`: every `pl11_*` mirrored with the D1/D3/D6/D7 keys and
  `history_adoption_file=data/history_adoption_pl12.csv`; `pl12_history` (heating
  history only, envelope free) is the D3 history run; `pl12_envcap_p05 … p50` are the
  D4 capacity sweep (envelope limits × 1.05 … 1.50, joint = env + 0.4 × 4 %/yr).
- Scripts: `make_pl11_summary.py <prefix>`; `test_pl12_pins.jl` (G1 pl10 record
  10,233.5 / G2 pl11 caps 230.39 / G3 history run) registered in `run_pl11_tests.sh`.

**Gates.** G1 pl10 design of record under the patched model: €10,233.5M, 2030 −0.07,
2040 +0.08 (bit-identical). G2 pl11 all caps: €49,186.2M, 2030 miss 8.26 (identical).
`test_pl12_pins.jl`: **11/11 PASS** (G1 pl10 record, G2 pl11 caps, G3 history run; `results/cert_logs/test_pl12.log`).

**History run (D3) — already evaluated, Phase 2 reads it.** `pl12_history` at the Czyste
Powietrze rates (0.70/0.40, applied in every period = constant-rate foresight,
OPEN O-pl12-2): period-1 envelope adoption at the 6-year capacity cap (15.15 %) for
every owner-occupied archetype (SFH deep for the worst-performing, medium for the
rest; MFH owners too, at σ = 0), public landlords 1.6 %, private landlords 0; 2026
stock primary energy **243.88** kWh/(m²·yr) (2020: 264.43); history subsidy spending
€5,021.7M nominal (€5,996.1M discounted to 2026). `data/history_adoption_pl12.csv`
fixes period 1: envelope from this run (all 44 archetypes), SFH heating from the
observed data, MFH heating from this run (model, ≈ 0).

**Hypotheses (pre-registered BEFORE reading the Phase 2/3 evaluations and before any
pl12 search).**
- H-pl12-1 (Phase 2): the 2026 state is 243.9 kWh/(m²·yr), i.e. 2030 (222.1) needs a
  further −8.9 % in four years; the heating history and boiler update contribute less
  than 3 kWh/(m²·yr) of the 2020→2026 drop (the envelope history dominates).
- H-pl12-2 (Phase 3, D4): 2030 is NOT reachable from 2026 at the caps; the miss is
  between 1 and 4 kWh/(m²·yr) (the history run at 0.70/0.40 missed by 1.9).
- H-pl12-3 (Phase 3): the smallest uniform envelope-capacity increase that makes the
  EPBD 2030 value reachable at the caps is between +10 % and +25 %.
- H-pl12-4 (Phase 4): with the soft 2030 target (= the max-σ value), the standard run is
  feasible and the 2035 milestone is slack; 2040 binds; spending is below pl10's
  €10.2bn because 2030 no longer forces early envelope renovation (expected €4–9bn).
- H-pl12-5 (Phase 4): the standard design shifts to heat pumps (high-income HP rate
  ≥ 20 %); landlords stay at 0; the 30 % equity floor is non-binding.
- H-pl12-6 (Phase 4): the local proof improves the search value by < 2 % (as pl10).
- H-pl12-7 (Phase 4): scenarios infeasible even with the soft 2030 target: `co2half`,
  `peffrozen`, `elec_p20` (2040 unreachable at the caps in pl11) and `envcap_m20`.

**OPEN (decision 8 of the brief).**
- O-pl12-1: the 550,000 replacement count is an estimate (range 520–580k); no sensitivity run.
- O-pl12-2: constant-rate foresight in the history run (rates 0.70/0.40 assumed to
  persist after 2025 in the households' expectations); the zero-after-2025 variant
  was not run. Recommendation: keep constant-rate (Czyste Powietrze continued in 2026).
- O-pl12-3: history classes exempt from liquidity and caps in the history period
  (fixed data). Recommendation: keep.
- O-pl12-4: MFH heating history = model value (≈ 0); no observed MFH figure. Keep.

## pl11 wave LANDED (2026-11-06, 18:06–18:58) — 38 of 40 scenarios have NO feasible design; 2030 is the killer; hypotheses scored

**What ran.** `scripts/run_pl11_wave.sh`: 38 scenarios × 4 starts (model candidates, `record`,
`pl10cert`, `hpheavy`) = 152 searches (≤ 6 parallel, 8 Gurobi threads each), then a max-σ
evaluation (`eval_<scn>_xe_max.log`) of every scenario without a feasible run, then
`make_pl11_summary.py`. Logs `results/cert_logs/run_pl11*.log`, `pl11_wave.log`, stamps
`pl11_done.txt`; tables `results/pl11_summary.csv` (160 run dirs) and
`results/pl11_multistart_summary.csv` (one row per scenario); figure
`results/figures_pl11{,_journal}/fig_pl11_feasibility.*` (`make_pl11_figures.py`).
Run dirs `out/scenarios/pl11*`. Note: the first batch stage launched up to 7 instead of 6
parallel runs (launch race in `run_pl11_batch.sh`, fixed afterwards — no effect on results).

**Result of record.**
- **No feasible design in 38 of 40 scenarios**, from any of the four starts. At ALL subsidy caps
  the 2030 milestone is missed by 3.5–16.2 kWh/(m²·yr): standard `pl11` **8.26** (as the
  pre-wave check), `envcap_p20` 3.46, `sav4666` 4.84, `woodpef` 5.87, `rule_pl_gross` 7.35,
  `rule_perm` 7.76, `w10` 8.00, `w05` 8.04, `inclusive` 8.05, `noeed` 8.65, `priv16` 8.51,
  `peffrozen` 9.82, `hpcost_lo` 11.77, `r12` / `hvac6` / `co2half` 12.70, `invertprices` 13.75,
  `envcap_m20` 16.20; all SQ1 income-limit, afford, rule_none/cap3, pubpoor, ban2040, split,
  traj_linear/soft, hpcost_hi, learn0 = 8.26 (their change does not touch the pre-2030 response).
  Later milestones at the caps: 2040 also missed for `co2half` (22.97), `peffrozen` (6.94),
  `elec_p20` (4.28); 2050 also for `co2half` (4.93). Infeasibility is search + max-σ evidence,
  NOT a proof (no list proofs ordered; a design with rates below the caps could in principle do
  better — the four warm starts and the model's own candidate list found none).
- **Feasible: `pl11_elec_m20` €4,168.1M** (batch; hpheavy start 4,281.1; pl10cert start
  10,773.6; record start infeasible) — a **pure heat-pump design**: low-income HP 32.8 %, DH
  1.6 %, high-income HP 15.0 %, envelope 0 everywhere, landlords 0; 2030 at 219.66 (slack 2.5),
  E2050 59.5; equity 29.9 % = floor binding (tolerance). vs pl10 `elec_m20` €5,493.8M.
  **Feasible: `pl11_kprb` €0** (absolute targets met naturally on the KPRB stock; 4/4 starts).
- Mechanism of the 12.70 group (`r12`, `hvac6`, `co2half`, and 11.77 for `hpcost_lo`): the 2030
  value at the caps is set by how much envelope renovation high-income owners do before 2030
  under their 40/40/50 % caps. In `pl11` they reach the capacity cap (23.9 % by 2030); with 12 %
  discounting, a halved carbon price, cheaper heat pumps or more heating capacity they renovate
  only 16.1 % (they wait for the heat pump), and 2030 is 4.4 kWh/(m²·yr) worse. Low-income owners
  are at the cap (23.9 %) in every scenario (100 % envelope subsidy). PV did this work in pl10.
- **Local proof (brief decision 5): NOT POSSIBLE** — the standard run has no feasible design
  around which to prove (O-pl11-1 realised). No proof was run.

**Hypothesis scoring.** H-pl11-1 **confirmed** (standard infeasible from all starts; max-σ miss
8.26). H-pl11-2 **refuted in three of four parts**: `envcap_p20` infeasible (miss 3.46, the
closest), `hvac6` infeasible and WORSE (12.70), `elec_m20` FEASIBLE (predicted infeasible); only
`kprb` as predicted. H-pl11-3 **confirmed where testable**: the one non-trivial feasible design
is heat pumps only, no envelope subsidy. H-pl11-4 half-confirmed: `learn0` infeasible like
`pl11` (identical 8.26 — HP learning does not act before 2030); cost comparison not testable.
H-pl11-5 **confirmed where testable**: landlords 0 in `elec_m20`; `rule_perm` infeasible, so the
"positive landlord rate under rule_perm" part is untested. H-pl11-6 **partly refuted**: 2030 is
the sole killer in 35 scenarios, but 2040 is also unreachable at the caps in `co2half`,
`peffrozen` and `elec_p20` (not only `peffrozen`), and 2050 in `co2half`.

**Consequence for the paper (O-pl11-1, now concrete).** Under the brief's model (no PV, HP
learning only, precedence kept), the Polish SFH+MFH stock cannot reach the 2030 milestone with
renovation subsidies at any rate on the five instruments, except with 20 % cheaper electricity
or on the KPRB demand data. The pl10 result (€10.2bn, 2030 binding) depended on PV displacing
coal in the primary-energy accounting. The paper's main question has to be reframed around
2030 reachability (capacity, demand data, PV accounting, a boiler-replacement option — see the
Phase 2 entry O-pl11-4/O-pl11-5) before any cost-minimal design can be reported. User decision.

**OPEN items added.** O-pl11-6: infeasibility of the 38 scenarios is search + max-σ evidence
only (no certified infeasibility). O-pl11-7: `pl11_elec_m20` is a search bound (4 starts, 3
feasible), no local proof ordered for a non-standard scenario.

## pl11 Phase 2 — realism check vs observed 2020–2025 + biomass-boiler question (2026-11-06, ~18:40; fixed-σ evaluations only, no search, production model untouched)

**Order.** Use `data/observed_2020_2025_poland.md`; answer its Section 4 (efficient biomass boiler).
Write-up: `results/paper/pl11_phase2_realism_check.md`. Scripts and the scratch biomass patch:
`experiments/2026-11-06_review_checks/phase2/`.

**Realism findings (pl10 σ=0 / record; pl11 σ=0 / all caps; period 1 × 0.5 for 2020–2025).**
- Heat-source replacements in SFH by 2025: model **0 in every configuration** (also at all subsidy
  caps, i.e. 100 % heat-pump subsidy for low-income owners) vs ≈ 0.6 million observed (CP). Cause:
  at the model's prices a heat pump costs more to run than the coal/wood mix (0.064 vs ≈ 0.060 EUR
  per kWh of heat demand) plus 2 %/yr maintenance, and there is no carbon price before 2030; a free
  heat pump raises a coal-heated household's yearly cost. Heat pumps in existing dwellings by 2025:
  13,900 (MFH public landlords via the EED obligation) vs a retrofit share of 0.5–0.6 million sold.
  → **O-pl11-5 (OPEN)**: pre-2030 heating-system switching is not reproduced; the 8 % discount rate
  was calibrated on the envelope rate only; mechanisms missing: 2022 price expectations, PV
  self-consumption, anti-smog resolutions, the 2023 subsidy peak.
- Envelope renovations by 2025: SFH 0.35–0.40 million (σ=0 / record), MFH 0.18–0.33 million; no
  observed envelope-only figure (CP 645,000 completed projects of any scope) — flagged, not refuted.
- PV (pl10): ≈ 0.9 million existing dwellings by 2025 vs ≈ 1.4 million prosumer installations
  observed (new + existing): right order of magnitude. Its removal (brief decision 1) is the single
  reason 2030 becomes unreachable in pl11.

**Biomass boiler (Section 4).** (a) The option does NOT exist: heating measures are fossil→heat pump
and fossil→district heat only; incumbent boilers keep η 0.70/0.65/0.87/0.85 forever. (b) Scratch
estimate (seventh measure `hvac_fossil_to_biomass`, SFH EUR 4,767 = CP max eligible pellet-boiler
cost PLN 20,500, MFH area-scaled EUR 2,335; η 0.87 base / 0.80 sens.; wood price 0.0523 base /
pellet 0.068 sens.; CO₂ 0; PEF 1.1; unsubsidised; shares the heating cap; excluded from the +0.3
rule): best reachable 2030 at all caps moves from 230.39 (miss 8.26) to **226.11 (miss 3.98)** at
η 0.87, to 231.22 (miss 9.09, worse: crowds out envelope renovation) at η 0.80, and is unchanged at
pellet prices (no pre-2030 uptake). **2030 stays unreachable in every variant.** σ=0 uptake 0.4–0.9
million SFH boilers by 2025 ≈ the observed order. Lock-in: with PEF 1.1 and no CO₂ cost the option
cuts SFH heat pumps by 2050 from 37.5 % to 5 % and the 2040/2050 milestones are then missed by
19–28 / 26–37 kWh/(m²·yr) at all caps. → **O-pl11-4 (OPEN, user decision)**: add a boiler-
replacement option to the production model or not; convention (total vs non-renewable PEF) decides
its reading. Production model NOT changed.

## pl11 wave — review brief IMPLEMENTED, gates running, wave PRE-REGISTERED (2026-11-06, ~18:00, user brief — BEFORE any pl11 search)

**Brief of record (user, 2026-11-06, verbatim decisions, not to be re-asked).**
(1) PV is removed entirely — no PV option at all. (2) Learning rates: heat pumps
2.5%/yr kept (sources as in MODEL_V2_ASSUMPTIONS.md: IEA Future of Heat Pumps 2022;
Applied Energy 2024 learning-rate range); envelope and district heat 0; the
"no cost decline at all" run is a sensitivity. (3) The heating ≤ envelope + 0.3
rule stays, documented as a proxy for minimum insulation for heat pumps. (4) In
the rent-rule scenarios landlord subsidies are allowed with the standard landlord
cap (0–100%). (5) No full list proofs; only the local proof around the new
standard design. (6) Commit to a new branch `pl11` with named paths only.
(7) Thread limit per Julia job in the wrappers (8). (8) Remaining ambiguity:
closest option to the brief, recorded OPEN here, continue.

**Why (review of 2026-11-06, `writing/bilevel_opt_paper/REVIEW_REPORT_2026-11-06.md`
and `QUANTIFICATION_2026-11-06.md`; scratch-copy experiments archived in
`experiments/2026-11-06_review_checks/`).** PV in the committed code cut 25% of
delivered energy on EVERY carrier incl. coal, with the fuel-cost, CO₂ and
primary-energy effect; 18–23% of owners had PV by 2030 under the record design,
which carried the 2030 milestone. Learning rates were undisclosed in the paper
and "assumed, no source" in PROVENANCE. The +0.3 rule was binding and undocumented.
The four `pl10_rule_*` scenarios had `landlord_subsidy_cap = 0`.

**What was changed (branch `pl11`, model file; every default = committed
behaviour, bit-identical — re-check: record design under `pl10` re-evaluates to
€10,233.5M with 2030 −0.07 / 2040 +0.08, identical to the value of record).**
- `scen(...)` keys `pv_enabled` (default true) and `learning_rates` (default
  nothing = CSV values; Dict m_id ⇒ annual rate overrides listed measures).
- `pv_enabled=false` zeroes `y_upper` for the PV measure everywhere (follower
  and master bounds), so no PV can be adopted; nothing else touches the energy
  chain (r_pv ≡ 0). The PV rows stay in `subsidies.csv` (rate 0) for format
  stability.
- Learning override applied where `learning_m` is read from `measures_v2.csv`.
- `P4_GRB_THREADS` (environment) caps Gurobi threads of the follower and master
  models; the wrappers in `scripts/` set 8. OPEN (decision 8): a thread cap can
  change which of several tied optimal follower responses Gurobi returns, so
  bit-identity across thread settings is not guaranteed; all pl11 results are
  produced with 8 threads and the setting is written to every log.
- Precedence rule: comment in the follower (kept; proxy for minimum insulation
  before a heat pump; 0.3 slack = switches in already adequate dwellings).
- Scenario family `pl11*`: every `pl10_*` mirrored with `pv_enabled=false`,
  `learning_rates = {envelope light/medium/deep 0, DH 0}` (HP keeps 0.025 from
  the CSV); `pl11_rule_none/pl/cap3/perm` keep `landlord_subsidy_cap = 1.0`
  (decision 4) — `pl11_rule_pl` is therefore identical to `pl11` and is not run;
  `pl11_learn0` adds HP learning 0 (decision 2 sensitivity). 39 scenarios.
- Wrappers `scripts/run_pl11_{batch,eval,local_proof,tests,figures,status,stop}.sh`
  + `scripts/eval_sigma_report.jl` (fixed-σ report); start designs
  `data/sigma_start_{record,max,w10}.csv` added (pl10 record, all caps, pl10_w10 record).

**Fixed-σ checks already made (evaluations, not searches; `results/cert_logs/eval_pl11_chk_*.log`).**
- `pl11` at the pl10 design of record: INFEASIBLE — 2030 missed by 13.62,
  2040 by 1.09; spending at those rates €12,715M; owner HP uptake 2050 rises to
  46% (high-income) / 22% (low-income); PV 0.
- `pl11` at ALL subsidy caps: INFEASIBLE — 2030 missed by **8.26** kWh/(m²·yr);
  2035 +20.6, 2040 +9.8, 2050 +33.3 slack; spending €49.2bn.
  Same picture as the PV-electricity-only experiment of the review
  (`experiments/2026-11-06_review_checks`).

**Hypotheses (pre-registered before the wave; scored when it lands).**
- **H-pl11-1**: `pl11` (standard) has NO feasible design: no warm start reaches
  2030 (max-σ miss 8.26 is beyond what intermediate rates can recover).
- **H-pl11-2**: feasible designs exist only where the 2030 gap closes by other
  means: `pl11_envcap_p20` (capacity ×1.2), `pl11_kprb` (lower demand), and
  possibly `pl11_hvac6`; `pl11_elec_m20` stays infeasible (cheap electricity
  helps 2040, not 2030).
- **H-pl11-3**: where feasible, designs move from envelope to heat pumps
  relative to pl10 (no PV, envelope learning 0, HP learning kept).
- **H-pl11-4**: `pl11_learn0` is infeasible wherever `pl11` is, and costlier
  where both are feasible.
- **H-pl11-5**: with the landlord cap restored in the rent-rule scenarios,
  landlords still receive ≈0 under the net (grant-deducting) rules; a positive
  landlord rate appears at most under `rule_perm`.
- **H-pl11-6**: the 2030 milestone is the sole feasibility killer; 2035/2040/2050
  are reachable at the caps in every scenario except `peffrozen`.

**Run plan (pre-registered).** `scripts/run_pl11_wave.sh`: 38 scenarios
(`pl11_rule_pl` skipped) × 4 starts (model candidates; `record`; `pl10cert`;
`hpheavy`) = 152 searches, ≤ 6 in parallel at 8 Gurobi threads each; then a
max-σ evaluation of every scenario without a feasible design (miss per milestone);
summary `results/pl11_multistart_summary.csv` (best per scenario, source tag);
local proof around the best `pl11` design ONLY if one is feasible — otherwise
OPEN: no proof possible, recorded with the max-σ evidence. Figures/tables of the
pl10 pipeline (`make_pl10_figures.py`) are NOT regenerated for pl11 until the
feasibility picture is known (OPEN; see wave-landed entry).

**OPEN items recorded under decision (8).**
- O-pl11-1: if H-pl11-1 holds, the "cost-minimal design" of the paper has no
  pl11 counterpart; the paper's main question becomes "what is needed to reach
  2030 at all" (capacity, demand data, or PV as an explicit accounted measure).
  Not resolved here; the wave quantifies the misses.
- O-pl11-2: Gurobi thread cap vs tie-breaking (above).
- O-pl11-3: `pl11_rule_pl` ≡ `pl11` — not run; ledger notes the identity.

## Worktrees MERGED into master + pinned gates PASS (2026-11-05, ~17:20)

Final checkpoint `183c052`, then `worktree-multistart-search` (`0363ca7`,
warm-start runs + wood_pef/traj/envcap/invertprices levers + summary CSV)
and `worktree-parallel-merge` (`0ebdbdc`, parallel cross product +
enumerate_local.jl) merged into master, both clean (0 conflicts). Pinned
gates re-run on merged master: `test_switches_off.jl` baseline **8/8
PASS** and tenure_on **8/8 PASS** (`cert_logs/gate_postmerge_*.log`) —
the merged model still reproduces the committed designs exactly. Large
proof diagnostics (24M–335M affordability grid/local reports, shard
caches) deliberately left uncommitted in the worktrees.

## Per-archetype reporting REGENERATED at the design of record
## (2026-11-05, ~17:00, user order) — all figures now show one design

Full run-dir reporting for the certified local optimum built with the
run_e1.jl pattern (σ fixed, follower evaluation only, leader NOT
re-optimised): `out/scenarios/pl10__local25_record/` (config_used,
subsidies, energy_path, adoption_values, subsidy_by_archetype,
uptake_by_group, affordability_by_archetype — all in the model's own
column formats; script scratchpad/run_record_pl10_local.jl; evaluation
reproduced €10,233.542M feasible). `make_pl10_figures.py` detail block
now uses this dir when the local certificate is the record (source
"local proof", label "certified local optimum"); the interim
"detail shows the search design" note is superseded. Figures 1/2/4/5
re-run in both modes — every figure now reports the SAME design.
Spot checks: fig2 group spending sums exactly to €10,233.5M; the two
low-income owner groups remain equal by construction (0.88524);
fig4's headline (WPB owners' 2050 cost share 40.5% → 19.6% ≈ halved;
private tenants slightly worse 8.9% → 9.3%) carries over. Numbers of
record for the paper (spending by group/measure, uptake by group/tenure,
2050 cost shares, milestones, scenario deltas) reported to the user from
these files + outcome_measures_summary.csv.

## LOCAL PROOF LANDED — pl10 VALUE OF RECORD IMPROVES TO €10,233.5M
## (2026-11-05, 16:10) — PROOF CHAIN COMPLETE

**CERTIFIED LOCAL OPTIMUM €10,233.540M** on the 2.5%-step box (±10 grid
points) around the stored pl10 search design (`cert_pl10_local25.log`;
gate passed 15:39 on the sav4666 certificate, shards 15:39–16:05, merge
done 16:10 — well inside the 2026-11-06 12:00 deadline). Joint
re-evaluation matched; the center (the €10,397.419M batch search design)
re-evaluates feasible — the arithmetic check passed. The local optimum is
**€163.9M (1.576%) BELOW the search design → it becomes pl10's value of
record** (ruling (a): cheapest feasible design known, labelled by source).
The grid certificate (€11,586.8M, proven optimum on the 5-pp rate list)
stays alongside, unchanged.

Design of record (exact rates = center + 2.5-pp-grid offsets, verified
against the center file): poor env 10.27/41.34/41.34 (light +10 pp vs
center), rich env 7.86/14.08/16.54 (light +7.5 pp), poor hvac 0/2.5
(upgrade +2.5 pp), rich hvac 21.56/0.31, landlords 0/0 — the improvement
is bought entirely with cheap LIGHT-envelope rates plus a small poor-DH
rate; all other rates sit at the center. Fixed-σ re-evaluation
(`eval_cert_pl10_local.log` → `record_dir_pl10_local25/`): €10,233.542M
(€0.002M from the certificate, rounding), binding milestones UNCHANGED
vs the old record (2030 −0.07, 2040 +0.08, within tolerance; 2035/2050
slack), KPIs E2050 92.06 (old 97-ish search design), equity 37.07%,
WPB 78.88% → `cert_design_kpis.csv` key `pl10__local25`.

Downstream per the standing procedure: outcome-measure rows for pl10
RECOMPUTED under the new record (old rows removed first): CO₂ 2020–2050
630.21 → 594.31 Mt (avoided 35.90, was 37.0), €285.1/t (was 281),
prim-2050 71,980 GWh, €2.508/kWh; record_source "certificate (local
box)". `design_table_of_record.csv` standard column rebuilt from the new
record design (source label "certified local optimum").
`make_pl10_figures.py` additions: `local_cert()` parser (the local log
deliberately avoids the grid-certificate marker), record_of override,
new fig3 mark "§ certified local optimum (2.5%-step box …) — value of
record" (journal: "proven on the local box"), summary-row KPIs from
`pl10__local25`, design table sourced from the record dir. Per-archetype
DETAIL panels (fig1/2/4/5) still show the SEARCH design (no run dir
exists for the local design) and now say so in their notes — regeneration
of full per-archetype outputs at the record design is available on order.
Both figure modes re-run and verified. Nothing committed.

## sav4666 CERTIFIED — GRID-PROOF PROGRAMME COMPLETE: 9/9 (2026-11-05, 15:37)

**pl10_sav4666 certified grid optimum €9,519.727M** (joint re-eval feasible
and matching — no stop). Certificate is ABOVE the search record
(ms_hpheavy **€8,724.0M**, −8.4% vs certificate) → **search stays the value
of record** (ruling (a)); certificate alongside in
`certified_grid_optimum_M`. Certified grid design: poor env 15/20/20,
rich env 0/0/20, poor hvac 80/80, rich hvac 0/5, landlords 0/0.

Chain notes of record: (1) the follow-on driver printed **"SAV4666
FOLLOWON DONE" PREMATURELY at 13:59** — the parallel-merge interceptor
killed its serial merge child (pid 2967444) and the driver took the kill
for completion; the marker predates the certificate by ~1h38m. The
interceptor's replacement ran on 24 threads and wrote the certificate to
the CANONICAL log name (`cert_pl10_sav4666_hybrid.log`), so every
downstream gate/parser works unchanged; killed-serial-log evidence is
inside the same file (progress lines up to 16.5% before the kill).
(2) The all-proofs and local-proof watchers died with the previous CLI
session (~14:20) and were re-armed in the new one (order of 15:00);
nothing was missed in the gap. (3) Shard phase 10:31–~13:55 (8 shards,
13,206 poor + 1,248 rich solves each), parallel merge 13:59–15:37.

With this, **all 9 grid proofs are done** — 8 certified optima + 1
certified infeasibility (co2half). Record vs certificate (€M, from
`fig3_scenario_spending_data.csv`): pl10 10,397.4 / 11,586.8; noeed
10,862.5 / 11,586.8 (identical to pl10's certificate — EED has €0 value
on the grid, as recorded 2026-11-03); ban2040 10,604.2 / 11,217.8;
split 11,916.3 / 12,885.9; elec_p20 28,282.0 / 28,282.0 (**the only
scenario where the certificate IS the value of record**); elec_m20
5,493.8 / 5,655.7; sav4666 8,724.0 / 9,519.7; inclusive 27,176.3 /
30,553.0. Zero ‡ (proof-pending) rows remain in fig3; both figure modes
re-run and verified (sav4666 row: 8,724.0 search / 9,519.7 certified /
proof_pending False; KPIs E2050 98.11, equity 31.4%, WPB 77.5%).
REMAINING: the LOCAL exact proof around the pl10 search design
(€10,397.4M; 2.5% box, 18,630 solves + 12-thread merge), gate passed by
this certificate, deadline 2026-11-06 12:00.

## sav4666 CERTIFIED — the LAST grid proof; local proof gate open
## (2026-11-05, ~15:30)

**pl10_sav4666 certified grid optimum €9,519.727M** (joint re-evaluation
feasible and matching — no stop). The certificate is ABOVE the search
record (ms_hpheavy €8,724.0M, −8.4% vs certificate) → **search stays the
value of record** (ruling (a)), certificate alongside in
`certified_grid_optimum_M`. Certified σ: poor env 15/20/20, rich env
0/0/20, poor hvac 80/80, rich hvac 0/5, landlords 0/0. Both figure modes
re-run; **no scenario carries the ‡ proof-pending mark any more — all
nine grid proofs are done** (5 certificates landed 11-03/04, elec_p20 +
co2half + sav4666 on 11-05; co2half = certified infeasibility).

Chain notes for the record: (1) the follow-on driver printed "SAV4666
FOLLOWON DONE" at 13:59 PREMATURELY — its serial merge child was killed
by the parallel-merge interceptor, which immediately launched a 24-thread
parallel merge writing to the SAME canonical log
(`cert_pl10_sav4666_hybrid.log`); the certificate there is the parallel
merge's (progress lines + 'PARALLEL cross product' in the same file).
The all-proofs watcher fired on the premature marker; the certificate
watcher fired correctly on the real certificate ~15:30. (2) Shard phase
10:31–13:55 (8 shards, 13,206 poor + 1,248 rich solves each), merge
13:59–~15:30. (3) The local-proof gate (certificates for noeed,
elec_m20, inclusive, sav4666) is now fully met — driver polls at 300 s,
local proof expected to start ≈15:40 and finish well inside the
2026-11-06 12:00 deadline.

## Certificate wave LANDED: elec_p20 + co2half (and inclusive, found
## unrecorded) — ALL MAIN PL10 PROOFS DONE (2026-11-05, 04:57–10:31)

elec_p20 and co2half certificates landed overnight; while recording them,
the **inclusive** certificate was found to have landed already on
2026-11-04 11:02 (its watcher waits on sav4666 too, so it never fired) —
it is recorded here for the first time; its value had been flowing into
the figures since yesterday's re-runs (record_of reads the cert logs).
elec_m20's certificate is NOT part of this wave — it landed 2026-11-04
01:26 and was recorded then (entry "~02:15" below). The orchestrator
marker **"ALL PL10 PROOFS DONE"** fired 10:26 (6/8 = all main-wave
scenarios; sav4666 runs in the follow-on, launched 10:30:58, ≈13–14 h
serial → expected late evening).
Option A guard finished cleanly: both serial merges killed on their parallel
certificates, **no re-evaluation mismatch** (exit states co2half=1,
elec_p20=1; log `optionA_guard.log`). Per-certificate procedure applied to
each (value-of-record rule, ruling (a)):

- **pl10_elec_p20** (parallel merge, 04:57): certified grid optimum
  **€28,281.982M**, joint re-eval matched exactly. Certificate is BELOW the
  search record (batch €29,617.5M) → **the certificate becomes the value of
  record** — the first pl10 scenario where the proof beats the search
  (−€1,335.5M, −4.5%). Certified design: poor env 30/70/70, rich env
  40/40/40, poor hvac 90/100, rich hvac 5/20, landlords 0/0. Fixed-σ joint
  evaluation (log `eval_cert_elec_p20.log`): spending reproduced to the
  €0.001M, feasible, all four milestones met (2030 margin +5.19, 2035
  +22.77, 2040 **+0.65 — nearly binding**, 2050 +1.13), E2050 107.29,
  equity 31.35%, WPB 73.91% → row appended to `cert_design_kpis.csv`; the
  design written as `cert_logs/record_dir_elec_p20_cert/subsidies.csv`.
  Outcome-measure rows RECOMPUTED under the new record (old batch rows
  removed from both outcome CSVs first): CO₂ 2020–2050 696.92 → 619.94 Mt
  (avoided 76.98), €367.4/tCO₂, prim-2050 104,529 → 83,891 GWh,
  €1.370/kWh; record_source "certificate (parallel merge)".
- **pl10_co2half** (parallel merge, 10:25): **certified INFEASIBLE on the
  grid** — no feasible policy at any rate combination. The search was also
  infeasible → this is the EXPECTED CONFIRMATION under the amended stop
  rule, not a stop. Halving the carbon price removes the private incentive
  the milestones need at any subsidy level.
- **pl10_inclusive** (serial merge, canonical log, landed 2026-11-04
  11:02, first recorded now): certified grid optimum
  **€30,553.023M**, joint re-eval matched. ABOVE the search record (batch
  €27,176.3M, −11.1% vs certificate) → search stays the value of record.
  The large gap is the biggest grid-resolution effect so far — the
  continuous search exploits rates between the 5-pp grid points.

Figures: `make_pl10_figures.py` re-run in both modes after three small
script fixes required by the co2half certificate (a certified-infeasible
log previously still counted as "proof pending"): new `cert_infeasible()`
helper; `proof_pending()` now ends on ANY certificate (optimum or
infeasibility); co2half's row/annotation now reads "certified infeasible" /
"not feasible (proven)" instead of carrying the ‡ proof-running mark.
Verified in both output dirs: elec_p20 row = 28,282.0 "certified (parallel
merge)" with the certificate's own KPIs (CERT_KPIS path); co2half
"certified infeasible", proof_pending False; elec_m20/inclusive keep their
search values with certificates alongside; **sav4666 is now the only ‡
row**. Still running: sav4666 follow-on (watcher bx4bo93t1/b2xdqt0cj),
local proof around the standard design (deadline 2026-11-06 12:00, log
still empty). Nothing committed (commits on explicit order).

## 2030-repair task AUTHORIZED + hypotheses (2026-11-04, ~02:30 — BEFORE runs)

User authorization (overnight, verbatim scope): (1) build a 2030-repaired
variant of the €8,302.6M design — raise the **cheapest-to-raise** subsidy
rate just enough to meet 2030 under plain pl10 — and evaluate it; then
**warm-start the pl10 search from it** and report the new pl10 bound.
(2) If the new bound is below €10,397.4M, **re-centre the pending local
proof** on the new best pl10 design before it starts (gate not yet passed —
confirmed: local_proof_driver.log still empty, driver waiting on
inclusive + sav4666 certificates). (3) **Hold interpretation of the w and
permanent-rent results** until the new pl10 bound is in.

Plan: probe each candidate single-rate raise (+2 pp) with the fixed-σ
evaluator, measure Δ(2030 margin)/Δ(spending), pick the cheapest €/margin
candidate, binary-search the minimal raise to 2030 margin ≥ −0.1, full
evaluation of the repaired design, then one warm start
(`P4_SIGMA_START`, tag `ms_pl10repair`) in the multistart worktree.

Re-centring hook implemented (item 2, race-free): worktree-parallel-merge
`enumerate_local.jl` now takes its center from
`out/scenarios/<scn>/subsidies_local_center.csv` (main tree) IF that file
exists, else from `subsidies.csv` as before (parse-checked; the file does
not exist yet, so behaviour is unchanged until the condition fires). The
driver script itself is running and was NOT touched.

Hypotheses (recorded before any probe):
- **H-repair-1**: the cheapest repair is a raise of **rich env deep**
  (10.32%) or a poor envelope rate — gap is tiny (2030 excess 0.023
  kWh/m² primary beyond the 0.1 tolerance; period-1 mean envelope y
  0.138 vs cap 0.239, so headroom exists). Expected repaired spending
  €8.35–8.6bn (Δ ≈ €50–300M above 8,302.6).
- **H-repair-2**: the pl10 warm start from the repaired design converges
  **below €9.0bn** — far below the 10,397.4 search record and the
  11,586.8 certificate → record flips to the new search value and the
  local proof needs re-centring (authorized item 2).

## fig3: pl10_rule_pl row DROPPED (2026-11-04, ~16:30, user order)

`make_pl10_figures.py` fig3 loop now skips pl10_rule_pl (identical to
the standard run — rule_PL IS the standard's rent rule, so the row
duplicated the €10,397.4M bar). 39 scenario rows remain; "Gross rule"
(rule_pl_gross) stays; fig6's rent-rule panel still shows rule_pl (the
order named fig3 only). Both figure sets re-run clean.

## Figure scenario names of record + fig3 additions (2026-11-04, ~16:15,
## user order)

`make_pl10_figures.py`: NAME dict rewritten to the user's exact paper
names (both figure modes; e.g. "Standard run", "Household discount
12%/8%", "Fossil-boiler ban", "Older typology savings",
"Behaviour-adjusted demand", "No rent increase", "Rent cap", "Permanent
rent increase", "Gross rule", "Public landlord w = 0.5 / 1",
"Cost-neutral rule"); pl10_rule_pl is not on the user's list and keeps
"Polish rent rule (Art. 8a)". Fig6 RLAB updated to the same rule names.
The two J() discount renames removed (a substring rule on "Household
discount 12%" would corrupt the new 12%/8% name); all other journal
renames untouched. Fig3 now also shows the five new scenarios
("Envelope limits ×0.8" infeasible / "×1.2" 5,358.8; "Straight-line" /
"Softer trajectory" 8,926.0; "Invert price level" infeasible;
"Firewood factor 0.2" 8,997.5 was already a row). Both figure sets
re-run clean (fig1–6 + design table + summary; 40 scenario rows in
fig3_scenario_spending_data.csv). Also answered read-only: rule_cap3
implements €3 per m² floor area per YEAR (`rent_increase_cap_per_m2=3.0`,
model line 1118, applied `rent_inc[a,ti] ≤ cap × fa_a[a]`, line 2066) —
NOT 3% of dwelling value (Art. 8a(4)'s 3%-of-replacement-value is a
justification threshold, not a ceiling; comment lines 167–173).

## invertprices rich-cap diagnostic LANDED (2026-11-04, ~15:50) —
## 2030 STILL unreachable (−3.05); expectation CONFIRMED on all four
## counts; landlords are the only remaining lever

Log of record `results/cert_logs/diag_invertprices_richcap.log`
(script scratchpad `diag_richcap_invert.jl`). Transparency note: the
FIRST run was an artifact — `enforce_ordering!` CLAMPS σ to σ_caps
(model ~line 2922), so the "raised" caps were silently clamped back and
run B reproduced run A bit-identically (caught via the unchanged
spending); fixed by setting the rich rates directly (ordering holds at
1.0 by construction) and re-run.

Results (fixed-σ evaluations, pl10_invertprices):
- **A, max σ at standard caps** (€35.9bn): 2030 missed by 11.49.
- **B, rich owner caps → 100%** (five instruments 4/5/6/9/10, were
  40/40/50/40/40): 2030 improves 233.61 → **225.17, still MISSED by
  3.05**; spending €90.8bn (diagnostic only — dominated by
  inframarginal transfers at 100% rates); 2035/2040/2050 all OK with
  huge slack (+31.0/+26.6/+48.4).
- **Period-1 (2020–30) classification** (env capacity cap 23.9%,
  hvac 33.5%): owner_poor env at the 23.9% CAP in 6/6 archetypes in
  BOTH runs → **capacity-bound**. owner_rich at standard caps: env
  12.5% mean, 4/6 at cap → **partly subsidy-cap-bound**; at 100% caps
  env jumps to the cap 6/6 → becomes capacity-bound. landlord_public:
  env 12.0%, hvac 6.4%, far below caps with its σ already at 100% in
  BOTH runs → **willingness-bound (rent-rule economics)**, unchanged.
  landlord_private: **0.0% — nothing pre-2030 at 100% subsidy**;
  recovery-levy economics, not caps.
- **Reading**: once both owner groups sit at the envelope capacity
  ceiling, NO owner-subsidy design can reach 2030 under Invert prices
  (remaining gap 3.05); the only untouched pre-2030 lever is landlord
  renovation (the w>0 / rule_perm institutional channel from the
  €2.1bn finding). Not tested here — would need a scenario run, not an
  evaluation.

**Scoring vs the registered expectation**: all four counts CONFIRMED
(2030 stays unreachable with a smaller negative margin; poor owners
capacity-bound; rich owners partly subsidy-cap-bound; landlords
willingness-bound).

## invertprices rich-cap diagnostic ORDERED + expectation (2026-11-04,
## ~15:40 — BEFORE the evaluation; user order)

Evaluation only: max-σ design with the HIGH-INCOME OWNER caps raised to
100% on all five of their instruments (standard caps: env 40/40/50,
hvac 40/40; poor and landlord caps unchanged at 70/85/100, 100/100 and
100/100). Question: is 2030 then reachable, and which groups' pre-2030
renovation is capacity-limited vs subsidy-cap-limited. **Expectation
(registered)**: 2030 remains unreachable — the 11.5 kWh/m² miss is too
large for the rich owners' remaining headroom alone (poor owners and
landlords already at 100% caps and the big poor groups presumably at
the capacity ceiling); the margin shrinks but stays negative. Groups:
poor owners capacity-bound, rich owners partly subsidy-cap-bound,
landlords willingness-bound (caps already 100%).

## pl10_invertprices LANDED (2026-11-04, ~14:30) — NO FEASIBLE DESIGN;
## 2030 unreachable by 11.5 at MAX subsidies; H-inv-1/2/3 all REFUTED

Both warm starts (search + cert seeds) found NO feasible σ (logs
worktree `results/paperwave_logs/pl10_invertprices__ms_*.log`; CCG 88
evals each, upward-σ adjustment failed). Max-σ diagnostic
(`diag_maxsigma_wt.jl`): at MAXIMUM subsidies (spend €35.9bn) the stock
reaches **233.61 at 2030 vs target 222.12 — missed by 11.5** kWh/(m²·yr)
(worst miss measured; envcap_m20's was 2.8); 2035 (199.5), 2040 (155.1)
and 2050 (78.7) all reachable. σ=0 eval: cumulative 2020–2050 CO₂
**669.2 Mt** (standard σ=0: 630.2), path E_prim 258.7/224.4/183.3/
106.9/50.9 — σ=0 under Invert prices MEETS the 2050 target (106.9 ≤
108.4) and fails 2030/2035/2040. Summary row appended (best none).

**Mechanism of record**: pre-2030 the model has NO carbon price (ETS2
first-period value 0; first non-zero 70 €/t from 2030), so the only
pre-2030 renovation incentive is fuel-cost savings; the Invert price
level cuts every carrier 29–51% below the standard, and the −16%-by-
2030 milestone becomes unreachable at ANY subsidy level. The 2030
feasibility of the ENTIRE pl10 family therefore rests on the assumed
PRICE LEVEL (and on ETS2's zero pre-2030 representation) — together
with envcap_m20 this is the second independent lever whose −20–40%
variation kills 2030 outright. KEY SENSITIVITY candidate; price year /
VAT of the Invert file remain the open %% CHECK (PROVENANCE).

**Scoring**: **H-inv-1 REFUTED** (expected €12–16bn; got infeasible —
direction right, magnitude beyond the range in the strongest sense);
**H-inv-2 REFUTED** (no design exists); **H-inv-3 REFUTED as posed**
(2030 is the ONLY failing milestone; 2040 reachable); **H-inv-4 half-
CONFIRMED** (σ=0 emissions rise 630.2 → 669.2 Mt; avoided-CO₂ and €/t
not computable — no record); **H-inv-5 directionally CONFIRMED on the
max-σ diagnostic** (SFH_wpb_poor 2050 average cost share 10.3% vs the
standard record's 20.2%; cheaper energy dominates), formally unscored —
no record design to compare.

## pl10_invertprices DEFINED + hypotheses (2026-11-04, ~15:00 — BEFORE
## runs; user order)

User order: replace ALL carrier prices with Invert's Poland "const"
values (source file named as `data/616_pol__const__energy_price.csv`;
**the file is NOT in the repo or scratchpad at definition time** —
values transcribed verbatim from the order; price year and VAT
treatment unknown, to be confirmed by the Invert team; recorded in
PROVENANCE). €/MWh → €/kWh: elec 0.16655, gas 0.04745, coal 0.03528,
wood (firewood/log) 0.02907, oil 0.07524, dh 0.05687. Constant over
time like the standard; fuel mixes, seasonal efficiencies and the ETS2
carbon price unchanged; gas on the same calorific basis (Invert per
HHV = Eurostat GCV, per the order — no conversion). Search only, warm
starts from the two pl10 designs, nice 19; proof chain untouched.
Every Invert price is BELOW the standard's (elec −37%, gas −33%, coal
−41%, wood −44%, oil −29%, DH −51%); relative prices shift toward DH
(dh/gas 1.20 vs 1.63) and slightly toward electricity.

**Hypotheses (BEFORE the runs):**
- **H-inv-1**: spending RISES above €10,397.4M, expected **€12–16bn**:
  cheaper energy weakens the private renovation incentive everywhere
  (the milestones are physical, so the incentive channel dominates).
- **H-inv-2**: the design keeps the capacity-driven envelope corner
  (poor env rates ≈ the 41–44% family) and the HVAC side needs MORE
  subsidy: rich HP above 21.6% and/or positive DH rates.
- **H-inv-3**: binding milestones stay 2030 and 2040.
- **H-inv-4**: σ=0 emissions rise vs the standard's 630.2 Mt (cheaper
  fossil fuel → less natural renovation), avoided CO₂ larger than
  37.0 Mt, €/tCO₂ in the €250–450 range.
- **H-inv-5**: low-income 2050 cost shares FALL vs the standard
  (cheaper energy bills dominate the unchanged incomes).

## Outcome measures LANDED (2026-11-04, ~14:00) — H-out-1 half-refuted,
## H-out-2 half-refuted; NEGATIVE 2050 saving under relaxed constraints

31 scenarios evaluated (value-of-record σ + σ=0 each; one model load per
scenario, nice 19; script scratchpad `outcome_measures.jl`, driver logs
worktree `results/paperwave_logs/outcome_*.log`). Outputs:
`results/outcome_measures_summary.csv`,
`results/outcome_measures_periods.csv` (incl. the 2060 period;
cumulative numbers cut at 2050 per the order). Every record spending
reproduced to the reported digit. Report section appended to
`results/paper/P4_open_questions_report.md`.

Headlines: pl10 avoids 37.0 Mt CO₂ cumulative 2020–2050 (630.2 → 593.2)
at €281/t and €2.17 per annual kWh primary saved at 2050 (4.80 TWh/yr);
spending splits deep env 69% / medium env 18% / HP 13%, poor owners
€3.79bn vs rich €6.60bn, landlords €0; nominal per period 3.6/2.4/2.6/
6.0 €bn (2030/35/40/50; nominal total 14.6 vs discounted 10.4). σ=0 is
EPBD-infeasible everywhere except pl10_kprb (record €0). Range: €138/t
(elec_m20) … €1,078/t (peffrozen); hpcost_hi avoids most (98.4 Mt,
€149/t — dirtiest counterfactual); w>0/rule_perm family €180/t.

**FINDING — timing, not end state**: traj_linear/traj_soft and
envcap_p20 end 2050 with MORE primary energy than σ=0 (79.5 vs 76.1
TWh/yr; free-optimum E2050 97.3 vs record 101.6): under relaxed
constraints the programme buys milestone timing (cumulative CO₂ still
−9.7 Mt), while capacity caps make early subsidised envelope displace
later own-initiative renovation; €/kWh-2050 undefined (negative
saving) for those three records. Caveat of record: each scenario's
avoided-CO₂ uses its OWN σ=0 baseline — cross-scenario €/t is not a
like-for-like programme comparison.

**Scoring**: **H-out-1 half-refuted** — the σ=0-infeasibility half
CONFIRMED (kprb the known exception), the magnitude half REFUTED:
avoided CO₂ is 1.5–14.3% of σ=0 cumulative across scenarios (pl10
5.9%), never in the predicted 15–30% band. **H-out-2 half-refuted** —
pl10 (€281/t) is WORSE per tonne than ban2040 (€200/t), not better
(the ban avoids more, 52.9 Mt); the elec_m20 half held (€138/t beats
pl10).

## Paper-analysis wave LANDED: trajectory + envelope capacity (2026-11-04,
## ~14:00) — TWO MAJOR FINDINGS, three hypotheses refuted

All 8 warm-started searches done (13:25–13:46, nice 19, sequential; logs
`worktree results/paperwave_logs/`). Values of record (search bounds, no
certificates ordered; summary CSV rows appended):

| scenario | ms_pl10search | ms_pl10cert | record |
|---|---|---|---|
| pl10_traj_linear | **8,926.0** | 9,084.2 | €8,926.0M |
| pl10_traj_soft | **8,926.0** | 9,084.2 | €8,926.0M |
| pl10_envcap_m20 | infeasible | infeasible | none — NO feasible design found |
| pl10_envcap_p20 | **5,358.8** | 5,367.9 | €5,358.8M |

Printed targets confirm the definitions: traj_linear 2040→177.2 (2050
108.4 unchanged); traj_soft 2040→171.9, 2050→119.0.

**FINDING 1 — the 2040 milestone costs ≈ €1.47bn, all of it the
high-income heat-pump subsidy.** Both relaxed trajectories converge to
the SAME design and value: the pl10 batch design with the rich HP rate
cut 21.56% → 0.34% (rich deep 16.54% → 15.00%; everything else
identical). €10,397.4M − €8,926.0M = €1,471M. KPIs: equity 42.5%, WPB
77.6%, E2050 101.6. That traj_soft (further relaxations at 2040 AND
2050) buys €0 beyond traj_linear says: once 2040 moves from −40% to
≈−33%, it stops binding, and 2050 already has slack at the optimum
(E2050 101.6 ≤ 108.4 even on the standard target; pl10's record sits at
91.1). The binding milestones of the standard trajectory are 2030 and
2040; 2035 and 2050 are free.

**FINDING 2 — the 2030 milestone stands or falls with envelope
capacity; ±20% is the difference between infeasible and −48% cost.**
- `envcap_m20` (×0.8): no feasible σ from either seed, and the max-σ
  diagnostic (`diag_maxsigma_wt.jl`) shows WHY: at MAXIMUM subsidies the
  stock reaches 224.95 at 2030 vs target 222.12 (missed by 2.8); 2035/
  2040/2050 are all reachable. With env capacity 2.16%/yr before 2030,
  −16% by 2030 is PHYSICALLY unreachable — no subsidy design exists.
  (Search + max-σ evidence, NOT a certified infeasibility.)
- `envcap_p20` (×1.2): record **€5,358.8M, −48.5% vs pl10** — the
  largest single-lever effect measured in the whole pl10 family. The
  crash-programme rates collapse (poor env med/deep 41.3/41.3% →
  13.2/24.5%, rich HP 21.6% → 1.4%); equity 33.9% (near the 30% floor),
  WPB 79.5%, E2050 92.6.
- Together with the repair findings (poor-env rates at the 44% corner,
  2030 margin −0.123 blocking the cheap family): **the binding
  constraint behind pl10's €10.4bn is renovation-industry capacity
  before 2030, not household willingness** — subsidy money is buying
  throughput at the capacity ceiling. KPRB's 2.7%/yr pre-2030 envelope
  rate sits almost exactly at the knife's edge (×0.8 infeasible, ×1.0
  = €10.4bn, ×1.2 = €5.4bn).

**Hypothesis scoring (registered ~13:30):**
- **H-trl-1 REFUTED in magnitude** (direction right): expected
  €9.4–10.4bn, got €8,926.0M — below the range; it IS below pl10 and
  above the 8,302.6 family as predicted.
- **H-trl-2 CONFIRMED**: the design change is (almost) purely HVAC —
  rich HP 21.56→0.34%; poor envelope rates bit-identical to the seed.
- **H-trs-1 REFUTED in direction**: traj_soft does NOT fall further
  than traj_linear — identical €8,926.0M (mechanism above); the value
  lands inside the predicted €8.5–9.8bn band.
- **H-env-1 REFUTED**: expected €11–14bn with feasibility surviving;
  feasibility does NOT survive (2030 unreachable at max σ).
- **H-env-2 REFUTED (badly)**: expected a modest fall to €9.5–10.4bn;
  got −48.5%. The registered reasoning ("the envelope cap was not the
  binding constraint") was wrong — it is THE binding constraint.
- H-out-1/H-out-2 (outcome measures) remain open; the pl10 test row
  already points to H-out-1 refutation (avoided CO₂ 5.0% of σ=0
  cumulative vs expected 15–30%) — scored when the full table lands.

Interpretation caveat of record: all four values are CCG search bounds;
the pl10 family's certificates showed search bounds can sit on local
optima in both directions. envcap_m20's infeasibility is a search +
max-σ verdict, not a grid certificate.

## Paper-analysis wave DEFINED + hypotheses (2026-11-04, ~13:30 —
## BEFORE runs; user order)

User order (pasted ~13:20): four additional analyses for the paper,
**search only** (warm starts from the two pl10 designs: `ms_pl10search`
seed = the €10,397.4M batch design, `ms_pl10cert` seed = the €11,586.8M
certified design), at **low priority** (nice 19, sequential) next to the
proof chain. No certificates ordered for these.

**(1) Trajectory sensitivity — two new scenarios** (multistart worktree
model only, pure `merge(base10, …)` on the existing `traj_reductions`
key; main tree untouched while the proof chain runs):
- `pl10_traj_linear`: 2030/2035 as the standard (−16 %/−20 % of the
  model's own 2020 primary 264.4); 2040 and 2050 on the straight line
  (in calendar years) from the 2035 target to −59 % in 2050. Line from
  (2035, 0.80·B) to (2050, 0.41·B) evaluated at 2040 gives 0.80 −
  (5/15)·0.39 = 0.67·B exactly → `traj_reductions=(0.16, 0.20, 0.33,
  0.59)`. **New 2040 target ≈ 0.67 × 264.4 = 177.1** kWh/(m²·yr)
  (exact value from the run print; standard was 158.7, i.e. the linear
  trajectory is LESS demanding at 2040). 2050 unchanged.
- `pl10_traj_soft`: `traj_reductions=(0.16, 0.20, 0.35, 0.55)` → 2040
  ≈ 171.9, 2050 ≈ 119.0 (standard 108.4). Both 2040 and 2050 relaxed.

**(2) Envelope capacity — two new scenarios**: the yearly envelope
adoption limits (`env_rate_path`, KPRB staging 2.7/3.2/3.6/3.9 %/yr)
scaled ×0.8 and ×1.2. Interpretation recorded BEFORE the runs: the
heating limit stays 4 %/yr, and the JOINT cap is recomputed by the
standing user-approved rule joint = env + 0.4×hvac (so the joint cap
moves with the envelope limit; the alternative — freezing the joint cap
— would let hvac crowd out the extra envelope room in _p20 and would
NOT implement "envelope limits ×1.2").
- `pl10_envcap_m20`: env (0.0216, 0.0256, 0.0288, 0.0312), joint
  (0.0376, 0.0416, 0.0448, 0.0472).
- `pl10_envcap_p20`: env (0.0324, 0.0384, 0.0432, 0.0468), joint
  (0.0484, 0.0544, 0.0592, 0.0628).

**(3) Outcome measures** for every scenario's value of record (the
`best_*` columns of `pl10_multistart_summary.csv`, plus certificates
where they are the record): per-period and cumulative 2020–2050 CO₂
(fossil fraction only, the model's accounting), the same at σ = 0
(no-programme counterfactual; the follower is always well-defined at
σ = 0 — policy feasibility of σ = 0 is reported alongside, expected
infeasible on the EPBD trajectory everywhere); subsidy € per kWh
primary saved (2050, vs σ = 0) and per tCO₂ avoided (cumulative);
spending per period, per measure (env light/medium/deep, HP, DH) and
per group. Implementation: read-only eval script on `evaluate_σ` (one
model load per scenario, both σ's), low priority.

**(4) Design table**: σ of record per measure and group, side by side,
for pl10, noeed, ban2040, split (12/8 %), elec_m20, w>0 (w05; w10
reported if it differs), rule_perm, woodpef. From stored run dirs —
no new runs.

**Hypotheses (BEFORE the runs):**
- **H-trl-1** (`traj_linear`): spending falls below 10,397.4 but stays
  above the 8,302.6 family's level, expected **€9.4–10.4bn**: only the
  2040 milestone is relaxed (−40 % → −33 %), while 2030 — the milestone
  that makes the cheap family infeasible (margin −0.123) — is unchanged,
  so the 8,302.6 design stays infeasible here.
- **H-trl-2** (`traj_linear`): the record design's σ changes mainly in
  the HVAC rates (2040 was the HVAC-timing milestone in the repair
  probes), not in the envelope rates.
- **H-trs-1** (`traj_soft`): spending falls further than traj_linear,
  expected **€8.5–9.8bn** (2050 relaxed 108.4 → 119.0 cuts the deep /
  HVAC requirement), but the 2030-driven floor keeps it above the
  8,302.6 family.
- **H-env-1** (`envcap_m20`): spending RISES, expected **€11–14bn**,
  and 2030 becomes harder (envelope is the only lever that moved 2030
  in the repair probes); risk of infeasibility at the σ-caps is real
  but we expect feasibility to survive.
- **H-env-2** (`envcap_p20`): spending falls modestly, expected
  **€9.5–10.4bn**; the binding constraint at the record was not the
  envelope cap alone, so +20 % capacity buys less than −20 % costs.
- **H-out-1** (outcome measures): σ = 0 is EPBD-infeasible in every
  scenario; programme-vs-σ=0 cumulative CO₂ saving for pl10 lands in
  the **15–30 %** range of cumulative σ=0 emissions.
- **H-out-2**: cost-effectiveness of the pl10 record is better per
  tCO₂ than ban2040's and worse than elec_m20's (cheap records save
  less CO₂ in absolute terms is the risk; recorded as uncertain).

## Option A ARMED: serial merges yield to parallel certificates
## (2026-11-04, ~12:15, user order)

Detached guard (`optionA_kill_serial_on_cert.sh`, PID 105024, log
`cert_logs/optionA_guard.log`): when a parallel certificate lands in
`cert_pl10_{co2half,elec_p20}_hybrid_par.log`, it verifies the joint
re-evaluation (feasible AND spending matches the certified optimum; a
certified infeasibility needs no re-eval) and then kills THAT scenario's
serial merge (PID checked against the exact command line before kill; on
any re-eval mismatch it does NOT kill and alerts instead — stop
condition). Purpose: the orchestrator's "ALL PL10 PROOFS DONE" marker
waits on the serial merge processes; killing them after their parallel
certificates land lets sav4666 and then the local proof proceed days
earlier and inside the local-proof driver's 2026-11-06 12:00 deadline.

**Certificate provenance note (user-ordered):** the pl10_co2half and
pl10_elec_p20 certificates will come from the PARALLEL merge only — no
serial agreement check will be run for these two (their serial merges
are killed mid-run; projected serial completion was ~3–7 days out).
Justification: the parallel merge is the exact-reproduction
implementation verified against the serial merge on the full pl9 proof
(bitwise-identical certificate value and σ, 2026-11-03), and the same
interception pattern was already applied to elec_m20 and inclusive.

## Wood-PEF standard DECIDED — OPEN item CLOSED (2026-11-04, ~12:00)

User ruling: **pl10 keeps wi = 1.1 for the wood share as the standard.**
Reason of record: the recast EPBD requires TOTAL primary energy; the
Commission's default for biomass is 1.0 renewable + 0.2 non-renewable
≈ 1.2 total, and Poland is moving its certificate method to total
primary energy (draft regulation of May 2025). The 0.2 in the current
Polish method (2015 regulation, Dz.U. 2015 poz. 376, amended 2023)
counts only NON-RENEWABLE primary energy. `pl10_woodpef` stays as the
named sensitivity for that non-renewable convention (key sensitivity in
results and discussion per the ~11:40 ruling). The %% CHECK on the
standard choice is RESOLVED; no model or standard-run change.

## pl10_woodpef — user wording of record (2026-11-04, ~11:40)

User ruling on the result (verbatim intent, for results + discussion):
"Wood primary energy factor sensitivity (0.2 instead of 1.1 for the wood
share): 2020 baseline 195.3 instead of 264.4 kWh/(m²·yr) (targets 164.0 /
156.2 / 117.2 / 80.1); spending €9.0bn instead of €10.4bn (−13.5%,
search); design shifts to the cheaper family (low-income envelope
medium/deep ≈48%, high-income heat pumps ≈21%, landlords 0). Treat as a
KEY SENSITIVITY in results and discussion: the national primary energy
factor for biomass changes how demanding the EPBD trajectory is."
**OPEN (user-flagged, stays %% CHECK): whether the STANDARD run should
use 0.2** — depends on the Polish certificate method and on Invert's
factor. No change to the pl10 standard; pl10_woodpef remains the named
sensitivity.

## pl10_woodpef LANDED (2026-11-04, ~11:20) — scoring

- New baseline **195.3 kWh/m²** (was 264.4; mix-weighted fossil PEFs
  0.79 / 0.8736); targets 2030→164.0, 2035→156.2, 2040→117.2,
  2050→80.1.
- Warm starts: from pl10 search design €12,216.4M; from pl10 certified
  design **€8,997.5M = value of record** (ms_pl10cert; E2050 67.80 vs
  target 80.06, equity 52.0%, WPB 79.4%). Summary row appended.
- Best design: poor env light 0.7% / medium 47.55% / deep 47.55%, poor
  DH 0.43%; rich deep 10.60%, rich HP 20.66%, rich DH 1.34%; landlords
  0/0 — the 8,302.6 design family, now feasible at w=0 because the 2030
  milestone moved with the baseline.
- **Scoring: H-wood-1 REFUTED in magnitude** (baseline fell to 195.3,
  below the 230–250 band — wood share larger than assumed);
  **H-wood-2 REFUTED in direction**: spending FALLS €10,397.4 →
  €8,997.5M (−13.5%). The lower-absolute-targets channel dominates the
  lost-cheap-savings channel; concretely, the near-miss 2030 milestone
  that forces pl10's €2.1bn premium relaxes. **H-wood-3 mostly not
  confirmed**: no shift toward coal/HP conversions; rich DH rises
  0.39→1.34%, poor envelope stays the core.
- FINDING for the paper: the wood-PEF assumption is MATERIAL — moving
  wood from 1.1 to the biomass factor 0.2 changes the headline cost by
  −€1.4bn and reshapes the optimal design toward the w>0 family.
  Search bounds only (no woodpef certificate; none ordered).

## pl10_woodpef DEFINED + hypotheses (2026-11-04, ~11:00 — BEFORE runs)

Scenario per user order: `pl10_woodpef` = pl10 + `wood_pef = 0.2` — wood
enters the fossil-mix PEF with the biomass factor 0.2 (coal/gas/oil stay
1.1), applied to the BASELINE (pef_a override on fossil rows) and the
TRAJECTORY accounting (c_prim_hp/dh, pef_base_at); relative targets
recompute from the new baseline automatically; Invert WPB shares
untouched. Implemented in the MULTISTART worktree's model file only
(main tree untouched while the proof chain runs); default wood_pef = 1.1
keeps every other scenario bit-identical (constant-PEF code path), to be
confirmed by a pl10 load check before the runs. Runs: two warm starts
(seeds = pl10 search design, pl10 certified design), tags
ms_pl10search / ms_pl10cert, nice −19.

Hypotheses:
- **H-wood-1**: the 2020 baseline primary falls from 264.4 to roughly
  230–250 kWh/m² (wood is a large share of the Polish SFH fossil mix);
  all four milestone targets scale down proportionally (same relative
  reductions).
- **H-wood-2 (direction uncertain, recorded as such)**: spending moves
  UP relative to €10,397.4M. Mechanism: wood-heavy archetypes now carry
  little primary energy, so renovating them "buys" less trajectory
  margin; worse, for wood-heavy stock c_prim_hp = pef_fossil −
  remain_hp·pef_elec can turn NEGATIVE early on (a heat pump on the
  2030 grid RAISES primary energy vs a wood boiler), removing cheap
  levers. Counter-channel: the targets are lower in absolute terms for
  everyone. Expected €10.5–14bn; genuine uncertainty recorded.
- **H-wood-3**: the optimal design shifts subsidy weight away from the
  wood-heavy poor SFH envelope toward coal/gas archetypes and DH/HP
  conversions of coal stock.

## Parallel merges co2half + elec_p20 LAUNCHED (2026-11-04, ~10:50 —
## hypotheses BEFORE the runs)

Setup per user order: verified parallel merge (worktree-parallel-merge,
exact-reproduction mode) from the existing main-tree shard files
(symlinked, interceptor pattern), 12 threads each, nice −19, logs
`cert_pl10_{co2half,elec_p20}_hybrid_par.log` — the running serial
merges are NOT touched and keep their canonical log paths. First
finisher = certificate; if both finish they must agree exactly.

Progress-printing fix (print-only, arithmetic untouched, parse-checked):
worker-count-based progress lines added to `combine_parallel()` in the
worktree's enumerate_exact.jl. DIAGNOSIS of the silent inclusive merge:
its 60 s monitor task sleeps on a libuv timer; a non-yielding compute
task on the timer thread starves it, so no line was ever printed (the
merge itself is healthy at ~860 % CPU; the running process loaded the
old code at launch and is unaffected by the edit).

Hypotheses:
- **H-par-1**: both parallel merges reproduce their serial counterparts
  exactly (pl9-verified implementation); co2half comes back **CERTIFIED
  INFEASIBLE** (expected confirmation, not a stop), elec_p20 with a
  certificate; no agreement failure.
- **H-par-2**: the parallel merges finish BEFORE the serial ones
  (serial co2half at 27 h CPU and counting). Caveat recorded: co2half's
  infeasible grid gives the spend-pruning nothing to prune with, so
  both co2half merges grind the full cross product — the 12-thread run
  should still win on wall time.
- **H-par-3** (figure plumbing): cert_spending() must read the _par log
  as fallback — implemented alongside the launch.

## User decisions on the morning report (2026-11-04, ~10:30)

1. **Checkpoint commits AUTHORIZED** (explicit order): the five proposed
   commits — master gets summaries and logs only (no `out/enum_shards/`
   3.0 GB binaries, no `out/scenarios/` re-run churn); the multistart
   worktree branch commit INCLUDES the warm-start run directories.
   Merge plan unchanged (OPEN item 1): after the local proof → gates →
   commit.
2. **OPEN item 2 (paper %% STATUS lines + Table 7): CLOSED by user** —
   the paper is being rewritten elsewhere; no draft edits from here; the
   numbers stay available in `results/paper/P4_open_questions_report.md`
   and the morning report.
3. **Parallel merges ORDERED for co2half + elec_p20** from the existing
   shard files, ~12 threads each, low priority, progress printing,
   ALONGSIDE the running serial merges (do not kill them). First
   finisher is the certificate; if both finish they must agree exactly.
   Also: diagnose why the inclusive parallel merge prints no progress.
4. **pl10_woodpef sensitivity ORDERED**: wood PEF 0.2 (instead of 1.1)
   in the fossil-mix PEF, baseline AND trajectory; Invert WPB shares
   unchanged; targets stay relative to the new (lower) baseline. Search
   via warm starts from the two pl10 designs. Report spending, design,
   new baseline and targets.

## ms_pl10repair LANDED — pl10 record STANDS; w/rule_perm interpretation
## UNBLOCKED (2026-11-04, ~10:05)

**Warm-start result: NO improvement.** CCG from the repaired seed
CONVERGED in 52 s at exactly the seed value **€11,086.785M** — no
coordinate move improves it (every lowering of dr/sr re-breaks 2030/2040;
every lowering of poor env breaks other constraints; raises only add
transfers). **H-repair-2 REFUTED** (expected < €9.0bn). The pl10 value
of record **stays €10,397.4M (batch search)**; ms_pl10repair recorded in
pl10_multistart_summary.csv (new columns), best_source unchanged →
figures unchanged (no re-run needed).

**Authorization item 2: condition NOT met** (11,086.8 > 10,397.4) → the
local proof is NOT re-centred; the hook stays inert and the proof will
run around the standard €10,397.4M design as originally specified.

**Item 3 — interpretation of the w and permanent-rent results (the new
bound is in; hold lifted). Interpretation of record:**
The €2.1bn divide between pl10 (€10,397.4M) and w05/w10/rule_perm
(€8,302.6M, identical owner-side σ, landlord rates 0) is REAL and its
mechanism is **early landlord renovation closing the 2030 milestone**:
- Owners alone miss 2030 by 0.023 kWh/m² beyond tolerance (the 8,302.6
  design's only violation under plain pl10).
- Under w > 0 the public landlord internalizes tenant costs and
  renovates BEFORE 2030 at its own expense: same σ, public-tenant 2030
  cost €1,637 vs €1,919 under w=0; 2030 margin +0.368 vs −0.123
  (eval_paper_w10_search.log vs eval_cross_8302_at_pl10.log). Any
  positive w suffices → binary divide w=0 vs w>0, not a gradient.
- Under rule_perm the permanent rent recovery makes PRIVATE landlords
  renovate early instead: private-rental envelope 19.96% by 2030
  (pl10: private rental renovates only toward 2050); public 12% by 2030
  (uptake_by_group.csv, pl10_rule_perm__ms_pl10cert).
- On the subsidy side alone (w=0), repairing 2030 costs ≥ €11,086.8M
  (this entry + the two below): the discrete rich-owner flips are MORE
  expensive than the €10,397.4M standard design. Reading for the paper:
  **either rent-rule reform (permanent recovery) or a tenant-cost-aware
  public landlord substitutes for ≈ €2.1bn of subsidy spending** — the
  cheapest known designs under those institutions cost €8,302.6M vs
  €10,397.4M under the Polish status quo rule with w=0.
- Caveats: all three values are search bounds (heuristic), not
  certificates; pl10's certificate (€11,586.8M, proven on the rate
  list) is reported alongside per ruling (a); no certificates exist for
  w05/w10/rule_perm.

## 2030-repaired design BUILT + warm start LAUNCHED (2026-11-04, ~10:00)

**FINDING — the authorized single-rate repair is IMPOSSIBLE.** Full
single-rate ladders on the 8,302.6M design (logs repair_scan_*.log,
repair_fine_*.log, scratchpad; 45 evaluations):
- poor DH (hvac_upg) 10→90%: 2030 margin NEVER moves (−0.123 throughout;
  poor DH adoption stays ≈0 even at 90% — unlike the standard design,
  where poor env 40/50/60 leaves KPRB room; at 44.44×3 the envelope
  consumes the joint capacity).
- poor HP 10→50% and rich HP 30→90%: 2030 never moves (rich HP spending
  saturates at €10,595.7M from 40% up — pure transfer).
- rich env deep is the ONLY lever that flips 2030: threshold at
  **18.21%** (18.20% still −0.123; the flip is discrete, margin jumps to
  +0.217, spending jumps +€264M). Mechanism: same total period-1
  adoption, rich owners substitute deep for shallower envelope.
  Non-monotone further up (40% breaks 2030 again; ≥50% fixes milestones
  but VIOLATES the equity floor, share 13.2%).
- **BUT the dr flip breaks 2040** (margin +3.944 → −4.660): rich owners
  postpone HVAC past 2040 once they renovate deep early. No overall-
  feasible single-rate repair exists.

**Two-rate minimal repair (deviation from the single-rate instruction,
recorded openly; it preserves the authorization's intent — a feasible
2030-repaired seed near 8,302.6):** rich env deep 10.32→**18.21%** +
rich HP 20.41→**21.60%** (threshold between 21.5 and 21.6; restores 2040
to +0.110). Evaluated FEASIBLE overall: **€11,086.785M**, margins 2030
+0.142, 2035 +20.7, 2040 +0.110, 2050 +16.4, equity +6.79 pp, WPB
+23.6 pp. Log of record: `results/cert_logs/eval_repair2030_dr1821_sr216.log`
(single-rate best, infeasible at 2040: eval_repair2030_dr1821.log).

**Hypothesis scoring:** H-repair-1 REFUTED twice — (i) no smooth
response exists (thresholds only), (ii) expected repaired cost
€8.35–8.6bn was wildly off: the minimal feasible repair costs
**€11,086.8M, ABOVE the €10,397.4M record** (the 2030+2040 flips are
discrete and drag ~€2.8bn of inframarginal transfers to rich owners).
The repaired design is a SEED, not a record.

**Warm start launched** (authorization item 1): `ms_pl10repair` from
`data/sigma_start_pl10repair.csv`, multistart worktree, nice −19
(log worktree results/run_pl10_ms_pl10repair.log). H-repair-2 (new pl10
bound < €9.0bn) now looks unlikely given (i); scored when it lands.
Re-centring (item 2) stays conditional on the result: the local-proof
center hook (`subsidies_local_center.csv`, see entry below) is in place
and inert. Item 3 (w / permanent-rent interpretation) remains ON HOLD.

## 2030-repair probes LANDED (2026-11-04, ~09:40) — FINDING: flat response

All six +2 pp single-rate probes of the 8,302.6M design leave the adoption
path **byte-identical** to the base design (per-period mean y unchanged to
4 decimals) and the 2030 margin exactly at −0.123; spending rises by pure
inframarginal transfer (dp +€449M, dr +€390M, sr +€148M, sp +€6M, up +€0M).
EXCEPTION: rich env medium 0→2% (mr) makes 2030 WORSE (−6.773) while
CUTTING spending to €7,274.9M — adding a cheap subsidized medium option
lets rich owners substitute away from deep renovations.

**Reading (H-repair-1 partially REFUTED):** there is no smooth σ-response
at this design. Poor envelope is at the period-1 KPRB cap (raises cannot
add period-1 adoption); rich owners and HVAC sit at delay corners (the
known delay rationality: learning curves + rising CO2 + time-constant σ),
so the 2030 response is a THRESHOLD, not a gradient — the "headroom
exists" reading of mean y 0.138 < cap 0.239 was wrong (the headroom is on
unsubsidized archetypes that a small raise cannot flip). The standard pl10
design meets 2030 through the 90% poor-DH rate; the 8,302.6 design has
0.24% there. Next (within authorization): coarse single-rate ladders on
up/sr/dr/sp to find each flip threshold, then the cheapest just-feasible
repair (logs repair_scan_*.log, scratchpad).

## Certificates LANDED: pl10_split + pl10_elec_m20 (2026-11-04, ~02:15)

- **pl10_split**: certified grid optimum **€12,885.852M** (joint re-eval
  feasible, spending matches). Warm-start search best **€11,916.3M**
  (ms_pl10cert) is CHEAPER → per ruling (a) the **search stays the value
  of record**; certificate recorded alongside as proven optimum on the
  rate list. No KPI eval needed (certificate not the record).
- **pl10_elec_m20**: certified grid optimum **€5,655.706M** (joint
  re-eval feasible, matches). Search best **€5,493.8M** (ms_hpheavy)
  CHEAPER → search stays the record; certificate alongside.
- No stop condition: both re-evaluations feasible where the search was
  feasible. Both figure sets re-run (working + journal); summary rows
  carry `certified_grid_optimum_M` 12,885.9 / 5,655.7, `proof_pending`
  now False for both.
- Remaining proofs: co2half (serial, expected certified-infeasible =
  confirmation), elec_p20 (serial), inclusive (12-thread parallel merge
  running), sav4666 (follow-on), then the local proof.

## OPEN-item evaluations LANDED (2026-11-04, ~01:00) — scoring

- **(1) 8,302.6 design under plain pl10: INFEASIBLE, by a hair.**
  Spending €8,302.617M; ONLY the 2030 milestone fails — E_prim
  222.247 vs 222.124 → **−0.123, just 0.023 beyond the 0.1
  tolerance**; 2040 +3.94 slack, 2050 +19.9, equity +19.1 pp, WPB
  +24.5 pp (log cert_logs/eval_cross_8302_at_pl10.log).
  H-8302-cross CONFIRMED in verdict, NOT in magnitude (hypothesis
  said 2030 and/or 2040 clearly beyond tolerance; it is 2030 alone,
  marginally). FINDING: pl10's €10,397.4M bound is likely far from
  the continuous optimum — a design €2.1bn cheaper misses
  feasibility by 0.12% of the 2030 target. NEW OPEN (recommendation):
  tomorrow, warm-start pl10 from a 2030-repaired variant of the
  8,302.6 design (slightly more poor envelope in 2020–30); expected
  to pull the standard bound well below €10bn. Not run tonight.
  → **CLOSED 2026-11-04 ~10:05**: authorized and run; the expectation
  was WRONG (minimal feasible repair €11,086.8M, warm start does not
  improve; pl10 record stands). See "ms_pl10repair LANDED" entry.
- **(3) w05 warm start from the 8,302.6 design: CONVERGED at
  €8,302.6M** — identical value (design feasible under w=0.5 as
  well; E2050 88.32). H-w05-cheap REFUTED in detail (hypothesis said
  slightly above): the w=0.5 public landlord's voluntary renovation
  already covers the 2030 gap. Value of record for w05 updated
  (source ms_pl10cheap; improvement vs batch 447.2). REVISED w
  finding: the ordering is NOT a smooth w-gradient — the divide is
  **w = 0 (10,397.4) vs w > 0 (8,302.6 for both 0.5 and 1)**; the
  earlier w05-vs-w10 gap was search noise after all; what is real is
  that ANY tenant-cost internalization by the public landlord
  unlocks the cheaper owner design. Summary + both figure sets
  re-run; multistart summary gained ms_pl10cheap columns.

## OPEN items RESOLVED by user (2026-11-04, ~00:30) — three small
## evaluations authorised; HYPOTHESES recorded BEFORE the runs

User decisions: (1) cross-evaluate the €8,302.6M design (σ: poor env
44.4/44.4/44.4%, poor DH 0.24%, rich deep 10.3%, rich HP 20.4%, rich
DH 0.39%, landlords 0/0) under plain pl10; (2) EED wording fixed (used
verbatim in the fig6 note and below); (3) one extra w05 warm start
from the 8,302.6 design. Nothing else changes overnight.

- **H-8302-cross**: the design is INFEASIBLE under plain pl10 — in
  both source scenarios it relies on extra rental renovation (w=1
  voluntary public uptake beyond EED / permanent-levy private uptake)
  that pl10 lacks; expect 2030 and/or 2040 milestones violated beyond
  the 0.1 tolerance, all money rules satisfied. If FEASIBLE instead,
  pl10's own bound drops to €8,302.6M — a major finding.
- **H-w05-cheap**: from the 8,302.6 start, w05 lands between the
  w=1 value (8,302.6) and its current bound (8,749.8) — the w=0.5
  landlord renovates less than at w=1, so slightly above 8,302.6 or
  the start is infeasible and descent stays nearer 8,749.8.

**EED wording of record (user, 2026-11-04):** "The EED obligation
makes public landlords renovate 72% of their dwellings by 2050, which
they would not do otherwise, and lowers public tenants' costs. It
barely reduces state spending, so including the municipalities' own
spending (about €1.5bn), total public spending is about €1–1.5bn
higher."

## WARM-START SWEEP LANDED — 11 bounds improved, two value-of-record
## flips, EED finding REVERSED (2026-11-04, 00:10)

All 68 runs done (driver log pl10_warmstarts_driver.log; summary of
record results/pl10_multistart_summary.csv REBUILT with columns
ms_pl10search_*/ms_pl10cert_*; pre-sweep file kept as
pl10_multistart_summary.pre_warmstart_2026-11-04.csv). Figures + CSVs
re-run (both sets). Improvements (old → new best, source):

- pl10_noeed **16,281.6 → 10,862.5** (ms_pl10cert; −33%); BELOW the
  €11,586.8M certificate → value of record flips BACK to the search
  design (label "search", certificate alongside).
- pl10_ban2040 **13,440.8 → 10,604.2** (ms_pl10cert); below its
  €11,217.8M certificate → same flip. Ban vs standard on best bounds:
  +€207M (10,604.2 vs 10,397.4).
- pl10_w10 **9,996.5 → 8,302.6**; pl10_rule_perm **8,843.9 →
  8,302.6** — both descend (from the cert start) to the IDENTICAL
  owner-side σ (verified: subsidies.csv byte-equal; spending is
  owner-only since landlords 0; KPIs differ as the rental stock
  behaves differently). Mechanism reading: both scenarios gain extra
  rental renovation for free (permanent-levy incentive / w=1
  voluntary public renovation), which relaxes the trajectory enough
  for the same cheaper owner design; presumably infeasible under
  plain pl10 (its own warm starts stop at 10,397.4/10,862.5).
- pl10_split 15,825.5 → 11,916.3; pl10_priv16 11,950.3 → 10,786.5;
  pl10_hvac6 9,933.7 → 9,454.5; pl10_hpcost_lo 9,525.3 → 9,319.1;
  pl10_s20 10,949.0 → 10,862.5; pl10_rule_cap3 10,623.1 → 10,397.4
  (= the standard design: the 3 €/m² cap costs nothing at the
  optimum); pl10_pubpoor 10,621.6 → 10,397.4 (same).
- UNCHANGED: pl10 (cert-start descent only reaches 10,862.5),
  pl10_afford, s25–s40, rule_none/pl/gross, w05 (8,749.8 stands),
  kprb (0), elec_m20 (5,493.8), sav4666 (8,724.0), hpcost_hi,
  elec_p20 (29,617.5 — BOTH warm starts infeasible), inclusive
  (27,176.3 — both infeasible), peffrozen (both infeasible).
- Still infeasible everywhere: s10–s15, r12, co2half (both starts).

**FINDING — the EED panel message REVERSES.** Total public-sector
spending (state + public-landlord own, disc. 3%): EED on = 10.40
(search) + 1.52 = **11.92**; EED off = **10.86** (search) + 0. With
the new noeed bound the obligation no longer merely shifts cost — it
RAISES total public-sector spending by ≈ €1.06bn on best-known
bounds (and by 1.52bn on the certified-grid comparison, where both
states are 11.59). fig6_rent_rules_v2 panel c now renders this
automatically (EED-off tick relabelled "search" dynamically). The
paper text built on "total is not lower" needs strengthening to
"total is HIGHER with the obligation" — flagged for the user.

**FINDING — the w ordering is now monotone decreasing**: w = 0/0.5/1
→ 10,397.4 / 8,749.8 / 8,302.6. The earlier "search noise" verdict
(H-w) is superseded in part: the noise explained the old
non-monotone ordering, but the new bounds suggest a REAL w effect
(public landlord internalizing tenant costs renovates beyond EED,
relaxing the milestones). Not proof — all heuristic bounds.

**H-warm scoring**: (a) noeed dropped ✓ (via cert start; search start
infeasible, exactly as H-cross-1 predicted); (b) suspicious bounds:
predicted collapse NOT realized — elec_p20, inclusive, peffrozen
transfers all infeasible (their high bounds stand; proofs will
decide), priv16 ✓ dropped, hpcost_hi no; (c) "rules and w change
little" WRONG for rule_perm and w10 (−€541M / −€1,694M) — recorded;
(d) infeasible set stayed infeasible ✓.

**OPEN (user decision, recommendation attached):**
1. Cross-evaluate the €8,302.6M design under plain pl10 (one fixed-σ
   eval) to confirm it is infeasible there — RECOMMENDED (same
   pattern as the noeed cross-eval); not run tonight (outside the
   agreed KPI-eval exception).
2. Paper EED wording per the reversed finding — RECOMMENDED: "the
   obligation raises total public-sector spending by ≈ €1.1–1.5bn;
   it also shifts €1.5bn from the state budget to municipal
   landlords".
3. w05 has no improved bound; if the w story enters the paper,
   RECOMMENDED one more warm start of w05 from the 8,302.6 design
   (cheap) — not run tonight.

## OVERNIGHT standing instruction (2026-11-03, ~23:45, user order)

Unsupervised night shift: continue per the agreed rules WITHOUT
asking. Anything needing a user decision → recorded here as **OPEN**
with a recommendation, work continues on everything independent of it.
Constraints: NO new model runs (the running warm-start batch and the
pre-authorized proof chain — interceptor parallel merges, sav4666
follow-on, local-proof driver — continue as agreed), NO commits, NO
changes to the proof chain. Interpretation stated to the user: the
single fixed-σ KPI evaluation per newly landed certificate (ordered
2026-11-03 so summary rows describe the design they report) counts as
part of the agreed procedure, not a new model run; everything else
run-shaped waits. One consolidated report when the user returns.

## Journal figures: second small-fix round (2026-11-04, user order)

fig6 v2 panel c: ticks "EED on (search)" / "EED off (proven on the
list)" with wider bar spacing (no touching labels); segment values
10.40 / 1.52 / 11.59 printed inside the bars. ONE rent-rule name set
across fig3 + fig6 (paper wording): "Polish rule (Art. 8a)", "Polish
rule, gross", "Polish rule with cap of 3 €/m² per year", "Permanent
rent increase", "No rent increase". fig2 rental rows → "Public-rental
dwellings" / "Private-rental dwellings" (fig2-local mapping — a global
rule would have hit the fig3 scenario name "Private rental share
16%"). All journal-only; re-exported PDF + 1000-dpi PNG; checked
visually.

## Journal figure set REVISED per user fix list (2026-11-04)

All fixes journal-mode only (P4_JOURNAL conditionals; working set
byte-identical in content): (1) fig2/fig4 left labels fully visible
(wider margins; fig4 journal row labels now "Low-income public-/
private-rental tenants", two-line); (2) fig3 value labels get white
boxes where the dashed standard line crosses, x-axis extended so
"34.3" fits, relabels "Household discount rate 12% (low-income) / 8%
(high-income)" (wrapped), "Household discount rate 12%",
"Behaviour-adjusted demand"; (3) fig4 legend "After the cost-minimal
programme (group average)"; (4) fig6 panel c widened, legend moved
below, panel spacing up (1131* clear of panel b); NEW
**fig6_rent_rules_v2**: panel c = TOTAL public spending EED on/off,
stacked state (10.40 search / 11.59 proven on the list) + public
landlords' own spending (1.52 disc. / 0), totals 11.92 vs 11.59 — the
EED finding shown directly (obligation shifts cost to public
landlords; total public spending is NOT lower); (5) fig1 unit
"kWh/(m²·yr)"; (6) fig5 group names matched to fig2. Every figure
checked visually at final size. Re-export: vector PDF + 1000-dpi PNG,
190 mm, fonts ≥ 8 pt.

## pl10_ban2040 CERTIFICATE + cross-evaluation RESULTS + journal
## figures (2026-11-03/04 night)

**pl10_ban2040 CERTIFIED: €11,217.794M** (serial merge, 59,814.7 s,
7 improvements; joint re-evaluation feasible at the same value → no
stop). σ: env poor 30/50/60, rich 0/0/10, HP poor 0, **DH poor only
5%** (vs 90% in the pl10 certificate — the ban forces boiler
replacement anyway, so the state need not buy the switch), HP rich
25%, DH rich 0, landlords 0/0. **BELOW the search bound €13,440.8M by
16.5%** → value of record (both restarts were infeasible). Certified
KPIs (eval_cross_cert_at_ban2040.log): E2050 83.65, equity 58.97%,
WPB 78.56%; binding 2030 (+0.354). FINDING (replaces the search-bound
reading "ban costs ~€3bn"): like-for-like on the hybrid grid the ban
**SAVES €369M** (11,217.8 vs pl10's 11,586.8); on best-known values
(mixed: certified vs continuous search) it still shows +€820M vs
€10,397.4M. The earlier +€3bn was largely a noeed/ban2040 search
failure, as with noeed.

**Cross-evaluations (hypothesis scoring):**
- **H-cross-1 CONFIRMED**: the pl10 search design is INFEASIBLE under
  pl10_noeed — 2030 margin −0.455 and 2040 −1.270 (beyond the 0.1
  tolerance); equity/WPB/2050 fine (log
  eval_cross_search_at_noeed.log). EED therefore has REAL value in
  continuous σ-space (the €10.4bn design needs the EED renovations at
  the 2030/2040 milestones), even though its value on the hybrid grid
  is €0 (identical certificates).
- **H-cross-2 CONFIRMED**: the certified grid design is feasible under
  both: pl10 — E2050 87.02, equity 61.34%, WPB 78.99%, margins 2030
  +0.354 / 2040 +4.962; noeed — E2050 89.10, equity 61.34%, WPB
  79.94%, margins 2030 −0.033 (inside tolerance) / 2040 +3.612;
  public-rental uptake 0.720 (pl10, EED) vs 0.000 (noeed); public
  landlord own investment ≈ €2.9bn nominal / €1.8bn disc. (pl10) vs €0
  (noeed); spending €11,586.838M in both (logs
  eval_cross_cert_at_{pl10,noeed}.log).
- NEW mechanism: `results/cert_design_kpis.csv` + make_pl10_figures.py
  now substitute the CERTIFIED design's re-evaluated KPIs into summary
  rows whose value of record is a certificate (currently pl10_noeed,
  pl10_ban2040) — each row describes the design it reports.

**Journal figures (order D)**: make_pl10_figures.py gained P4_JOURNAL=1
mode → results/figures_pl10_journal/ (working files untouched): no
in-figure titles/footnotes, journal wording via J() (owner-occupiers,
No rent increase, Permanent rent increase, Public landlord weight on
tenants' costs w=0.5/1, Cost-minimal design, Public-/Private-rental
tenants, "proven on the list of subsidy rates"), Fig 3 standard bar
annotated "search; proven on the list: 11.6", certified bars "(proven
on the list)", "no feasible design" wording, * and ‡ kept; vector PDF
+ 1000-dpi PNG, 190 mm width, fonts ≥ 8 pt; layouts visually checked.

## Ruling on noeed: cross-evaluations + WARM STARTS ordered — HYPOTHESES
## recorded BEFORE the runs (2026-11-03, late night, user order)

Ordered: (1) pl10 search design evaluated under pl10_noeed (fixed σ);
(2) the certified grid design evaluated under BOTH pl10 and pl10_noeed
with real KPIs (E2050, equity, WPB, uptake per group, public-landlord
spending) so summary rows describe the design they report; (3) WARM
STARTS: every pl10-family search re-run from two additional starts —
the pl10 search design and the pl10 certified design (P4_SIGMA_START
mechanism, multistart worktree, tags ms_pl10search / ms_pl10cert),
best feasible kept per scenario; (4) figures re-run; NO commit before
the user sees the report.

**H-cross-1**: the pl10 search design is INFEASIBLE under pl10_noeed.
Reasoning: it is tolerance-tight at 2030 (−0.068) and 2040 (+0.080)
under pl10 WITH the EED-driven public renovation; removing the public
stock's renovation (no obligation, no landlord subsidy, w=0) raises
stock-average E_prim by more than the 0.1 tolerance at those
milestones. If CONFIRMED: EED has real value in continuous σ-space
(the pl10 design does not transfer), even though its value on the
hybrid grid is €0 (identical certificates). If REFUTED (feasible):
noeed's warm start from this design immediately yields ≤ €10,397.4M.
**H-cross-2**: the certified design is feasible under both (already
certified); under pl10_noeed its E2050 is slightly HIGHER (public
stock unrenovated) and public-landlord own investment ≈ 0 (vs ≈
€2–3bn under pl10's EED); equity above pl10-search's 36.5% (heavier
poor envelope rates); spending €11,586.838M in both.
**H-warm**: (a) noeed drops to €11,586.8M (cert start reproduces the
certificate; search start per H-cross-1); (b) the suspicious bounds
collapse toward ≈ €10.4bn where the pl10 design transfers: elec_p20
(€29.6bn — expected to be a search failure like sav4666's +31%,
commit d28f263), inclusive (€27.2bn; different stock, start still a
valid σ), priv16, hpcost_hi, sav4666, peffrozen (unclear — PEF physics
differ); (c) rule scenarios and w05/w10 already below €10.4bn change
little; (d) the infeasible set (s10–s40, r12, co2half) stays
infeasible (max-σ evidence); any warm start finding a feasible point
there would be a major finding (and for co2half would contradict the
expected certified infeasibility — stop and report per the amended
rule). Where a warm start IMPROVES a bound, the earlier batch value is
recorded as a search failure, not tuned away.

## pl10_noeed CERTIFICATE LANDED — identical to pl10's, BELOW the noeed
## search bound by 28.8% (2026-11-03, 22:19)

Certificate (`cert_pl10_noeed_hybrid.log`, serial merge, 2.067e11
combinations in 73,903.1 s): **CERTIFIED GRID OPTIMUM pl10_noeed =
€11,586.838M** — the SAME value and the SAME σ as the pl10 grid
certificate (env poor 40/50/60, rich 0/0/10, HP poor 0, district-heat
poor 90%, HP rich 25%, DH rich 5%, landlords 0/0). Joint re-evaluation:
feasible=true at the same value → no stop condition (amended rule).

Value of record (ruling (a)): the certificate — it is **BELOW the
search bound €16,281.6M by €4,694.7M (−28.8%)** (batch, both restarts
infeasible). Label "certified (serial merge)"; figures re-run — noeed
row now `11586.8, source certificate`, pl10 row unchanged (search
10397.4 ° + certificate alongside).

**Why identical to pl10 (recorded reading):** the owner-side follower
problems do not see the EED lever, so the poor/rich response tables are
identical between pl10 and pl10_noeed; both grid optima set landlord
rates 0, so spending is owner-only and the same σ costs the same. EED
only changes whether the PUBLIC rental stock renovates (obligation),
which affects feasibility through the trajectory — and the pl10-optimal
design evidently stays trajectory-feasible even WITHOUT the EED
renovations. Consequences: (i) on the hybrid grid, the EED obligation
is worth €0 to the leader at the grid optimum (the €16.3bn search
bound for noeed was a poor local optimum — the heuristic compensated
the lost EED renovations expensively; heuristic noise, consistent with
the H-w verdict); (ii) the earlier search-bound claim "EED saves
€5.9bn" (16.3 vs 10.4) does NOT survive certification — on the grid
the two scenarios' certified optima coincide; any true EED effect
lives between the continuous designs, where pl10's search found
€10,397.4M and noeed's search found nothing better than €16.3bn
(one-sided evidence only). CAVEAT recorded: the summary row's
E2050/equity/wpb for noeed still describe the SEARCH design's outputs
(92.42/0.526/0.792), not the certified design's KPIs under noeed —
only the spending and label follow the certificate.

## Paper questions — RESULTS and hypothesis scoring (2026-11-03, night)

13 fixed-σ evaluations ran clean (logs of record:
`results/cert_logs/eval_paper_*.log`; scratchpad script
`eval_design_variants.jl`). Scoring against the pre-registered
hypotheses below:

- **H-max CONFIRMED, sharpened.** All max-σ designs INFEASIBLE.
  pl10_r12: ONLY the 2040 milestone violated, by **−0.221 kWh/m²**
  (2030 now OK +0.81; spending €37.8bn) — near-feasible at max σ.
  pl10_co2half: ONLY 2040, by **−3.66** (2050 just OK +0.87; €38.7bn).
  pl10_s10–s15: trajectory fine everywhere (+5.3 at 2030, +13.2 at
  2040); they fail ONLY the enforced income-share check in the final
  period — violating poor-household share 34.4% (s10) → 32.2% (s15);
  violators at s15: SFH_wpb_poor owners (1460.9 vs limit 1445.2 —
  €16/yr over) and the poor+rich private-rental DH WPB tenants
  (1868.8 vs 1445.2, rent-increase-driven). Max-σ spending €44.4bn.
- **H-mono CONFIRMED (probe monotone; no proof claimed).** r12 at
  caps/2 is worse at EVERY milestone than at caps (2030 −8.31 vs
  +0.81; 2040 −13.26 vs −0.22) — no higher-subsidy-reduces-adoption
  effect observed. Structural caveat stands: follower adoption is an
  argmin, monotonicity is NOT a theorem, so max-σ infeasibility is
  strong EVIDENCE, not a certificate (co2half's exact verdict comes
  from the running enumeration; r12/s* have no proof queued).
- **H-gross CONFIRMED.** pl10_rule_pl_gross at the pl10 search design
  with both landlord rates 10/20/30%: spending €10,620.1M / €10,858.4M
  / €11,203.3M (+223/+461/+806M vs €10,397.4M at 0%); private-rental
  envelope uptake jumps 0.328 → 0.688 already at 10% (hvac 0 → 0.139
  at 20%, 0.336 at 30%; dwelling-weighted shares at 2050). Landlords
  DO accept gross-base grants at 10%; the optimum's 0% is pure
  cost-minimality (the trajectory is met more cheaply via owners),
  not landlord refusal — exactly the E2 mechanism.
- **H-w CONFIRMED.** Both stored designs re-evaluate FEASIBLE at
  exactly €8,749.838M (w05) / €9,996.463M (w10). Binding constraint
  for BOTH: the 2030 milestone (+0.18 / +0.37); 2040 has +4.3 / +4.5
  slack (pl10 w=0: +0.08 — tighter), equity/WPB far slack. The designs
  differ mainly on the RICH side, which w does not touch; both
  multistart restarts were infeasible (single-seed values); w's only
  direct channel is the 2.9%-of-stock public rentals at €0 subsidy.
  VERDICT: the non-monotone €10.40/€8.75/€10.00bn ordering is search
  noise of the CCG heuristic, not a w mechanism; the one systematic
  w effect is public-rental envelope uptake 0.720/0.725/0.798.
- **Wood-PEF flag ADDED** to data/PROVENANCE_polish_stock.md (model
  uses 1.1 for the wood share incl. baseline; Polish certificate
  convention ≈0.2 — open methodological choice).

## Paper questions (read-only evaluations) — HYPOTHESES recorded BEFORE
## the runs (2026-11-03, late evening, user order)

Ordered evaluations (all fixed-σ follower evaluations via evaluate_σ;
no model changes, no search): (1) max-subsidy design (all 12 rates at
caps, depth ordering enforced) for pl10_r12, pl10_s10/s12/s13/s14/s15,
pl10_co2half + a σ = caps/2 probe on pl10_r12 for the monotonicity
question; (3a) pl10_rule_pl_gross at the pl10 search design with both
landlord rates at 10/20/30%; (3b) fixed-σ re-evaluation of the stored
pl10_w05 and pl10_w10 designs for binding-constraint margins.

- **H-max**: all max-σ evaluations come back INFEASIBLE, consistent
  with the batch search verdicts: pl10_r12 and pl10_co2half fail the
  2030 and/or 2040 trajectory milestones (pl9 precedent: r12 at max σ
  2030 −5.5 / 2040 −2.0); pl10_s10–s15 fail the income-share
  affordability check in the final period (pl9 precedent: private-
  rental tenants + the capacity-bound unrenovated remainder bind).
- **H-mono**: feasibility is NOT structurally monotone in σ (the
  follower's adoption is an argmin over its own objective; σ enters
  the objective and relaxes liquidity, so chosen adoption need not
  rise in every period — rational delay is possible in principle). We
  nevertheless EXPECT the caps/2 probe on pl10_r12 to show milestone
  margins no better than at full caps (i.e. monotone in practice
  here); if any milestone is BETTER at caps/2, that demonstrates
  higher subsidies reducing early adoption and is a finding.
- **H-gross**: at landlord rates 10/20/30% under the gross rule,
  public spending rises with the landlord rate and private-rental
  uptake rises from ~0 (E2 precedent: gross-base grants are accepted);
  the zero landlord rate in the optimum reflects cost-minimality (the
  trajectory can be met more cheaply through owners), not landlord
  refusal.
- **H-w**: both stored w designs re-evaluate feasible at €8,749.8M
  (w05) / €9,996.5M (w10) with 2030/2040 trajectory milestones
  binding; the w05-cheaper-than-w10 ordering is plausibly search
  noise (single-seed CCG heuristics on different objectives for the
  public landlord), to be judged against the multistart restarts.

## STOP-RULE AMENDED for the remaining certificates (2026-11-03, user
## order)

A certificate ABOVE its scenario's search result is NO LONGER a stop
condition: apply the value-of-record rule (cheapest feasible design
known, labelled by source), record BOTH values (search bound and
certified grid optimum), re-run the figures, and continue. Stop only
for the unexpected: a certified INFEASIBILITY where the search found a
feasible design, a FAILED joint re-evaluation (consistency error), or
a crash. Applies to pl10_noeed, pl10_elec_m20, pl10_inclusive,
pl10_sav4666 (and the pending ban2040/co2half/split/elec_p20 merges);
for pl10_co2half the search was INFEASIBLE, so a certified
infeasibility there is the expected confirmation, not a stop.

## Ruling executed: re-evaluation, value-of-record labels, local proof
## armed (2026-11-03, evening)

**(1) Fixed-σ re-evaluation of the pl10 search design — HYPOTHESIS
CONFIRMED, with one sharpening.** Script: scratchpad
`eval_search_design.jl` (read-only; log of record
`results/cert_logs/eval_pl10_search_design.log`). σ loaded verbatim
from `out/scenarios/pl10/subsidies.csv`; `evaluate_σ` verdict:
FEASIBLE, spending **€10,397.419M — matches policy_kpis.csv to <1e-4**.
Margins: equity 36.48% vs 30% floor (+6.48 pp); WPB 78.68% vs 55%
(+23.68 pp); trajectory 2030: E_prim 222.192 vs 222.124 → **−0.068,
feasible ONLY through the model's +0.1 kWh/m² tolerance** (the same
tolerance the enumeration uses — consistent); 2035: +20.79 slack;
2040: 158.580 vs 158.660 → **+0.080, also binding within the
tolerance band**; 2050: 91.13 vs 108.42 (+17.28); affordability mode
off, reported check ok, violating share 0. Sharpening of the picture:
the continuous design sits ON the 2030 and 2040 milestone boundaries —
the CCG search tuned the rates to the constraint edge, which no 5/10%
grid point can do; this is consistent with (and strengthens) the
grid-resolution reading of the +11.4% certificate gap.

**(3) hvac semantics (user question):** `hvac_std` =
`hvac_fossil_to_hp` (fossil boiler → heat pump); **`hvac_upg` =
`hvac_fossil_to_district` (fossil boiler → district-heat connection)**
(measures_v2.csv, depth column "standard"/"upgrade"). The pl10 grid
certificate therefore subsidises the DISTRICT-HEAT connection for the
poor at 90% where pl9's certificate subsidised the HEAT PUMP at 90% —
recorded as an open finding in the certificate entry below.

**(4) Value-of-record labels implemented + figures re-run.**
make_pl10_figures.py: new `record_of(scn)` implements ruling (a) —
value of record = cheapest feasible design known; label = "certified
(serial|parallel merge)" when the certificate is the record, else
"search"; the certified grid optimum is reported alongside in a new
column `certified_grid_optimum_M` ("proven optimum on the rate list")
in fig3_scenario_spending_data.csv and pl10_scenarios_summary.csv.
Fig 3 marks: † = certified value of record; NEW ° = search design
cheaper than its certificate (certificate in the CSV). Re-run clean,
all six figures re-exported: pl10 row now `10397.4, source batch,
label search, certified_grid_optimum_M 11586.8`; all other labels
unchanged.

**(2) LOCAL proof implemented and ARMED (gated).** New file
`enumerate_local.jl` in worktree-parallel-merge (read by no running or
queued process): identical machinery to the pl9-verified
enumerate_exact.jl (same Resp/build_table/shard/merge and the exact-
reproduction parallel combine), but the per-rate grid is center
± {0, 2.5, 5, 7.5, 10} points around the stored pl10 search design,
clamped to [0, cap], plain depth ordering kept. Smoke run (model
loaded, no solves): 6,750 poor × 11,880 rich σ-vectors, landlords
5 × 5 → cross product 2.0e9 (≈1% of a full hybrid merge), 18,630
follower solves ≈ 40 min on 8 shards; merge minutes on 12 threads. The
center is on the box by construction, so local optimum ≤ €10,397.419M
unless the center fails the arithmetic check (would be a finding). The
result marker is "CERTIFIED LOCAL OPTIMUM" — deliberately NOT the grid-
certificate marker, so no watcher or figure parser mistakes it for a
grid certificate; log `results/cert_logs/cert_pl10_local25.log`.
Driver: scratchpad `local_proof_driver.sh`, detached (PID 2381126), log
`results/cert_logs/local_proof_driver.log`; GATE = certificates for
pl10_noeed + pl10_elec_m20 + pl10_inclusive + pl10_sav4666 all present
(user condition: the merges no longer need the cores), backstop
2026-11-06 12:00 → ping "decision needed" and exit WITHOUT running.

## RULING on the pl10 certificate-above-search-bound finding
## (2026-11-03, user order)

User ruling (a), general rule for ALL scenarios from now on: **value of
record = the cheapest feasible design known** (search or certificate),
labelled by source; where the certificate is cheaper (as in pl9) it
replaces the search. The grid certificate is reported alongside as
"**proven optimum on the rate list**". Ordered follow-ups: (1) re-
evaluate the pl10 search design at fixed σ — feasibility and margin per
milestone and rule; (2) once the noeed merge and the three intercepted
merges free the cores, a LOCAL proof around the pl10 search design with
the parallel merge — each rate in 2.5% steps within ±10 points (clamped
to [0, cap], respecting the depth ordering) — does anything cheaper
exist? (3) clarify "hvac upgrade" (answered below: district-heat
connection); (4) re-run make_pl10_figures.py with the new labels.

**HYPOTHESIS for (1), recorded BEFORE the run:** the stored pl10 search
design (subsidies.csv, continuous rates) re-evaluates FEASIBLE at
€10,397.4M (= policy_kpis.csv TotalPublic, batch 2026-11-02), with all
rules satisfied: equity ≈ 36.5% vs 30% floor, WPB ≈ 78.7% vs 55%,
E2050 ≈ 91.1 vs 108.4 target; the tightest margins are expected at the
2030/2040 trajectory milestones (these were the binding ones at σ=0:
−9.1 / −12.3). If the re-evaluation comes back INFEASIBLE or at a
different spending, that is a finding (and would reopen the ruling's
premise); it is recorded, not tuned away.

**HYPOTHESIS for (2), recorded BEFORE any run:** the local 2.5%-step
±10-point proof around the search design finds a cheapest design within
a few % of €10,397.4M — strictly below €11,586.8M (the hybrid-grid
certificate) and plausibly slightly below the search value itself
(coordinate descent is a local heuristic; fast_reno precedent). If the
local optimum lands ABOVE the search value, that contradicts
grid-resolution as the explanation and is a finding.

## pl10 CERTIFICATE LANDED — ABOVE the search bound; STOP rule fired
## (2026-11-03, 21:10)

**Certificate** (`results/cert_logs/cert_pl10_hybrid.log`, serial merge,
cross product 206,730,940,416 checked in 69,488.7 s ≈ 19.3 h under
contention; 19 feasible improvements):

- **CERTIFIED GRID OPTIMUM pl10 (hybrid grid): €11,586.838M.**
  σ: env poor 40/50/60 (light/medium/deep), env rich 0/0/10,
  heat pump poor 0, **district-heat connection poor 90%** ("hvac
  upgrade" = hvac_fossil_to_district per measures_v2.csv; "hvac
  standard" = heat pump — user question answered 2026-11-03), heat
  pump rich 25%, district heat rich 5%, landlords 0/0. Joint
  re-evaluation: feasible=true at the same €11,586.838M. NOTE the
  carrier flip vs pl9: pl9's certified design subsidised the HEAT PUMP
  for the poor at 90%; pl10's grid design subsidises DISTRICT HEAT for
  the poor at 90% (finding, open).

**STOP rule fired.** The standing rule says: any certificate ABOVE its
scenario's best search bound → stop and report. The pl10 search bound
of record is **€10,397.4M** (batch default start, seed 42; both
multistart restarts INFEASIBLE, so the batch bound stands). The
certificate is **+€1,189.4M = +11.4% ABOVE** it. Reported to the user;
downstream processing for pl10 (figures re-run / relabel) is HELD until
the user's verdict. Nothing is tuned; nothing is re-run.

**Reading of the contradiction (recorded, not resolved).** The two
numbers answer different questions and the gap is explainable without
any bug: the certificate is the exact minimum **on the hybrid σ-grid**
(0/5/.../30%, then 10% steps), while the CCG search optimises
**continuous** σ — its pl10 design sits OFF-grid (env poor
0.27/41.34/41.34%, rich 0.36/14.08/16.54%, HP-std rich 21.56%,
HP-upg rich 0.31%; `out/scenarios/pl10/subsidies.csv`), so the
enumeration never visits it and cannot bound it. Precedent: fast_reno
2026-07, where the continuous heuristic was 4.4% BETTER than the
10%-grid certificate; the 20%- vs 10%-grid comparison measured ~€34M
of grid-granularity value on the old model. Consequence if confirmed:
for pl10 the grid certificate does NOT certify the search bound —
€10,397.4M remains a feasible continuous design (CONVERGED, equity
36.5%, WPB 78.7%, E2050 91.1 vs target 108.4) and is the better
spending number, while €11,586.8M certifies only the grid. Contrast
pl9, where the certificate (€10,094.8M) was BELOW the search bound
(€11.384bn) and therefore improved it. Why the sign flips is OPEN
(pl10's cost/savings tables move the optimum between grid points;
sensitivity near 41% envelope rates is consistent with the +11.4% gap
but is NOT verified).

**Multistart comparison (standing order):** both pl10 multistart
restarts were infeasible → €10,397.4M (batch) stands as the search
bound; the certificate changes nothing there.

noeed merge still running at the time of recording (19.3 h CPU);
interceptor in phase 1 (waits for BOTH certificates before resuming
the wave-4 shards) — untouched, as designed.

## Figure labels now carry the merge mode (2026-11-03, user order)

Order: the result label in pl10_scenarios_summary.csv and the figure
CSVs must distinguish "certified (parallel merge)" from "certified
(serial merge)". It did not (plain "certified"/"search") — added:
make_pl10_figures.py gained cert_mode(), which reads the merge mode
off the certificate log itself (the parallel merge prints a "PARALLEL
cross product on N threads" marker; the serial merge never does);
label_of() now returns "certified (serial merge)" / "certified
(parallel merge)" / "search", the two literal "certified" writers
(Fig 3 rows, summary CSV) route through label_of(), and the Fig 3
†-mark test uses startswith("certified"). Verified against both real
pl9 logs: serial log → "certified (serial merge)", parallel
verification log → "certified (parallel merge)", both €10,094.809M.
Full re-run with no pl10-family certificate present: outputs unchanged
(all "search"), script clean. The figure † mark itself stays one
symbol — the mode distinction lives in the CSVs, where provenance
belongs.

## Parallel merge IMPLEMENTED in worktree-parallel-merge (2026-11-03, user order — conditional on ETA > ~6 h)

Order: if the ETA estimates say the pl10 or noeed merge needs more than
~6 further hours, implement the parallel merge (threads over the
low-income index with a shared best value, plus progress printing with
flush) in a separate worktree, verify on pl9 that it reproduces the
serial certificate EXACTLY, then run it for pl10 and pl10_noeed from
the existing shard files on idle cores — without touching the running
merges, the paused wave-4 shards or the follow-on.

Early estimator readings (sampled replication, before calibration)
project the pl10/noeed cross products at raw ≈ 128,000 s ≈ 35 h —
far above the threshold — so the implementation started while the
calibrated estimates finish. Worktree `worktree-parallel-merge` at
master c625fe1 (enumerate_exact.jl and the model byte-identical to the
code that produced the shards; verified clean vs HEAD). Change ONLY in
the worktree's enumerate_exact.jl: a combine_parallel() that activates
with julia -t N — contiguous ordered chunks over the poor index,
thread-local incumbents with the serial skip rule, a shared atomic
bound compared STRICTLY so a combo tying the global minimum is never
pruned, reduce takes the minimal value and, among exact ties, the
lowest chunk — reproducing the serial tie-break (first argmin in loop
order) exactly; progress line with flush every 60 s. The built-in
evaluate_σ joint re-evaluation stays as the final consistency check.
Main-tree enumerate_exact.jl UNTOUCHED (the sav4666 follow-on still
re-reads it). Shard dirs symlinked read-only into the worktree.

HYPOTHESIS (before the verification run): the pl9 parallel merge on
the existing pl9 shard files reproduces the serial certificate exactly
— value €10,094.809M and the same optimal σ (the printed "feasible
improvements" counter is path-dependent and exempt). Runtime expected
roughly 22,075 s / threads + load overhead. If value or σ differ, the
parallel merge is WRONG and will not be used — recorded as a finding,
not patched around silently.

VERIFICATION RESULT (landed ~18:46): **PASS, exact.** Certificate
block byte-identical to the serial certificate of record: Optimal
spending €10094.809M, all 12 σ rates identical (env poor 15/25/25,
rich 0/5/15, HP-std poor 90%, landlords 0/0), joint re-evaluation
feasible at €10094.809M. Log: worktree
results/cert_logs/cert_pl9_parallel.log. Cross product 206,730,940,416
combinations in 3,993.9 s on 36 nice-19 threads (serial: 22,074.8 s →
5.5× on a loaded machine; memory-bandwidth-bound, not 36×). Progress
printing with flush confirmed working. One post-launch patch to the
worktree code (running julia unaffected — file parsed at include):
one thread reserved for the progress monitor (nwork = nthreads − 1),
since compute tasks never yield and starved the monitor until the
first chunk finished.

DEPLOYMENT per the follow-up order (verification passed → use the
parallel merge for the three REMAINING merges instead of serial; keep
the six running serial merges): old wave-4 resumer replaced by the
detached interceptor resume_and_parallel_merge.sh (log
results/cert_logs/parallel_merge_interceptor.log). It (1) takes over
the resume gate unchanged (pl10+noeed certificates or the 24 h
backstop 2026-11-04 13:30 → SIGCONT the 16 frozen shards), then
(2) intercepts each of the three serial merge launches — elec_m20 and
inclusive by the orchestrator, sav4666 by the follow-on; the running
scripts cannot be edited safely — by killing the serial julia within
~20 s of launch (still in startup, no writes; identified by
P4_ENUM_MERGE in /proc/<pid>/environ, which distinguishes it from the
shard julias' identical command line) and running the verified
parallel merge from the worktree into the SAME
cert_<s>_hybrid.log path (12 threads each for elec_m20/inclusive,
concurrent with the sav4666 shard phase; 24 threads for sav4666).
affordability_grid_report.csv is copied from the worktree scenario dir
to the main one on certification. Pre-announced cosmetic artifacts:
the orchestrator/follow-on subshells ping "merge FAILED (no
certificate)" right after each kill, and "ALL PL10 PROOFS DONE" fires
early (usefully starting the sav4666 shards during the wave-4 parallel
merges); the signals of record are the interceptor's "PARALLEL merge
CERTIFIED" pings and the certificate logs.

## Figure data + figures 1–6 EXPORTED; wave-4 shards PAUSED for the pl10/noeed merges (2026-11-03, user order)

Order (2026-11-03): export figure data today from the best available
result per scenario (multi-start best; certificate where one exists),
every value labelled search/certified; draw Figs. 1–6 (Carlito,
TU Wien blue #0063A6 only accent); speed-up check on the running merges;
report the pl10 certificate as soon as it lands.

**Speed-up action**: load average was 310 on 48 cores (16 wave-4 shard
julias × ~2.7 cores Gurobi each + 6 merges). No TimeLimit / Threads cap
anywhere in enumerate_exact.jl or the model → SIGSTOP is safe (no
wall-clock solver limits to violate). The 16 wave-4 shard processes
(pl10_elec_m20 + pl10_inclusive) were SIGSTOPped at 13:28; a DETACHED
resumer (scratchpad resume_wave4_shards.sh, log
cert_logs/wave4_resume_driver.log) sends SIGCONT when BOTH
cert_pl10_hybrid.log and cert_pl10_noeed_hybrid.log contain
"CERTIFIED GRID OPTIMUM", with a 24 h backstop so the shards can never
stay frozen. The queued sav4666 follow-on is a sleeping grep loop (zero
load) — left running. The orchestrator's `wait` on the stopped PIDs
simply blocks; wave-4 resumes where it left off.

**Exports** (results/figures_pl10/, script make_pl10_figures.py — reads
the multistart summary for best source per scenario and ingests
cert_*_hybrid.log certificates automatically on re-run; at export time
NO pl10-family certificate had landed → all values labelled "search"):
fig1 primary energy per period (σ=0 from diag_sigma0_pl10.log misses
2030 by 9.1 / 2040 by 12.3; standard meets all milestones, E2050 91.1);
fig2 spending/uptake per income×WPB group + rentals (poor owners
€3.79bn / rich owners €6.60bn discounted; rentals €0 — landlord rates
0; uptake 2050: poor WPB 89% / rich rest 36% / public 72% / private
33% of floor area); fig3 all 34 scenarios vs standard (7 infeasible);
fig4 poor 2050 cost share, unrenovated vs after-policy stock average —
**FINDING stated in the figure: private rental after-policy 9.3% >
unrenovated 8.9%** (rent increases exceed bill savings for the little
that is renovated; all other poor groups improve, WPB owners 40.5→
19.6%); a per-dwelling renovated-only bill is NOT IN MODEL
(archetype-average accounting) — figure says so; fig5 uptake by tenure;
fig6 rent rules (tenant bill + rent increase, 2050, dwelling-weighted;
rule_perm from the ms_pl9cert restart, €8,844M bound) + public landlord
own spending €2.18bn (EED on) vs €0.00 (EED off, renovates nothing).
Plus pl10_design_table.csv (standard design σ) and
pl10_scenarios_summary.csv (all 34 + σ=0, best bound, source, label,
E2050/equity/WPB). Ledger row added to results/README.md.

Revision (same day, user fixes): (1) Fig2b identical 89% for both
low-income owner groups CHECKED — not an aggregation bug: every
poor-owner archetype has s_env = 0.88524 exactly (adoption-cap-bound
each period under the optimum; rich WPB 80% vs rich rest 36% shows the
split differentiates); a consistency assert now pools the split back to
the model's own owner_poor value and aborts on mismatch. (2) Public
landlord own spending also reported DISCOUNTED at the landlord's/state's
3% with the model's TotalPublic convention (period-START years, base
2020; flows CSV stamps period ends — mapped back): **EED on €2,183.5M
nominal / €1,523.4M discounted; EED off €0 / €0** — the discounted
number is the one comparable with state spending. (3) Fig3 plain-language
scenario names (grounded in each config_used.txt descr), "not feasible"
wording, and "‡" on the 9 proof-list scenarios without a landed
certificate (value/infeasibility to be confirmed); name + proof_pending
columns added to fig3 data CSV and pl10_scenarios_summary.csv.

## Multistart results LANDED (2026-11-02 22:19; recorded 2026-11-03)

All 68 restart runs done in 36 min (worktree branch
`worktree-multistart-search`, outputs out/scenarios/<scn>__ms_*/,
summary results/pl10_multistart_summary.csv, committed on the branch).
**Best bound changed in 5 of 34 scenarios** (H38 direction confirmed,
smaller breadth): sav4666 13,591→**8,724** (hpheavy start; the +31%
batch anomaly WAS a search failure — sav4666 is now BELOW the standard,
so H36's "higher deep saving lowers spending" is CONFIRMED with the
better search); elec_m20 9,112→**5,494** (hpheavy, −40%); hpcost_lo
10,760→**9,525** (pl9cert; H36's "cheaper HPs lower spending"
CONFIRMED — the batch's +3.5% was indeed search noise); rule_perm
9,996→**8,844** (pl9cert); hvac6 10,397→**9,934** (pl9cert).
Flagged elec_p20 (29.6bn) and inclusive (27.2bn): UNRESOLVED — both
restarts trajectory-infeasible, bounds stand until their proofs.
pl10 standard: both restarts infeasible; 10,397.4 stands (certificate
pending). kprb: restarts descend to 4–106M, batch €0 stands.
FINDING (mechanism, recorded): the upward-adjustment fallback also
moves ONE rate at a time, so a trajectory-infeasible forced start
usually cannot be repaired (in sav4666 it could: start [traj]-infeasible
→ adjusted feasible 10,455 → descended 8,724). Restart infeasibility is
mechanism behaviour, not a bug. Scenario-of-record convention: the best
feasible bound across {batch, ms_pl9cert, ms_hpheavy} per scenario —
tables updated when the certificates land.

## RULING on the pl10_co2half stop (2026-11-02, user)

User ruling, verbatim intent: co2half recorded as a FINDING (infeasible
at maximum subsidies under the search; the proof will settle it);
dependent work continues as ordered. ALL pl10 search results are
PROVISIONAL: elec_p20 (€29.6bn), inclusive (€27.2bn) and sav4666 (+31%)
flagged as possible search failures — to be checked FIRST against the
multistart results when they land. pl10_sav4666 ADDED to the proof list
(after the current waves; follow-on orchestrator waits for the
"ALL PL10 PROOFS DONE" marker, then 8 shards + merge, detached). For
no-EED, the public landlord's OWN spending is reported next to the
state's. The pl10 certificate is reported together with its multistart
results (watcher in place).

no-EED landlord accounting (from investment_flows.csv, own_payment_eur,
tenure = rented_public, 2020–2050 horizon; provisional — search bounds):
pl10 standard (EED on): state €10,397.4M + public landlord's OWN
spending €2,183.5M (subsidies received €0 — landlord rates are 0; the
EED obligation alone drives it; €2,910.3M incl. 2050–60).
pl10_noeed: state €16,281.6M + public landlord €0.0M — WITHOUT the EED
obligation the public landlord renovates NOTHING (zero rented_public
investment rows). Dropping EED saves the landlord €2.2bn and costs the
state €5.9bn: EED shifts €2.2bn onto the landlord and leverages a
further €3.7bn of net savings.

## pl10 BATCH LANDED — STOP: unexpected infeasibility pl10_co2half (2026-11-02, 21:44)

Batch complete in 29 min (34/34 searches "CCG run complete"; the new
costs make follower solves much faster — pl10 standard: 252 evals,
240 s). Results of record (search bounds, heuristic; default start):
**pl10 €10,397.4M** (E2050 91.1, equity 36.5%, WPB 78.7%); afford
10,397.4 (slack); s-sweep s10–s15 INFEASIBLE, s20 10,949.0, s25+ =
standard; rules: none/pl/pl_gross 10,397.4, cap3 10,623.1, perm
9,996.5; w05 8,749.8, w10 9,996.5; noeed 16,281.6 (EED saves €5.9bn);
priv16 11,950.3; pubpoor 10,621.6; ban2040 13,440.8 (+€3.04bn);
r12 INFEASIBLE (expected); split 15,825.5; kprb 0.0 (!); hvac6
10,397.2; **co2half INFEASIBLE (UNEXPECTED — STOP)**; peffrozen
34,287.2; elec_p20 29,617.5 / elec_m20 9,111.7 (**sign flip vs pl9**);
hpcost_lo 10,760.1 / hpcost_hi 14,619.5; sav4666 13,590.7; inclusive
27,176.3. σ=0: INFEASIBLE, 2030 −9.1 / 2040 −12.3, 2050 now met
naturally (97.3 vs 108.4; pl9 violated all three).

**STOP RULE TRIGGERED — pl10_co2half**: at MAX subsidies the search
could not reach the 2030/2040 milestones (upward adjustment exhausted;
closest E2050 107.0 is itself feasible — the EARLY milestones bind).
Under pl9 co2half was feasible at €24.35bn. Mechanism candidates
(recorded, NOT tuned): deep now saves 0.576 (vs 0.70) so the early
envelope-only channel is weaker, and halved CO₂ prices remove the
fossil-bill pressure that drove natural early adoption. The pl10_co2half
proof (in the launched proof list) will settle whether ANY grid point is
feasible. NO parameter was changed.

Hypothesis scoring (contradictions recorded as findings, not tuned):
- H32 PARTIAL: spending fell below pl9's €11.384bn ✓ (−8.7%); but the
  default-start design is still poor-HP-free (poor env med/deep
  41.3/41.3%, poor HP 0; NEW: rich HP-std 21.6%) — same descent
  limitation as pl9; design question deferred to multistart + proof.
- H33 MIXED: σ=0 stays infeasible ✓; 2030 tightened (−9.1 vs −6.1) ✓
  but 2050 LOOSENED (met naturally; cheap late HPs) — recorded.
- H34 CONTRADICTED: the SQ1 edge moved DOWN to (0.15, 0.20]
  (pl9: (0.20, 0.25]) — cheaper renovations lower the required income
  share despite higher post-renovation bills at r_deep 0.576.
- H35 CONFIRMED (design level): envelope_light subsidy ≈0 and €0
  subsidy spending; 6.1% natural uptake remains.
- H36 CONTRADICTED on two of three: hpcost_lo RAISED the bound
  (+3.5%, within the 2–4% search noise — weak evidence); sav4666
  RAISED it +31% (NOT noise; higher SFH deep saving makes the
  programme dearer — mechanism open, recorded); ban2040 premium
  +€3.04bn ≈ pl9's +€2.8bn, not smaller.
- H37 (was open): inclusive = €27.2bn, 2.6× standard — it moves
  spending MORE than the KPRB sensitivity (which collapsed to €0.0:
  with the KPRB stock's 186.8 baseline, the ABSOLUTE standard targets
  are met naturally under pl10 economics — σ=0 feasible there).
- FINDING — electricity-price sign FLIP: pl9 had elec+20% CHEAPER
  (10.84 vs 11.38) and −20% dearer; pl10 has elec+20% at €29.6bn
  (+185%) and −20% at €9.1bn (−12%). The pl9 "cheap power makes the
  programme dearer" reading was derived from heuristic pure-envelope
  designs; with HP-bearing designs expensive power hurts. The
  elec_p20/m20 proofs (launched) will settle it. Recorded, not tuned.

Committed with this entry: results/pl10_summary.csv, 34 run logs +
diag_sigma0_pl10.log + pl10_batch_driver.log, gate_postmerge logs,
out/scenarios/pl10*/ outputs. Multistart restarts + proofs (both
detached) were ALREADY ordered and keep running; no NEW dependent step
is taken until the user rules on the co2half stop.

## Multistart searches + pl10 proofs ORDERED — PRE-REGISTERED (2026-11-02, user order on the pl9-certificate finding; batch NOT stopped)

Order: (1) after the pl10 batch, rerun every pl10 search from two extra
starting points — the certified pl9 design and a heat-pump-heavy start —
keep the best result per scenario, report where the best changed.
(2) Proofs for core pl10 scenarios (list below), runtime/memory
estimate, launch detached once the standard pl10 proof is set up.
(3) Explain the heuristic miss.

**Why the search missed the HP design** (code reading, search phases
at bilevel_model_affordable_housing.jl:2889–3190): Phase 2 evaluates
~100 starting candidates (HP-heavy corners included) but keeps only the
single cheapest FEASIBLE initial; Phases 3/5 coordinate descent only
LOWERS one rate at a time (binary search between lower bound and the
current value — it can never raise a rate); Phase 4 perturbation is
multiplicative (δ = σ·0.25·U(−1,1)), so a rate at exactly 0 stays 0
through all 100 trials. The HP-heavy Phase-2 candidates start either
infeasible (envelope 0 → trajectory fails) or expensive (rates at
caps), so an envelope-heavy start wins the initial comparison, HP-poor
enters descent at 0, and no later phase can switch it on. Reaching the
certified design (HP poor 90% + envelope poor 15/25/25) requires the
coordinated move "raise HP while lowering envelope", which
single-coordinate moves never evaluate.

**Mechanism** (implemented in worktree `multistart-search`; the main
tree model file is NOT touched while the detached batch re-reads it per
scenario launch): `P4_SIGMA_START=<file>` (one σ value per line,
canonical order, length n_σ) replaces the Phase-2 candidate list with
that single start — clamped to caps + depth-ordered, infeasible starts
go through the existing upward-adjustment fallback — then Phases 3–5
run unchanged. `P4_OUT_TAG=<tag>` redirects outputs to
`out/scenarios/<scenario>__<tag>/` so restarts never overwrite the
batch results. Start vectors (data/): `sigma_start_pl9cert.csv` = the
certified pl9 σ (0.15,0.25,0.25, 0,0.05,0.15, 0.90,0, 0,0, 0,0);
`sigma_start_hpheavy.csv` = HP-standard poor at cap (1.0 pre-clamp) +
envelope poor 0.30 flat, everything else 0.

Hypotheses BEFORE any run:
H38 — the restarts improve several pl10 optima (the pl9-certificate
start transplants the HP basin); plausible size up to the measured
12.8% heuristic gap; most likely on standard-like scenarios (pl10,
afford, feasible s-sweep, rent-rule/w variants). H39 — scenarios whose
constraints already pushed the heuristic toward HP (ban2040, hvac6)
improve less. H40 — proofs: certified optimum ≤ best search bound per
scenario, gaps of order 10% where the search stayed pure-envelope, and
certified designs include poor-HP subsidies in most core scenarios.
Stop rule: a proof certificate ABOVE its scenario's best search bound
is a contradiction → stop and report (no tuning).

Proof list: pl10, pl10_noeed, pl10_ban2040, pl10_co2half, pl10_split,
pl10_elec_p20, pl10_elec_m20 (the user's minimum) + **pl10_inclusive
(my addition, flagged as such** — it changes the demand data itself,
the deepest structural sensitivity). 8 shards per scenario, two
scenarios' shard phases at a time, merges backgrounded; both the
multistart runner and the proof orchestrator WAIT for the batch-done
marker, then run detached (setsid, ntfy pings). Runtime/memory
estimates and expected end times: session report of 2026-11-02.

## pl10 BATCH LAUNCHED (2026-11-02, 21:14 CET)

Post-merge gate on master PASSED 8/8 ×2 (baseline + tenure_on;
cert_logs/gate_postmerge_{baseline,tenure_on}.log). Batch launched
DETACHED (setsid session leader, no TTY, survives SSH drops): σ=0
diagnostic + 34 CCG searches (run_pl10_batch.sh, N_PAR=6; driver log
cert_logs/pl10_batch_driver.log; ntfy ping on exit). Pre-registration
and hypotheses H32–H37: entry below. Expected completion ≈2–6 h wall
(prior sweep pace ~20–45 min per search, 6-way parallel on 48 cores).
Note: the comment line in run_pl10_batch.sh saying the user-behaviour
sensitivity is "BLOCKED" is stale — pl10_inclusive IS in the scenario
list (unblocked 2026-10-29); left as committed to avoid drift while the
detached chain runs model code.

## pl10 FULL RERUN ORDERED — PRE-REGISTERED BEFORE ANY RUN (2026-10-29, user approval of the cost branch)

Order of work: (1) pl9 proof lands → certificate recorded + committed on
master; (2) cost branch committed (`0ebc216`) and merged, gate rerun on
master; (3) pl10 batch (below); (4) pl10 sharded proof with expected end
time; (5) figure CSVs (Fig. 1–6) after the proof.

**pl10** = pl9 + measure_costs=MEASURE_COSTS_PL2026 (annex od
2026-07-20, 100%-tier unit costs × 1.08 VAT; HP 37,500 PLN gross; DH
legacy) + measure_reductions=MEASURE_REDUCTIONS_PL2026 (SFH
0.134/0.367/0.576, MFH 0.054/0.333/0.490).

Batch (same machinery as the pl8/pl9 phase-2 batch; σ=0 via
eval_sigma0.jl; one search per scenario, seed 42): pl10;
pl10_afford; pl10_s10/s12/s13/s14/s15/s20 + s25/s30/s40;
pl10_rule_none/rule_pl/rule_cap3/rule_perm/rule_pl_gross; pl10_w05/w10;
pl10_noeed (public landlord own spending reported); pl10_priv16;
pl10_pubpoor; pl10_ban2040; pl10_r12; pl10_split; pl10_kprb (absolute
standard targets); pl10_hvac6; pl10_co2half; pl10_peffrozen;
pl10_elec_p20/m20; pl10_hpcost_lo/hi (30,000/45,000 PLN SFH,
area-scaled MFH); pl10_sav4666 (1946–66 typology savings).
**pl10_inclusive UNBLOCKED (2026-10-29, user message)**: the Invert
distributions ARE on this machine —
`writing/epbd.wise_paper/data/dist_curve.xlsx` (XOL = Poland updated
stock, Status quo 2020, both service factors, 100 area-percentiles per
building type). Re-derivation at the census weights (same method as the
standard: rescale to census floor-area shares, merge, rank, cut at 43%)
**VERIFIES the delivered exclusive-SF standard within the curve's
percentile resolution** (mine 274.6 / SFH 52.9% 424/162 / MFH 7.9%
283/135 / avg 266.8 vs delivered 275 / 52.5% 421/162 / 7.1% 281/135 /
266.5) — the 2026-10-27 "VERIFICATION OPEN" flag is CLOSED. Inclusive
SF: mine 266.1 / SFH 50.7% 378.6/175.7 / MFH 15.9% 291.5/167.0 / avg
258.3 vs the user's check 264 / 50.5% 377/175 / 17.2% 288/165 / 256.8 —
all within ~1% except the MFH WPB share (flat curve near the threshold
+ 1%-of-area percentile quantisation; recorded, both SFs show the same
±1pp wobble). Stock file `archetypes_pl_inclusive_mix.csv` built from
the USER-DELIVERED inclusive values (same provenance convention as the
standard stock): poor 15.9%, MFH DH 25/48 ordered splits (overall
44.0% at WPB 17.2%), final = primary/PEF; checks: census total exact,
WPB area share 43.2%, stock avg primary 257.0. Scenario
`pl10_inclusive` ADDED to the batch.
- **H37**: pl10_inclusive moves spending by less than the KPRB
  sensitivity does — the inclusive rescaling lowers the SFH worst
  baseline (377 vs 421 primary) but raises the MFH WPB pool (17.2% vs
  7.1%); with the RELATIVE trajectory both targets and baseline scale
  together, so the net direction is genuinely uncertain (recorded as
  open, not predicted).

Hypotheses (before results; contradictions will be recorded as
findings, not tuned away):
- **H32**: the pl10 optimum shifts away from pl9's pure-envelope design
  toward heat pumps (HP cost −43%, deep saving 0.70→0.576), and total
  spending falls below pl9's €11.384bn (costs fall more than savings).
- **H33**: σ=0 stays infeasible; the trajectory tightens relative to
  pl9 because deep saves less — if any milestone becomes infeasible at
  MAX subsidies, STOP and report (user stop rule: anything UNEXPECTED
  infeasible). Expected infeasible: σ=0, SQ1 at small s (≤0.20 under
  pl9; the edge may move UP because post-renovation bills are higher at
  r_deep=0.576), pl10_r12 (infeasible under pl9 — myopia bound).
- **H34**: SQ1 income-share edge at or above the pl9 edge (between
  s=0.20 and 0.25).
- **H35**: MFH envelope_light (saves 0.054 at €735) drops out of
  optimal designs entirely.
- **H36**: pl10_hpcost_lo lowers spending further; pl10_sav4666 (SFH
  deep 0.629) lowers spending vs pl10; pl10_ban2040 stays MORE
  expensive than pl10 but by less than under pl9 (ban-forced HPs are
  cheaper now).

Summary table, commit after the batch, stop + report on unexpected
infeasibility — then the sharded pl10 proof.

## Rulings on the phase-2 stops — diagnostics LANDED; commit/proof PENDING (2026-10-27, session cut at usage limit)

Ruling (1) SQ1: infeasibility ≤ s=0.20 recorded as the FINDING. Sweep
extension: **s=0.25, 0.30, 0.40 all FEASIBLE at €11.817bn = the pl9
optimum** (the rule is slack there) → the new edge lies between s=0.20
and s=0.25, i.e. €1,927–2,409/yr. Max-subsidy diagnostic (σ at caps,
€57.6bn, diag_max logs → cert_logs pending commit): lowest achievable
2050 cost shares per low-income archetype, renovated|unrenovated split —
owners reach 1.5–7.9% renovated but capacity leaves ~11.5% unrenovated
(e.g. SFH_wpb 42.0% of income unrenovated → archetype avg 11.8%);
PRIVATE-rental poor are the binding block: renovation stalls at 32.8%
(pass-through economics), archetype averages 7.1–18.0% — the sweep's
[afford] failures below s≈0.25 come from private tenants + the
unrenovated remainder, confirming the archetype-average mechanism.
Affordability is checked in the FINAL period only (ending 2050) for the
income-share sweep; "all periods" for cost_neutral.
Ruling (2) pl8_r12: recorded INFEASIBLE; at max subsidies the best
achievable misses 2030 by 5.5 and 2040 by 2.0 (2035/2050 ok) — a
genuine bound: myopic (12%) households cannot be subsidised onto the
early milestones.
Ruling (3) seed-7 restarts: pl9 **€11.618bn** (seed-42: 11.817, −1.7%),
pl9_elec_p20 **€11.618bn** (seed-42: 10.839), pl8_ban2040 **€14.349bn**
(seed-42: 14.577). READING: search noise ≈ 2% on the standard; under
seed 7 the elec+20% anomaly DISAPPEARS (identical to pl9); best-known
bounds are now pl9 ≤ 11.618, elec_p20 ≤ 10.839, ban2040 ≤ 14.349 —
the "+20% elec is cheaper" result is at least partly a seed artifact
(elec_p20's seed-42 basin was better than any pl9 basin found; the gap
10.84 vs 11.62 remains to be explained or closed in the detailed
pass). ban2040 > pl9 holds under both seeds (+€2.6–2.8bn, robust).
NOTE: the seed-7 reruns overwrote out/scenarios/{pl9,pl9_elec_p20,
pl8_ban2040}; seed-42 numbers preserved in the batch logs/this entry.
**STILL PENDING (next session): the constraint/uptake/capacity
explanation of the two anomalies, stale-output cleanup
(pl8_s20, pl8_r12), the batch commit, the sharding equivalence test,
and the pl9 proof launch + end time.**

## PHASE-2 BATCH LANDED — 8 infeasible, STOP RULE TRIGGERED; NOT committed (2026-10-27)

(One relaunch was needed: a shell quoting slip backgrounded the batch
variables so only the σ=0 evaluation ran first; the searches ran on the
second launch. The σ=0 result: **pl9 at σ=0 INFEASIBLE** — 2030 by 6.1,
2040 by 12.7, 2050 target by 10.1; natural owner envelope pace
1.24%/yr pre-2030. H29/H31: the corrected CO₂ intensities (0.18–0.19
vs 0.30) weaken the carbon channel more than cheaper heat pumps help.)

**Feasible (20 of 28; search bounds, € 2020–2050):** pl9 **11.817bn**
(equity 41.0%, E2050 106.1 — the 2050 target is now the tight margin);
pl8_afford 11.817bn (cost-neutral free); rule_none/pl/cap3/gross
11.817bn (rule-invariant again), rule_perm 11.493bn; w05 12.157bn, w10
11.509bn; noeed 14.829bn; priv16 14.677bn; ban2040 14.577bn (**now
COSTS €2.76bn instead of saving** — forced boiler replacement at
corrected prices pushes expensive early switching); split 13.974bn;
kprb(absolute targets) **0.789bn** (its 186.8 baseline sits under the
222.1/211.6 milestones, so only 2040/2050 bind — cheap by
construction); hvac6 9.642bn (−2.2bn, biggest lever); co2half
**24.348bn**; peffrozen 17.372bn; pubpoor 11.817bn; elec+20%
**10.839bn** / elec−20% 11.861bn (counterintuitive sign — dearer
electricity makes households fund more of the transition themselves;
to verify in the detailed pass).
**INFEASIBLE (8) — none registered → STOP:** the whole SQ1 sweep
pl8_s10/12/13/14/15/20 + s10_caprelax (tags [afford]; even s = 0.20
fails now — H30 CONTRADICTED) and **pl8_r12** (tags [E2050, traj]; best
E2050 95.9 still trajectory-infeasible). PRELIMINARY diagnosis,
unverified: the affordability check is the END-STATE ARCHETYPE AVERAGE,
and capacity-bound renovation leaves a 2050 unrenovated remainder whose
boiler bill (≈€5,190 WPB-SFH) drags the average above the s-limits —
under corrected prices the renovated-vs-unrenovated spread widened; for
r12, myopic households miss the early milestones at any subsidy. BOTH
need user decisions (e.g. affordability on the renovated state only?
per-dwelling vs archetype average? r12 recorded as a bound finding?).
Stale step-1 outputs still sit in out/scenarios/pl8_s20, pl8_r12 (their
searches wrote no new KPIs) — flagged for cleanup at commit.
Batch NOT committed; sharding test and proof NOT started (step order).

## Phase-1 review corrections (1) boiler efficiencies, (2) electricity 2025 — implemented, gated, STOPPED again (2026-10-27)

(1) **Seasonal generation efficiencies.** Before: no explicit η existed —
E0 (final) was implicitly useful heat in the HP link (electricity =
E0/SCOP, η = 1), DH switch at the measure's fixed 0.70. New kwarg
`carrier_etas` (nothing = legacy, bit-identical; requires
carrier_prices): η_a from each archetype's fuel mix; HP electricity =
E0×η_a/3.0; DH delivered = E0×η_a/η_dh; applied to bills (per-archetype
Δp), the switch's final-energy accounting (per-archetype HVAC reduction
factors, follower + master) and primary energy (per-archetype carrier
coefficients, follower evaluation + master expression). η of record
(PROPOSED, FLAGGED, certificate-methodology frame — exact table
citation OPEN): coal 0.70, wood 0.65, gas 0.87, oil 0.85, DH substation
0.95 → η SFH 0.7311 / MFH 0.7685; remain_hp 0.2437/0.2562; remain_dh
0.770/0.809.
(2) **Electricity base = 2025 average 0.2634** (2024 was freeze-capped;
user correction); ±20% sensitivities 0.3161/0.2107. PROVENANCE rows
updated; firewood price, MFH mix and heating oil stay as flagged
(user-accepted).
Corrected bill check (SFH low-income, worst-performing 41,561 kWh/yr):
boiler €3,053 (2030) / €5,191 (2050); heat pump €2,668 flat; deep
envelope €916 / €1,557; both €800 — the heat pump now beats the boiler
already in 2030 (was slightly worse under the η=1 + frozen-price
combination). Gate + pl9 smoke load rerun (results below). NO searches,
NO commit; phase 2 still awaits the user's OK.

## Carrier energy prices PHASE 1 — implemented, checked, STOPPED for review (2026-10-27, user order; NO searches, NO commit)

Sourced per-carrier household prices (EUR/kWh final, real 2024, incl.
taxes, excl. ETS2, constant in real terms) + per-archetype fossil fuel
MIXES so price and CO₂ factor come from the same mix; Δp_hp≈0 removed
(heat-pump electricity at the sourced price via remain_hp = 1/SCOP 3).
Full price table, sources, mixes, conventions and flags:
data/PROVENANCE_polish_stock.md ("Carrier energy prices and fossil fuel
mixes"). Headlines: elec 0.2284 (Eurostat DC 2024, freeze-capped), gas
0.0707 (D2 2023, PL confidential 2024+, frozen level), coal 0.0594 (GUS
M.P. 2025 poz. 52), wood 0.0523 (FLAGGED — no GUS series; 450 PLN/m³
central of market range), oil 0.1065 (FLAGGED, 1% weight), DH 0.1151
(URE 2024, 105.74+31.76 PLN/GJ). Mixes: SFH coal/wood/gas/oil
.3702/.3445/.2749/.0104 (census Tabl. 24 + GUS ZEwGD-2024 coal/wood
split 51.8/48.2); MFH .2704/.2516/.4670/.0110 (PROPOSED: urban
individual-heating structure, flagged). CO₂ (user order): coal .34, gas
.20, oil .27, wood 0 → archetype intensities 0.1837 (SFH) / 0.1883
(MFH), replacing the stylised 0.30. Resulting fossil-mix prices
0.0606/0.0634; Δp_hp +0.0148 (SFH) / +0.0120 (MFH) / −0.0397 (DH
incumbents); Δp_dh +0.0200/+0.0172/−0.0345.
Implementation: scen kwargs carrier_prices (nothing = legacy,
bit-identical) + carrier_co2; stock files with mix columns
(archetypes_pl_mix.csv, archetypes_pl_kprb_mix.csv); per-archetype
pfuel_a/Δp_hp_a/Δp_dh_a (legacy values reproduced exactly at the
defaults); scenarios pl9, pl9_elec_p20, pl9_elec_m20 DEFINED, not run.
Sources stored: data/gus_zewgd_2024_sygnalna.pdf; Eurostat API pulls.
**Checks: gate baseline + tenure_on 8/8 PASS ×2
(cert_logs/gate_carrierprice_*); pl9 smoke load prints the sourced
prices, mixes, CO₂ and unchanged baseline primary 264.4
(cert_logs/pl9_smoke_load.log). Bill check in the session report.**
Phase 2 (reruns + KPRB-absolute + proof) awaits the user's OK.

## FULL RUN on the new standard pl_r8 — ORDERED, PRE-REGISTERED BEFORE ANY RUN (2026-10-27)

**Step 0 — subsidy horizon.** New scen kwarg `subsidy_horizon_end`
(nothing = unlimited = every committed scenario, bit-identical; enforced
in the follower fz, z_leader and the master McCormick block). The pl_r8
base now carries 2050: post-2050 adoption is unsubsidised and reported
spending covers 2020–2050. The committed pl_r8 result (€5.257bn incl. a
€1.051bn post-2050 tail) is SUPERSEDED by the rerun below; the old
outputs remain in git history (def5c8b). Gate first; stop on failure.
Expectation: spending falls by roughly the old tail minus any
behaviour shift of post-2050 adoption.
**Step-0 RESULT (landed):** gate baseline + tenure_on 8/8 PASS ×2
(cert_logs/gate_horizon_*); pl_r8 rerun **€4.190bn (2020–2050)** vs
€5.257bn unlimited — the −€1.067bn matches the old €1.051bn post-2050
tail almost exactly (expectation confirmed); equity 73.0%, WPB 79.7%,
E2050 92.63 unchanged; design shape unchanged (poor env
20.6/32.1/32.1%, rich HVAC 15.3/5.0%, landlords 0/0). This €4.190bn is
the SPENDING OF RECORD for the new standard.

**Step 1 — pre-registered search list (all on pl_r8 + horizon; CCG,
search bounds; parallel):** rerun `pl_r8`; SQ1: `pl8_afford`
(cost-neutral, zero-subsidy ref), `pl8_s10/12/13/14/15/20`
(income-share, end state), `pl8_s10_caprelax` (reno_scale=100,
DIAGNOSTIC); SQ2: `pl8_rule_none/pl/cap3/perm` (landlord_subsidy_cap=0),
`pl8_rule_pl_gross` (grants not deducted; landlord subsidy allowed),
`pl8_w05`, `pl8_w10`, `pl8_noeed`, `pl8_priv16`; regulation:
`pl8_ban2040`; sensitivities: `pl8_r12`, `pl8_split`, `pl8_kprb`,
`pl8_hvac6`, `pl8_co2half`, `pl8_peffrozen`, `pl8_pubpoor`.
26 searches. The "inclusive SF" demand sensitivity is BLOCKED — the
Invert workbook never arrived and no inclusive-SF numbers exist in the
repo ("not in model"); recorded, not run.
EXPECTED infeasibilities, registered so the stop-rule is not tripped by
them: low income-share points (s=0.10, possibly 0.12/0.13) may be
infeasible as in the stylised sweep — that is the SQ1 finding, not an
error. Any OTHER infeasibility stops the batch per the order.
Hypotheses: H25 — the income-share feasibility edge sits at a similar
EURO limit as before; H26 — rent-rule choice again cannot be separated
by spending (levies/tenant costs differ); H27 — no-EED saves the
landlord outlay but barely changes leader spending; H28 — ban2040
lowers spending (forced switching substitutes for subsidy-driven
acceleration) at higher private cost.

**Step-1 RESULT — batch landed, then STOPPED per the order (2026-10-27).**
All 25 searches ran. 18 feasible (search bounds, €bn 2020–2050):
pl8_afford 4.190 (cost-neutral FREE at the optimum — identical to
pl_r8); pl8_s20 5.890; rule_none/pl/cap3/gross and w05 all 4.190
(identical spending, rule-invariant as in H26); rule_perm 5.633
(equity 100%); w10 5.519 (equity 100%); noeed 7.360 (EED SAVES the
state €3.17bn — H27 CONTRADICTED: without the obligation the state
must BUY the public+WPB savings elsewhere); priv16 5.759; ban2040
3.164 (H28 confirmed, −€1.03bn); r12 10.585; split 5.939; hvac6 4.344;
co2half 6.596 (equity floor binds 29.9%); peffrozen 6.624 (floor
binds); pubpoor 4.190.
7 INFEASIBLE, all "No feasible solution found":
- pl8_s10/12/13/14/15 + s10_caprelax — failing tag [afford]: the
  income-share limit is unreachable below s = 0.20 on the Polish stock
  (end-state poor-SFH costs exceed s×9,635 even fully renovated;
  Δp_hp≡0 makes heat pumps bill-neutral). Euro edge between €1,445
  (s=15) and €1,927 (s=20) vs €1,156–1,253 on the stylised stock —
  H25 partly: same mechanism, higher edge. REGISTERED class (s14/s15
  extend the registered low-s set; same failing tag) → not the stop
  trigger. First feasible point s = 0.20 at €5.890bn.
- **pl8_kprb — UNEXPECTED, STOP TRIGGERED**: failing tags
  [E2050, traj]. Mechanism: traj_mode="relative_to_2020" recomputes
  the targets from the KPRB stock's OWN lower baseline (186.8 →
  2050 target 76.6); even at maximal subsidies the best E2050 is
  ≈79.8 (€16.9bn). The −59% is structurally harder from a lower base
  because the PEF-driven heating floor does not scale with demand.
  Interaction of two user decisions (relative trajectory × KPRB
  demand) — needs a user ruling: (a) run the KPRB sensitivity with
  ABSOLUTE targets from the standard baseline (264.4-based values);
  (b) keep relative and accept INFEASIBLE as the finding; (c) relative
  with a softer 2050 reduction for this sensitivity. NOTHING tuned.
**Searches NOT committed and the proof NOT launched pending the
ruling (step-3 ordering preserved).**

**Step 2 — proof.** Parallel workers for enumerate_exact (shard the
side-vector table builds across processes, merge, then the cross
product; serial path unchanged). Gate: a small serial case must be
reproduced EXACTLY by the sharded run before the pl_r8 proof starts
(hybrid list, plain ordering; 115,656 follower solves under the
pre-horizon count — recomputed at launch).

**Step 3 — commits** after step 0, after the searches, and for the
proof infrastructure/launch; run-log churn and legacy root files
excluded throughout.

## Household discount rate separated from the state's — pl_r8 family ORDERED, PRE-REGISTERED (2026-10-27)

New kwarg `household_discount_rates` (per group: owner_poor/owner_rich/
landlord_public/landlord_private; nothing = committed behaviour,
bit-identical — follower objective now discounts via `fdisc(a, yr)`,
which reduces to the old disc/disc_ll split at the defaults). State rate
3% unchanged everywhere leader-side. pl_r8 = pl_standard + owners and
private landlords at 8% (CALIBRATED, see PROVENANCE_polish_stock.md:
σ=0 pre-2030 envelope pace ≈0.9%/yr ↔ observed EU ≈1%/yr, EC 2019;
Schleich et al. 2016, Kubiak 2016), public landlord 3%. Ordered runs:
σ=0 evaluation; searches pl_r8 + equity floor off/20/40 + all-12% +
split 12/8. Note: the searches run under the NEW plain-ordering rule
(zero-envelope designs now reachable).

**Hypotheses — recorded BEFORE the runs:**
- H21: pl_r8 at σ=0 is INFEASIBLE at the 2030 (and likely 2040)
  milestone, magnitudes near the global-r diagnostic (−2.8/−4.9),
  slightly different because ncf and the public landlord keep 3%.
- H22: the pl_r8 search finds a strictly positive optimum for the FIRST
  time under plain ordering — subsidies are needed to accelerate
  pre-2030/2040; expect the trajectory milestones to bind at the
  optimum, spending well below the old conditional €6.99bn.
- H23: the equity floor binds on top of the trajectory where it exceeds
  the natural poor share of the acceleration spending; eqoff optimum
  > 0 (trajectory-driven), rising in the floor thereafter.
- H24: all-12% costs the most; the 12/8 split shifts spending toward
  low-income owners and makes the 30% floor cheaper or slack.

**pl_r8 RESULTS (landed 2026-10-27; gate baseline+tenure_on 8/8 PASS ×2
after the fdisc edit, logs cert_logs/gate_hhdisc_*; σ=0 diagnostic
cert_logs/diag_sigma0_pl_r8.log):**
- H21 CONFIRMED: pl_r8 σ=0 INFEASIBLE — 2030 by 2.9, 2040 by 5.0 kWh/m²
  (2035/2050 ok); owner natural envelope pace 0.88%/yr pre-2030.
- H22 CONFIRMED: search optimum **€5.257bn**, and the binding constraints
  are the 2030 and 2040 trajectory milestones (221.57 vs 222.12;
  158.76 vs 158.66 — at tolerance); 2035/2050 slack; E2050 92.6.
- H23 CONTRADICTED — finding: the equity floor is SLACK at every level —
  pl_r8 = pl_r8_eqoff = pl_r8_eq20 = pl_r8_eq40 = €5.257bn identically,
  equity share 64.4% unconstrained. Under 8% household discounting the
  cheapest acceleration money goes to the poor WPB stock anyway (poor
  envelope rates 26.7/32.0/32.0% light/med/deep; rich get HVAC 15.2/5.1%
  and no envelope). The r=3% finding (floor binds at 29.9%) INVERTS at
  r=8% — the equity-floor price is a discounting artifact.
- H24 CONFIRMED + nuance: all-12% costs €13.449bn (2.6×, equity 38.5%,
  rich envelope subsidies needed); the 12/8 split costs €7.521bn
  (+€2.26bn vs base — more-myopic poor need deeper rates 28/37/45%,
  equity 72.3%).
- Design regime change vs r=3%: LIGHT envelope now subsidised, poor HP
  disappears (0% at 2050; rich 18% via their HVAC rates), private rental
  envelope 33% (pass-through at 8% landlord discounting), public pinned
  at the EED 72%. Plain ordering is exercised: interior, non-corner
  rates (e.g. 0.267/0.320/0.320).
- Uptake 2050 (env%/HP%): owners poor 66/0, owners rich 44/18, public
  72/0, private 33/0 (base; split lowers poor env to 57).

## DECISION — spread rule replaced by PLAIN ordering; committed results are CONDITIONAL optima (2026-10-27, user order)

**Old rule (in force for every result committed before this change):**
`enforce_ordering!` (search) and the `side_vectors` grid filter (proof)
required medium ≥ light + 0.05 and deep ≥ light + 0.10 — at light = 0 an
absolute floor of 5% (medium) / 10% (deep) on the envelope rates of BOTH
income groups, excluding σ = 0 and all low-envelope designs from both
the heuristic search space and every certificate grid.

**New rule (search + proof, user decision):** plain depth ordering —
deep ≥ medium ≥ light, ZERO allowed. (Note the old rule never ordered
deep against medium; the new one does.)

**Effect on all committed results — recorded, NOT re-certified (order):**
every committed optimum is a CONDITIONAL optimum subject to the old
floor. That includes the stylised results of record — the €2.885M
heuristic design (= the floor corner 0/5/10) and the €3.998M D0/D2/D3/D4
grid certificates (= the floor corner 0/10/10 on the 10% grid) — and the
2026-10-27 PL searches (€5.70–8.15bn), whose unconditional optimum is €0
(diagnosis entry below). Whether the stylised baseline is also feasible
at σ = 0 is evaluated in the same diagnostic batch (results below).
CONSEQUENCE, flagged: pinned full-CCG reproduction gates (rentlaw
invariance pins etc.) pin SEARCH results under the old rule and will NOT
reproduce under the new rule (larger search space); the fixed-σ gate
(test_switches_off) is unaffected — rerun with this change: results
below. Legacy searches reproduce only at the pre-change commits.
**Proof size under the new rule (hybrid grid, pl_standard):** poor
105,644 + rich 9,984 + landlords 28 = **115,656 follower solves**
(−17% vs the 140,176 reported under the old rule; d ≥ m prunes more
than the old spreads added), cross product 2.07e11.

**σ = 0 DIAGNOSTIC RESULTS (landed same day; evaluations only, fixed-σ
gate rerun alongside: baseline + tenure_on 8/8 PASS ×2):**
- **Stylised baseline at σ = 0: FEASIBLE** — milestones 179.3/154.6/
  123.9/73.3 vs 180/170/130/90 (2030 margin only 0.7 kWh/m²), WPB 81.1%,
  equity vacuous. **The committed stylised headline (€2.885M heuristic,
  €3.998M certificates) is therefore ALSO a conditional optimum of the
  old spread rule; the unconditional minimum is €0** — at the 3%/yr
  discount rate and the full CO₂ path. Recorded; nothing re-certified
  (order).
- **pl_standard σ = 0 behavioural sensitivities** (natural envelope pace
  of owners, %/yr, pre-2030 → 2040s; feasibility):
  r=3% (as now): 1.69 → 2.67, FEASIBLE (margins 12.6/33.8/18.6/25.7);
  r=8%: 0.89 → 2.57, INFEASIBLE (2030 by 2.8, 2040 by 4.9);
  r=12%: 0.87 → 0.93, INFEASIBLE (2030 by 4.4, 2040 by 20.5, 2050 by
  13.9, E2050 122.3 > 108.4);
  CO₂ ×0.5: 1.69 → 2.30, FEASIBLE (margins shrink to 8.8–12.5, heat
  pumps vanish until 2050);
  r=8% + CO₂ ×0.5: 0.91 → 1.23, INFEASIBLE (2040 by 19.3, 2050 by 20.5).
  **Reading: the €0 result is NOT robust — it hinges on patient (3%/yr)
  households acting on the full ETS2 path. At household discount rates
  of 8–12% the zero-subsidy stock misses the milestones and subsidies
  are genuinely needed; the single global discount rate is now a
  first-order modelling choice, not a technicality (open gap recorded
  since 2026-07).** Public landlords are EED-pinned in every variant;
  private landlords renovate late but strongly (pass-through) except
  under r=12%/combined, where they stall until 2040.
- Observed Polish renovation pace: NO observed-pace source exists in the
  repo (only the DSRB session note ≈3.8%/yr and the KPRB operational
  scenario 2.7→3.9%/yr, both scenario figures) — stated, not guessed.
  For context, the r=8% natural envelope pace pre-2030 (≈0.9%/yr) is
  the variant closest to commonly cited observed paces, but no citation
  is in the repo.

## FINDING — the design-space ordering rule puts a FLOOR under all optima; σ = 0 is feasible at €0 in pl_standard (2026-10-27, user-ordered diagnosis, read-only)

User flagged the inconsistency (everything slack + capacity-bound, yet
€5.76bn "minimum"). Diagnostic evaluations (evaluate_σ, no search, no
model edits; log results/cert_logs/diag_sigma0_designs_pl_standard.log):

| design (env m/d both groups + poor heat 31/50%) | spending | feasible | note |
|---|---|---|---|
| all-zero | **€0.000bn** | **YES** | milestones slack 12.6/33.8/18.6/25.7; WPB 77.4%; equity vacuous |
| found 0/5/10 + heat | €6.989bn | yes | the search result |
| 0/5/10, no heat | €5.762bn | NO — equity 15.0% | |
| 0/0/10 + heat | €7.768bn | NO — equity 26.9% | dropping medium RAISES spending (adoption shifts into subsidised deep) |
| 0/5/0 + heat | €2.247bn | YES — equity 59.5% | |
| 0/0/0 + heat | **€1.335bn** | **YES — equity 100%** | |

**Answers:** (1) σ = 0 is policy-feasible at €0 — natural adoption under
the CO₂ path meets every milestone (E2050 82.7 vs 78.9 at the found
design: the €7bn buys ≈4 kWh/m²). (3) The equity floor is vacuous at
zero spending (evaluate_σ: equity = NaN when ub = 0 → passes; master:
0 ≥ 0.3×0). (4) The search COULD NOT reach these designs:
`enforce_ordering!` lifts EVERY seed and descent candidate to
σ_med ≥ σ_light + 0.05 and σ_deep ≥ σ_light + 0.10 — at light = 0 this
is an ABSOLUTE floor of 5%/10% on medium/deep for both income groups,
and the SAME filter sits in the proof grid (`side_vectors`). The
reported "€6.989bn minimum" is the minimum of that restricted design
space: forced env 0/5/10 both groups (€5.762bn of windfall on
capacity-bound renovation) + the cheapest equity repair (poor heating
rates). The rule as implemented is a minimum-SPREAD rule, not a
monotonicity rule (m ≥ l, d ≥ m would allow 0/0/0).

**IMPLICATION, OPEN (not evaluated — would need one stylised run):**
every committed stylised optimum (heuristic €2.885M AND the €3.998M
grid certificates) is likewise a minimum SUBJECT to this design floor;
whether σ = 0 was feasible in the stylised baseline (fossil ban ON,
absolute trajectory) is unknown. Flagged for the user's decision:
(a) keep the rule as an intended policy-design constraint ("deep rates
always ≥10%" — then the results stand, relabelled as conditional
optima), or (b) relax to monotone ordering / drop it, re-search and
eventually re-certify. NOTHING changed; recorded as a finding per the
standing rule.

## Equity-floor sweep on the PL stock — ORDERED, PRE-REGISTERED (2026-10-27)

The 30% floor binds in all four PL runs → user orders searches at floor
OFF / 20% / 40%. New scen kwarg `equity_floor_value` (nothing = the
context.csv 0.30, bit-identical default; active only with
equity_spending_floor=true); scenarios `pl_eqoff`, `pl_eq20`, `pl_eq40`
(= pl_standard otherwise). Gate rerun alongside.

**H20, recorded BEFORE the runs:** spending rises monotonically in the
floor; pl_eqoff ≈ the unconstrained cost minimum with equity share well
below 30% (the cheap savings sit with high-income owners); pl_eq40
costs substantially more than +33% of the 30→40 gap suggests (the poor
segment is small: 16.5% of dwellings must absorb 40% of spending);
low-income uptake and low-income HVAC rates rise with the floor.

**LANDED (same day; gate baseline+tenure_on 8/8 PASS ×2 alongside):**
| floor | spending | equity | design beyond env 5/10 | owner-poor HP 2050 |
|---|---|---|---|---|
| off | €5.762bn | 15.0% (natural level) | none | 6.7% |
| 20% | €6.116bn | 19.9% | poor hvac_upg 43% | 6.7% |
| 30% (standard) | €6.989bn | 29.9% | poor HVAC 31%/50% | 26.6% |
| 40% | €8.152bn | 39.9% | poor HVAC 50%/50% | 41.9% |
**H20 verdicts:** monotone ✓; eqoff equity 15.0% = roughly the poor
dwelling share, design collapses to the pure env-5/10 stylised shape ✓;
convexity ✓ (20→30 costs +€0.87bn, 30→40 +€1.16bn); low-income HVAC
rates and HP uptake rise steeply with the floor ✓ (HP 6.7→26.6→41.9%).
Price of the floor vs no floor: 30% = +€1.23bn (+21%), 40% = +€2.39bn
(+41%). Rented-sector uptake INVARIANT across the sweep (EED pins public
at 72%; private stays pass-through-driven 49.6%) — the floor works
entirely through poor OWNER heating subsidies. E2050 77.3–80.5, WPB ~76%,
trajectory met in all three. Outputs out/scenarios/pl_eq*/ + run logs.

## Proof grid: hybrid rate list becomes the DEFAULT for new enumerations (2026-10-27, user order)

`enumerate_exact.jl` grid per σ dimension is now, by default ("hybrid"):
**0, 5, 10, 15, 20, 25, 30%, then 10% steps up to each cap, cap always
included** — for every measure, income group AND both landlord rates
(one rate per landlord type, caps 100%). Depth-ordering rule unchanged
(med ≥ light+0.05, deep ≥ light+0.10). A numeric first argument
reproduces the legacy uniform grid, so EXISTING CERTIFICATES stay valid
as recorded (none re-run). Points per cap: 0.40→8, 0.50→9, 0.70→11,
0.85→13, 1.00→14.

**Size for the new standard scenario (pl_standard, 12 σ dimensions):**
poor side 131,124 vectors, rich 9,024, landlords 14+14 → **140,176
follower solves**; cross product 2.32e11 (minutes at the D4-measured
rate). Measured pl follower solve ≈ 2.26 s under 4-way parallel load
(289 s / 128 evals in the search), ~1–1.5 s solo. **Runtime estimate:
≈ 88 h serial at 2.26 s (≈ 58 h at 1.5 s); ≈ 11 h on 8 workers, ≈ 5.5 h
on 16 — NOTE: the script is serial today; the parallel figures assume
splitting the side-vector lists across worker processes (not yet
implemented).** No runs performed.

## PL searches LANDED (2026-10-27) — results of record (search bounds, heuristic)

All four converged (Round 2 = Round 1, perturbation 0 improvements;
~128 evals each, ~5 min wall per scenario in 4-way parallel).

| Scenario | Spending (disc.) | E2050 (target 108.4) | Equity | WPB | Design (nonzero σ) |
|---|---|---|---|---|---|
| pl_standard | **€6.989bn** | 78.9 ✓ | **29.9% (floor BINDS)** | 75.9% | env 0/5/10 both inc; poor HVAC 31%/50%; landlords 0/0 |
| pl_kprb | €5.701bn | 73.2 ✓ | 29.9% (binds) | 80.1% | env 0/5/10; poor HVAC 36%/50%; landlords 0/0 |
| pl_pubpoor | €6.988bn | 80.5 ✓ | 29.9% (binds) | 76.1% | env 0/5/10 both inc; landlord_public 31%, landlord_private 50%; NO owner HVAC |
| pl_hvac6 | €6.517bn | 73.1 ✓ | 29.9% (binds) | 77.6% | env 0/5/10; poor HVAC 21%/50%; landlords 0/0 |

Uptake 2050 (pl_standard; dwelling-weighted): owners low-inc env 60.6%,
HP 26.6%, DH-switch 16.8%; owners high-inc env 67.9%, HP 6.7%; private
rental env 49.6% (pass-through-driven, zero landlord subsidy, no HP);
public rental env 72.0% = the EED requirement EXACTLY (deep min 72.0%,
req 72.0%), DH-switch 38.6%, no HP. EPBD trajectory met in all four;
2050 target met with ~30 kWh/m² slack; WPB rule slack everywhere.

**Hypothesis verdicts (recorded findings, nothing tuned):**
- H15 CONFIRMED: spending €5.7–7.0bn (single-digit billions).
- H16 PARTLY: EED binds exactly at its requirement and carries no leader
  spending in pl_standard/kprb/hvac6 (landlord rates 0); but pl_pubpoor
  lands on a near-tie design (€6.988 vs €6.989bn) that DOES pay
  landlords (31%/50%) instead of poor owner HVAC — the two instrument
  mixes are nearly equivalent in spending (degeneracy, recorded).
- **H17 CONTRADICTED — headline finding: the 30% equity floor BINDS in
  all four runs (29.90–29.93%, at the constraint tolerance), unlike
  every stylised-stock result (61% slack).** With the Polish stock the
  cheap savings sit in the (much larger) high-income owner segment, so
  the floor actively redistributes. WPB stays slack; the trajectory is
  met — capacity (H17's candidate) is NOT the binding margin for
  feasibility, the floor is the binding margin for cost.
- H18 RESOLVED: pl_kprb is cheaper (−€1.29bn): lower baseline demand
  makes the relative target cheaper, not harder.
- H19 CONTRADICTED on spending: the 6% heating limit saves €0.47bn
  (−6.8%) and shifts the design toward more HP uptake (owners low-inc
  26.6→33.7%) at a LOWER poor hvac_std rate (31→21%).

Outputs: out/scenarios/pl_{standard,kprb,pubpoor,hvac6}/ + run logs in
results/cert_logs/run_pl_*.log. Ledgered in results/README.md. NO commit.

## Polish stock recalibration — DECISIONS APPLIED, IMPLEMENTED, searches launched (2026-10-27, user order)

User decisions on the failed checks (scope stays census SFH 1–2 +
MFH 3–19): (1) WPB cut re-derived at census floor-area weights from the
Invert distributions — USER-DELIVERED numbers (threshold ≈275; WPB 52.5%
SFH / 7.1% MFH; averages 421/162, 281/135 primary; stock avg ≈266.5).
NOTE, flagged: the order says "add the attached Invert workbook to
data/" and cites a rural-14% estimate and KPRB values as "already in
PROVENANCE" — the workbook did NOT arrive on this machine and neither
value was previously recorded; all three are recorded from the order
itself, and the workbook verification of the re-derived cut stays OPEN.
The "inclusive SF" sensitivity is BLOCKED for the same reason (no
numbers). (2) Rural split dwelling-based: 14% of rural dwellings in
multi-dwelling buildings, no rural 20+ blocks. (3) Incomes 15.9% owners /
23.8% tenants. (4) Hot water: Invert values treated as total heat demand,
OPEN. (5) KPRB demand sensitivity: final demand rescaled per type to
SFH 177.4 / MFH 162.0 kWh/m²·yr final, worst/rest ratio kept (scales
×0.6549 SFH, ×1.0830 MFH).

**Stock of record:** `archetypes_pl.csv` (12 rows, 8,847,407 inhabited
dwellings: SFH 5,617,609 / MFH 3,229,798; national absolute; KPRB variant
`archetypes_pl_kprb.csv`). CHECKS: totals census ✓; WPB floor-area share
42.52% ≈ 43 ✓ (the 0.5 pp shift comes from the ordered rural-split
change, which moves the SFH area share from 79.4% to 78.0%); stock-avg
primary 264.4 ≈ 266.5 ✓ (same cause, −0.8%); low-income 16.52% ≈ 16.2 ✓
(+0.3 pp); MFH DH overall 46.4% (was ≈44% under the old WPB share —
follows from the ordered 25/48 splits at WPB 7.1%, reported); gate below.

**Implementation (scenario-gated, all defaults reproduce the committed
model bit-identically):** scen kwargs `stock_file` (archetypes read from
it), `public_rich_tenant_share` (public tenants split into poor/rich
twins like private; 0 = committed structure), `traj_mode`/
`traj_reductions` ("relative_to_2020": trajectory and 2050 target =
(1−r)×the model's own 2020 stock-average primary; −16/−20% EPBD Art. 9(2)
sourced, −40/−59% ASSUMED), `env_rate_path`/`hvac_rate_const`/
`joint_rate_path` (4-stage KPRB profile; joint = env + 0.4×hvac as
approved, logic unchanged). Scenarios (below the pin block, ban OFF):
`pl_standard`, `pl_kprb`, `pl_pubpoor` (all public tenants low-income),
`pl_hvac6` (6%/yr heating, joint adjusted). Smoke test: 44 archetypes,
baseline primary 264.4, trajectory 222.1/211.5/158.7/108.4, EED path
computed. COSMETIC, noted: the tenure-split @warn still describes the
tenant split with the wave-9 AROP wording while printing the new 0.762
shares — log text only, no numerical effect.

**Hypotheses — recorded BEFORE the searches (search bounds, not proofs):**
- H15: public spending lands in the single-digit billions EUR
  (discounted) — the stock is ~885× the stylised one but the relative
  trajectory is comparably deep and capacity is looser.
- H16: the EED obligation again binds exactly at its (capacity-clipped)
  requirement for public archetypes and costs the state nothing at the
  optimum (landlord rates 0), as in E3.
- H17: what binds overall is the envelope-capacity path against the
  −59% 2050 target, not the budget-side constraints; the 30% floor
  stays slack (poor stock is the cheap savings reservoir, H1 logic).
- H18: pl_kprb (SFH demand ×0.65) is CHEAPER to the trajectory than
  pl_standard in absolute savings terms but may struggle on the same
  RELATIVE −59% (lower baseline → lower absolute reduction need —
  direction genuinely uncertain, recorded as open).
- H19: pl_hvac6 changes spending little (heating is CO₂/price-driven at
  σ_HVAC = 0), mainly shifting the heat-pump path earlier.

**Ordered runs (launched after the gate):** CCG searches for pl_standard,
pl_kprb, pl_pubpoor, pl_hvac6. Results below when landed.

## Polish stock recalibration ORDERED — pre-run CHECKS FAILED, STOPPED (2026-10-27)

User order: new standard model on the Polish stock (census counts, Invert
WPB shares/averages, KPRB capacity profile, EED on, relative EPBD
trajectory, ban off) + CCG searches for the standard and 3 sensitivities.
The order pre-registers five checks before running and says STOP on any
failure. Executed: census tables obtained (GUS NSP 2021 final, housing
conditions, workbook stored in data/), stock derived and documented
(data/PROVENANCE_polish_stock.md, draft table
data/archetypes_pl_DRAFT.csv, 12 rows, 8,847,407 inhabited dwellings:
SFH 5.78M / MFH(3–19) 3.07M), checks computed.

**RESULT: two checks FAIL — WPB floor-area share 53.4% (target 43%) and
2020 stock-average primary 266.6 kWh/m²·yr (target ≈232). Root cause:
Invert's 43% cut implies SFH = 55.9% of the combined floor area; the
census SFH(1–2)+MFH(3–19) scope gives 79.4%. The Invert frame and the
ordered census scope are structurally incompatible; transplanting the
62.6/18.2 shares onto census counts is not valid. STOPPED per the order:
no model edits for the new scenarios, no stock loaded, NO RUNS.**
Secondary: low-income total computes to 15.59% vs the ≈16.2% benchmark
(owners 8.19M @15% + tenants 0.66M @23%); MFH DH share 43.8% ✓ ≈44%.
Also recorded: the Invert workbook is not in the repo, so hot-water
inclusion could NOT be verified (OPEN); the KPRB heat-demand sensitivity
is BLOCKED — no KPRB demand values exist in the repo or the order ("not
in model"). The KPRB capacity profile (2.7/3.2/3.6/3.9 %/yr envelope,
4%/yr heating) and the proposed joint-cap values (env + 0.4×hvac:
4.3/4.8/5.2/5.5 %/yr; 5.1/5.6/6.0/6.3 at the 6% sensitivity) are
recorded as the plan, NOT implemented. Options reported to the user
(align scope to Invert's frame incl. blocks; use Invert's own area
weights; or re-derive segment WPB shares from the Invert distribution at
census weights — needs the workbook). Nothing tuned to pass.

## Polish stock packet begins: WPB/energy-performance provenance (2026-10-27, user-delivered; documentation only)

First piece of the awaited Polish stock input packet. Created
`data/PROVENANCE_polish_stock.md` with the section "Worst-performing
buildings and energy performance", recorded as delivered: Invert/EE-Lab
(TU Wien), Poland (XOL), Status quo 2020, output of 17 Oct 2025
(`Auswertung_Verteilung_Ergebnisse_XOL_output_25_10_17.xlsx`); SFH+MFH
only; metric = calculated primary energy demand kWh/(m²·yr) per gross
floor area, "exclusive service factor" main / "inclusive service factor"
sensitivity; WPB = worst 43% of the merged SFH+MFH floor area (EPBD
Art. 9(2)), threshold ≈ 240 kWh/(m²·yr); shares 62.6% SFH / 18.2% MFH;
averages 393/139 (SFH wpb/rest), 262/120 (MFH wpb/rest); dwelling counts
and floor areas from the 2021 census, only shares and averages from
Invert; scope note: the EPBD 43% is defined over the whole residential
stock, applied here to the modelled stock. NOTHING LOADED into the model;
no values changed, no runs. Loading awaits an explicit order.

## Fossil-ban default: option (b) pins applied (2026-10-27, user decision)

User decision on the 2026-10-27 flag: **pin `fossil_boiler_ban=true`
explicitly on all scenarios of record**, so every committed result, table,
figure, certificate and test pin reproduces exactly; new scenarios use the
new OFF default. Implemented as one explicit block after the last
scenario definition (before SCENARIO selection): every entry of
SCENARIO_DEFS at that point gets `fossil_boiler_ban=true`, EXCEPT the six
2026-10-27 public-landlord scenarios (`pub_w00/05/10`,
`eed_pub_w00/05/10`), which keep the new OFF default (their with-ban E3
evaluations used the explicit hook). Scenarios added below the block get
the OFF default automatically.

Judgement call, recorded and reversible: the pre-registered but NOT-yet-run
next-round scenarios (`tenure_on_nopass`, `s2pl_ptr00..10`,
`s2fpl_ptr00..10`, `s2fpl_ptr05_nopv`) are also pinned TRUE, although no
committed result sits behind them — their pre-registered definitions are
anchored to with-ban comparators (tenure_on, the original S2 sweep);
leaving them on the new default would silently redefine pre-registered
runs. Say the word and they flip to the new default instead.

Pinned (everything in SCENARIO_DEFS except the six exceptions): baseline,
high_subsidy, early_ban, high_co2, dh_expansion, fast_reno, frozen_pef,
no_residual, all_levers, boiler_ban (already true), afford_neutral,
afford_only, no_floor, afford_incshare(+_only, _s11..s15, _s20,
_s10_capacity_relaxed), claw_p10..p50 + claw_p50_returns, tenure_on,
tenure_on_nopass, tenure_afford, d5_inc_signalnote, tenure_test_no_return,
tenure_test_high_passthrough, s3_claw25/50_incshare15,
afford_neutral_frozenref, tenure_afford_scoped(+_frozenref, _shares2x),
tenure_afford_frozenref, tenure_on_shares2x, s2_ptr00..10,
s2f_ptr00..10 + s2f_ptr05_nopv, s4_rule_pl(+_gross, _capped, _permanent),
s4_rule_de, s4_rule_none, s4f_rule_* (6), rentlaw test scenarios,
tenure_oldshares_test, tenure_newshares_test, lldisc4_rule_pl/_de,
e2_rule_de_gross, the 48 l3_* grid scenarios, s2pl_ptr00..10,
s2fpl_ptr00..10, s2fpl_ptr05_nopv.

`P4_FORCE_BOILER_BAN` hook: KEPT (user order). After the pins it is no
longer needed for reproduction gates or scenarios of record; its only
remaining use is forcing the ban onto a NEW off-default scenario without
defining a with-ban variant (as the E3 wave did for pub_w*/eed_pub_*).
test_switches_off.jl no longer sets it (relies on the pins) and now also
asserts `SC.fossil_boiler_ban == true` for the scenario of record it
checks. Gate result (pins only, no hook): baseline 8/8 PASS and tenure_on
8/8 PASS — spending/equity/WPB/E2050 identical to the committed
policy_kpis.csv, ban pin confirmed active in both (logs:
results/cert_logs/gate_pins_{baseline,tenure_on}_20261027.log).

## EED/weight decisions + first evaluation wave (2026-10-27, user order)

User decisions on the same-day implementation, applied:
1a. **nZEB standard**: an EED-compliant dwelling needs DEEP envelope AND a
    heat pump or district-heat connection (Polish nZEB limit for MFH:
    65 kWh primary/m²·yr, WT 2021 — proxied, not checked against 65).
    Convention recorded: comonotone bundling — nZEB share =
    min(deep share, heating share), so both components must reach the
    requirement; DH incumbents satisfy heating by incumbency.
1b. **Capacity-clipped requirement**: required share = min(0.03 × years
    since 2026, cumulative envelope cap, cumulative heating cap, cumulative
    joint labour cap / 1.4 for fossil-heated archetypes — /1.0 and no
    heating term for DH incumbents) — `eed_required_share`. This resolves
    the near-clash recorded at implementation: at 2050 the requirement for
    fossil-heated public archetypes is capacity-clipped to ≈ 71.0% instead
    of the 72% target (joint labour cap binding).
2.  **w = 1 tie-break**: + RENT_TIEBREAK_EPS (1e-6) × rent_inc for
    rented_public rows at w ≥ 1, so the indeterminate rent level resolves
    to ZERO — at w = 1 the public landlord charges no rent increase.
    Inactive for w < 1 (net rent coefficient strictly negative there).
PROVENANCE row rewritten per the ordered text (base = non-nZEB floor area
on 1 Jan 2024, Art. 6(1); linear 3%/yr; start 2026 assumed; all
public-rental dwellings; period-end check instead of Art. 6(3) carry-over).
New ENV hook `P4_FORCE_BOILER_BAN` (loud, opt-in): forces
fossil_boiler_ban=true for a load — used by the regression gate and this
wave's evaluations, since all pins/comparisons are WITH-ban.

**Ordered runs (this wave):** test_switches_off.jl (baseline + tenure_on,
ban forced ON; STOP on failure), then fixed-σ evaluations at the certified
D0 rates (env med+deep 10/10, landlord 0/0), ban ON, for pub_w00, pub_w05,
eed_pub_w00, eed_pub_w05 — report nZEB-proxy share 2050, public-landlord
spending, public tenant bill + rent 2050, trajectory verdict. NO commit.
Results recorded below after the runs land.

**Gate result:** test_switches_off PASSED 7/7 for baseline AND 7/7 for
tenure_on (spending/equity/WPB/E2050 identical to the committed
policy_kpis.csv; logs: results/cert_logs/gate_switches_{baseline,tenure_on}_20261027.log).

**CORRECTION during the wave (implementation error, not a tuning):** the
first eed_required_share clipped the target with AGGREGATE cumulative
capacity (min(Σenv, Σhvac, Σjoint/1.4)). Both eed_pub_* evaluations came
back FOLLOWER-INFEASIBLE at the D0 rates: the joint labour cap binds per
period, so once the 2040 milestone (42%) is enforced, envelope and heating
cannot BOTH reach the aggregate bound (per-period arithmetic: enforcing
e,h ≥ 0.42 by 2040 uses ≥ 0.599 of the 0.593 joint capacity of periods
1–3). The failed logs are kept (results/cert_logs/e3_eed_pub_w0{0,5}_attempt1_infeasible.log). Fix: eed_required_share now computes the exact greedy max PATH —
per period end a small LP maximises the reachable nZEB share under the
per-period class caps + joint cap, subject to the already-fixed earlier
requirements; requirement = min(target, max − 1e-6 safety margin when
capacity binds). The 3%/yr TARGET itself is unchanged; only the
capacity clip (decision 1b, "what capacity allows") is computed correctly.
The two eed evaluations were rerun after the fix; pub_w00/pub_w05 did not
use the requirement and were not rerun.

**E3 RESULTS (landed 2026-10-27; evaluations at the certified D0 rates,
ban forced ON; out/scenarios/E3_publandlord/):**
- Requirement path (corrected clip), period ends 2030/35/40/50/60:
  fossil-heated 12/27/42/69.49/95.75%; DH incumbents 12/27/42/72/100%
  (capacity clips only the fossil 2050/2060 points and DH never).
- nZEB-proxy share 2050 (dwelling-weighted public stock): pub_w00 0%,
  pub_w05 0% (NO deep envelope at the D0 rates — heating switches only,
  ban- and w-driven), eed_pub_w00 71.2%, eed_pub_w05 71.2% (= the clipped
  requirement; the obligation binds exactly).
- Public-landlord discounted outlay (total, 451 dwellings): €0.216M (w00),
  €0.682M (w05), €3.482M (eed_w00), €3.586M (eed_w05).
- Public tenant 2050, poor-fossil archetype (bill / rent levy €/yr):
  w00 966/50; w05 546/94; eed_w00 403/242; eed_w05 392/243 — under EED
  the levy triples but the bill falls by more: NET tenant cost falls
  (1015 → 646 €/yr poor-fossil). H12 partly contradicted on net cost:
  warm rent component rises as predicted, but total tenant cost falls —
  recorded as a finding (bills dominate at these CO₂ prices).
- Leader spending €3.998M, trajectory OK, policy-feasible in ALL four
  (the obligation is borne by the landlord, not the state: leader
  spending unchanged, H12 confirmed on spending).
- H13 direction confirmed without EED: w = 0.5 raises heating switches
  (47.9% → 59.6–67.7%) and outlay; deep envelope stays 0.
- CONFIGS OF RECORD (recorded 2026-10-27, pre-commit): the four E3
  evaluations ran their base scenarios with the ban forced via
  P4_FORCE_BOILER_BAN; the equivalent explicit scenarios
  `pub_w00_ban`, `pub_w05_ban`, `eed_pub_w00_ban`, `eed_pub_w05_ban`
  are now defined in the model file (base config + fossil_boiler_ban=true)
  and are the named configs the E3 results correspond to.

## Fossil-boiler ban becomes a SCENARIO, default OFF — IMPLEMENTED, NO RUNS (2026-10-27, user order)

**What the ban was (code before this change).** Unconditional constraints in
BOTH the follower (`solve_follower`) and the master mirror: for every
fossil-heated archetype (the DH incumbents `is_dh0_a` are exempt), from the
period whose START year ≥ `ban_year` (default 2040; `early_ban` 2030; the
tenure test scenarios neutralise it with 2060), per-period HVAC switching ≥
(remaining fossil fraction) × boiler_break, boiler_break = 1 − (1 − 1/25)^len
(33.5% per 10-yr period, 18.5% per 5-yr). So not a literal sales ban but
forced HP/DH replacement of end-of-life boilers. Known issue carried over,
unchanged: 33.5%/decade exceeds the 26.3%/decade HVAC adoption cap, silently
forcing pre-ban switching.

**Change.** New scen kwarg `fossil_boiler_ban` — **default false (the new
standard for all future runs)**: both constraint blocks are not built and
`ban_year` is inert. Kept ON as the named scenario `boiler_ban` (ban_year
2040). `early_ban` and `all_levers` now carry `fossil_boiler_ban=true`
EXPLICITLY — their defined purpose is the ban lever, so this preserves their
meaning (definition-preserving, no result change). Config echo now prints
`fossil_boiler_ban=ON/OFF`. Source for the ban OPTION: **EPBD 2024/1275 aim
to phase out fossil-fuel boilers by 2040; there is NO binding Polish ban** —
the reason it is no longer the standard.

**Existing results: NOT changed, NOT deleted — labelled.** Every result
committed up to 2026-10-27 (all tables, figures, certificates incl. the D0/
D2/D3/D4 grid certificates, all sweeps) was produced WITH the ban ON.
Labels added: README ledger header note (results/README.md) and this entry.

**FLAG — reproducibility consequence (not resolved, user to decide):** the
pre-existing scenario definitions (baseline, tenure_on, s2*, s4*, …) now
inherit the new OFF default, so RE-RUNNING any of them will NOT reproduce
the committed results; the pinned reproduction/invariance gates
(test_invariants pins, rentlaw pins, repro gates) pin WITH-ban numbers and
would FAIL under the new default. Options: (a) run gates via `boiler_ban`-
style configs only; (b) pin `fossil_boiler_ban=true` explicitly on the
scenarios of record (as was done for the rule_PL default flip); (c) accept
the break and re-pin after the first no-ban wave. No runs ordered, nothing
re-pinned.

**Hypothesis — recorded BEFORE any run: H14**: without the ban, HVAC uptake
at the certified rates collapses to the subsidy-driven level (near zero at
HVAC σ = 0), E2050 rises toward the trajectory bound and the EPBD 2040/2050
constraints may become binding or infeasible at the committed design —
i.e. part of the committed designs' feasibility was carried by the ban, not
by subsidies. If instead feasibility survives, that is a finding about the
envelope-driven trajectory.

## EED Art. 6 public-landlord obligation + tenant-cost weight — IMPLEMENTED, NO RUNS (2026-10-27, user order)

Two scenario switches added to the model file, both OFF by default, so every
committed scenario and result is unchanged (at w = 0 the new objective term is
a literal 0.0; the EED constraint block is not built at all when the switch is
false).

**(A) `eed_public_obligation` (default false).** Follower constraint on each
public-rental archetype: cumulative deep-envelope share ≥ min(1, 0.03 ×
(end_year − 2026)) in every period. A legal obligation on the landlord, so it
sits in the FOLLOWER problem; the master omits it (a pure follower
restriction — the master stays a valid relaxation, the same argument as for
the apply binary and the rent cap). Source: Directive (EU) 2023/1791 Art. 6.
SIMPLIFICATION, recorded: applied to ALL public-rental dwellings (the 250 m²
threshold and the possible social-housing exemption are ignored); clock
starts 2026 (order).

**Clash check (ordered BEFORE implementation; arithmetic only, no runs).**
Required deep share at the period ends 2030/2035/2040/2050 = 12/27/42/72%.
Cumulative per-archetype envelope capacity (staged rates 1.5/3.0/3.5 %/yr via
`cap_from_rate`) = 14.03/28.15/42.28/72.25%. NO hard infeasibility at the
default reno_scale = 1, but the margins are only +2.0/+1.2/+0.3/+0.3 pp: the
obligation consumes essentially the ENTIRE envelope capacity of the public
archetypes (no room for light/medium envelope), and from 2040 it meets the
fossil-ban HVAC minimum inside the joint labour cap — jointly feasible only
if ≥ ~24% of the fossil-heated public stock switches heating BEFORE 2040.
The €5,000/dwelling·yr liquidity cap does NOT clash (worst-period outlay
≈ €700/dwelling·yr at σ = 0). Any reno_scale < 1 or tighter capacity
sensitivity makes the obligation INFEASIBLE — options reported to the user,
nothing resolved unilaterally (per the order).

**(B) `public_tenant_weight` w (default 0.0).** The public landlord's
objective gains + w × (tenant energy bill + carbon cost + rent increase),
the same fuel/CO₂ terms as `annual_bill`, discounted like the other landlord
terms (disc_ll). w = 0 reproduces committed behaviour bit-identically; at
w = 1 the rent increase cancels against the landlord's rent income. Private
landlords unchanged (always w = 0). KNOWN INDETERMINACY, recorded: at w = 1
rent_inc has objective coefficient 0 — the optimizer may return any feasible
rent level, so reported tenant costs at w = 1 are solver-arbitrary (not
resolved; needs a user decision on the rent convention at w = 1).

**New scenarios (defined, NOT run):** `pub_w00`, `pub_w05`, `pub_w10`
(w = 0/0.5/1, EED off) and `eed_pub_w00`, `eed_pub_w05`, `eed_pub_w10`
(the same with EED on). All tenure_enabled=true, rule_PL defaults,
affordability off — the (A)×(B) evaluation grid of the order. Note for
future runs: with EED on, the σ = 0 zero-subsidy affordability REFERENCE
also carries the obligation (the legal duty exists without the programme) —
correct reading, but it changes what "no-programme cost" means there.

**Validation/tests (written; runs NOT ordered):** config check fails loudly
(w ∉ [0,1], either switch without tenure_enabled); syntax-only parse check
of the edited files (Meta.parseall, no model execution) — result recorded in
the session report; new `test_switches_off.jl` — loads the model with
P4_SKIP_SEARCH=1, asserts both defaults OFF, re-evaluates the committed
subsidies.csv design and compares spending/equity/WPB/E2050 against the
committed policy_kpis.csv (run it for `baseline` and `tenure_on`, one
process each). PROVENANCE.md: new "Scenario switches" section.

**NOTE on line citations:** these insertions shift the model file's line
numbers below ~:216 again — the `:NNN` citations in data/PROVENANCE.md
(last updated 2026-10-13, commit 2ce6968) are stale below that point.
Update not ordered; flagged.

**Hypotheses — recorded BEFORE any run:**
- **H12**: with EED on and w = 0, public-rental deep-envelope uptake at 2050
  jumps from 5.4% (tenure_on) to the forced 72%; at fixed subsidy rates the
  landlord bears it mostly unsubsidised (apply decision may flip), and the
  public tenant's warm rent RISES via the ρ_public = 0.02 pass-through.
- **H13**: raising w at fixed rates weakly increases public-landlord uptake
  even without the obligation (w internalises the tenant's energy saving);
  at w = 1 the split incentive is gone and uptake approaches the
  owner-occupier pattern, subject to the €5,000 liquidity cap.

## Poland-only reporting + next-round run list (2026-10-12, user order; NO runs)

Paper decision: Poland-only; rule_DE (§559 BGB) must not appear in any
reported result. Reporting-only changes made (rule_DE CODE and all 50
run outputs untouched):
- Table 4: `s4_rule_de`/`s4f_rule_de` rows dropped from
  `table4_institutional.jl`; "German cap" wording → "3 EUR/m2/yr cap";
  regenerated (10 rows).
- Figure 6: rule_DE line + German title clause dropped from
  `make_figure6.py`; regenerated (PL vs none).
- Table 5: collector restricted to the Polish frame — ρ 0.10, no cap,
  {recovery, permanent} × {net, gross} (8 of 48 runs); regenerated.
  NEW chosen rule per zero_subsidy block: ρ 0.10/no cap/RECOVERY
  (= rule_PL exactly), tied with permanent at €2.8846M, recovery wins
  the pre-registered levy tie-break (€563 vs €1,788); frozen blocks
  still NONE FEASIBLE. The old 12-rule result (ρ0.05+cap3+recovery by
  tie-break) is kept in README as the H11 historical record.
- Figures 2/3: stale "§559 BGB placeholders pending Polish rent law" +
  "shares/incomes are placeholders" footers replaced with the wave-9
  rule_PL/sourced wording; regenerated.
- README: Table 4/5 + Figure 6 sections and ledger rows updated; S2 and
  Figure 4 ledger rows marked NOT paper-reportable (rule_DE frame) with
  the Polish re-pin queued. NOTE: `lldisc4_rule_de` has NO README ledger
  row to drop — it is recorded only in the CHANGELOG §3d entry
  (pre-existing ledger gap, flagged); it is simply not reported.
- Figure 4 remains DE-framed of record until the S2 re-pin runs.

**Run list for the next round — PRE-REGISTERED, NOT STARTED** (the round
will also include the stock rescaling, which needs its own packet):
1. `E1_baseline_rates_tenure_nopass` (new): E1 fixed-rates evaluation
   (certified D0 rates, no re-optimisation) with private ρ = 0.00,
   counterpart to `E1_baseline_rates_tenure_on` — gives the rule_PL vs
   no-pass-through uptake comparison at identical subsidy rates.
2. S2 sweep re-pinned to the Polish frame (no cap, levy until recovery;
   public 0.02; ρ swept 0.00–0.10): `s2pl_ptr00..10` (7),
   `s2f` analogues (7) + `s2pl_ptr05_nopv` (1) = 15 runs; Figure 4
   rebuilt from these.
   AMENDMENT 2026-10-13 (recorded BEFORE any run, user-reviewed): the
   nopv diagnostic is defined as `s2fpl_ptr05_nopv` — FROZEN-STOCK
   frame, matching the original `s2f_ptr05_nopv` whose ρ=0.05 PV-base
   spike is a frozen-frame phenomenon. The line above wrote
   "s2pl_ptr05_nopv" (zero-subsidy frame) in error; run count stays 15.
   The frozen analogues are named `s2fpl_ptr00..10`.
3. Everything the stock rescaling order will list (not yet defined).
Scenario definitions for 1–2 are NOT yet in the model file (no model
edits while the D4 re-certification chain is running); they are added
when the round is ordered.

## Input provenance documented (2026-10-12, user order, documentation only)

New file `data/PROVENANCE.md`: every input in `archetypes_v2.csv`,
`measures_v2.csv`, `context.csv` + the in-code capacity rates
(model `:926-935`) and other hard-coded numerics, each labelled
sourced / derived (with calculation) / assumed / no source. Honest
outcome: most stock and cost numbers are stylised with NO recorded
source; genuinely sourced or supported are the electricity-PEF base
(Dz.U. 2023 poz. 697, in-code), the HP reduction 0.67 (1−1/SCOP 3.0),
the liquidity-cap rationale (GUS/NBP), equity 0.30 (EPBD Art. 17(18)/
SCF), EPBD 90-target and capacity rates (DSRB-informed, session
notes). Also recorded: `energy_price`/`co2_factor` in context.csv are
UNUSED legacy columns. CORRECTION of the 2026-10-12 inspection report
(user caught it): per-archetype fraction caps DO bound national
activity at the same aggregate rate (Σ_a y_a·dwell_a ≤ rate·Σ_a
dwell_a); the earlier claim that effective capacity "grows with
archetype disaggregation" was wrong. The caps are TIGHTER than one
national pool (no reallocation across archetypes), and an absolute
dwellings/yr industry ceiling still has no representation. No model
or data file touched; no runs.

## D4 re-certification LANDED (2026-10-12, 13:20–16:19) — hypothesis confirmed

Run finished clean (exit 0, ~3.0 h wall: 13:20:50 → 16:19:16; poor side
10,376 s for 39,688 σ-vectors, rich 228 s, landlord sides 2 s each; cross
product 4.80e9 combinations in 4.3 s). Log:
`results/cert_logs/cert_D4_tenure_on.log` (wave-9 certificate of record).

**Result — exactly the pre-registered hypothesis**: certified grid optimum
€3.998M at the D0 design (env 0/10/10 both income groups, HVAC 0/0) +
landlord rates 0/0; joint re-evaluation feasible, spending matches; CCG
heuristic €2.885M lies −38.6% BELOW the grid optimum (continuous rates
between grid points). The entire certified block is character-identical to
the archived wave-8 certificate
(`cert_D4_tenure_on_wave8shares_20261010.log`), including the affordability
side report (poor side: 1,053 of 39,688 σ-vectors violate, reported only —
expected, since incomes were already wave-8-sourced and only shares/split
changed). No deviation, nothing tuned.

**Flag closed**: `table2_tenure.jl` D4 label → "re-certified 2026-10-12 on
the wave-9 shares; first 2026-10-10", staleness NOTE removed (the row-level
placeholder flag `Y` stays — it marks ρ-public 0.02 open + derived share,
not the certificate). Table 2 regenerated — all numbers unchanged vs the
committed CSV, only the D4 certification label changed. Ledger row 47,
Table 2 section intro + D4 row, and the baseline certification-status
paragraph updated in `results/README.md` (D0/D2/D3 wave-9 re-certification
remains open, not ordered). No model code, data, or other scenario touched.

## D4 re-certification vs wave-9 inputs — ORDERED, PRE-REGISTERED (2026-10-12)

User order (explicit, 2026-10-12): re-certify D4 (`tenure_on`) against the
wave-9 inputs; scope D4 ONLY, no other change authorised. This closes the
staleness flag recorded in the wave-9 pre-registration ("tonight's D4
certificate pins the wave-8 shares/split") and carried in Table 2 and the
ledger.

**Preconditions verified before launch** (2026-10-12): HEAD = d445aae; the
only non-output file differing from the commit is the legacy root
`model_bilevel.jl` (pre-existing, uncommitted per NOTES.md; not used here).
`out/scenarios/tenure_on/` matches the committed wave-9 solve bit-identically
in all numbers (worktree diff = timestamp/git-stamp/elapsed-time only;
spending 2.884618424124881e6 identical); its `config_used.txt` carries the
wave-9 inputs: incomes 9,635/23,761, shares 0.082/0.08, rich split 0.84,
rule_PL (ρ public 0.02 / private 0.10, recovery, uncapped). Certification
tooling unchanged since the 2026-10-10 certificates (`enumerate_exact.jl`
last modified in wave 8; `run_d4_cert.sh` untouched) — identical invocation
`enumerate_exact.jl 0.1 tenure_on 0.1` (10% owner grid, 10% landlord grid,
same solver settings/tolerances). No inputs regenerated or modified.

**Old certificate archived, not deleted**: `cert_D4_tenure_on.log` (wave-8
shares, finished 2026-10-10 04:43) →
`results/cert_logs/cert_D4_tenure_on_wave8shares_20261010.log`.

**Hypothesis (recorded BEFORE the run)**: the certified grid optimum is
unchanged — spending €3.998M at the D0 design (env 0/10/10 both income
groups, HVAC 0/0) + landlord rates 0/0. Grounds: (i) E1's evaluation of the
certified D0 rates under the wave-9 data already reproduced €3.998M spending;
(ii) the wave-9 heuristic D4 reproduced the wave-8 spending bit-identically
despite the share change, so spending at these designs is insensitive to the
owner/renter re-weighting; (iii) certified designs are income-independent
(code check 2026-10-09). The CCG heuristic €2.885M should again lie BELOW
the grid optimum (continuous rates between grid points), gap ≈ −38.6%. If
the optimum, design, or landlord rates move, that is recorded as a finding;
nothing is tuned to recover this hypothesis.

## Wave 9 LANDED (2026-10-11, 15:58–19:10) — results of record

Full chain clean (`results/cert_logs/wave9.log`), all gates green first
(including both full-CCG rent-law pins under their pinned wave-8
configs — the data flip is proven non-destructive). All values below are
search bounds (CCG heuristic) under the wave-9 data: incomes 9,635 (Q1)
/ 23,761 (Q2–Q5 mean), shares 0.082/0.08, split 0.16/0.84, rule_PL
default. Comparators: wave-8 data runs (2026-10-08, and the 2026-10-09
rule_PL reruns where the rule matters).

**Pre-registered expectations: all met. No contradictions.**

- **Income-share wave MOVED (expected)**: infeasibility widens — s =
  0.10–0.12 all infeasible (wave 8: first feasible was s = 0.11);
  first feasible now **s = 0.13 at €33.26M**; s = 0.14 €29.02M;
  s = 0.15 **€9.1M → €23.38M** (×2.6); s = 0.20 €2.9M (at floor) →
  **€4.99M** (no longer at the floor); capacity-relaxed s = 0.10
  €27.1M → **€49.54M**. Driver: the low income falls 17%, so the
  s-budget s×income falls (s = 0.12 → €1,156/yr = exactly the old
  s = 0.10 budget).
- **S3 FINDING**: at s = 0.15 BOTH clawback points are now
  **infeasible** (wave 8: claw 25% +€4.6M, claw 50% +€11.7M,
  feasible). With Tablica-2 incomes a 25% clawback already breaks
  income-share 15% feasibility. Recorded as found.
- **Tenure wave unchanged in design and cost (expected)**: D4, D5,
  D5x scoped, D5x scoped-frozen all feasible at **€2.884618M**
  (landlord rates 0/0); D5 frozen-stock still infeasible;
  E2050 73.666 → 73.760 (share re-weighting). **d5_inc_signalnote =
  €2.884618M identical** — the income choice does not move the
  cost-neutral designs (incomes never enter that solve).
- **shares2x is the one spending move**: €2.8846M → **€10.66M**,
  E2050 74.77 (both shares2x variants). NOT directly comparable to the
  committed row: three things changed at once (doubled shares now
  0.164/0.16 vs 0.164/0.10, rule_PL default instead of rule_DE, split
  0.84). Recorded as found; decomposition not run (no order).
- **E1 (certified D0 rates)**: €3.998M, equity share 44.29%
  (unchanged); env-2050 owner low-income 0.4949 (was 0.4919), owner
  high-income 0.4257, public 0.05375 (unchanged), private 0.43599
  (unchanged — per-dwelling landlord behaviour does not depend on the
  shares).
- **Tenant costs (D5/E1, rule_PL, 2050): euros unchanged, ratios
  re-based** — bill €862→€494, levy €563, total €1,057 (= the
  zero-subsidy reference, exact cost-neutrality as before). Levy as %
  of income: low 4.87% → **5.84%**, high 1.57% → **2.37%**; total cost
  10.97% / 4.45% of the new incomes (was 9.14% / 2.94%).
- **Table 5 / H11 unchanged**: all 12 rules tie at €2.8846M under both
  bases (main reference); tie-break picks rho 0.05 + 3 €/m² cap +
  recovery; levy €189.5 = **1.97%** of the low income (was 1.6%); no
  landlord subsidy in any optimum; frozen-stock: none feasible.
- **S2**: spending flat €2.8846M across the sweep; the hump stands
  (private env-2050: 0.234 at ptr 0.05 vs 0.152 at 0.08/0.10,
  rule_DE frame pinned).
- Tables 2–5, household structure, Figures 1–6 regenerated; Figure 1 /
  Table 1 / Figure 5 inputs unchanged as expected (owner-only,
  income-independent). reproduce_all.sh extended to cover
  d5_inc_signalnote, the 48 l3 runs and Table 5 (they are ledgered),
  and its stale placeholder header updated. run_wave9.sh's stale
  "33,378" echo fixed post-hoc (the 15:58 log header shows the old
  string; the loaded value was 23,761 — verified in the gate logs and
  outputs).

## Wave 9 CORRECTION — high-income = Q2–Q5 mean (2026-10-11, ~15:55, user order)

User correction, received ~6 minutes after the first wave-9 launch
(chain still in the gates; NO scenario run had started — the whole
chain was stopped, process group killed, and is relaunched after this
edit, so every run sees the corrected value):

- **high-income = €23,761/yr**, mean of the Q2–Q5 annual household
  incomes (€16,332 / 19,802 / 22,693 / 33,378), weighted by POPULATION
  household count ∝ 1/household size (Tabl. 2 sizes 2.63 / 2.50 /
  2.26 / 1.97; each GUS quintile holds 20% of persons). Explicitly NOT
  weighted by surveyed household counts. Arithmetic check passed
  before loading: Σ(income/size) ÷ Σ(1/size) = 23,761.5 ≈ €23,761 ✓.
  Supersedes the packet's Q5 = €33,378 (which was loaded for ~6 min
  but never used by any run). This resolves the €23,761 discrepancy
  flagged 2026-10-09/-11.
- Source string recorded verbatim: "Mean of Q2–Q5, GUS HBS 2024
  tables (Tabl. 2 sizes, per-person income table), weighted by
  household count ∝ 1/size, FX 4.30".
- Display label "high-income (Q2–Q5)": applied in label_map.csv, the
  household-structure export, the spend-split output, and the Figure
  2/3 legends where the income group is named standalone; composite
  labels like "private rental (high-income tenant)" keep their short
  form, with "high-income = Q2–Q5 mean" defined in the same table's
  footnote (recorded interpretation — say so if every composite label
  should carry the qualifier too).
- Everything else stays as loaded (low-income €9,635, private share
  0.08, split 0.84). Gate pins and `d5_inc_signalnote` (11,560/35,920)
  unchanged. Stale strings fixed in the same pass: the model's tenure
  @warn (shares no longer "placeholder"), the income_share @info
  (Q5 wording), make_paper_tables incomes row (had the SIGNAL-NOTE
  values €11,560/€35,920), figure 4/6 captions ("incomes are
  placeholders (GUS pending)").
- Mechanical expectation update vs the pre-registration: high-income
  ratios now use €23,761, not €33,378 — e.g. the rule_PL 2050
  private-tenant cost of €1,057 would be 4.4% of the high-income
  tenant's income (was 2.9% at €35,920); levy €563 → 2.37%.

## Wave 9 LAUNCHED (2026-10-11, 15:48, detached — `run_wave9.sh`)

Certification wave 2 had landed (see entry above), so the pre-registered
edits were applied 2026-10-11: incomes 9,635/33,378 (Tablica 2 sizes),
private share 0.08 (derived, flagged), rich split 0.84 (AROP-based,
flagged); wave-8 values pinned in both repro-gate scenarios;
`d5_inc_signalnote` added; shares2x pins updated to (0.164, 0.16);
stale "[PLACEHOLDER incomes]" descr tags and the private-share/split
placeholder footnotes in the model footer and Tables 2–5 /
household-structure source strings updated to the sourced/derived/flag
wording. Load-check via P4_SKIP_SEARCH passed (new values and 16/84
split visible in the household-structure export; no config stamps
touched). High-income value note: the user's 2026-10-09 side message
mentioned €23,761, which is not in the model, the GUS report, or any
order — the packet's €33,378 (Q5) is loaded as ordered; the discrepancy
is flagged in the session report. Log: `results/cert_logs/wave9.log`.

## Wave 9 — final data load PRE-REGISTERED (2026-10-09, ~17:15, user order)

User order (pasted packet, 2026-10-09): load the decided values, to START
ONLY AFTER certification wave 2 lands (no model edits while the wave's
enumerations load the model file). Values as given by the user, loaded
verbatim, source strings recorded:

1. **Incomes** — Tablica 2 household sizes (3.00 / 1.97):
   low-income €9,635 (1,151 PLN/pers/mo × 3.00 × 12 ÷ 4.30),
   high-income €33,378 (6,071 × 1.97 × 12 ÷ 4.30). GUS "Budżety
   gospodarstw domowych w 2024 r.", Tablica 2 + Tablica 19, FX 4.30.
   The signal-note values (sizes 3.60 / 2.12 → €11,560 / €35,920)
   become a SENSITIVITY: new scenario `d5_inc_signalnote` (D5 config +
   old incomes).
2. **private_rich_tenant_share = 0.84** — Eurostat EU-SILC, AROP-based
   16/84, FLAGGED "AROP-based, not quintile-based". Replaces the 0.5
   placeholder.
3. **rented_private = 0.08** — derived as 0.05 × 14.1M households ÷
   8.61M MFH dwellings (Eurostat ilc_lvho02 RENT_MKT 5.0% of persons;
   GUS household count; Census 2021 MFH count), FLAGGED "derived,
   assumes market-rent tenants live in MFH". Replaces the 0.05
   placeholder.

**Planned edits** (defaults only; no scenario of record edited except
as listed): the three default values above + source comments; PIN the
wave-8 values explicitly in the two repro-gate scenarios
(`tenure_oldshares_test`: incomes 11,560/35,920 + rich split 0.5;
`tenure_newshares_test`: same + shares 0.082/0.05) — without this the
gates would silently evaluate the new data and fail their pins; add
`d5_inc_signalnote`; update the two `*_shares2x` pins from
(0.164, 0.10) to (0.164, 0.16) — their registered meaning is "rental
shares doubled", which under the new private share is 0.16 (flagged
for user veto in the report). All-off baseline untouched
(incomes/shares never enter it).

**Plan**: gates (invariants, affordability, tenure, rentlaw with both
full-CCG pins) → detached heuristic rerun chain `run_wave9.sh` of
everything income- or share-dependent: income-share wave (9 scenarios),
S3 (2), the full tenure wave as in wave 8 (D4, D5, D5-frozen, D5x
scoped ×2, shares2x ×2 — all share-dependent) + d5_inc_signalnote, E1,
S2 (15), S4 (12), L3 lite (48) → summaries, Tables 1–5 (Table 1 has no
generator and its inputs — claw/baseline owner runs — are neither
income- nor share-dependent: verified-unchanged is the expectation),
Figures 1–6, household structure
→ report what moved vs wave 8 → commit "Wave 9 — final data load",
re-stamp provenance, one reproduce_all.sh confirmation run → STOP (no
further model changes without an explicit order).

**Pre-registered expectations** (recorded before any wave-9 run):
- Cost-neutral and no-affordability designs (D4, D5, S2, S4, L3) do not
  use incomes in the solve; their spending should stay ≈ €2.8846M and
  designs should reproduce up to the share re-weighting. The share
  changes (0.05→0.08 private, 0.5→0.84 rich split) shrink the enforced
  low-income private-tenant stock (0.16 of private vs 0.50) and enlarge
  the private stock by 60%.
- Income-share wave and S3 WILL move: the low-income income falls 17%
  (11,560→9,635), so a 10% income-share budget drops €1,156→€964/yr —
  constraints bind harder; spending ↑ or feasibility worsens.
- Indicators move mechanically: the rule_PL 2050 private-tenant cost
  €1,057/yr was 9.1% of €11,560 → ≈11.0% of €9,635 if euros are
  unchanged; high-income ratios rise ~7.6%.
- E1 equity/uptake re-weight with the new split; certified designs
  themselves are income-independent (confirmed from code 2026-10-09).
- STALENESS FLAG, recorded now: tonight's D4 certificate pins the
  wave-8 shares/split; after wave 9 it certifies rule_PL on wave-8
  structure, not wave-9. Table 2 must say so; a wave-9 re-certification
  is NOT started (no order).
- NOT rerun (user list governs): claw_p* (income-independent, owner
  archetypes only), lldisc4_*, E2 diagnostics — their stored outputs
  remain wave-8 runs and stay flagged as pre-wave-9 where tabled.

## GUS BGD 2024 tables downloaded — income check PARTLY FAILS (2026-10-09)

Order: download the BGD 2024 XLSX tables, report Q1–Q5 persons per
household and monthly disposable income per person from Table 2,
compute annual EUR household incomes (FX 4.30), check Q1/Q5 reproduce
€11,560/€35,920. Report only; nothing loaded. Source:
budzety_gospodarstw_domowych_2024_tablice.zip, stat.gov.pl page 9,23,
downloaded 2026-10-09; raw files in scratchpad (gus_bgd/).

Values as downloaded: persons per household (Tablica 2): Q1 3.00,
Q2 2.63, Q3 2.50, Q4 2.26, Q5 1.97. Monthly "dochód rozporządzalny"
PLN/person (Tablica 19 — Table 2 carries no income rows; the
income-by-quintile lines live in Tablica 19): Q1 1,150.86, Q2 2,225.17,
Q3 2,838.28, Q4 3,598.00, Q5 6,071.28.

**Check result:** the per-person incomes CONFIRM the 2026-10-08 note
exactly (1,151 / 6,071). The household sizes DO NOT: the note's
derivation used 3.60 (Q1) and 2.12 (Q5) persons, which reproduce
€11,562 / €35,919 ✓ arithmetically — but Tablica 2 gives 3.00 / 1.97,
yielding **€9,635 (Q1) and €33,378 (Q5)**. The 3.60/2.12 factors are
not found in the downloaded tables (not persons, not fed persons, not
consumption or equivalent units). Recorded as a source discrepancy for
the user to resolve; config values NOT changed (load-as-given rule).

Computed annual EUR household incomes from the downloaded values:
Q1 9,635; Q2 16,332; Q3 19,802; Q4 22,693; Q5 33,378. Mean Q2–Q5:
23,051 unweighted / 23,969 weighted; mean Q3–Q5: 25,291 unweighted /
25,917 weighted. Weighting caveat: Tablica 2 gives only SURVEYED
household counts (4,284/4,891/5,567/6,316/7,292 — sample sizes, not
population household numbers), so the weighted means use those as a
proxy, flagged as such.

## DECISION — rule_PL becomes the default rent rule (2026-10-09, user order)

User decision: "the paper's 'current law' case is the Polish rule."
Default private rent rule flips from the German §559 placeholder to the
sourced Polish Art. 8a values: private ρ 0.10, no cap (1.0e6 sentinel),
levy until recovery, base net of grants; public 0.02 stays an open
placeholder. rule_DE remains an S4 comparison rule only. This RESOLVES
the 2026-10-08 recorded deviation (default "permanent" was chosen then
so committed scenarios would not be silently redefined) — now the
redefinition is explicit, user-ordered and documented.

Planned edits (recorded before making them):
- scen() defaults: pass_through_rate_by_landlord private 0.08 → 0.10;
  rent_increase_cap_per_m2 3.0 → 1.0e6; pass_through_years "permanent"
  → "recovery". passthrough_base_net_of_grants stays true.
- Every scenario whose MEANING depends on the old German defaults gets
  them pinned EXPLICITLY so nothing is silently redefined: s4_rule_de
  (the German comparison rule), tenure_oldshares_test and
  tenure_newshares_test (the repro-gate pins reproduce rule_DE-era
  results and must keep that config), the S2 sweeps s2_*/s2f_* (a
  German-rule pass-through sweep, results of record 2026-10-08), and
  the tenure test scenarios where they rely on cap/duration defaults.
- The L3-lite l3_* scenarios set every rent-law key explicitly already;
  unaffected. Owner-only scenarios (baseline, D0–D3, income-share wave)
  never instantiate landlords; bit-identical by construction.
- Model edit waits until the L3 chain stops spawning model subprocesses;
  gates (tenure, rentlaw t5t6/twins/invariance incl. both full-CCG pins,
  invariants) run before any rerun. Certification wave 2's D4 slot
  (enumeration starts hours from now, loads the model at its start)
  will thereby certify D4 UNDER RULE_PL — exactly the ordered "add D4
  to tonight's certification queue"; no separate rule_DE certificate is
  needed since rule_DE is comparison-only now.
- Added to the same edit window (user, 2026-10-09 afternoon): (i) the
  model skips writing config_used.txt when P4_SKIP_SEARCH=1, so stamps
  only change when a run does (fixes the quirk that test/export loads
  re-stamped tenure_afford's timestamp); (ii) Table 2's D4 status label
  states the rule explicitly — "search bound — rule_PL certification
  running" until the wave-2 D4 enumeration lands, then "certified 10%
  grid under rule_PL (2026-10-09)".

**Expectations recorded BEFORE the reruns** (all derivable from the S4
wave-8 runs, which already solved these exact configurations): D4-PL =
s4_rule_pl minus the affordability constraint → spending €2.8846M,
landlord rates 0/0, E2050 ≈ 73.67; D5-PL zero_subsidy = s4_rule_pl →
feasible, €2.8846M, affordability gap 0; D5-PL frozen_stock =
s4f_rule_pl → INFEASIBLE; E1-PL: private envelope uptake 2050 ≈ 44%
(vs 15% under rule_DE), public 5.4%, low-income owners ≈ 43%,
spending €3.998M (evaluation at certified D0 rates). Deviations from
these will be recorded as findings.

## Eurostat tenure-by-income downloaded, NOT loaded (2026-10-09, user order)

Order: download (not estimate) ilc_lvho02 geo=PL unit=PC hhcomp=TOTAL,
latest year, tenure {OWN, RENT_MKT, RENT_FR} × income {TOTAL, below,
above 60% median}, plus ilc_li02 for the AROP weighting; report first,
do not load. API note: the live API's income dimension is `rskpovth`
(TOTAL/B_60/A_60), matching the ordered incgrp codes; the modernised
ilc_li02 encodes the ordered indic_il=LI_R_MD60 as statinfo=MED_EI +
rskpovth=B_60 + unit=PC. Latest year with values: **2025** (survey
year; income reference 2024). Values stored with dataset code, filters,
year and download date (2026-10-09) in `eurostat_tenure_income_PL.csv`;
raw JSON responses archived in results/_scratch/eurostat_raw/.
- (1) RENT_MKT share, total population: **5.0%** of persons.
- (2) RENT_MKT share below / above 60% of median: **6.1% / 4.8%**.
- (3) AROP rate (ilc_li02, 60% median, 2025): 13.2% → share of
  market-rent tenants below 60% of median = 6.1×0.132 /
  (6.1×0.132 + 4.8×0.868) = **16.2%**. Consistency: the implied total
  (4.97%) matches the published 5.0% up to rounding.
- NOT loaded into the model (report-first order). Open mapping
  decisions before loading: persons (Eurostat) vs MFH-dwelling shares
  (model); AROP below/above-60%-median split vs the model's Q1/Q5
  income classes (the current 50/50 placeholder would become ~16/84
  only under an AROP reading).
- Cooperative assumption source string updated in the README as
  ordered: "EU-SILC counts cooperative ownership as owner-occupancy
  for Poland (OECD Affordable Housing Database, HM1.3)".

## Relabel "poor/rich" → "low-income/high-income" (2026-10-09, user order)

User-facing text only; internal config keys, variable names, scenario
names, archetype ids and CSV join keys are UNCHANGED (protecting the
tests and reproducibility gates, as ordered). One mapping dictionary
`label_map.csv` is the single source; output scripts read it or carry
the mapped literals with a pointer to it. Changed: Table 2 headers
(`env2050_owner_low_income` etc.) and rate-string suffixes; Table 3
`group` column now the display label with the stable key kept in a new
`group_key` column (figure 3 matches on `group_key`); Table 4 levy-%-
income headers; Table 1 CSV headers (stored file, no generator script);
figure 1/2/5 titles, legends and axis labels; README display text
(archetype keys left literal). Tables 1–4 and Figures 1–6 regenerated
with labels only — **float-level comparison against the committed
versions confirms every number identical** (65/104/63/104 floats in
Tables 2/3/4/figure3-data; Table 1 digits identical). New entries in
this file use the new terms from here on; older entries stay as
written. DEFERRED to the next safe model-edit window (two detached
chains re-include the model): the model's own @info/@warn log messages,
and the Table 5 collector labels (the running L3 chain executes that
script at its end).

## Household structure export (2026-10-09, user order)

`household_structure.jl` exports results/household_structure.csv — one
row per loaded follower archetype with group, heating, decision-maker,
bill payer, income group + sourced €/yr, parent archetype, dwelling
share + source string (placeholders flagged), liquidity cap and
affordability-enforcement flag — built from the model's own globals
after the tenure_afford (D5) config is applied, never from docs. Added
to reproduce_all.sh stage 7; Markdown copy + ledger row in
results/README.md. Answer recorded: rented variants are split from ALL
FOUR MFH owner archetypes (the "rich/poor" in the parent key is the
parent building's owner-income class; tenant income is set by the
variant — public and private-poor variants low-income, the
`_rent_priv_rich` twin high-income).

## Level 3 lite — rent rule as a leader choice (2026-10-09, user order)

Order: "rent rule as a discrete leader choice — rate {0.05, 0.08, 0.10}
× cap {none, 3 €/m²} × duration {recovery, permanent} — chosen jointly
with subsidy rates, minimising public spending under EPBD +
affordability (poor tenants, both references), under base net and
gross. Heuristic only. Output: Table 5 = chosen rule, spending, private
renovation share, poor-tenant peak levy and % of income, per reference
× base."

Design: outer enumeration of the 12 discrete rules (the rule is leader-
chosen but discrete, so "jointly" = run the CCG subsidy-rate heuristic
per rule and take the spending-minimal feasible rule — exact over the
rule grid, heuristic in the rates). 48 scenarios generated
programmatically (`l3_r{05,08,10}_{capn,cap3}_{rec,perm}_{net,gross}_{zs,fs}`),
D5 configuration (cost-neutral affordability, scope all = poor owners +
poor tenants, rich twin indicators only), public landlord 0.02
throughout. **Tie-break recorded BEFORE runs:** min spending; among
spending ties the lowest poor-tenant PEAK levy; residual ties
lexicographic (lower rate, cap3 before none, recovery before
permanent). Full 12-rule grid stored per reference × base
(`results/_scratch/l3lite_grid.csv`); Table 5 reports the chosen row
and the tie count.

**H11 pre-registered (user, verbatim):** "a capped, permanent rule is
chosen; under gross base a landlord subsidy enters the optimum."

**Model-side priors, written down a priori (from S4/E2, before runs):**
under the zero_subsidy reference every S4 rule was feasible at the
€2.8846M floor with zero affordability gap, so ALL 12 rules may tie at
minimum spending — then the "chosen" rule follows from the
pre-registered tie-break, not from strict preference, and the report
must say so. Under the frozen_stock reference every positive
pass-through S4 rule was infeasible at fixed rules; the leader now also
holds landlord grants, which under NET base + recovery are
acceptance-neutral (E2) and at high rates can shrink the levy base —
feasibility MAY be restorable there; under gross base grants do not
reduce the levy, so frozen gross rows are expected infeasible. If the
runs contradict any of this, the contradiction is recorded as a
finding; parameters are not tuned.

## Certification wave 2 launched (2026-10-09, 13:52, detached)

User order: re-certify the 10% grid under the sourced data before
anything is submitted. `run_cert_wave2.sh`: D0, D2, D3 (0.1 grid), D4
(0.1 grid, landlord rates 0.1 step) sequentially, ~10 h, detached; log
`results/cert_logs/cert_wave2.log`. The 2026-10-01 pre-sourced
certificate logs are ARCHIVED (not deleted) to
`results/cert_logs/archive_pre_sourced/` — they remain the certificates
of the old-data configuration. Note recorded before results: D0/D2/D3
optimise owner-only cost-neutral designs that the sourced incomes and
public share do not enter, so their certified values are EXPECTED
unchanged (the rerun refreshes the pinned config/provenance); D4 is the
one whose data actually changed (share 0.082 + rich twin) — expected,
from the wave-8 heuristic, to return the same grid optimum €3.998M with
landlord rates 0, but that is exactly what the certificate must now
prove. Tree state at launch: commit 4189042 + uncommitted E2/stamp/
bookkeeping edits (recorded in each cert's config_used).

## Paper inputs (2026-10-09, evening, user order "P4 — paper inputs")

Reported per part in the session reply; repository changes recorded here.
No model edit (two detached chains, cert wave 2 and L3 lite, re-include
the model file; the safe-edit window is after L3 lite ends). Nothing was
re-solved with a leader; two FOLLOWER-ONLY evaluations were run at the
D0-certified rates (env medium+deep 10/10, HVAC 0, landlord 0):
- `results/_scratch/cert_design_eval_summary.csv` (baseline config):
  spending €3.998M, E2050 72.4, equity 44.3%, **WPB share 81.4%**
  (2.c; the certification log prints no WPB line).
- `results/_scratch/e1_rule_pl_*.csv` (s4_rule_pl config = E1 under the
  Polish rule, 2.a): feasible, €3.998M, E2050 73.7; envelope 2050
  public rental 5.4%, private rental 43.6%, low-income owners 43.5% of
  dwellings (49.2% of floor area). Landlord responses are identical to
  the s4_rule_pl optimum by separability (landlord rates 0 in both).
  Side effect: both evaluations rewrite `config_used.txt` of the
  baseline / s4_rule_pl run folders (timestamp + tree state only).
- `make_paper_tables.py` → `results/paper_tables/{measures,parameters,
  model_structure}.{csv,tex}`: values as loaded with the source string
  stored next to them; "not in model" where none is stored (measure
  costs/savings/lifetimes, discount rate, CO₂ path, energy prices,
  EPBD trajectory carry NO source string in config). Found: context.csv
  columns energy_price (0.35) and co2_factor (0.2) are not referenced by
  the model; the 2020 stock average is 217.1 kWh/m²a (221 is not a
  model value).
- `make_paper_figures.py` → `results/paper_figures/fig{2..5}_*.{pdf,png}`
  + data CSVs (TU Wien blue + greys, Carlito, one axis per panel; Fig 5
  replaces the dual-axis Figure 5 with two single-axis panels and adds
  the S3 regime). No re-solving.
- 2.b clarified: the "7.1% vs 2.3%" figure (Table 3) is the TOTAL 2050
  tenant cost (bill + levy) ÷ income under rule_DE (D5/E1, German rule);
  Table 4's 4.9% is the LEVY ONLY ÷ income at the peak year under
  rule_PL. Different quantity, rule and year.
- Open for the user's separate decision message (part 1): the 16/84
  private-tenant split — load 0.838 (= 1 − 0.162 as stored) or 0.84 as
  written; and whether the private share 0.05 is now to be labelled
  sourced (Eurostat RENT_MKT 5.0% of persons) or stays a placeholder.

## DECISION CHANGE — rich private tenant (2026-10-08, user/Lukas)

Supersedes decision 5 of 2026-10-01 ("tenant is always poor; no
rich-tenant archetype"). New rule:
- Add `rented_private_rich`: private rental only, income = Q5 household
  income from the GUS note (€35,920/yr), same building physics and the
  SAME landlord (type, pass-through rule, subsidy instrument σ12) as
  `rented_private`. NO rich public tenant.
- Affordability constraint ENFORCED for poor tenants only; the rich
  tenant is reported with two indicators: cost change vs reference and
  cost-to-income share.
- Private-rental stock split poor/rich tenants: **50/50 PLACEHOLDER,
  flagged open** until Eurostat tenure-by-income (EU-SILC) is in
  (config key `private_rich_tenant_share=0.5`; 0.0 reproduces the old
  single-poor-tenant structure).
- Outputs: Table 3 row + Figure 3 bar for the rich tenant; Table 4
  gains "levy as % of income, poor vs rich tenant".
- Reruns ordered: D5, S2 (frozen stock), S4 — heuristic.
- **Test ordered:** the landlord problem is UNCHANGED by the split —
  same solution as before the archetype (per-building decisions cannot
  depend on tenant income; the poor/rich twins must behave identically
  and the committed aggregates must reproduce). Comparison baseline =
  the COMMITTED pre-archetype results (commit 2b5f3fa) via the
  `tenure_oldshares_test` invariance case; the pre-archetype S4 chain
  never produced runs (it stopped at its gate on a test-driver bug and
  then on a mis-pinned value, both fixed) and S4 runs once, in wave 8.

Expectations recorded before the runs: (i) landlord invariance holds
(the tenant's income never enters the landlord objective); (ii) the
levy in € is identical for the poor and the rich tenant of the same
building, so the %-of-income indicator differs only by the income
ratio 11,560/35,920 ≈ 0.32; (iii) D5 feasibility verdicts unchanged.

## GUS incomes and tenure (2026-10-08, second user source note)

**A. Incomes LOADED (GUS, Budżety gospodarstw domowych w 2024 r.;
Informacja sygnalna 29 May 2025, stat.gov.pl).** Derivations verbatim
from the note (PLN/person/month × persons × 12 ÷ FX):
- poor = Q1: 1,151 × 3.60 × 12 = 49,723 PLN/yr ≈ **€11,560/yr** (loaded
  11560.0; exact quotient 11,563.5 — the note's rounded value is used).
- rich = Q5: 6,071 × 2.12 × 12 = 154,446 PLN/yr ≈ **€35,920/yr** (loaded
  35920.0).
- FX pinned: **4.30 PLN/EUR** (2024 annual average, rounded, per the
  note; written in the config comment).
- **Mapping decision (recorded as the note requires):** rich = Q5. The
  model's rich class is "all non-poor", for which the note's better
  match is the Q3–Q5 average — but that value is OPEN (needs Q3/Q4
  household sizes from the XLSX tables) and the note forbids using the
  rough €28–30k without them. Q5 is loaded meanwhile; the choice is
  expected to be immaterial for income-share results because the rich
  threshold is slack by a wide margin (to be confirmed in the rerun and
  reported).
- Household sizes for Q2–Q4: OPEN (not in the signal note).

**H10 (pre-registered before the rerun, from the note's expectation):**
the s = 0.10 threshold rises from €900 to ≈ €1,156/yr, so feasibility
at s = 0.10 may change — the rerun is reported against that
expectation. Context cited, not loaded: Q1 expenditure exceeds income
(113.2%), average energy share of income ≈ 6.3%.

**B. Tenure shares — PARTIALLY BLOCKED, reported not guessed.** The
note's recipe for the public-landlord share of MFH is
(595,800 municipal units 2024 + TBS from the 2024 M-01 table) ÷
Census-based MFH dwelling count. Two numbers are missing: (1) the TBS
count is not in the note; (2) there is NO Census-based MFH count in
the stock data — archetypes_v2.csv is a stylised miniature (9,650
dwellings), not a Poland-scaled stock, and no repo document carries
the real MFH count. Loading a share would require outside research or
inference, which both notes forbid. Therefore:
- `tenure_share_by_archetype` stays (public 0.10, private 0.05),
  PLACEHOLDER, with the sourced RAW figures recorded in the README
  (total stock 15.97 M; municipal 595,800 ≈ 3.7% of the stock; 2020
  breakdown: municipal 5.4%, cooperatives 13.2%, natural persons
  80.0%).
- The ordered D4/D5/S2 rerun with the sourced public share is BLOCKED
  on those two numbers; formula ready to apply the moment they arrive.
- Cooperatives → owner-occupied MFH recorded as the ASSUMPTION (the
  cooperative renovates with member consent; costs are a member
  charge, not a levy); split-to-public sensitivity to be decided with
  Lukas (note: open).
- Private rental share: OPEN (Eurostat EU-SILC ilc_lvho02 or Census
  2021 pending); S2 + shares-×2 showed findings are insensitive to it.

**C.** Energy-poverty line s stays a reported sweep {0.10, 0.15, 0.20}
(the 10% line is a choice, not data; GUS shares cited as context).

**D. Rerun plan (incomes only):** gates (A1, tenure, invariants,
rent-law incl. repro), then afford_incshare, afford_incshare_only,
s11–s15, s20, s10_capacity_relaxed, SFH split diagnostic, sweep
summary, S3 (s15 + claw25/50) + s3_summary; Table 1 income-share rows
and the S3 row regenerated; results reported against H10. Previous
income-share outputs (placeholder €9,000/€30,000) are superseded and
say so in the ledger.

## Run-plan additions (2026-09-30, evening)

**Added.** Income-share affordability made runnable with pinned placeholder
incomes; end-state-only application; per-run configuration dump; overnight
certification queue.

**Config keys**: `household_income_by_class` placeholder values set to
(poor €9,000, rich €30,000) per household per YEAR, disposable, PLN 4.30/EUR —
GUS to replace (a loud warning prints on every income_share run);
`affordability_periods` = `"all"` (default, baseline-neutral) / `"final"`
(constraint on the period ending 2050 only — how income_share is applied).
New scenarios: `afford_incshare` (s=0.10 + floor), `afford_incshare_only`
(s=0.10, no floor), `afford_incshare_s15`, `afford_incshare_s20`.
Every run now writes `config_used.txt` (scenario, full NamedTuple, Julia
version, git commit, timestamp) into its output folder.

**Energy-poverty pre-check (recorded before the income_share runs).** In the
reference case the 10% indicator is already violated: SFH_poor heats for 20%
of placeholder income in 2030 and 39% by 2050; MFH_poor_fossil 17%; only
MFH_poor_dh is below 10%. Reference feasibility would need s ≈ 0.39. Finding,
not bug: the poor coal stock starts in energy poverty by this indicator.

**Queued overnight** (`run_tonight.sh`, logs in `results/cert_logs/`):
baseline heuristic regression gate → 4 income-share runs → certified 10%-grid
enumeration D0 (gate: must equal €3.998M, else stop) → D2 → D3.

**Tested**: gates run tonight; nothing else changed on the baseline path
(new keys default to baseline-neutral values).

## s = 0.10 diagnostics queued (2026-09-30, late evening)

Requested diagnostics for the infeasible income-share 10% case, heuristic
only, auto-starting after the certification queue (`diag_after_queue.sh`,
watcher running; log `results/cert_logs/diagnostics.log`):
1. `afford_incshare_s10_capacity_relaxed` — s = 0.10 with `reno_scale = 100`
   (per-period adoption caps ≈ 1): does feasibility return, at what spending?
2. `diag_sfh_split.jl` — SFH_poor at 2050 under σ = caps: renovated shares
   and conditional heating bills (heat-pump vs still-fossil vs untouched
   dwelling; proportional-mixing attribution caveat stated in the script).
3. Sweep s = 0.14 → 0.11 (scenarios `afford_incshare_s11..s14`) closing the
   0.15→0.10 gap in 0.01 steps; summary with failing-constraint tags per s
   → `results/_scratch/incshare_sweep_summary.csv`.
Also: infeasible runs now save their best-infeasible subsidy vector
(`best_infeasible_sigma.csv`). All outputs land in `results/_scratch/`
(diagnostics, §7) until promoted to reported findings.

## Level 1b — clawback (2026-10-01)

**What was added.** A share of the nominal subsidy can be lost to tax and
benefit rules before reaching the household. The follower now receives
σ × (1 − clawback) — this drives liquidity, private cost, and the
affordability check — while public spending counts the NOMINAL σ. With
`clawback_returns_to_budget` the clawed-back part is netted out of spending
instead (it returns to the state through taxes). Follower and leader now
price subsidies through separate functions (`fz` = received, `z_leader` =
paid); they coincide exactly at clawback zero, so the baseline is unchanged.
`investment_flows.csv` now reports `subsidy_paid_eur` and
`subsidy_received_eur` separately.

**Config keys**: `clawback_rate_by_class` (default poor 0.0, rich 0.0;
validated in [0,1)), `clawback_returns_to_budget` (default false).
Scenarios: `claw_p10` … `claw_p50` (S1 sweep; cost-neutral affordability +
spending floor on; clawback-0 point = `afford_neutral`), `claw_p50_returns`.

**Where implemented.** Follower subsidy pinning (effective rate); shared
`z_leader` used by `evaluate_σ`, the results section, and the enumeration's
`arch_response` — the certification path prices clawback identically.

**How tested** (gated in `run_s1.sh`, logs `results/cert_logs/`): the full
affordability suite (incl. exact baseline reproduction at clawback 0) and
the 38-check invariant suite must pass BEFORE any sweep run; H3 monotonicity
check (poor uptake must not rise with clawback) runs in `s1_summary.jl` and
flags violations as findings.

**S1 results — H3 CONTRADICTED, recorded as a finding (2026-10-01).**
Clawback on the poor class from 0 to 0.5 changes NOTHING: public spending
(€2.885M), poor envelope uptake (41.9%), equity share (61.4%), affordability
and floor status are identical at every sweep point (differences at solver
tolerance only). Clawback propagation verified in the outputs: at 0.5 the
poor receive exactly half of what the state pays, and their own annual cost
rises €7/yr (223→230). Interpretation: at the cost-minimal design the poor's
adoption is driven by the CO₂ price and the boiler ban, not by the small
subsidy margin, so halving the received subsidy moves no decision. H3's
predicted spending rise, uptake fall and affordability break did not occur;
parameters were NOT tuned to recover it. Returns-to-budget variant at 0.5:
booked spending falls to €2.0M (accounting only; design and uptake unchanged;
changes no conclusion). Caveat: search bounds; certified sweep not run.

**Gate incident (recorded for transparency).** The A1 baseline-reproduction
gate stopped the first S1 chain: spending is now computed arithmetically as
σ·y (`z_leader`) instead of reading the solver's z variable, and the two
differ by Gurobi's constraint tolerance — €0.23 on €2.9M (8×10⁻⁸ relative)
at clawback 0. Not a behaviour change. Test tolerance set to 1×10⁻⁷ relative
(≈ €0.30) in `test_affordability.jl` and `run_tonight.sh`, with the reason
documented in both; anything tighter tests the solver, not the model.

**H3 final verdict (user-confirmed, 2026-10-01): CONTRADICTED, with the
conditional reading** — clawback is irrelevant where subsidies are residual.
At the Polish cost-minimum the CO₂ price and the boiler ban do the work and
the subsidy is a residual instrument, so taxing it back moves nothing. The
result is conditional on that regime: where subsidies carry the adoption
(income-share designs, €29M+), clawback is expected to bite. That conditional
is tested directly by S3 (below).

**S3 queued (user request, 2026-10-01), to run after Level 2, heuristic only:**
clawback on the poor ∈ {0, 0.25, 0.5} × income-share constraint at s = 0.15,
leader re-optimising at each point. Report whether feasibility or spending
changes. This is the regime where the subsidy is NOT residual (€28.9M at
clawback 0), i.e. the direct test of the conditional reading of H3.

**Level 2 scope decision (user, 2026-10-01): the tenant is always poor.**
No rich-tenant archetype is created; rented variants exist only with a poor
tenant, and tenant costs enter the affordability constraint as poor-household
costs.

## Overnight results (2026-10-01, morning)

**Certification gates both passed.** Gate 1: heuristic baseline reproduces
`results/baseline/` exactly. Gate 2: D0 enumeration on the new code path
returned **€3.998M — identical to the parent repository's July value**, so the
Level 1a code changes provably did not move the certified baseline.

**Certified D0 = D2 = D3 (10% grid): €3.998M each, identical rates**
(envelope medium+deep 10% for BOTH income groups, all HVAC rates zero).
**H1 CONFIRMED at certified level**: both the 30% spending floor and the
cost-neutral affordability constraint are slack at the cost-minimum; all three
equity regimes select the same design. The known grid-vs-continuous gap stands
(search bound €2.885M below the 10%-grid certified €3.998M).

**s = 0.10 diagnostics (heuristic, placeholder incomes) — capacity, not
money, is the binding constraint:**
1. Sweep: feasibility breaks between s = 0.14 (feasible, €32.9M) and
   s = 0.13 (no design found); failing tag is always `afford` (sometimes with
   `eq`), never the energy trajectory.
2. **Capacity relaxed (reno_scale=100): s = 0.10 becomes FEASIBLE at €52.3M.**
3. SFH_poor split at 2050 under maximum subsidies (normal capacity): 52% of
   the stock is still on fossil heating (deep envelope 71%, HP 43%, DH 5%);
   a still-fossil dwelling costs €1,557/yr and an untouched one €3,500/yr vs
   the €900 limit, while a heat-pump dwelling sits at €904/yr. The archetype
   average (€1,248) fails because of the unrenovated remainder — confirming
   the capacity hypothesis. (Proportional-mixing attribution; heuristic.)

## Step 0 / Checkpoint 1 — setup and model map (2026-09-30)

**Added** (no model code changed):
- `bilevel_model_affordable_housing.jl`: exact copy of `../model_bilevel_260207_CCG.jl`
  (the verified July-2026 model). Byte-identical except nothing — no edits yet.
- Copies of the three inputs (`archetypes_v2.csv`, `measures_v2.csv`, `context.csv`).
- `enumerate_exact.jl`, `test_invariants.jl`: copied from parent, one-line patch each
  so they `include` this folder's model file instead of the parent's.
- `MODEL_MAP.md`: repository map (archetypes, follower, leader, certification, outputs,
  where parameters live).

**Config keys**: none yet. Plan decision recorded in MODEL_MAP.md: new switches will be
added to the `scen(...)` NamedTuple in `SCENARIO_DEFS`, defaults baseline-neutral.

**Tested**: Gurobi license renewed 2026-09-30 (expires 2027-09-30). Baseline
scenario run on the unmodified copy; all outputs frozen in `results/baseline/`
(run log included). Reproduces the parent repo's July-2026 baseline EXACTLY,
to the last printed digit: spending €2.8846186558583367M, E2050 = 72.39959310635848,
equity 61.39%, WPB 81.35%. This is the reference every later change with all
switches off must match.

**Placeholders needing real data**: none introduced yet (see plan §6 for the list
coming in Levels 1–2).

## Level 1a — outcome-based affordability constraint (2026-09-30)

**What was added.** A poor household's annual housing energy cost after the
programme (energy bill at that period's prices, fuel plus CO₂, plus the
annualised own contribution to renovation — capex net of subsidy, annuitised
over the measure lifetime while the annuity runs) can now be constrained.
The check sits in the leader problem only: it is applied to the follower's
response and makes a subsidy design infeasible if ANY poor archetype violates
it in ANY period. The follower problem is unchanged. Maintenance is not part
of the cost, following the plan's definition.

**Config keys** (all in the scenario NamedTuple, defaults reproduce baseline):
- `affordability_mode` — `"off"` (default) / `"cost_neutral"` / `"income_share"`
- `affordability_tolerance` — default 1.0 (0.9 = costs must fall ≥10%)
- `affordability_income_share` — default 0.10
- `affordability_reference` — `"frozen_stock"` (default; un-renovated building
  at same-period prices) or `"zero_subsidy"` (follower response at σ = 0).
  DECISION PENDING: which one matches Domenig et al. (2024) Eq. 5.
- `household_income_by_class` — PLACEHOLDER (NaN); model errors loudly if
  `income_share` mode is used before GUS data is filled in
- `equity_spending_floor` — default true; false disables the ≥30% floor
  (needed for the plan's (a)–(d) design comparison)

New scenarios: `afford_neutral` (c: both), `afford_only` (b: affordability only),
`no_floor` (d: neither); `baseline` is (a: floor only).

**Where implemented.** Shared functions (`annual_bill`, `own_annualised`,
`affordability_reference_costs`, `affordability_check`) in the model file;
enforcement in `evaluate_σ` (heuristic) AND as a poor-vector pre-filter in
`enumerate_exact.jl` (certification), with a hard consistency assertion at the
certified optimum. Reporting: `affordability_by_archetype.csv` per run (always
written, also when the mode is off), `affordability_grid_report.csv` from the
enumeration, new columns in `scenario_summary.csv`, console summary per poor
archetype.

**How tested.** `test_affordability.jl`: A1 baseline reproduction against
`results/baseline/` (all switches off); A2 hand-computed reference costs;
A3 subset property + determinism; A4 σ=0 ⇒ own contribution = full annuity;
A5 off-mode never affects feasibility. Plus the unchanged 38-check invariant
suite. Test log: `level1a_tests.log`.
