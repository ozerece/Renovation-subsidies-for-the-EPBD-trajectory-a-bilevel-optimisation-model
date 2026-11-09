#!/bin/bash
########################################################################
# build_release.sh — assemble the P4 public-release folder (version pl12)
# from the source repository R (bilevel_optimization, branch pl12).
#
# Usage:  tools/build_release.sh <R>
#   R     the source repository (read-only; nothing in R is modified)
#   DEST  the release folder = the parent of this script's folder (tools/..)
#
# Idempotent: it may be re-run over an existing release folder. It (re)copies
# the listed content, applies the path fixes to the copies, audits the result
# and refuses (exit 1) if an excluded pattern is present. It never deletes or
# rewrites DEST/.git, the root documents (README.md, MANIFEST.md, LICENSE*,
# CITATION.cff, .zenodo.json, INVERT_DERIVED.md, .gitignore) or tools/.
# Every included and excluded path group is listed in MANIFEST.md.
########################################################################
set -euo pipefail
R="${1:?usage: tools/build_release.sh <source repository R>}"
R="$(cd "$R" && pwd)"
A="$R/affordable_housing"
DEST="$(cd "$(dirname "$0")/.." && pwd)"
D="$DEST/affordable_housing"
die() { echo "build_release: $*" >&2; exit 1; }
# the source commit the release was built from (branch pl12, frozen 2026-11-09); the record check compares against it
FROZEN="${P4_RELEASE_SOURCE_COMMIT:-6d77ac9}"
[ -f "$A/bilevel_model_affordable_housing.jl" ] || die "$A is not the model folder"
[ -f "$R/Project.toml" ] && [ -f "$R/Manifest.toml" ] || die "$R lacks Project.toml/Manifest.toml"
[ "$DEST" != "$R" ] && [ "$DEST" != "$A" ] || die "DEST must not be the source repository"
echo "source  R    = $R"
echo "release DEST = $DEST"

# ---------------------------------------------------------------- lists
# 1. model code, proofs, tests, reporting scripts (pl12 pipeline only)
CODE=(bilevel_model_affordable_housing.jl enumerate_local.jl enumerate_exact.jl
      make_pl12_outcomes.jl test_pl12_pins.jl test_invariants.jl test_affordability.jl
      test_tenure.jl test_rentlaw.jl test_switches_off.jl household_structure.jl
      make_pl11_summary.py make_pl12_design_table.py make_pl12_figures.py make_pl12_paper_numbers.py
      make_pl12_review_evals.jl MODEL_MAP.md CHANGELOG.md)
# 2. input data at the model-folder root (all stock variants referenced by SCENARIO_DEFS + defaults)
INPUTS=(archetypes_pl.csv archetypes_pl_mix.csv archetypes_pl_inclusive_mix.csv
        archetypes_pl_kprb.csv archetypes_pl_kprb_mix.csv archetypes_v2.csv
        measures_v2.csv context.csv eurostat_tenure_income_PL.csv label_map.csv)
# 2b. data/: every *.csv and *.md (history files, start designs, record and local25 designs, provenance)
#     except the unused draft stock; never *.pdf / *.xlsx (third-party documents, listed in README)
DATA_EXCLUDE=(archetypes_pl_DRAFT.csv)
# 4. results of record
RESULTS=(results/pl12_summary.csv results/pl12_multistart_summary.csv
         results/pl12_design_table.csv results/pl12_outcome_measures.csv results/README.md
         results/rev12_summary.csv results/rev12_multistart_summary.csv
         results/paper/pl12_paper_numbers.csv results/paper/pl12_final_report.md
         results/paper/P4_decisions_2026-11-06.md results/paper/pl11_phase2_realism_check.md
         results/paper/P4_open_questions_report.md)
# 4b. run folders: every out/scenarios/pl12* and out/scenarios/rev12* (the pre-registered pl12 wave,
#     the D10 strict re-runs, the local-proof record dirs, and the review follow-ups of 2026-11-08/09:
#     rev12_*, *__ms_rec25, *__chk_rev12, pl12__review_evals, the re-proved R5 scenarios).
#     affordability_local_report.csv (the per-grid-point by-product of a local proof, 12-116 MB each,
#     read by no script) is stored gzipped to keep the release under 300 MB.
RUN_GLOBS=('pl12*' 'rev12*')
GZIP_FILES=(affordability_local_report.csv)
# 4c. certificate and run logs (globs relative to results/cert_logs)
LOG_GLOBS=('proof_local_pl12*.log' 'proof_local_rev12*.log' 'run_pl12*.log' 'run_rev12*.log'
           'eval_pl12*.log' 'eval_rev12*.log' 'eval_pl10_gate_pl12_pl10.log' 'eval_pl11_gate_pl12_pl11.log'
           'pl12_wave.log' 'pl12_wave_driver.log' 'pl12_strict_launcher.log' 'rev12_wave.log'
           'pl12_outcomes_run*.log' 'test_pl12*.log' 'pl11_done.txt')
# 4d. review follow-up evaluations (CSV outputs, their log and the hand-over STATUS note)
REVIEW_DIR=results/review_2026-11-08
# 5. figure folders
FIG_DIRS=(results/figures_pl12 results/figures_pl12_journal)

matches_any() {  # matches_any <name> <glob...>
  local n="$1"; shift; local g
  for g in "$@"; do [[ "$n" == $g ]] && return 0; done
  return 1
}

# ---------------------------------------------------------------- copy
mkdir -p "$D/data" "$D/results/paper" "$D/results/cert_logs" "$D/out/scenarios" "$DEST/scripts"
echo "[1] code and documentation"
for f in "${CODE[@]}"; do cp -p "$A/$f" "$D/$f"; done
echo "[2] input data"
for f in "${INPUTS[@]}"; do cp -p "$A/$f" "$D/$f"; done
n_data=0
for f in "$A"/data/*.csv "$A"/data/*.md; do
  b="$(basename "$f")"
  matches_any "$b" "${DATA_EXCLUDE[@]}" && continue
  cp -p "$f" "$D/data/$b"; n_data=$((n_data+1))
done
echo "    data/: $n_data files (csv + md)"
echo "[3] wrappers and Julia project"
rsync -a --include='*.sh' --include='*.jl' --include='README.md' --exclude='*' "$R/scripts/" "$DEST/scripts/"
cp -p "$R/Project.toml" "$R/Manifest.toml" "$DEST/"
echo "[4] results of record"
for f in "${RESULTS[@]}"; do cp -p "$A/$f" "$D/$f"; done
n_runs=0; n_gz=0
for g in "${RUN_GLOBS[@]}"; do
  for d in "$A"/out/scenarios/$g; do
    [ -d "$d" ] || continue
    b="$(basename "$d")"
    rsync -a $(printf -- "--exclude=%s " "${GZIP_FILES[@]}") "$d/" "$D/out/scenarios/$b/"
    for z in "${GZIP_FILES[@]}"; do
      if [ -f "$d/$z" ] && { [ ! -f "$D/out/scenarios/$b/$z.gz" ] || [ "$d/$z" -nt "$D/out/scenarios/$b/$z.gz" ]; }; then
        gzip -c -6 "$d/$z" > "$D/out/scenarios/$b/$z.gz"; touch -r "$d/$z" "$D/out/scenarios/$b/$z.gz"; n_gz=$((n_gz+1))
      fi
    done
    n_runs=$((n_runs+1))
  done
done
echo "    run folders: $n_runs copied ($n_gz proof by-product files gzipped)"
n_logs=0
for g in "${LOG_GLOBS[@]}"; do
  for f in "$A"/results/cert_logs/$g; do
    [ -f "$f" ] || continue
    b="$(basename "$f")"
    cp -p "$f" "$D/results/cert_logs/$b"; n_logs=$((n_logs+1))
  done
done
echo "    cert_logs: $n_logs files"
mkdir -p "$D/$REVIEW_DIR"; rsync -a "$A/$REVIEW_DIR/" "$D/$REVIEW_DIR/"
echo "    $REVIEW_DIR: $(find "$D/$REVIEW_DIR" -type f | wc -l) files"
echo "[5] figures"
for d in "${FIG_DIRS[@]}"; do mkdir -p "$D/$d"; rsync -a "$A/$d/" "$D/$d/"; done

# ---------------------------------------------------------------- path fixes
echo "[6] path fixes"
FIXLOG="$DEST/tools/PATH_FIXES.txt"
{
  echo "# Files in which absolute paths of the source machine were replaced (generated by tools/build_release.sh, $(date '+%F %H:%M'))"
  echo "# rule 1: enumerate_local.jl  const MAINTREE = \"<R>/affordable_housing\"  ->  const MAINTREE = @__DIR__"
  echo "# rule 2: \"<R>/\" -> \"\" (paths become relative to the release root), a bare \"<R>\" -> \".\""
  echo "# rule 3: \"<HOME>\" -> \"\$HOME\""
} > "$FIXLOG"
# rule 1 (behaviour preserved: the file is included from the model folder, so @__DIR__ is that folder)
if grep -q '^const MAINTREE = "' "$D/enumerate_local.jl"; then
  sed -i 's|^const MAINTREE = ".*"$|const MAINTREE = @__DIR__   # release: the model folder itself (the source tree used an absolute path to the main checkout)|' "$D/enumerate_local.jl"
  echo "affordable_housing/enumerate_local.jl  (rule 1)" >> "$FIXLOG"
fi
# rules 2-3 on every copied text file (not the root documents, not tools/, not .git)
HOMEPAT="${HOME}"
mapfile -t HITS < <(grep -rIl -e "$R" -e "$HOMEPAT" "$D" "$DEST/scripts" "$DEST/Project.toml" "$DEST/Manifest.toml" 2>/dev/null || true)
for f in "${HITS[@]}"; do
  sed -i -e "s#$R/##g" -e "s#$R#.#g" -e "s#$HOMEPAT#\$HOME#g" "$f"
  echo "${f#$DEST/}  (rules 2-3)" >> "$FIXLOG"
done
echo "    ${#HITS[@]} files with absolute paths rewritten (+ enumerate_local.jl MAINTREE); list: tools/PATH_FIXES.txt"

# ---------------------------------------------------------------- audit (refuse on failure)
echo "[7] audit"
fail=0
bad=$(find "$DEST" -path "$DEST/.git" -prune -o -path "$DEST/tools" -prune -o \
  \( -name 'enum_shards' -o -name '_scratch' \
     -o -name 'gurobi.env' -o -name '*.lic' -o -name '__pycache__' -o -name 'experiments' \
     -o -name 'test_small_instance' -o -name 'archetypes_pl_DRAFT.csv' -o -name 'Manifest.toml.julia11.backup' \
     -o -name 'figures_pl10*' -o -name 'figures_pl11*' -o -name 'pl10_*.csv' -o -name 'pl11_*.csv' \) -print)
[ -z "$bad" ] || { echo "EXCLUDED NAMES PRESENT:"; echo "$bad"; fail=1; }
bad=$(find "$D/data" -type f \( -name '*.pdf' -o -name '*.xlsx' \) -print)
[ -z "$bad" ] || { echo "THIRD-PARTY DOCUMENTS PRESENT in data/:"; echo "$bad"; fail=1; }
bad=$(find "$D/out/scenarios" -mindepth 1 -maxdepth 1 ! -name 'pl12*' ! -name 'rev12*' -print)
[ -z "$bad" ] || { echo "RUN FOLDERS OUTSIDE pl12*/rev12* PRESENT:"; echo "$bad"; fail=1; }
bad=$(find "$D/out/scenarios" -type f -name 'affordability_local_report.csv' -print)
[ -z "$bad" ] || { echo "UNCOMPRESSED PROOF BY-PRODUCTS PRESENT:"; echo "$bad"; fail=1; }
bad=$(find "$DEST" -path "$DEST/.git" -prune -o -type f -name '*.log' ! -path "$D/results/cert_logs/*" ! -path "$D/$REVIEW_DIR/*" -print)
[ -z "$bad" ] || { echo "LOGS OUTSIDE cert_logs:"; echo "$bad"; fail=1; }
bad=$(grep -rIl -E 'WLSACCESSID|LICENSEID|GRB_LICENSE' "$D" "$DEST/scripts" "$DEST/Project.toml" "$DEST/Manifest.toml" 2>/dev/null || true)
[ -z "$bad" ] || { echo "CREDENTIAL TOKENS PRESENT:"; echo "$bad"; fail=1; }
bad=$(grep -rIl -e '/media/944a3ab1' -e '/home/users/' "$DEST" --exclude-dir=.git --exclude-dir=tools 2>/dev/null || true)
[ -z "$bad" ] || { echo "ABSOLUTE PATHS REMAIN:"; echo "$bad"; fail=1; }
[ "$fail" = 0 ] || die "audit failed — the release folder contains excluded content (see above)"
echo "    audit passed"

# ---------------------------------------------------------------- record-file check (informational)
echo "[8] record check against the frozen source commit ($FROZEN)"
if git -C "$R" rev-parse --verify -q "$FROZEN" >/dev/null 2>&1; then
  for f in bilevel_model_affordable_housing.jl make_pl11_summary.py make_pl12_figures.py make_pl12_paper_numbers.py \
           results/pl12_summary.csv results/pl12_multistart_summary.csv results/pl12_design_table.csv \
           results/pl12_outcome_measures.csv results/paper/pl12_paper_numbers.csv results/paper/pl12_final_report.md \
           data/sigma_pl12_local25_record.csv out/scenarios/pl12__local25_record/scenario_summary.csv; do
    if ! git -C "$R" diff --quiet "$FROZEN" -- "affordable_housing/$f" 2>/dev/null; then
      echo "    WARNING: affordable_housing/$f differs from commit $FROZEN (modified in R after the freeze)"
    fi
  done
  git -C "$R" diff "$FROZEN" -- affordable_housing/bilevel_model_affordable_housing.jl > "$DEST/tools/model_file_vs_frozen_commit.diff" || true
  echo "    model-file diff vs $FROZEN: $(grep -c '^[-+][^-+]' "$DEST/tools/model_file_vs_frozen_commit.diff" || true) changed lines (tools/model_file_vs_frozen_commit.diff; empty = identical)"
  echo "    source HEAD: $(git -C "$R" rev-parse --short HEAD) ($(git -C "$R" branch --show-current))"
else
  echo "    (commit $FROZEN not found in R — check skipped)"
fi

# ---------------------------------------------------------------- inventory and size
echo "[9] inventory"
INV="$DEST/tools/INVENTORY.txt"
{
  echo "# Release inventory (generated by tools/build_release.sh, $(date "+%F %H:%M"), source repository $(basename "$R") at commit $(git -C "$R" rev-parse --short HEAD 2>/dev/null || echo unknown))"
  printf "%-52s %8s %10s\n" "group" "files" "size"
  grp() { local n s; n=$( (find "$@" -type f 2>/dev/null || true) | wc -l); s=$( (du -sk --apparent-size "$@" 2>/dev/null || true) | awk '{t+=$1} END {printf "%.1f MB", t/1024}'); printf "%-52s %8s %10s\n" "$label" "$n" "$s"; }
  label="affordable_housing/*.jl *.py *.md *.csv (code, inputs)"; grp "$D"/*.jl "$D"/*.py "$D"/*.md "$D"/*.csv
  label="affordable_housing/data"; grp "$D/data"
  label="affordable_housing/out/scenarios (pl12*/rev12* run folders)"; grp "$D/out/scenarios"
  label="affordable_housing/results/cert_logs"; grp "$D/results/cert_logs"
  label="affordable_housing/results/figures_pl12"; grp "$D/results/figures_pl12"
  label="affordable_housing/results/figures_pl12_journal"; grp "$D/results/figures_pl12_journal"
  label="affordable_housing/results (tables, paper, review, README)"; grp "$D"/results/*.csv "$D/results/README.md" "$D/results/paper" "$D/$REVIEW_DIR"
  label="scripts + Project.toml + Manifest.toml"; grp "$DEST/scripts" "$DEST/Project.toml" "$DEST/Manifest.toml"
  label="root documents + tools"; grp "$DEST"/*.md "$DEST"/LICENSE* "$DEST/CITATION.cff" "$DEST/.zenodo.json" "$DEST/tools"
  echo
  echo "run folders: $(find "$D/out/scenarios" -mindepth 1 -maxdepth 1 -type d | wc -l)"
  echo "total (without .git): $( (du -sk --apparent-size --exclude=.git "$DEST" || true) | awk '{printf "%.1f MB", $1/1024}')"
} > "$INV"
cat "$INV"
echo "build_release: done"
