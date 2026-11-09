########################################################################
# enumerate_exact.jl — CERTIFIED optimal policy on a discrete subsidy grid
#
# Exploits two structural facts:
#  (1) The follower problem separates by archetype (all follower
#      constraints are per-archetype; only leader constraints couple).
#      Poor archetypes respond only to the 5 poor rates, rich only to
#      the 5 rich rates. Level 2: each rented archetype responds only
#      to its OWN landlord rate (public or private) — the landlord
#      problems are independent of each other and of the owner problems
#      given the leader's rates, so the decomposition is PRESERVED
#      (plan §4 "Certification/enumeration": confirmed here in code).
#  (2) One follower solve with one side's rates set (others zero) yields
#      that side's exact responses, so the full policy space factorizes:
#         #solves = Σ_side #side-vectors   (not the product)
#
# For every grid combination the leader KPIs are additive across
# archetypes, so feasibility (equity/WPB/EPBD/trajectory/affordability)
# and spending are evaluated arithmetically over the cross product.
# The reported minimum is the EXACT optimum over the grid — no gap.
#
# Usage: julia --project=. enumerate_exact.jl [gridspec] [scenario] [landlord_gridspec]
#        gridspec: "hybrid" (DEFAULT for new proof runs since 2026-10-27,
#        user order): rates 0, 5, 10, 15, 20, 25, 30%, then 10% steps up
#        to each cap, cap always included — for every measure, income
#        group AND the two landlord rates (caps 100%). Or a number
#        (e.g. 0.1): the legacy uniform step, which reproduces every
#        existing certificate. landlord_gridspec defaults to gridspec;
#        a coarser landlord grid is allowed (plan §4) and is stated
#        clearly in the log and in the certificate line.
#        Depth ordering: PLAIN since 2026-10-27 — deep ≥ medium ≥ light,
#        zero allowed (the pre-2026-10-27 spread rule med ≥ light+0.05,
#        deep ≥ light+0.10 made all earlier certificates CONDITIONAL
#        optima; see the CHANGELOG).
########################################################################

GRIDSPEC = length(ARGS) >= 1 ? ARGS[1] : "hybrid"
EN_SCENARIO = length(ARGS) >= 2 ? ARGS[2] : "baseline"
LANDLORD_GRIDSPEC = length(ARGS) >= 3 ? ARGS[3] : GRIDSPEC

# Load the model in the chosen scenario — gives solve_follower, params, and
# runs the CCG heuristic whose best_UB we compare against at the end.
empty!(ARGS); push!(ARGS, EN_SCENARIO)
include(joinpath(@__DIR__, "bilevel_model_affordable_housing.jl"))

using Printf
using Serialization

spec_coarser(a, b) = tryparse(Float64, a) !== nothing &&
    tryparse(Float64, b) !== nothing && parse(Float64, a) > parse(Float64, b) + 1e-12
println("\n" * "="^70)
println("EXACT ENUMERATION on σ-grid (spec = $GRIDSPEC" *
        (GRIDSPEC == "hybrid" ? ": 0/5/10/15/20/25/30%, then 10% steps to cap" : " uniform step") * ")")
if SC.tenure_enabled
    println("  Level 2: landlord rates enumerated on spec = $LANDLORD_GRIDSPEC" *
            (spec_coarser(LANDLORD_GRIDSPEC, GRIDSPEC) ?
             "  *** COARSER SUB-GRID than the household rates — certificate holds on THIS grid ***" : ""))
end
println("="^70)

# σ_keys indices: poor = [1,2,3,7,8], rich = [4,5,6,9,10]
POOR_IDX = [1,2,3,7,8]
RICH_IDX = [4,5,6,9,10]

# Grid per σ dimension (cap always included).
# "hybrid" (default since 2026-10-27): {0, .05, .10, .15, .20, .25, .30}
# up to the cap, then 0.40, 0.50, ... up to the cap, plus the cap itself.
# Numeric spec: the legacy uniform 0 : step : cap grid (existing
# certificates reproduce with their recorded step).
function gridpts(cap; spec=GRIDSPEC)
    cap <= 1e-9 && return [0.0]
    if spec == "hybrid"
        fine   = collect(0.0:0.05:min(cap, 0.30) + 1e-9)
        coarse = cap > 0.30 + 1e-9 ? collect(0.40:0.10:cap + 1e-9) : Float64[]
        return sort(unique(round.(vcat(fine, coarse, [cap]), digits=6)))
    end
    step = parse(Float64, spec)
    return unique(vcat(collect(0.0:step:cap), [cap]))
end

# Enumerate ordered vectors for one income side (light, med, deep, hvac_std, hvac_upg)
# respecting the PLAIN depth ordering: deep ≥ medium ≥ light (zero allowed)
function side_vectors(idxs)
    li, mi, di, hsi, hui = idxs
    vecs = Vector{Vector{Float64}}()
    for l in gridpts(σ_caps[li]), m in gridpts(σ_caps[mi]), d in gridpts(σ_caps[di]),
        hs in gridpts(σ_caps[hsi]), hu in gridpts(σ_caps[hui])
        # PLAIN ordering since 2026-10-27 (user decision): deep ≥ medium ≥
        # light, zero allowed (the old spread rule med ≥ l+0.05, deep ≥
        # l+0.10 made every earlier certificate a CONDITIONAL optimum)
        (m >= l - 1e-9 && d >= m - 1e-9) || continue
        push!(vecs, [l, m, d, hs, hu])
    end
    return vecs
end

# Per-archetype response record from a follower solution
struct Resp
    spend::Float64                  # discounted public spending, this archetype
    spend_low::Float64              # part counting toward the ≥30% floor (lowmask)
    sav::Float64                    # Σ_t site-energy savings × area (WPB numerator terms)
    wpb_sav::Float64
    prim_area::Vector{Float64}      # E_primary × area per period (for EPBD/traj)
end

function arch_response(fr, a, σv)
    # Leader spending at the NOMINAL rate (fr.z is the household-received
    # fraction, which differs under Level 1b clawback; for rented archetypes
    # z_leader equals fr.z — the state pays what the landlord receives)
    spend = sum(inv_cost(a,m,ti) * z_leader(σv,fr,a,m,ti) * disc(years[ti]) * dwell_a[a]
                for m in M, ti in T)
    sav = sum((E_sav_ref(fr, a) - fr.E[a,ti]) * fa_a[a] * dwell_a[a] for ti in T_LEADER:length(T))   # pl12 D7 window
    wpb = wpbmask_a[a] * sav
    prim = [primary_intensity(fr, a, ti) * fa_a[a] * dwell_a[a] for ti in T]
    return Resp(spend, lowmask_a[a] * spend, sav, wpb, prim)
end

# Build response table for one side: solve follower once per side-vector.
# afford_archs: the poor archetypes WHOSE verdicts belong to this side (poor
# owners for the poor side; each landlord type's tenants for its side) — the
# Level 1a affordability constraint is per-archetype and depends only on
# that side's rates, so violating vectors can be excluded BEFORE the cross
# product, and the per-grid-point report is collected here.
function build_table(side::String, idxs, archs, vecs; afford_archs=Int[])
    println("\n$side side: $(length(vecs)) σ-vectors × 1 follower solve each...")
    table = Vector{Vector{Resp}}(undef, length(vecs))
    afford_ok = trues(length(vecs))
    grid_report = []
    t0e = time()
    for (k, v) in enumerate(vecs)
        σv = zeros(n_σ)
        for (j, i) in enumerate(idxs); σv[i] = v[j]; end
        fr = solve_follower(σv)
        fr === nothing && error("follower failed at $side vector $v")
        table[k] = [arch_response(fr, a, σv) for a in archs]
        if !isempty(afford_archs)
            det = affordability_details(fr)
            side_rows = [r for r in det if r.a in afford_archs]
            afford_ok[k] = all(r.ok for r in side_rows)
            for rrow in side_rows, ti in T
                push!(grid_report, (side=side, grid_point=k,
                    sigma=join(round.(v, digits=2), "|"),
                    archetype=arch_id[rrow.a], tenure=tenure_a[rrow.a], year=end_year[ti],
                    bill_after_eur_yr=round(rrow.bill_after[ti], digits=1),
                    own_annualised_eur_yr=round(rrow.own_ann[ti], digits=1),
                    rent_increase_eur_yr=round(rrow.rent_inc[ti], digits=1),
                    cost_after_eur_yr=round(rrow.cost_after[ti], digits=1),
                    cost_reference_eur_yr=round(rrow.cost_ref[ti], digits=1),
                    limit_eur_yr=round(rrow.limit[ti], digits=1),
                    satisfied=rrow.cost_after[ti] <= rrow.limit[ti] + AFFORD_TOL_EUR))
            end
        end
        if k % 250 == 0
            @printf("  %d/%d  (%.0fs elapsed)\n", k, length(vecs), time()-t0e)
        end
    end
    @printf("  done in %.0fs\n", time()-t0e)
    return table, afford_ok, grid_report
end

A_poor_own = [a for a in A if inc_a[a] == "poor" && !is_rented(a)]
A_rich_own = [a for a in A if inc_a[a] == "rich" && !is_rented(a)]
A_rent_pub  = [a for a in A if tenure_a[a] == "rented_public"]
A_rent_priv = [a for a in A if tenure_a[a] == "rented_private"]

poor_vecs = side_vectors(POOR_IDX)
rich_vecs = side_vectors(RICH_IDX)

# ---- Parallel workers (2026-10-27, user order): the response-table builds
# (one follower solve per side-vector, embarrassingly parallel) can be split
# across N processes. Worker k of N solves the strided slices k:N:end of the
# poor AND rich vector lists and serializes its partial tables; a final
# merge run reassembles them in vector order (verified complete) and
# continues with the landlord tables and the exact cross product, which stay
# in one process. With neither env var set the serial path below is
# byte-identical to before. Run shards AND the merge with P4_SKIP_SEARCH=1
# (the CCG heuristic is not needed for the tables; the final heuristic-gap
# line is then skipped and the comparison against the stored search bound
# is made manually). Usage:
#   P4_SKIP_SEARCH=1 P4_ENUM_SHARD=k/N julia --project=.. enumerate_exact.jl <spec> <scen> &  (k = 1..N)
#   P4_SKIP_SEARCH=1 P4_ENUM_MERGE=N   julia --project=.. enumerate_exact.jl <spec> <scen>
ENUM_SHARD_DIR = "out/enum_shards/$(EN_SCENARIO)_$(GRIDSPEC)"
if !isempty(get(ENV, "P4_ENUM_SHARD", ""))
    k, N = parse.(Int, split(ENV["P4_ENUM_SHARD"], "/"))
    (1 <= k <= N) || error("P4_ENUM_SHARD must be k/N with 1<=k<=N")
    idxp = collect(k:N:length(poor_vecs))
    idxr = collect(k:N:length(rich_vecs))
    ptab, pok, prep = build_table("poor[shard $k/$N]", POOR_IDX, A_poor_own,
                                  poor_vecs[idxp]; afford_archs=A_poor_own)
    rtab, _, _ = build_table("rich[shard $k/$N]", RICH_IDX, A_rich_own, rich_vecs[idxr])
    # remap the per-grid-point affordability report to GLOBAL vector indices
    prep_g = [merge(row, (grid_point = idxp[row.grid_point],)) for row in prep]
    mkpath(ENUM_SHARD_DIR)
    serialize("$ENUM_SHARD_DIR/shard_$(k)_of_$(N).jls",
              (k=k, N=N, n_poor=length(poor_vecs), n_rich=length(rich_vecs),
               idxp=idxp, ptab=ptab, pok=pok, prep=prep_g, idxr=idxr, rtab=rtab))
    println("SHARD $k/$N DONE: $(length(idxp)) poor + $(length(idxr)) rich follower solves serialized")
    exit(0)
elseif !isempty(get(ENV, "P4_ENUM_MERGE", ""))
    N = parse(Int, ENV["P4_ENUM_MERGE"])
    poor_tab = Vector{Vector{Resp}}(undef, length(poor_vecs))
    rich_tab = Vector{Vector{Resp}}(undef, length(rich_vecs))
    poor_afford_ok = trues(length(poor_vecs))
    rep_poor = []
    for k in 1:N
        f = "$ENUM_SHARD_DIR/shard_$(k)_of_$(N).jls"
        isfile(f) || error("merge: missing shard file $f")
        d = deserialize(f)
        (d.k == k && d.N == N && d.n_poor == length(poor_vecs) && d.n_rich == length(rich_vecs)) ||
            error("merge: shard $k metadata mismatch (grid or scenario changed between shard and merge?)")
        for (j, i) in enumerate(d.idxp); poor_tab[i] = d.ptab[j]; poor_afford_ok[i] = d.pok[j]; end
        for (j, i) in enumerate(d.idxr); rich_tab[i] = d.rtab[j]; end
        append!(rep_poor, d.prep)
    end
    all(isassigned(poor_tab, i) for i in eachindex(poor_tab)) || error("merge: poor table incomplete")
    all(isassigned(rich_tab, i) for i in eachindex(rich_tab)) || error("merge: rich table incomplete")
    println("MERGE: $(length(poor_vecs)) poor + $(length(rich_vecs)) rich responses assembled from $N shards")
else
    poor_tab, poor_afford_ok, rep_poor =
        build_table("poor", POOR_IDX, A_poor_own, poor_vecs; afford_archs=A_poor_own)
    rich_tab, _, _ = build_table("rich", RICH_IDX, A_rich_own, rich_vecs)
end

# Level 2: one small 1-D table per landlord type (its tenants' affordability
# depends only on that rate, so it is pre-filtered the same way)
pub_vecs  = SC.tenure_enabled ? [[r] for r in gridpts(σ_caps[IDX_LANDLORD_PUBLIC];  spec=LANDLORD_GRIDSPEC)] : [[0.0]]
priv_vecs = SC.tenure_enabled ? [[r] for r in gridpts(σ_caps[IDX_LANDLORD_PRIVATE]; spec=LANDLORD_GRIDSPEC)] : [[0.0]]
if SC.tenure_enabled
    global pub_tab, pub_afford_ok, rep_pub =
        build_table("landlord_public", [IDX_LANDLORD_PUBLIC], A_rent_pub, pub_vecs;
                    afford_archs=A_rent_pub)
    # affordability_scope (D5x): private tenants are reported, not enforced —
    # same semantics as affordability_check in the model
    global priv_tab, priv_afford_ok, rep_priv =
        build_table("landlord_private", [IDX_LANDLORD_PRIVATE], A_rent_priv, priv_vecs;
                    # enforcement is poor tenants only (2026-10-08): the rich
                    # private twin is reported, never filtered on
                    afford_archs=SC.affordability_scope == "all" ?
                        [a for a in A_rent_priv if inc_a[a] == "poor"] : Int[])
else
    global pub_tab  = [Resp[]]; global pub_afford_ok  = trues(1); global rep_pub  = []
    global priv_tab = [Resp[]]; global priv_afford_ok = trues(1); global rep_priv = []
end

# Level 1a/2: report and (when the mode is on) enforce affordability per vector
AFFORD_BINDING = SC.affordability_mode != "off"
afford_grid_report = vcat(rep_poor, rep_pub, rep_priv)
if !isempty(afford_grid_report)
    CSV.write("$OUTDIR/affordability_grid_report.csv", DataFrame(afford_grid_report))
    println("  Per-grid-point affordability report → $OUTDIR/affordability_grid_report.csv")
end
for (nm, vv, okv) in (("poor", poor_vecs, poor_afford_ok),
                      ("landlord_public", pub_vecs, pub_afford_ok),
                      ("landlord_private", priv_vecs, priv_afford_ok))
    (nm != "poor" && !SC.tenure_enabled) && continue
    nviol = count(!, okv)
    println("  Affordability ($(SC.affordability_mode)) on $nm side: $nviol of $(length(vv)) " *
            "σ-vectors violate" *
            (AFFORD_BINDING ? " → EXCLUDED from the grid (feasible set ⊆ baseline set by construction)" :
                              " (not enforced — reported only)"))
end

# Pre-aggregate per side (empty side = zero contribution)
agg(resps) = (spend = sum(r.spend for r in resps; init=0.0),
              spend_low = sum(r.spend_low for r in resps; init=0.0),
              sav = sum(r.sav for r in resps; init=0.0),
              wpb = sum(r.wpb_sav for r in resps; init=0.0),
              prim = isempty(resps) ? zeros(n_years) : reduce(+, [r.prim_area for r in resps]))
poor_agg = [agg(t) for t in poor_tab]
rich_agg = [agg(t) for t in rich_tab]
pub_agg  = [agg(t) for t in pub_tab]
priv_agg = [agg(t) for t in priv_tab]

# Trajectory targets per period index
traj_req = fill(Inf, n_years)
for (k, yr) in enumerate(traj_years)
    tidx = get(end_t_idx, yr, nothing)
    tidx !== nothing && (traj_req[tidx] = traj_values[k])
end
TI2050 !== nothing && (traj_req[TI2050] = min(traj_req[TI2050], epbd_target))

# Cross product: exact feasibility + spending, purely arithmetic.
# With tenure off the landlord sides are single zero entries, so this is
# bit-for-bit the former poor × rich loop.
function combine()
    best = Inf; best_combo = (0, 0, 0, 0); nfeas = 0
    for i in eachindex(poor_agg)
        AFFORD_BINDING && !poor_afford_ok[i] && continue
        p = poor_agg[i]
        for u in eachindex(pub_agg)
            AFFORD_BINDING && !pub_afford_ok[u] && continue
            pu = pub_agg[u]
            for v in eachindex(priv_agg)
                AFFORD_BINDING && !priv_afford_ok[v] && continue
                pv = priv_agg[v]
                spend3 = p.spend + pu.spend + pv.spend
                spend3 - 1e-12 >= best && continue   # partial dominance prune
                for j in eachindex(rich_agg)
                    r = rich_agg[j]
                    spend = spend3 + r.spend
                    spend >= best && continue        # dominance prune
                    # equity: low-share spending ≥ floor (0-spend policies pass
                    # vacuously, matching evaluate_σ's NaN-tolerant check)
                    spend_low = p.spend_low + pu.spend_low + pv.spend_low + r.spend_low
                    if spend > 1e-6 && spend_low < equity_min_eff * spend - 1e-6; continue; end
                    # WPB
                    tot_sav = p.sav + pu.sav + pv.sav + r.sav
                    tot_wpb = p.wpb + pu.wpb + pv.wpb + r.wpb
                    if tot_sav > 1e-9 && tot_wpb < 0.55 * tot_sav - 1e-6; continue; end
                    # EPBD + trajectory
                    ok = true
                    for ti in 1:n_years
                        if isfinite(traj_req[ti]) &&
                           (p.prim[ti] + pu.prim[ti] + pv.prim[ti] + r.prim[ti]) / total_area > traj_req[ti] + 0.1
                            ok = false; break
                        end
                    end
                    ok || continue
                    nfeas += 1
                    best = spend; best_combo = (i, j, u, v)
                end
            end
        end
    end
    return best, best_combo, nfeas
end

# ---- Parallel cross product (2026-11-03, user order; worktree-parallel-merge) ----
# Active only when julia runs with -t N (N > 1); with 1 thread the serial
# combine() above runs byte-identically. Exact-reproduction design:
#   * the poor (outer) index is split into nthreads contiguous, ordered
#     chunks; within a chunk each thread runs the SAME loop body with the
#     SAME skip rule against its LOCAL incumbent (spend >= lbest skips),
#     so each thread finds the first-in-order argmin of its chunk;
#   * a shared atomic global bound (gbest) sharpens pruning across
#     threads but is compared STRICTLY (spend > gbest skips), so a combo
#     that TIES the global minimum is never pruned away — the reduce can
#     then pick, among threads with the identical minimal value, the
#     lowest chunk (= earliest in serial order), which reproduces the
#     serial tie-break (first argmin in loop order) exactly;
#   * all spending/feasibility arithmetic is the same expressions on the
#     same aggregates, so every checked combo gets a bitwise-identical
#     verdict. The certificate value and σ therefore match the serial
#     merge exactly. Only the printed "feasible improvements" counter is
#     path-dependent (it counts incumbent updates, which depend on how
#     pruning interleaves) and is labelled accordingly.
#   * a monitor task prints progress with flush every 60 s.
function combine_parallel()
    nth = Threads.nthreads()
    # reserve one thread for the progress monitor: compute tasks never
    # yield, so with nwork == nthreads the monitor would be starved and
    # print nothing until the first chunk finishes
    nwork = max(nth - 1, 1)
    nP = length(poor_agg)
    bounds = round.(Int, range(0, nP; length=nwork+1))
    gbest = Threads.Atomic{Float64}(Inf)
    nprog = Threads.Atomic{Int}(0)
    results = Vector{Tuple{Float64,NTuple{4,Int},Int}}(undef, nwork)
    t0p = time()
    # Count-based progress from the workers themselves (2026-11-04): the
    # sleep(60) monitor below starves when a non-yielding compute task sits
    # on the libuv timer thread (observed: pl10_inclusive, 10 h without a
    # line). Printing on a progress count needs no timer. Print-only change;
    # the enumeration arithmetic is untouched (exact-reproduction mode).
    prog_every = max(1, nP ÷ 200)
    plock = Threads.SpinLock()
    bump_progress!() = begin
        dn = Threads.atomic_add!(nprog, 1) + 1
        if dn % prog_every == 0 || dn == nP
            el = time() - t0p
            if trylock(plock)
                @printf("  cross-product progress: %d/%d poor vectors (%.1f%%)  elapsed %.0fs  projected total %.0fs  incumbent €%.1fM\n",
                        dn, nP, 100*dn/nP, el, el*nP/dn, gbest[]/1e6)
                flush(stdout)
                unlock(plock)
            end
        end
    end
    done_flag = Threads.Atomic{Bool}(false)
    printer = Threads.@spawn begin
        while !done_flag[]
            sleep(60)
            done_flag[] && break
            dn = nprog[]
            el = time() - t0p
            @printf("  cross-product progress: %d/%d poor vectors (%.1f%%)  elapsed %.0fs  projected total %.0fs  incumbent €%.1fM\n",
                    dn, nP, 100*dn/nP, el, el*nP/max(dn,1), gbest[]/1e6)
            flush(stdout)
        end
    end
    @sync for t in 1:nwork
        Threads.@spawn begin
            lo, hi = bounds[t] + 1, bounds[t+1]
            lbest = Inf; lcombo = (0, 0, 0, 0); lfeas = 0
            for i in lo:hi
                if AFFORD_BINDING && !poor_afford_ok[i]
                    bump_progress!(); continue
                end
                p = poor_agg[i]
                gb = gbest[]
                for u in eachindex(pub_agg)
                    AFFORD_BINDING && !pub_afford_ok[u] && continue
                    pu = pub_agg[u]
                    for v in eachindex(priv_agg)
                        AFFORD_BINDING && !priv_afford_ok[v] && continue
                        pv = priv_agg[v]
                        spend3 = p.spend + pu.spend + pv.spend
                        # serial slack rule vs the local incumbent; STRICT vs the global bound
                        (spend3 - 1e-12 >= lbest || spend3 - 1e-12 > gb) && continue
                        for j in eachindex(rich_agg)
                            r = rich_agg[j]
                            spend = spend3 + r.spend
                            (spend >= lbest || spend > gb) && continue
                            spend_low = p.spend_low + pu.spend_low + pv.spend_low + r.spend_low
                            if spend > 1e-6 && spend_low < equity_min_eff * spend - 1e-6; continue; end
                            tot_sav = p.sav + pu.sav + pv.sav + r.sav
                            tot_wpb = p.wpb + pu.wpb + pv.wpb + r.wpb
                            if tot_sav > 1e-9 && tot_wpb < 0.55 * tot_sav - 1e-6; continue; end
                            ok = true
                            for ti in 1:n_years
                                if isfinite(traj_req[ti]) &&
                                   (p.prim[ti] + pu.prim[ti] + pv.prim[ti] + r.prim[ti]) / total_area > traj_req[ti] + 0.1
                                    ok = false; break
                                end
                            end
                            ok || continue
                            lfeas += 1
                            lbest = spend; lcombo = (i, j, u, v)
                            # publish the improved bound (atomic min)
                            while true
                                cur = gbest[]
                                lbest >= cur && break
                                Threads.atomic_cas!(gbest, cur, lbest) === cur && break
                            end
                            gb = gbest[]
                        end
                        gb = gbest[]
                    end
                end
                bump_progress!()
            end
            results[t] = (lbest, lcombo, lfeas)
        end
    end
    done_flag[] = true
    wait(printer)   # let the monitor exit so no progress line interleaves with the certificate block
    # reduce: minimal value; among exact ties the lowest chunk = earliest
    # serial order (within a chunk the thread already kept its first argmin)
    best = Inf; best_combo = (0, 0, 0, 0); nfeas = 0
    for t in 1:nwork
        (lb, lc, lf) = results[t]
        nfeas += lf
        if lb < best
            best = lb; best_combo = lc
        end
    end
    return best, best_combo, nfeas
end

t0c = time()
if Threads.nthreads() > 1
    @printf("\nPARALLEL cross product on %d threads (exact-reproduction mode)\n", Threads.nthreads())
    flush(stdout)
    best, (bi, bj, bu, bv), nfeas = combine_parallel()
else
    best, (bi, bj, bu, bv), nfeas = combine()
end
ncombos = length(poor_agg) * length(rich_agg) * length(pub_agg) * length(priv_agg)
@printf("\nCross product: %d combinations checked in %.1fs — %d feasible improvements%s\n",
        ncombos, time()-t0c, nfeas,
        Threads.nthreads() > 1 ? " (thread-local update count; not comparable with the serial counter)" : "")
flush(stdout)

println("\n" * "="^70)
println("CERTIFIED GRID OPTIMUM (spec = $GRIDSPEC" *
        (SC.tenure_enabled ? ", landlord spec = $LANDLORD_GRIDSPEC" : "") * ")")
println("="^70)
if isinf(best)
    println("  NO feasible policy on this grid — infeasibility is certified for the grid.")
else
    σ_opt = zeros(n_σ)
    for (j, i) in enumerate(POOR_IDX); σ_opt[i] = poor_vecs[bi][j]; end
    for (j, i) in enumerate(RICH_IDX); σ_opt[i] = rich_vecs[bj][j]; end
    if SC.tenure_enabled
        σ_opt[IDX_LANDLORD_PUBLIC]  = pub_vecs[bu][1]
        σ_opt[IDX_LANDLORD_PRIVATE] = priv_vecs[bv][1]
    end
    @printf("  Optimal spending:  €%.3fM  (CERTIFIED minimum on grid)\n", best/1e6)
    println("  Optimal σ:")
    for i in 1:n_σ
        @printf("    %-30s %5.1f%%\n", string(σ_keys[i]), 100*σ_opt[i])
    end
    # cross-check with a joint follower solve (separability verification;
    # evaluate_σ includes the affordability check, so a disagreement between
    # the enumeration filter and the shared check aborts here)
    ev = evaluate_σ(σ_opt)
    @printf("  Joint re-evaluation: feasible=%s, spending €%.3fM (must match)\n",
            ev.feasible, ev.ub/1e6)
    ev.feasible || error("CONSISTENCY FAILURE: certified grid optimum rejected by evaluate_σ " *
                         "(afford_ok=$(ev.afford_ok)) — enumeration filter and shared check disagree")
    abs(ev.ub - best) <= 1e-4 * max(best, 1.0) ||
        error("CONSISTENCY FAILURE: joint spending €$(ev.ub) ≠ certified €$best")
    if (@isdefined best_σ) && best_σ !== nothing
        @printf("  CCG heuristic UB was €%.3fM → heuristic gap vs grid optimum: %.1f%%\n",
                best_UB/1e6, 100*(best_UB - best)/max(best_UB,1.0))
    elseif haskey(ENV, "P4_SKIP_SEARCH")
        println("  (loaded with P4_SKIP_SEARCH — compare against the stored search bound manually)")
    else
        println("  (CCG heuristic found no feasible solution on this scenario)")
    end
end
println("="^70)
