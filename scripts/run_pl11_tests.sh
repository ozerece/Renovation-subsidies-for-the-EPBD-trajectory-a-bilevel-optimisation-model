#!/bin/bash
########################################################################
# run_pl11_tests.sh — the model's verification suites, foreground.
#
# Usage: scripts/run_pl11_tests.sh [all|invariants|affordability|tenure|rentlaw|switches] ...
#   Default: all five suites in sequence; stops at the first failure.
#   Logs: results/cert_logs/test_<suite>.log
########################################################################
set -u
source "$(dirname "$0")/pl11_common.sh"
cd "$MODEL_DIR" || exit 1
SUITES=("$@"); [ ${#SUITES[@]} -eq 0 ] && SUITES=(all)
[ "${SUITES[0]}" = all ] && SUITES=(invariants affordability tenure rentlaw switches pl12)
for s in "${SUITES[@]}"; do
  case "$s" in
    invariants) f=test_invariants.jl;; affordability) f=test_affordability.jl;; tenure) f=test_tenure.jl;; pl12) f=test_pl12_pins.jl;;
    rentlaw) f=test_rentlaw.jl;; switches) f=test_switches_off.jl;;
    *) echo "unknown suite $s" >&2; exit 2;;
  esac
  echo "== $s ($f) $(date '+%H:%M') =="
  "$JULIA" --project="$ENV_DIR" "$f" > "$LOG_DIR/test_$s.log" 2>&1
  rc=$?
  grep -i "pass\|fail\|✓\|✗\|error" "$LOG_DIR/test_$s.log" | tail -6 | sed 's/^/  /'
  if [ $rc -ne 0 ]; then echo "FAILED: $s (exit $rc), see $LOG_DIR/test_$s.log"; exit $rc; fi
done
echo "all requested suites passed"
