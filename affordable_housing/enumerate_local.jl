########################################################################
# enumerate_local.jl — LOCAL exact proof around a stored search design
# (2026-11-03 user order, task (2) of the pl10 ruling).
#
# Identical machinery to enumerate_exact.jl (same Resp/arch_response/
# build_table/shard/merge/combine/combine_parallel code, worktree-
# parallel-merge version verified exact on pl9), with ONE change: the
# per-rate grid is a LOCAL box around the scenario's stored continuous
# search design (out/scenarios/<scn>/subsidies.csv in the MAIN tree):
#   each rate takes the 9 values center + k*2.5% for k = -4..4,
#   clamped to [0, cap] (duplicates after clamping removed), and the
#   PLAIN depth ordering deep >= medium >= light is enforced as always.
# The center itself (k = 0) is always on the grid, so the local optimum
# is <= the search design's value by construction if the center passes
# the arithmetic feasibility check.
# The result is the EXACT minimum over this local box — reported as a
# CERTIFIED LOCAL OPTIMUM, deliberately NOT the string "CERTIFIED GRID
# OPTIMUM" so that no watcher or figure-script certificate parser picks
# it up as a grid certificate.
#
# Usage (from the worktree, cwd = its affordable_housing/):
#   P4_SKIP_SEARCH=1 P4_LOCAL_SMOKE=1 julia --project=<mainroot> enumerate_local.jl <scen>
#   P4_SKIP_SEARCH=1 P4_ENUM_SHARD=k/N julia --project=<mainroot> enumerate_local.jl <scen>
#   P4_SKIP_SEARCH=1 P4_ENUM_MERGE=N   julia -t <nt> --project=<mainroot> enumerate_local.jl <scen>
########################################################################

EN_SCENARIO = length(ARGS) >= 1 ? ARGS[1] : "pl10"

empty!(ARGS); push!(ARGS, EN_SCENARIO)
include(joinpath(@__DIR__, "bilevel_model_affordable_housing.jl"))

using Printf
using Serialization

# ---- Local grid: center = the stored search design of the MAIN tree ----
const MAINTREE = @__DIR__   # release: the model folder itself (the source tree used an absolute path to the main checkout)
const LOC_STEP = 0.025
const LOC_KMAX = 4            # +-4 * 2.5% = +-10 points

function _csvkey(k)
    cls, depth, who = k
    cls == "envelope" && return (who, "env_" * depth)
    cls == "hvac"     && return (who, depth == "standard" ? "hvac_std" : "hvac_upg")
    cls == "landlord" && return ("landlord_" * who, "all_non_pv")
    error("unknown σ key $k")
end

# Re-centring hook (2026-11-04 user authorization, item 2): if the main tree
# holds out/scenarios/<scn>/subsidies_local_center.csv, that design is the
# center (the new best search design); otherwise subsidies.csv as before.
const CENTER_FILE = let override = joinpath(MAINTREE, "out/scenarios/$EN_SCENARIO/subsidies_local_center.csv")
    isfile(override) ? override : joinpath(MAINTREE, "out/scenarios/$EN_SCENARIO/subsidies.csv")
end
let sub = CSV.read(CENTER_FILE, DataFrame)
    rate = Dict((String(r.group), String(r.measure)) => Float64(r.rate) for r in eachrow(sub))
    global CENTER = zeros(n_σ)
    for i in 1:n_σ
        g, m = _csvkey(σ_keys[i])
        haskey(rate, (g, m)) || error("center rate ($g,$m) not in $CENTER_FILE")
        CENTER[i] = rate[(g, m)]
        CENTER[i] <= σ_caps[i] + 1e-9 || error("center $(CENTER[i]) above cap for $(σ_keys[i])")
    end
end

function localpts(i)
    cap = σ_caps[i]
    cap <= 1e-9 && return [0.0]
    pts = [clamp(CENTER[i] + k * LOC_STEP, 0.0, cap) for k in -LOC_KMAX:LOC_KMAX]
    return sort(unique(round.(pts, digits=6)))
end

println("\n" * "="^70)
println("LOCAL EXACT ENUMERATION around the stored search design — $EN_SCENARIO")
println("  box: each rate at center + k*2.5% (k = -4..4), clamped to [0, cap]")
println("  center (verbatim from $CENTER_FILE):")
for i in 1:n_σ
    @printf("    %-32s %10.6f%%  → %d local values\n",
            string(σ_keys[i]), 100*CENTER[i], length(localpts(i)))
end
println("="^70)

# σ_keys indices: poor = [1,2,3,7,8], rich = [4,5,6,9,10]
POOR_IDX = [1,2,3,7,8]
RICH_IDX = [4,5,6,9,10]

# Enumerate ordered vectors for one income side (light, med, deep, hvac_std, hvac_upg)
# respecting the PLAIN depth ordering: deep ≥ medium ≥ light (zero allowed)
function side_vectors(idxs)
    li, mi, di, hsi, hui = idxs
    vecs = Vector{Vector{Float64}}()
    for l in localpts(li), m in localpts(mi), d in localpts(di),
        hs in localpts(hsi), hu in localpts(hui)
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
    spend = sum(inv_cost(a,m,ti) * z_leader(σv,fr,a,m,ti) * disc(years[ti]) * dwell_a[a]
                for m in M, ti in T)
    sav = sum((E_sav_ref(fr, a) - fr.E[a,ti]) * fa_a[a] * dwell_a[a] for ti in T_LEADER:length(T))   # pl12 D7 window
    wpb = wpbmask_a[a] * sav
    prim = [primary_intensity(fr, a, ti) * fa_a[a] * dwell_a[a] for ti in T]
    return Resp(spend, lowmask_a[a] * spend, sav, wpb, prim)
end

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
                    sigma=join(round.(v, digits=4), "|"),
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

if haskey(ENV, "P4_LOCAL_SMOKE")
    println("SMOKE: $(length(poor_vecs)) poor × $(length(rich_vecs)) rich side-vectors; " *
            "landlord values $(SC.tenure_enabled ? (length(localpts(IDX_LANDLORD_PUBLIC)), length(localpts(IDX_LANDLORD_PRIVATE))) : (1,1))")
    println("SMOKE: cross product = $(length(poor_vecs)) × $(length(rich_vecs)) × " *
            "$(SC.tenure_enabled ? length(localpts(IDX_LANDLORD_PUBLIC)) : 1) × " *
            "$(SC.tenure_enabled ? length(localpts(IDX_LANDLORD_PRIVATE)) : 1)")
    exit(0)
end

ENUM_SHARD_DIR = "out/enum_shards/$(EN_SCENARIO)_local25"
if !isempty(get(ENV, "P4_ENUM_SHARD", ""))
    k, N = parse.(Int, split(ENV["P4_ENUM_SHARD"], "/"))
    (1 <= k <= N) || error("P4_ENUM_SHARD must be k/N with 1<=k<=N")
    idxp = collect(k:N:length(poor_vecs))
    idxr = collect(k:N:length(rich_vecs))
    ptab, pok, prep = build_table("poor[shard $k/$N]", POOR_IDX, A_poor_own,
                                  poor_vecs[idxp]; afford_archs=A_poor_own)
    rtab, _, _ = build_table("rich[shard $k/$N]", RICH_IDX, A_rich_own, rich_vecs[idxr])
    prep_g = [merge(row, (grid_point = idxp[row.grid_point],)) for row in prep]
    mkpath(ENUM_SHARD_DIR)
    serialize("$ENUM_SHARD_DIR/shard_$(k)_of_$(N).jls",
              (k=k, N=N, n_poor=length(poor_vecs), n_rich=length(rich_vecs),
               idxp=idxp, ptab=ptab, pok=pok, prep=prep_g, idxr=idxr, rtab=rtab))
    println("LOCAL SHARD $k/$N DONE: $(length(idxp)) poor + $(length(idxr)) rich follower solves serialized")
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
    println("LOCAL MERGE: $(length(poor_vecs)) poor + $(length(rich_vecs)) rich responses assembled from $N shards")
else
    poor_tab, poor_afford_ok, rep_poor =
        build_table("poor", POOR_IDX, A_poor_own, poor_vecs; afford_archs=A_poor_own)
    rich_tab, _, _ = build_table("rich", RICH_IDX, A_rich_own, rich_vecs)
end

pub_vecs  = SC.tenure_enabled ? [[r] for r in localpts(IDX_LANDLORD_PUBLIC)]  : [[0.0]]
priv_vecs = SC.tenure_enabled ? [[r] for r in localpts(IDX_LANDLORD_PRIVATE)] : [[0.0]]
if SC.tenure_enabled
    global pub_tab, pub_afford_ok, rep_pub =
        build_table("landlord_public", [IDX_LANDLORD_PUBLIC], A_rent_pub, pub_vecs;
                    afford_archs=A_rent_pub)
    global priv_tab, priv_afford_ok, rep_priv =
        build_table("landlord_private", [IDX_LANDLORD_PRIVATE], A_rent_priv, priv_vecs;
                    afford_archs=SC.affordability_scope == "all" ?
                        [a for a in A_rent_priv if inc_a[a] == "poor"] : Int[])
else
    global pub_tab  = [Resp[]]; global pub_afford_ok  = trues(1); global rep_pub  = []
    global priv_tab = [Resp[]]; global priv_afford_ok = trues(1); global rep_priv = []
end

AFFORD_BINDING = SC.affordability_mode != "off"
afford_grid_report = vcat(rep_poor, rep_pub, rep_priv)
if !isempty(afford_grid_report)
    CSV.write("$OUTDIR/affordability_local_report.csv", DataFrame(afford_grid_report))
    println("  Per-grid-point affordability report → $OUTDIR/affordability_local_report.csv")
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

agg(resps) = (spend = sum(r.spend for r in resps; init=0.0),
              spend_low = sum(r.spend_low for r in resps; init=0.0),
              sav = sum(r.sav for r in resps; init=0.0),
              wpb = sum(r.wpb_sav for r in resps; init=0.0),
              prim = isempty(resps) ? zeros(n_years) : reduce(+, [r.prim_area for r in resps]))
poor_agg = [agg(t) for t in poor_tab]
rich_agg = [agg(t) for t in rich_tab]
pub_agg  = [agg(t) for t in pub_tab]
priv_agg = [agg(t) for t in priv_tab]

traj_req = fill(Inf, n_years)
for (k, yr) in enumerate(traj_years)
    tidx = get(end_t_idx, yr, nothing)
    tidx !== nothing && (traj_req[tidx] = traj_values[k])
end
TI2050 !== nothing && (traj_req[TI2050] = min(traj_req[TI2050], epbd_target))

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
                    nfeas += 1
                    best = spend; best_combo = (i, j, u, v)
                end
            end
        end
    end
    return best, best_combo, nfeas
end

# Parallel cross product — identical to the pl9-verified combine_parallel of
# worktree-parallel-merge/enumerate_exact.jl (exact-reproduction design:
# contiguous ordered chunks, local incumbent with the serial skip rule,
# STRICT comparison against the shared atomic bound, lowest-chunk tie-break).
function combine_parallel()
    nth = Threads.nthreads()
    nwork = max(nth - 1, 1)
    nP = length(poor_agg)
    bounds = round.(Int, range(0, nP; length=nwork+1))
    gbest = Threads.Atomic{Float64}(Inf)
    nprog = Threads.Atomic{Int}(0)
    results = Vector{Tuple{Float64,NTuple{4,Int},Int}}(undef, nwork)
    t0p = time()
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
                    Threads.atomic_add!(nprog, 1); continue
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
                Threads.atomic_add!(nprog, 1)
            end
            results[t] = (lbest, lcombo, lfeas)
        end
    end
    done_flag[] = true
    wait(printer)
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
println("CERTIFIED LOCAL OPTIMUM (2.5%-step box, ±10 points around the stored search design)")
println("="^70)
if isinf(best)
    println("  NO feasible policy in the local box — including the center?! (center was " *
            "feasible on 2026-11-03 re-evaluation; investigate before trusting this)")
else
    σ_opt = zeros(n_σ)
    for (j, i) in enumerate(POOR_IDX); σ_opt[i] = poor_vecs[bi][j]; end
    for (j, i) in enumerate(RICH_IDX); σ_opt[i] = rich_vecs[bj][j]; end
    if SC.tenure_enabled
        σ_opt[IDX_LANDLORD_PUBLIC]  = pub_vecs[bu][1]
        σ_opt[IDX_LANDLORD_PRIVATE] = priv_vecs[bv][1]
    end
    @printf("  Optimal spending:  €%.3fM  (CERTIFIED minimum on the local box)\n", best/1e6)
    println("  Optimal σ:")
    for i in 1:n_σ
        @printf("    %-30s %7.3f%%%s\n", string(σ_keys[i]), 100*σ_opt[i],
                abs(σ_opt[i] - CENTER[i]) < 1e-9 ? "  (= center)" : @sprintf("  (center %+.1f pts)", 100*(σ_opt[i]-CENTER[i])))
    end
    ev = evaluate_σ(σ_opt)
    @printf("  Joint re-evaluation: feasible=%s, spending €%.3fM (must match)\n",
            ev.feasible, ev.ub/1e6)
    ev.feasible || error("CONSISTENCY FAILURE: local optimum rejected by evaluate_σ " *
                         "(afford_ok=$(ev.afford_ok)) — enumeration filter and shared check disagree")
    abs(ev.ub - best) <= 1e-4 * max(best, 1.0) ||
        error("CONSISTENCY FAILURE: joint spending €$(ev.ub) ≠ certified €$best")
    ev_c = evaluate_σ(copy(CENTER))
    @printf("  Center (stored search design): feasible=%s, €%.3fM → local optimum is %s by €%.3fM (%.3f%%)\n",
            ev_c.feasible, ev_c.ub/1e6,
            best < ev_c.ub - 1e-6 ? "BELOW the search design" :
            (abs(best - ev_c.ub) <= 1e-6 ? "EQUAL to the search design (center is locally optimal on the box)" :
             "ABOVE the search design (UNEXPECTED — center should be in the box)"),
            abs(ev_c.ub - best)/1e6, 100*abs(ev_c.ub - best)/max(ev_c.ub, 1.0))
end
println("="^70)
