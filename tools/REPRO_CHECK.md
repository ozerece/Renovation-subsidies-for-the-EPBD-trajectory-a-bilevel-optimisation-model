# Reproduction check of the release (2026-11-09)

Run in a **fresh copy** of `release_p4/` (rsync without `.git`) in a scratch folder, not in the source
repository and not in `release_p4/` itself. Machine: Linux x86_64, 48 cores, Julia 1.11.6 (juliaup),
Gurobi 12.0.3 (Gurobi_jll, licensed), Python 3 with matplotlib 3.10.1, Carlito font installed. Several
other Julia/Gurobi jobs were running on the machine at the same time. Source repository at commit
`6d77ac9` (branch `pl12`), frozen; `R` below denotes it.

## Step 1 — fixed-σ evaluation of the design of record

```bash
cd fresh/affordable_housing
P4_GRB_THREADS=8 P4_FIXED_SIGMA=data/sigma_pl12_local25_record.csv P4_OUT_TAG=repro \
  julia --project=.. bilevel_model_affordable_housing.jl pl12 > repro.log 2>&1
```

Result (exit 0; follower solve 8.2 s, whole run about 2 min incl. compilation):

```
>>> P4_FIXED_SIGMA=data/sigma_pl12_local25_record.csv: fixed-design evaluation, NO search; full outputs written <<<
  fixed design: spending €24936.168M, feasible=true
  Public spending: €24936.17M
  History (periods 1..1, fixed): subsidy spending nominal €5021.7M, discounted to 2026 €5996.1M — NOT in the state's objective
```

`out/scenarios/pl12__repro/scenario_summary.csv`: `spending_M = 24936.168185283543`, `feasible = true`,
`E2050 = 97.57153502536251`, `equity = 0.30035062781501654`, `wpb = 0.7450520616638225` — the same
spending as `R/affordable_housing/out/scenarios/pl12__local25_record/scenario_summary.csv`
(24936.168185283543; the certificate log quotes the proof's 24,936.163, the record run writes .168).

Comparison of `out/scenarios/pl12__repro/` with `R/affordable_housing/out/scenarios/pl12__local25_record/`:

| file | result |
|---|---|
| `subsidies.csv` | byte-identical |
| `subsidy_by_archetype.csv` | byte-identical |
| `measure_totals.csv` | byte-identical |
| `energy_path.csv` | identical except the 2060 row: 55.75418222727132 vs 55.75418222727134 (relative difference 4e-16; floating-point noise of the solver, all reported years 2020–2050 identical) |
| `scenario_summary.csv`, `policy_kpis.csv` | identical except the equity share in the 17th significant digit (0.30035062781501654 vs 0.3003506278150164) and the solve-time field |
| `adoption_values.csv` | identical except one dwelling count in the 16th significant digit (65.94729032963377 vs 65.94729032963376) |

Verdict: **the record is reproduced**; the only differences are last-digit floating-point noise
(the record notes that results may differ in the last digit with another Gurobi thread count or load).

## Step 2 — figures and the numbers sheet

```bash
cd fresh/affordable_housing
P4_JOURNAL=1 python3 -I make_pl12_figures.py      # exit 0, no font warning (Carlito present)
python3 -I make_pl12_paper_numbers.py             # exit 0: "381 numbers -> results/paper/pl12_paper_numbers.csv"
```

`cmp` of every regenerated `results/figures_pl12_journal/fig*_data.csv` against
`R/affordable_housing/results/figures_pl12_journal/`:

| file | lines | result |
|---|---|---|
| `fig1_primary_energy_data.csv` | 8 | identical |
| `fig2_spend_uptake_groups_data.csv` | 7 | identical |
| `fig3_scenario_spending_data.csv` | 47 | identical |
| `fig4_poor_cost_share_2050_data.csv` | 5 | identical |
| `fig5_uptake_tenure_data.csv` | 21 | identical |
| `fig6_rent_rules_data.csv` | 15 (incl. the two public-tenant EED on/off rows added 2026-11-09) | identical |

`results/paper/pl12_paper_numbers.csv` (382 lines = header + 381 numbers): **byte-identical** to
`R/affordable_housing/results/paper/pl12_paper_numbers.csv`.

## Step 3 — pinned gates (`test_pl12_pins.jl`)

The test needs only files of the release (`data/sigma_start_record.csv`, `data/sigma_start_max.csv`,
`data/sigma_history_pl12.csv`, `scripts/eval_sigma_report.jl`; it writes `out/scenarios/<scn>__pintest/`).

```bash
cd fresh/affordable_housing
P4_GRB_THREADS=8 julia --project=.. test_pl12_pins.jl > test_pl12_pins_repro.log 2>&1
```

Result (exit 0, 2 min 18 s wall time for the three evaluations):

```
--- pl10 @ sigma_start_record.csv ---      PASS E2030 222.19 | spending_M 10233.54 (got 10233.50) | E2040 158.58 | E2050 92.06
--- pl11 @ sigma_start_max.csv ---         PASS E2030 230.39 | spending_M 49186.20 | E2050 75.14
--- pl12_history @ sigma_history_pl12.csv  PASS E2026 243.88 | E2030 224.05 | hist_nominal_M 5021.70 | E2050 73.39
PL12 PINS: 11 passed, 0 failed
```

The gates G1 (pl10 design of record), G2 (pl11 at all caps) and G3/G4 (pl12 history run) pass from the
release alone; the run wrote `out/scenarios/pl10__pintest/`, `pl11__pintest/`, `pl12_history__pintest/`.

## Not run

- Scenario searches, local proofs and the outcome-measure wave (hours to days; the certificate logs
  in `results/cert_logs/` document the runs of record).
- `test_affordability.jl`, `test_switches_off.jl`, `test_rentlaw.jl`: they compare against reference
  outputs of earlier model versions that are not in the release (see MANIFEST.md).
