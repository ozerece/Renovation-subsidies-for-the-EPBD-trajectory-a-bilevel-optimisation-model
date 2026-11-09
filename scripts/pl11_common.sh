#!/bin/bash
# Shared settings for the run_pl11_*.sh wrappers. Sourced, not executed.
# Every wrapper cd's into MODEL_DIR (the model uses relative input paths) and
# runs julia with --project=ENV_DIR (the Julia environment of the repository).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODEL_DIR="${PL11_MODEL_DIR:-$REPO_ROOT/affordable_housing}"
ENV_DIR="${PL11_ENV_DIR:-$REPO_ROOT}"
MODEL_FILE="bilevel_model_affordable_housing.jl"
LOG_DIR="$MODEL_DIR/results/cert_logs"
DONE_FILE="$LOG_DIR/pl11_done.txt"          # one line per finished detached job
JULIA="${PL11_JULIA:-julia}"
mkdir -p "$LOG_DIR"

# Run a command detached from the calling session (survives the caller's
# exit and any kill of the caller's process group). Appends a done-stamp.
#   detach <label> <logfile> <cmd...>
detach() {
  local label="$1" log="$2"; shift 2
  setsid nohup bash -c "cd '$MODEL_DIR' && $(printf '%q ' "$@") > '$log' 2>&1; echo \"done $label \$? \$(date '+%F %H:%M')\" >> '$DONE_FILE'" \
    > /dev/null 2>&1 < /dev/null &
  echo "launched $label -> $log"
}

# Resolve a start design: a tag (data/sigma_start_<tag>.csv), a scenario
# (out/scenarios/<scn>/subsidies.csv is converted), or an existing file.
#   resolve_sigma <tag|scenario|file>  -> prints the file path
resolve_sigma() {
  local s="$1"
  if [ -f "$MODEL_DIR/data/sigma_start_$s.csv" ]; then echo "data/sigma_start_$s.csv"; return 0; fi
  if [ -f "$s" ]; then echo "$s"; return 0; fi
  if [ -f "$MODEL_DIR/$s" ]; then echo "$s"; return 0; fi
  if [ -f "$MODEL_DIR/out/scenarios/$s/subsidies.csv" ]; then
    local f="data/sigma_start_from_$s.csv"
    # map by (group, measure) key into the model's canonical σ order (env poor×3,
    # env rich×3, hvac poor×2, hvac rich×2, landlords); run-dir CSVs are NOT in that order
    python3 -I - "$MODEL_DIR/out/scenarios/$s/subsidies.csv" "$MODEL_DIR/$f" "$s" <<'PY'
import csv, sys
src, dst, name = sys.argv[1:4]
rate = {(r["group"], r["measure"]): float(r["rate"]) for r in csv.DictReader(open(src))}
KEYS = [("poor","env_light"),("poor","env_medium"),("poor","env_deep"),("rich","env_light"),("rich","env_medium"),("rich","env_deep"),
        ("poor","hvac_std"),("poor","hvac_upg"),("rich","hvac_std"),("rich","hvac_upg"),("landlord_public","all_non_pv"),("landlord_private","all_non_pv")]
with open(dst, "w") as f:
    f.write(f"# converted from out/scenarios/{name}/subsidies.csv by (group,measure) key into canonical order\n")
    for k in KEYS: f.write(f"{rate.get(k, 0.0):.10f}\n")
PY
    echo "$f"; return 0
  fi
  echo "ERROR: cannot resolve start design '$s'" >&2; return 1
}
