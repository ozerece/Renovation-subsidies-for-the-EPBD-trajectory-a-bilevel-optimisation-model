# scripts/ — wrappers for unsupervised run waves

All Julia and figure work of a run wave goes through these wrappers so that a
Claude Code session needs only a handful of permission allow rules. Every
wrapper `cd`s into `affordable_housing/` (the model reads relative paths) and
uses the Julia environment of the repository root (`--project=<repo>`).
Long runs are **detached** (`setsid nohup`), survive the session, write one log
each under `affordable_housing/results/cert_logs/`, and append a line
`done <label> <exit> <date>` to `results/cert_logs/pl11_done.txt` when finished.

| Script | Purpose | Runs |
|---|---|---|
| `run_pl11_batch.sh [--starts a,b] [--par N] [--tag T] [--env K=V] [--wait] scn...` | model searches (`bilevel_model_affordable_housing.jl`) | detached |
| `run_pl11_eval.sh [--env K=V] scn design [tag]` | fixed-σ evaluation with milestone report (`eval_sigma_report.jl`) | foreground, 1–3 min |
| `run_pl11_local_proof.sh local|grid|smoke scn ...` | local-box proof (`enumerate_local.jl`, shards + merge) or full-list proof (`enumerate_exact.jl`) | detached (smoke: foreground) |
| `run_pl11_tests.sh [suite...]` | the five test suites | foreground |
| `run_pl11_figures.sh make_x.py` | figure/table scripts of the model folder | foreground |
| `run_pl11_status.sh [filter]` | running processes, done-stamps, last log lines | read-only |
| `run_pl11_stop.sh <pattern>|--all [--force]` | stop detached model/proof processes | kills |

Start designs for `--starts` and `eval`: a tag of `data/sigma_start_<tag>.csv`
(`record`, `max`, `pl10cert`, `pl10search`, `hpheavy`, ...), a scenario name
(its `out/scenarios/<scn>/subsidies.csv` is converted), or a file.

Environment: `PL11_MODEL_DIR`, `PL11_ENV_DIR`, `PL11_JULIA` override the model
folder, the Julia project and the julia binary.
