# MANIFEST — what this release contains, what it leaves out, and why

Release `release_p4/` = public copy of the P4 model (version pl12) built by `tools/build_release.sh` from
the source repository `bilevel_optimization` (branch `pl12`, frozen at commit `6d77ac9`, 2026-11-09).
`R` = the source repository, `A` = `R/affordable_housing` (the model folder). The release mirrors the
source layout (`affordable_housing/…`, `scripts/…`, `Project.toml`, `Manifest.toml`). Sizes: `tools/INVENTORY.txt`
(regenerated at every build); total **103.3 MB** without `.git` (limit 300 MB).

## 1. Included

| group | paths (relative to the release root) | notes |
|---|---|---|
| Model code | `affordable_housing/bilevel_model_affordable_housing.jl` | the working-tree file = commit `6d77ac9`; it includes the `rev12` scenario block and the `σ_lower_bound` plain-ordering change of 2026-11-08 (searches of record before that date ran with the earlier +5/+10 pp offsets; the fixed-design evaluation is unaffected — reproduction step 1 confirms the record). `tools/model_file_vs_frozen_commit.diff` is empty (identical to the commit) |
| Proof scripts | `enumerate_local.jl` (local box proof), `enumerate_exact.jl` (full-list proof) | `MAINTREE` path fix, see §3 |
| Evaluation and test scripts | `make_pl12_outcomes.jl`, `make_pl12_review_evals.jl`, `test_pl12_pins.jl`, `test_invariants.jl`, `test_affordability.jl`, `test_tenure.jl`, `test_rentlaw.jl`, `test_switches_off.jl`, `household_structure.jl` | `test_affordability/switches_off/rentlaw` need pl10-era reference outputs (`results/baseline/`, `out/scenarios/tenure_on`, `tenure_oldshares_test`, `rentlaw_test_t5`) that are excluded (§2); included for completeness of the code, not runnable here. `test_pl12_pins.jl`, `test_invariants.jl`, `test_tenure.jl` run on included files |
| Reporting scripts (Python) | `make_pl11_summary.py` (prefix argument pl12 / rev12), `make_pl12_design_table.py`, `make_pl12_figures.py`, `make_pl12_paper_numbers.py` | working-tree = commit `6d77ac9` |
| Documentation of the model folder | `MODEL_MAP.md`, `CHANGELOG.md` (full development log, newest first; top entry = review follow-ups 2026-11-08/09) | `CHANGELOG.md` and `results/README.md` mention files of earlier versions (pl10, pl11, levels 1–3) that are not in the release |
| Wrappers, Julia project | `scripts/*.sh`, `scripts/eval_sigma_report.jl`, `scripts/README.md` (incl. `run_pl12_wave.sh`, `run_pl12_outcomes.sh`, `run_rev12_wave.sh`); `Project.toml`, `Manifest.toml` | wrappers resolve the repository root from their own location, no path fix needed |
| Input data (model-folder root) | `archetypes_pl.csv`, `archetypes_pl_mix.csv` (stock of record, `stock_file` of pl9–pl12), `archetypes_pl_inclusive_mix.csv` (`*_inclusive`), `archetypes_pl_kprb.csv`, `archetypes_pl_kprb_mix.csv` (`*_kprb`), `archetypes_v2.csv` (default stock of `scen()`, used by `test_invariants.jl`/`test_tenure.jl`), `measures_v2.csv`, `context.csv`, `eurostat_tenure_income_PL.csv`, `label_map.csv` | every `stock_file=` value of `SCENARIO_DEFS` is included |
| Input data (`data/`) | all 56 `*.csv` and `*.md`: `history_adoption_pl12.csv`, `_env050`, `_env075`, `_pubpoor` (rev12 repair), `history_heating_pl12.csv`, `sigma_history_pl12.csv`, `history_2020_2025_pl12.md`, `observed_2020_2025_poland.md`; start designs `sigma_start_*.csv` (incl. `sigma_start_rec25.csv`); designs of record `sigma_pl12_local25_record.csv`, `sigma_pl12_cert2/3/4.csv`, `sigma_<scn>_local25.csv` (rev12 proofs); `PROVENANCE.md`, `PROVENANCE_polish_stock.md` | Invert-derived content: `INVERT_DERIVED.md` |
| Scenario configurations | `SCENARIO_DEFS` in the model file; `config_used.txt` in every run folder | |
| Results of record (tables) | `results/pl12_summary.csv` (233 run dirs), `pl12_multistart_summary.csv` (45 scenarios), `pl12_design_table.csv`, `pl12_outcome_measures.csv` (32 scenarios); `results/rev12_summary.csv`, `rev12_multistart_summary.csv` | regenerated 2026-11-09 after the review follow-ups (they now list the `__ms_rec25` / `__local25_record` runs) |
| Paper documents | `results/paper/pl12_paper_numbers.csv` (381 numbers with status and source file), `pl12_final_report.md` (§12 = review follow-ups), `P4_decisions_2026-11-06.md` (D1–D10), `pl11_phase2_realism_check.md`, `P4_open_questions_report.md`; `results/README.md` (the P4 output ledger) | |
| Run folders | `out/scenarios/pl12*` and `out/scenarios/rev12*` — **322 folders**: the pre-registered wave (`pl12_<scn>`, `__ms_record/pl10cert/hpheavy/max/p05design`), warm starts `__ms_pl12record`, D10 strict re-runs `__strict_ms_cur_*`, fixed-design evaluations `__xe_*`, diagnostics `pl12_diag_*`, `pl12_history__hist`, record dirs `pl12__local25_record` (+ `_cert2`, `_cert4` = earlier records), `pl12__outcomes`, `pl12__chk_*`; review follow-ups `rev12_*`, `*__ms_rec25`, `*__chk_rev12`, `pl12__review_evals`, `<scn>__local25_record` of the five 2026-11-09 proofs | `affordability_local_report.csv` (per-grid-point by-product of a local proof, read by no script) is stored **gzipped** in six folders: `pl12` 27.6→1.8 MB, `pl12_envcap_p05` 67.6→4.6, `pl12_hpcost_hi` 27.6→1.7, `pl12_hpcost_lo` 111.1→7.0, `rev12_eq00` 61.3→3.7, `rev12_no2030` 11.4→0.7 (`gunzip` restores them) |
| Certificate and run logs | `results/cert_logs/`: `proof_local_pl12*.log` (final proof + `_center27422/25142/25162/24974` archives, 8 shard logs each), `proof_local_pl12_envcap_p05*`, `proof_local_pl12_hpcost_*`, `proof_local_rev12_*`; `run_pl12*.log`, `run_rev12*.log`; `eval_pl12*.log`, `eval_rev12*.log`, `eval_pl10_gate_pl12_pl10.log`, `eval_pl11_gate_pl12_pl11.log`; `pl12_wave.log`, `pl12_wave_driver.log`, `pl12_strict_launcher.log`, `rev12_wave.log`, `pl12_outcomes_run2/3/4.log`, `test_pl12*.log`; `pl11_done.txt` (done-stamp ledger, verbatim — it also lists detached jobs of earlier versions) — **388 files** | absolute paths rewritten, §3 |
| Figures | `results/figures_pl12/` (working set: png + svg + `fig*_data.csv`), `results/figures_pl12_journal/` (pdf + 1000-dpi png + `fig*_data.csv`), 18 files each | reproduction step 2 regenerates the data CSVs identically |
| Review follow-ups 2026-11-08/09 | `results/review_2026-11-08/` (E1–E4, M13 CSVs, `review_evals.log`, `STATUS_2026-11-08.md`); the `rev12*` run folders, tables, logs and `data/` files listed above; `make_pl12_review_evals.jl`; `scripts/run_rev12_wave.sh` | not part of the pre-registered pl12 wave; the prefix `rev12` keeps them out of the pl12 tables (`make_pl11_summary.py` globs `out/scenarios/pl12*`) |
| Root documents | `README.md`, `MANIFEST.md`, `INVERT_DERIVED.md`, `LICENSE` (MIT), `LICENSE-data` (CC BY 4.0), `CITATION.cff`, `.zenodo.json`, `.gitignore`; `tools/build_release.sh`, `tools/REPRO_CHECK.md`, `tools/PATH_FIXES.txt`, `tools/INVENTORY.txt`, `tools/model_file_vs_frozen_commit.diff` | written for the release |

## 2. Excluded (and why)

| group | paths in the source | reason |
|---|---|---|
| Raw Invert/EE-Lab data | none in `R` (the Invert workbooks were never in the repository) | the Invert-derived quantities live inside the archetype CSVs — `INVERT_DERIVED.md` |
| Third-party source documents | `A/data/*.pdf`, `A/data/*.xlsx` (5 files: Czyste Powietrze annex and KPO unit-cost table, GUS NSP 2021 tables, GUS energy-consumption 2024, NAPE typology handbook) | copyrighted publications; listed with origin in `README.md`; the derived numbers are in the CSVs and `PROVENANCE_polish_stock.md` |
| Unused draft stock | `A/data/archetypes_pl_DRAFT.csv` | referenced by no scenario (first Invert cut, never loaded) |
| Proof shards | `A/out/enum_shards/` (3.5 GB) | intermediate serialized follower tables; the merged certificates are the `proof_local_*.log` files |
| Earlier-version run folders | `A/out/scenarios/*` not starting with `pl12`/`rev12` (563 folders: `pl10*`, `pl11*`, `pl_*`, `pl8*`, `pl9*`, `afford_*`, `claw_*`, `s2_*`, `s4_*`, `tenure_*`, `E1_*`, `baseline`, …), incl. `pl10__gate_pl12_pl10`, `pl11__gate_pl12_pl11` | belong to pl10/pl11 and levels 1–3; the two gate folders are not read by `test_pl12_pins.jl` (it re-evaluates the gates via `eval_sigma_report.jl`) |
| Earlier-version summaries, tables, figures | `A/results/pl10*`, `pl11*`, `figures/`, `figures_pl10*`, `figures_pl11*`, `paper_figures/`, `paper_tables/`, `baseline/`, `table*.csv`, `s1_*/s2_*/s3_*.csv`, `cert_design_kpis.csv`, `design_table_of_record.csv`, `household_structure.csv`, `outcome_measures_*.csv`, `provenance.txt`, `run_pl10_ms_pl10repair.log`, `paperwave_logs/`, `cert_logs_worktree/`, `results/paper/pl10_archetypes_appendix.csv` | not pl12 results |
| Scratch | `A/results/_scratch/` | debug material by definition of the ledger |
| Other cert logs | `A/results/cert_logs/*` outside the globs of §1 (1185 − 388 = 797 files: `cert_pl10_*`, `cert_D*`, `run_pl10_*`, `run_pl11_*`, `eval_pl11_*`, `realism_*`, `diag_*`, `rentlaw_*`, `fig_*`, `archive_pre_sourced/`, …) | earlier versions |
| Earlier-version scripts in `A` | shell: `diag_after_queue.sh reproduce_all.sh run_cert_wave2.sh run_d4_cert.sh run_l3lite.sh run_level2.sh run_level3.sh run_pl10_batch.sh run_pl10_multistart.sh run_pl10_warmstarts.sh run_s1.sh run_s4.sh run_tonight.sh run_wave8.sh run_wave9.sh`; Julia: `diag_sfh_split.jl e2_landlord_grant.jl eval_certified.jl eval_sigma0.jl run_e1.jl run_e1_nopass.jl run_eval_pub.jl run_scenarios.jl s1_summary.jl s2_summary.jl s3_summary.jl stamp_provenance.jl table2_tenure.jl table3_tenant_costs.jl table4_institutional.jl table5_rent_rule_choice.jl`; Python: `make_figure1-6.py make_paper_figures.py make_paper_tables.py make_pl10_figures.py make_pl10_summary.py make_pl11_figures.py` | none is called by the pl12 pipeline (checked by grepping `scripts/*`, the pl12 Python/Julia scripts and the model file for every file name; only `make_pl10_figures.py`/`make_paper_tables.py` appear, as usage examples in `scripts/run_pl11_figures.sh`). `stamp_provenance.jl` is called only by `reproduce_all.sh` and `run_wave8.sh` (excluded) |
| Other model-folder files | `A/baseline_run.log`, `A/level1a_tests.log`, `A/__pycache__/`, `A/lit review/` | logs outside `cert_logs`, caches, literature notes |
| Repository root | `R/*.jl`, `R/*.tex`, `R/*.md`, `R/*.log`, `R/*.csv` (pre-P4 models and notes), `R/master/`, `R/docs/`, `R/experiments/`, `R/test_small_instance/`, `R/slides/`, `R/presentations/`, `R/research_log/`, `R/out/`, `R/claude_screenshots/`, `R/*.pptx`, `R/CLAUDE.md`, `R/.claude/`, `R/Manifest.toml.julia11.backup`, `R/.git/` | earlier models, manuscripts, presentations, assistant configuration, backup |
| Manuscript and reviews | everything under `writing/` | not part of the model release |
| Credentials | none found: a grep over `R` (excluding `.git`) for the Gurobi WLS access-id, licence-id and licence-file tokens returned nothing; no `gurobi.env`, no `*.lic` | the build audits the release for these tokens and file names at every run |

## 3. Path fixes (applied to the copies only; `tools/PATH_FIXES.txt` lists every file)

The source machine's absolute paths appeared in one script and in the run/proof logs. Rules of `tools/build_release.sh`:

1. `affordable_housing/enumerate_local.jl`, line 36: `const MAINTREE = "<R>/affordable_housing"` →
   `const MAINTREE = @__DIR__`. `MAINTREE` is only used to locate `out/scenarios/<scn>/subsidies.csv`
   (or `subsidies_local_center.csv`) of the main tree; the file is included from the model folder, so
   `@__DIR__` is that folder and the behaviour is unchanged for a checkout that is its own main tree.
2. `"<R>/"` → `""` (paths become relative to the release root, e.g.
   `affordable_housing/results/cert_logs/pl11_done.txt`); a bare `"<R>"` → `"."`.
3. `"<HOME of the source user>"` → `"$HOME"` (no occurrence was found in the included files; the rule is kept).

Rules 2–3 touched **383 files**, all in `affordable_housing/results/cert_logs/` (`run_*.log`, `eval_*.log`,
`proof_local_*.log`, `rev12_wave.log`, `pl12_wave.log`, `pl11_done.txt`): launch lines ("launched … -> <log>"),
Julia stack traces and the done-stamp paths. No other included file (code, CSV, Markdown, `config_used.txt`,
`Project.toml`, `Manifest.toml`, figures) contained an absolute path. `CHANGELOG.md` contained none.
The build's audit fails if any string of the source mount path (`/media/…`) or of the source user's home directory remains outside `tools/build_release.sh` (which carries the patterns it audits for).

## 4. Notes and open points

- **ORCIDs** of both authors are unknown: `CITATION.cff` carries `TODO-ORCID` placeholders.
- **Invert/EE-Lab permission pending**: see `INVERT_DERIVED.md`; the listed files must not be redistributed before e-think grants it.
- **Licence of datasets**: GUS, Eurostat, URE and NFOŚiGW/Czyste Powietrze figures are public statistics or programme documents; their source files are excluded and cited. The Invert-derived values are the only inputs with a pending condition.
- `results/README.md` (the ledger) and `CHANGELOG.md` document the whole P4 development including results that are not in the release; their file references to `pl10*`, `pl11*`, `baseline/`, `_scratch/`, `enum_shards/`, worktrees and `writing/` point outside the release.
- `pl11_done.txt` is kept verbatim (it is the done-stamp ledger of every detached job, incl. pl10/pl11).
- `test_pl12_pins.jl` gate G1/G2 evaluate the `pl10` and `pl11` scenarios; both are defined in the model file and use included stock files, so the gates run from the release (reproduction step 3).
- The `Manifest.toml` was last resolved under Julia 1.10.10; all runs of record used Julia 1.11.6 with it.

## 5. Reproduction check

See `tools/REPRO_CHECK.md` for the exact commands, outputs and file comparisons. Summary:
step 1 — the fixed-design evaluation of `data/sigma_pl12_local25_record.csv` on `pl12` gives
**24,936.168 M EUR, feasible = true**, `subsidies.csv` and `subsidy_by_archetype.csv` byte-identical to the
record dir, `energy_path.csv` identical except the 2060 value in the 16th significant digit;
step 2 — all six `fig*_data.csv` of the journal set and `pl12_paper_numbers.csv` (381 numbers) regenerate
byte-identically; step 3 — `test_pl12_pins.jl` **11 of 11 pins pass** (pl10 record 10,233.5 M EUR, pl11 caps 49,186.2 M EUR, history run 243.88 / 224.05 / 5,021.7) in 2 min 18 s.
