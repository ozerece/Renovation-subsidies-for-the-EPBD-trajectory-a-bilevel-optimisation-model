# Bilevel renovation-subsidy design for the EPBD trajectory — P4, version pl12

Model, data and results of record for the paper on bilevel (Stackelberg) design of building-renovation
subsidies (Ece Özer and Lukas Kranzl, TU Wien, Energy System Economics Lab, Institute of Net-Zero
Energy Systems). Release built from the source repository `bilevel_optimization`, branch `pl12`,
commit `6d77ac9` (frozen 2026-11-09).

- Release: **1.0.1** (10 November 2026) of model version pl12. Release 1.0.1 corrects the licence
  text on the Invert/EE-Lab-derived inputs and the release metadata; code, data and results are those of 1.0.
- Repository: <https://github.com/ozerece/p4-renovation-subsidies>
- Archive: <https://doi.org/10.5281/zenodo.24081332> (Zenodo, all versions; each release has its own version DOI)

## What the model is

The **state (leader)** sets subsidy rates — the share of the investment cost it pays — for each of
twelve instruments: envelope renovation of three depths (light, medium, deep) and heat-pump
installation for low-income and for high-income owner-occupiers, the district-heat connection
("upgrade") for both income groups, and one rate each for public and for private landlords. It
minimises discounted public spending over 2026–2050 subject to the EPBD residential primary-energy
trajectory (−16 % in 2030, −20 % in 2035, −40 % in 2040, −59 % in 2050 against 2020, Directive (EU)
2024/1275), a floor on the share of spending that reaches low-income households (30 %), the
worst-performing-building rule, the EED Art. 6 obligation of public landlords, the Polish rent law
and optional affordability rules.

The **followers** — owner-occupiers (two income groups) and public and private landlords, 44
archetypes of the Polish census stock (single- and multi-family houses, worst-performing and
rest, fossil and district-heat incumbents, owner-occupied, public rental, private rental) —
choose renovation measures over time in their own economic interest (investment net of subsidy,
fuel, carbon and maintenance costs, rent pass-through), under renovation-capacity and liquidity
limits. The follower problem is solved exactly with Gurobi for a given design; the design is
searched by a column-and-constraint-generation heuristic and then **certified on a local grid**
(every rate ± 10 percentage points in 2.5-pp steps, exact enumeration).

**Version pl12** (decision record of 6 November 2026, `affordable_housing/results/paper/P4_decisions_2026-11-06.md`):
periods 2020 / 2026 / 2030 / 2035 / 2040 / 2050; the first period 2020–2025 is a **fixed history**
(single-family heating replacements from observed Czyste Powietrze data, envelope renovation from a
run at the historical subsidy rates 70 % / 40 %); the state designs subsidies **from 2026**, spending
is counted and discounted from 2026; carbon price 22.5 EUR/t in 2026–2030; no PV measure; strict
equity floor. Poland case on the 2021 census stock (8.85 million dwellings).

### Results of record (standard run `pl12`; from `results/paper/pl12_final_report.md`)

| quantity | value | status |
|---|---|---|
| Public subsidy spending 2026–2050 | **24,936 M EUR** discounted to 2026 (31,976 M EUR nominal) | certified local optimum (± 10-pp box, 2.5-pp grid, strict 30 % equity floor; fixed point after five re-centred proofs) |
| Design of record | low-income owners: envelope 42.9 / 42.9 / 45.1 %, heat pump 94.7 %; high-income owners: envelope 20.4 / 37.09 / 37.09 %, heat pump 0; landlords 0 | certified |
| 2026 state after the fixed history | 243.9 kWh/(m²·yr) (2020: 264.4) | fixed history |
| EPBD milestones at the record | 2030 221.9 (target 222.1, slack 0.24) · 2035 197.4 · 2040 158.1 (target 158.7, slack 0.57) · 2050 97.6 (target 108.4) | evaluation |
| CO₂ avoided 2026–2050 | 30.7 Mt (6.8 % of 451.6 Mt without the programme), 811 EUR/t | evaluation vs σ = 0 |
| Equity share (low-income owners) | 30.0 %, the floor binds | certified |
| Scenarios | 31 of 45 feasible (three of them certified local optima), 14 without a feasible design | search bounds / max-σ evidence |

### Status vocabulary

- **certified local optimum** — the exact minimum over the local grid around a search design
  (every rate ± 10 pp in 2.5-pp steps, clamped to its cap, depth ordering deep ≥ medium ≥ light,
  equity floor applied strictly). No design on that grid is cheaper; a cheaper basin elsewhere is
  not excluded. Certificates: `results/cert_logs/proof_local_<scenario>*.log`; record dirs
  `out/scenarios/<scenario>__local25_record/`.
- **search bound** — the best feasible design found by the heuristic search from several starts
  (`results/pl12_multistart_summary.csv`, column `best_source`). An upper bound on the minimum.
- **max-σ evidence** — a scenario has "no feasible design" when every rate at its cap misses a
  milestone (`results/cert_logs/eval_<scenario>_xe_max.log`; `miss_*` columns of the summary).
  Evidence, not a certificate of infeasibility.
- **evaluation** — a fixed-design follower solve (no optimisation of the design), e.g. the outcome
  measures, the σ = 0 counterfactual, the 2026 state.

### Review follow-ups of 2026-11-08/09 (prefix `rev12`)

After the paper review of 8 November 2026 the scenarios `rev12_no2030`, `rev12_2050only`,
`rev12_eq00`, `rev12_eq20`, `rev12_eq40` (price of the milestones; cost of the equity floor), the
repaired `pl12_pubpoor`, re-searches and local proofs of `pl12_envcap_p05`, `pl12_hpcost_lo`,
`pl12_hpcost_hi`, and the evaluations E1–E4 and M13 (`make_pl12_review_evals.jl`) were run. They are
**not part of the pre-registered pl12 wave**; the prefix `rev12` keeps them out of the pl12 tables.
Their files: `out/scenarios/rev12_*`, `out/scenarios/*__ms_rec25`, `out/scenarios/*__local25_record`,
`results/rev12_summary.csv`, `results/rev12_multistart_summary.csv`, `results/review_2026-11-08/`,
`results/cert_logs/rev12_wave.log`, `run_rev12*.log`, `proof_local_rev12*.log`,
`proof_local_pl12_envcap_p05*.log`, `proof_local_pl12_hpcost_*.log`, `scripts/run_rev12_wave.sh`.
Results: `results/paper/pl12_final_report.md` §12 and the top entry of `affordable_housing/CHANGELOG.md`.

## Repository layout

```
README.md, MANIFEST.md, INVERT_DERIVED.md, LICENSE, LICENSE-data, CITATION.cff, .zenodo.json
Project.toml, Manifest.toml          Julia environment (pinned)
scripts/                             run wrappers (detached waves, evaluations, proofs, tests, figures)
tools/                               build_release.sh (how this folder was assembled), REPRO_CHECK.md,
                                     PATH_FIXES.txt, INVENTORY.txt, model_file_vs_frozen_commit.diff
affordable_housing/                  the model folder (every script is run from here)
  bilevel_model_affordable_housing.jl  model: data loading, follower, master LP, search, result writing
  enumerate_local.jl                 local exact proof (sharded)      enumerate_exact.jl  full-list proof
  make_pl12_outcomes.jl              outcome measures                 make_pl12_review_evals.jl  E1–E4, M13
  test_pl12_pins.jl, test_*.jl       verification suites              household_structure.jl
  make_pl11_summary.py               summary tables (prefix pl12 / rev12)
  make_pl12_design_table.py, make_pl12_figures.py, make_pl12_paper_numbers.py
  MODEL_MAP.md, CHANGELOG.md         where things live; full development log (newest entry first)
  archetypes_pl_mix.csv              stock of record (12 rows; tenure split at run time -> 44 archetypes)
  archetypes_pl*.csv, archetypes_v2.csv, measures_v2.csv, context.csv, eurostat_tenure_income_PL.csv, label_map.csv
  data/                              2020-2025 history files, start designs, designs of record,
                                     PROVENANCE.md, PROVENANCE_polish_stock.md, observed_2020_2025_poland.md
  out/scenarios/<run>/               one folder per run: config_used.txt (full scenario configuration),
                                     scenario_summary.csv, subsidies.csv, energy_path.csv, ... (322 folders)
  results/pl12_*.csv, rev12_*.csv    summary tables of record
  results/paper/                     pl12_final_report.md, pl12_paper_numbers.csv (every number of the paper
                                     with status and source file), decision record, open-questions report
  results/cert_logs/                 run, evaluation, proof and test logs; pl11_done.txt (done-stamp ledger)
  results/figures_pl12/, figures_pl12_journal/   figures 1-6 with their data CSVs (working set / journal set)
  results/review_2026-11-08/         E1-E4 and M13 evaluation outputs, STATUS note
  results/README.md                  the P4 output ledger (also covers earlier versions not in this release)
```

Scenario configurations: `SCENARIO_DEFS` in `bilevel_model_affordable_housing.jl` (the `pl12*` and
`rev12*` entries) and the `config_used.txt` of every run folder. Input provenance:
`affordable_housing/data/PROVENANCE.md` (stylised inputs) and `PROVENANCE_polish_stock.md` (Polish stock,
prices, costs, savings). Run-folder names: `<scenario>` = search from the model's candidate list,
`<scenario>__ms_<start>` = warm start, `__strict_ms_cur_<scenario>` = D10 strict re-run,
`__xe_<design>` = fixed-design evaluation, `__local25_record` = record dir of the certified design.

## Requirements

- **Julia 1.11** (every run of record used 1.11.6) with the pinned `Manifest.toml`
  (`julia --project=. -e 'using Pkg; Pkg.instantiate()'` in the release root). The Manifest was last
  resolved under Julia 1.10.10 and instantiates under 1.11.
- **Gurobi 12** (Gurobi_jll 12.0.3 is pinned) with a valid licence available to Gurobi.jl.
- **Python 3** with `matplotlib` (3.10 was used) for the figure and table scripts; run them with `python3 -I`.
- Optional: the **Carlito** font (`fonts-crosextra-carlito`) for the figures; without it matplotlib
  falls back to its default font and prints a warning.
- Disk: the release is about 105 MB; a local proof writes shards to `affordable_housing/out/enum_shards/`
  (hundreds of MB to a few GB).

All commands below are run from `affordable_housing/` with the Julia environment of the release root
(`--project=..`); the wrappers in `scripts/` do this for you.

## Reproducing the record

Exactly the commands of the reproduction check (`tools/REPRO_CHECK.md`), run in a fresh copy of this folder:

```bash
cd affordable_housing
# 1. fixed-design evaluation of the certified design (1-3 min; 8 Gurobi threads)
P4_GRB_THREADS=8 P4_FIXED_SIGMA=data/sigma_pl12_local25_record.csv P4_OUT_TAG=repro \
  julia --project=.. bilevel_model_affordable_housing.jl pl12 > repro.log 2>&1
#    -> "fixed design: spending €24936.168M, feasible=true"; out/scenarios/pl12__repro/ equals
#       out/scenarios/pl12__local25_record/ (subsidies.csv, subsidy_by_archetype.csv byte-identical)
# 2. figures (journal set) and the numbers sheet of the paper
P4_JOURNAL=1 python3 -I make_pl12_figures.py     # -> results/figures_pl12_journal/fig1..fig6 (+ _data.csv)
python3 -I make_pl12_paper_numbers.py            # -> results/paper/pl12_paper_numbers.csv
# 3. pinned gates (pl10 record, pl11 caps, pl12 history run; ~10 min)
P4_GRB_THREADS=8 julia --project=.. test_pl12_pins.jl
```

## Running the model

```bash
# a scenario search (the model's own candidate starts; writes out/scenarios/<scenario>/)
P4_GRB_THREADS=8 julia --project=.. bilevel_model_affordable_housing.jl pl12
# detached, several scenarios, warm starts (tags of data/sigma_start_<tag>.csv); see scripts/README.md
scripts/run_pl11_batch.sh --par 6 --wait pl12 pl12_afford
scripts/run_pl11_batch.sh --par 6 --starts record,pl10cert,hpheavy --wait pl12
scripts/run_pl12_wave.sh            # the whole pre-registered pl12 wave (44 scenarios x 4 starts + max-σ evaluations)
scripts/run_rev12_wave.sh           # the review follow-up wave of 2026-11-08
# a fixed-σ evaluation with a milestone report (1-3 min); design = start tag, scenario name or 12-value file
scripts/run_pl11_eval.sh pl12 data/sigma_pl12_local25_record.csv xe_record
# the local proof around out/scenarios/<scenario>/subsidies.csv (or subsidies_local_center.csv if present);
# 8 shards + merge, 15 min to a day depending on the scenario; shards in out/enum_shards/
scripts/run_pl11_local_proof.sh local pl12
scripts/run_pl11_local_proof.sh smoke pl12          # minutes, foreground
# the record dir of a certified design
P4_FIXED_SIGMA=data/sigma_pl12_local25_record.csv P4_OUT_TAG=local25_record julia --project=.. bilevel_model_affordable_housing.jl pl12
# tests
scripts/run_pl11_tests.sh pl12                      # test_pl12_pins.jl (needs only files of this release)
scripts/run_pl11_tests.sh invariants tenure         # run on the stylised default stock archetypes_v2.csv
# summary tables, design table, outcome measures, figures, numbers sheet
python3 -I make_pl11_summary.py pl12 && python3 -I make_pl11_summary.py rev12
python3 -I make_pl12_design_table.py
scripts/run_pl12_outcomes.sh pl12                   # -> results/pl12_outcome_measures.csv (one julia process per scenario)
python3 -I make_pl12_figures.py                     # working set, results/figures_pl12/
P4_JOURNAL=1 python3 -I make_pl12_figures.py        # journal set, results/figures_pl12_journal/
python3 -I make_pl12_paper_numbers.py
julia --project=.. make_pl12_review_evals.jl pl12   # E1-E4, M13 -> results/review_2026-11-08/
```

Environment switches of the model: `P4_GRB_THREADS` (Gurobi thread cap; the record used 8 — results can
differ in the last digit with another count), `P4_OUT_TAG` (output folder suffix), `P4_SIGMA_START`
(warm-start file), `P4_FIXED_SIGMA` (evaluate one design, no search), `P4_SKIP_SEARCH=1` (load only),
`P4_SEED`, `P4_FORCE_BOILER_BAN`. The test suites `test_affordability.jl`, `test_switches_off.jl` and
`test_rentlaw.jl` compare against reference outputs of earlier model versions (`results/baseline/`,
`out/scenarios/tenure_on`, `tenure_oldshares_test`, `rentlaw_test_t5`) that are not part of this release;
they are included for completeness of the code but cannot be run here (see MANIFEST.md).

## Third-party source documents (not included)

The derived numbers are in the CSV inputs and in `data/PROVENANCE_polish_stock.md`; the documents
themselves are copyrighted publications and are available from their publishers:

| file in the source repository | origin |
|---|---|
| `data/czyste_powietrze_zalacznik2_od_2026_07_20.pdf` | NFOŚiGW, *Program Priorytetowy Czyste Powietrze, Załącznik nr 2: Koszty kwalifikowane oraz maksymalny poziom dofinansowania*, version valid from 20 July 2026, czystepowietrze.gov.pl |
| `data/czyste_powietrze_kpo_tabela_kosztow_jednostkowych.pdf` | MKiŚ / NFOŚiGW and the 16 WFOŚiGW, *Tabela kosztów jednostkowych dla termomodernizacji domu* (KPO/FEnIKS unit-cost table, June 2025), copy from bip.wfosigw.rzeszow.pl |
| `data/gus_nsp2021_warunki_mieszkaniowe_tablice.xlsx` | GUS (Statistics Poland), *Warunki mieszkaniowe w Polsce w świetle wyników NSP 2021* — tables workbook, stat.gov.pl |
| `data/gus_zewgd_2024_sygnalna.pdf` | GUS, *Zużycie energii w gospodarstwach domowych w 2024 r.*, signal publication of 9 January 2026, stat.gov.pl |
| `data/nape_tabula_typologia_budynkow_podrecznik.pdf` | NAPE, *Podręcznik typologii budynków mieszkalnych* (Polish TABULA/EPISCOPE building typology handbook) |

Other sources are cited inline in the two PROVENANCE files (Eurostat `nrg_pc_204`, `nrg_pc_202`,
`ilc_lvho02`; GUS coal price communiqué; URE *Energetyka cieplna w liczbach 2024*; KPRB; EPBD 2024/1275;
Czyste Powietrze statistics; PORT PC). The Invert/EE-Lab outputs used for the stock split are not in
the repository either; see the next section.

## Invert/EE-Lab-derived inputs

The worst-performing-building shares and the average energy intensities of the archetypes were derived
from the Invert/EE-Lab building-stock model (e-think / TU Wien). `INVERT_DERIVED.md` lists every file and
column that carries these values and how they were derived. They are published with the permission
of e-think energy research (granted November 2026); the raw Invert outputs are not part of the
release.

## Licences

- `LICENSE` (MIT): the code — `affordable_housing/*.jl`, `affordable_housing/*.py`, `scripts/`,
  `tools/`, `Project.toml`, `Manifest.toml`.
- `LICENSE-data` (CC BY 4.0): data, results, figures and documentation —
  `affordable_housing/*.csv`, `affordable_housing/data/`, `affordable_housing/out/`,
  `affordable_housing/results/`, `affordable_housing/*.md` and the root documents.
- Third-party-derived inputs keep the terms of their sources; the Invert/EE-Lab-derived files are
  published with the permission of e-think energy research (November 2026) and are documented in
  `INVERT_DERIVED.md`.

## Citation

Özer, E. and Kranzl, L. (2026). *Bilevel renovation-subsidy design for the EPBD trajectory: model, data
and results of record (P4, version pl12)*. TU Wien, Energy System Economics Lab, Institute of Net-Zero
Energy Systems. Release 1.0.1, 2026-11-10. https://github.com/ozerece/p4-renovation-subsidies,
https://doi.org/10.5281/zenodo.24081332. See `CITATION.cff`.
