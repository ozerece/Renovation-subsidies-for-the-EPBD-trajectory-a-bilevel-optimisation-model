########################################################################
# eval_sigma_report.jl — fixed-σ evaluation with a compact report.
# Called by scripts/run_pl11_eval.sh with cwd = the model folder.
# Usage: julia --project=<env> eval_sigma_report.jl <scenario> <sigma_file> <tag>
########################################################################
SCN = ARGS[1]; SIGF = ARGS[2]; TAG = ARGS[3]
ENV["P4_SKIP_SEARCH"] = "1"
ENV["P4_OUT_TAG"] = TAG
empty!(ARGS); push!(ARGS, SCN)
include(joinpath(pwd(), "bilevel_model_affordable_housing.jl"))
using Printf
σ = [parse(Float64, strip(l)) for l in eachline(SIGF) if !isempty(strip(l)) && !startswith(strip(l), "#")]
length(σ) == n_σ || error("sigma file has $(length(σ)) values, model has $n_σ")
ev = evaluate_σ(σ)
fr = ev.result
println("\n#### EVAL $TAG scenario=$SCN sigma=$(basename(SIGF))")
if fr === nothing
    println("#### follower INFEASIBLE"); exit()
end
@printf("#### spending %.1f M EUR  feasible=%s  equity=%.3f  wpb=%.3f  afford_ok=%s\n",
        ev.ub/1e6, ev.feasible, ev.equity, ev.wpb, ev.afford_ok)
for (k, yr) in enumerate(traj_years)
    ti = end_t_idx[yr]; v = ev.E_primary[ti]; t = traj_values[k]; m = t - v
    status = v > t + 0.1 ? "VIOLATED" : (m <= 0.1 ? "BINDING" : "slack")
    @printf("####   %d: E=%7.2f target=%7.2f margin=%+6.2f %s\n", yr, v, t, m, status)
end
ti50 = end_t_idx[2050]
grp(a) = tenure_a[a] != "owner" ? String(tenure_a[a]) : (inc_a[a] == "poor" ? "owner_low" : "owner_high")
groups = sort(unique(grp(a) for a in A))
println("#### 2050 cumulative shares by group (env | HP | DH | PV) and discounted subsidy (M EUR):")
for g in groups
    archs = [a for a in A if grp(a) == g]
    w = sum(dwell_a[a] for a in archs)
    e  = sum(fr.s[a,m,ti50] * dwell_a[a] for a in archs, m in M_env) / w
    hp = idx_hp === nothing ? 0.0 : sum(fr.s[a,idx_hp,ti50] * dwell_a[a] for a in archs) / w
    dh = idx_dist === nothing ? 0.0 : sum(fr.s[a,idx_dist,ti50] * dwell_a[a] for a in archs) / w
    pv = sum(fr.s[a,m,ti50] * dwell_a[a] for a in archs, m in M_pv) / w
    sp = sum(inv_cost(a,m,ti) * z_leader(σ,fr,a,m,ti) * disc(years[ti]) * dwell_a[a] for a in archs, m in M, ti in T) / 1e6
    @printf("####   %-15s env %.3f | HP %.3f | DH %.3f | PV %.3f | subsidy %8.1f\n", g, e, hp, dh, pv, sp)
end
ti30 = end_t_idx[2030]
println("#### 2020-2030 envelope renovation share by group:")
for g in groups
    archs = [a for a in A if grp(a) == g]
    w = sum(dwell_a[a] for a in archs)
    @printf("####   %-15s %.4f\n", g, sum(fr.y[a,m,ti30] * dwell_a[a] for a in archs, m in M_env) / w)
end
# full adoption dump (y, s per archetype, measure, period) and the primary-energy path
mkpath(OUTDIR)
let rows = Any[]
    for a in A, m in M, ti in T
        push!(rows, (archetype=arch_id[a], measure=m_id[m], period_end=end_year[ti], y=fr.y[a,m,ti], s=fr.s[a,m,ti], z=fr.z[a,m,ti]))
    end
    CSV.write("$OUTDIR/adoption_eval.csv", DataFrame(rows))
    CSV.write("$OUTDIR/energy_path_eval.csv", DataFrame(year=[years[1]; [end_year[ti] for ti in T]],
        Eavg=[baseline_primary; [sum(primary_intensity(fr, a, ti) * fa_a[a] * dwell_a[a] for a in A) / total_area for ti in T]]))
end
println("#### primary energy path (year: kWh/m2): ", join(["$(years[1]):$(round(baseline_primary, digits=2))"; ["$(end_year[ti]):$(round(ev.E_primary[ti], digits=2))" for ti in T]], " "))
if (@isdefined HIST_ON) && HIST_ON
    hist_nom = sum(inv_cost(a,m,ti) * σ_hist(m, a) * fr.y[a,m,ti] * dwell_a[a] for a in A, m in M, ti in 1:T_HIST)
    @printf("#### history subsidy spending (fixed periods, not in the objective): nominal %.1f M EUR, discounted to %d %.1f M EUR\n",
            hist_nom/1e6, DISC_BASE, sum(inv_cost(a,m,ti) * σ_hist(m, a) * fr.y[a,m,ti] * dwell_a[a] * disc(years[ti]) for a in A, m in M, ti in 1:T_HIST)/1e6)
    println("#### SFH incumbent after the history (η, fuel price EUR/kWh, CO2 kg/kWh): ",
            join(["$(arch_id[a]) η $(round(η_at[a,1], digits=3))→$(round(η_at[a,T_HIST+1], digits=3)) p $(round(pfuel_at[a,1], digits=4))→$(round(pfuel_at[a,T_HIST+1], digits=4)) c $(round(co2_int_at[a,1], digits=3))→$(round(co2_int_at[a,T_HIST+1], digits=3))" for a in A if btype_a[a] == "SFH"], "; "))
end
println("#### done $TAG")
