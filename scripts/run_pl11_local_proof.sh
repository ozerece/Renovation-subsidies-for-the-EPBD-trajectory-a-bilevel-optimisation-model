#!/bin/bash
########################################################################
# run_pl11_local_proof.sh — exact proofs, detached.
#
# Usage:
#   scripts/run_pl11_local_proof.sh local <scenario> [--shards N] [--threads T]
#       Local-box proof (enumerate_local.jl) around the stored search design
#       out/scenarios/<scenario>/subsidies.csv: N shards in parallel, then the
#       merge. Default 8 shards, 24 merge threads. About 1 day for pl10.
#   scripts/run_pl11_local_proof.sh grid <scenario> [gridspec] [landlord_gridspec]
#       Full-list proof (enumerate_exact.jl), default gridspec "hybrid". 4–12 h.
#   scripts/run_pl11_local_proof.sh smoke <scenario>
#       enumerate_local.jl smoke run (P4_LOCAL_SMOKE=1), foreground, minutes.
#
# Logs: results/cert_logs/proof_<mode>_<scenario>[_shard_k].log
# Done-stamps: results/cert_logs/pl11_done.txt (label proof_<mode>_<scenario>)
########################################################################
set -u
source "$(dirname "$0")/pl11_common.sh"
MODE="${1:-}"; SCN="${2:-}"; shift 2 2>/dev/null
[ -n "$MODE" ] && [ -n "$SCN" ] || { sed -n 2,16p "$0"; exit 2; }
cd "$MODEL_DIR" || exit 1
case "$MODE" in
  smoke)
    P4_SKIP_SEARCH=1 P4_LOCAL_SMOKE=1 "$JULIA" --project="$ENV_DIR" enumerate_local.jl "$SCN" 2>&1 | tee "$LOG_DIR/proof_smoke_$SCN.log" | tail -20
    ;;
  grid)
    GRID="${1:-hybrid}"; LGRID="${2:-$GRID}"
    detach "proof_grid_$SCN" "$LOG_DIR/proof_grid_$SCN.log" "$JULIA" --project="$ENV_DIR" enumerate_exact.jl "$GRID" "$SCN" "$LGRID"
    ;;
  local)
    NSH=8; NT=24
    while [ $# -gt 0 ]; do case "$1" in --shards) NSH="$2"; shift 2;; --threads) NT="$2"; shift 2;; *) echo "unknown $1" >&2; exit 2;; esac; done
    [ -f "out/scenarios/$SCN/subsidies.csv" ] || { echo "no out/scenarios/$SCN/subsidies.csv (run the search first)" >&2; exit 1; }
    # one detached driver runs the shards in parallel, waits, then merges
    detach "proof_local_$SCN" "$LOG_DIR/proof_local_$SCN.log" bash -c "
      for k in \$(seq 1 $NSH); do
        P4_SKIP_SEARCH=1 P4_ENUM_SHARD=\$k/$NSH '$JULIA' --project='$ENV_DIR' enumerate_local.jl '$SCN' > '$LOG_DIR/proof_local_${SCN}_shard_'\$k'.log' 2>&1 &
      done; wait
      P4_SKIP_SEARCH=1 P4_ENUM_MERGE=$NSH '$JULIA' -t $NT --project='$ENV_DIR' enumerate_local.jl '$SCN'"
    ;;
  *) echo "mode must be local, grid or smoke" >&2; exit 2;;
esac
