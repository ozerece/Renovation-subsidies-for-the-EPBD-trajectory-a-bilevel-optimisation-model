########################################################################
# make_pl12_review_evals.jl — fixed-σ evaluations for the review follow-ups of
# 2026-11-08 (paper review REVIEW_SUMMARY §5.2: E1–E4; §2.2 M13: the 37 % check).
# Nothing is optimised: the record design (data/sigma_pl12_local25_record.csv)
# and σ = 0 are evaluated with the follower, plus a few neighbouring designs.
#   E1  incidence by group, 2026–2050 (ETS2 paid, bills, subsidies received, own
#       investment, rent increases), nominal and discounted to 2026 at 3 %
#   E2  free-ridership: adoption under the design that also occurs at σ = 0 in the
#       same period, by period and measure class, and the subsidy paid on it
#   E3  marginal cost per kWh/(m²·yr) of 2030 primary-energy reduction by channel
#   E4  decomposition of the primary-energy cut at each milestone into envelope,
#       heating system (incl. the 2025 boiler update) and primary-energy-factor change
#   M13 the high-income medium/deep rate (37.09 %): response of the design to that rate
# Usage (cwd = affordable_housing): P4_GRB_THREADS=8 julia --project=.. make_pl12_review_evals.jl [scenario]
# Output: results/review_2026-11-08/*.csv
########################################################################
SCN = length(ARGS) >= 1 ? ARGS[1] : "pl12"
ENV["P4_SKIP_SEARCH"] = "1"; ENV["P4_OUT_TAG"] = "review_evals"
empty!(ARGS); push!(ARGS, SCN)
include(joinpath(pwd(), "bilevel_model_affordable_housing.jl"))
using Printf
OUT = "results/review_2026-11-08"; mkpath(OUT)
SIGF = "data/sigma_pl12_local25_record.csv"
σ_rec = [parse(Float64, strip(l)) for l in eachline(SIGF) if !isempty(strip(l)) && !startswith(strip(l), "#")]
length(σ_rec) == n_σ || error("record file has $(length(σ_rec)) rates, model has $n_σ")
ev  = evaluate_σ(σ_rec); ev0 = evaluate_σ(zeros(n_σ))
fr, fr0 = ev.result, ev0.result
(fr === nothing || fr0 === nothing) && error("follower infeasible")
@printf("record: spending %.1f M EUR feasible=%s equity=%.4f wpb=%.4f\n", ev.ub/1e6, ev.feasible, ev.equity, ev.wpb)
TW = [ti for ti in T if ti >= T_LEADER && end_year[ti] <= 2050]   # design periods counted by the state
dfac(ti) = disc(years[ti])                                           # state discounting, base 2026

# ---------------------------------------------------------------- groups
function grp(a)
    if is_rented(a)
        tenure_a[a] == "rented_public" && return "tenant_public"
        return inc_a[a] == "poor" ? "tenant_private_low" : "tenant_private_high"
    end
    w = occursin("_wpb_", arch_id[a]) ? "wpb" : "rest"
    return (inc_a[a] == "poor" ? "owner_low_" : "owner_high_") * w
end
landlord_of(a) = tenure_a[a] == "rented_public" ? "landlord_public" : "landlord_private"
GROUPS = ["owner_low_wpb", "owner_low_rest", "owner_high_wpb", "owner_high_rest", "tenant_public", "tenant_private_low", "tenant_private_high", "landlord_public", "landlord_private"]

# ---------------------------------------------------------------- E1 incidence
# per archetype and period: annual flows × dwellings × period length; one-off flows × dwellings
ets2(f, a, ti) = (f.E_ep[a,ti] - f.E_ep_hp[a,ti] - f.E_ep_dh[a,ti]) * fa_a[a] * co2_int_at[a,ti] * co2_price_per_ton[ti] / 1000
bill(f, a, ti) = annual_bill(f, a, ti)                       # fuel + carbon, EUR/yr per dwelling
subs_recv(f, a, ti) = sum(inv_cost(a,m,ti) * f.z[a,m,ti] for m in M)        # received by the decider
subs_paid(σv, f, a, ti) = sum(inv_cost(a,m,ti) * z_leader(σv,f,a,m,ti) for m in M)
own_inv(f, a, ti) = sum(inv_cost(a,m,ti) * (f.y[a,m,ti] - f.z[a,m,ti]) for m in M)
rent(f, a, ti) = is_rented(a) ? f.rent[a,ti] : 0.0
acc = Dict{Tuple{String,String},Vector{Float64}}()   # (group, quantity) => [nominal, discounted]
function addflow!(g, q, a, ti, v_per_dwelling_year; oneoff=false)
    v = v_per_dwelling_year * dwell_a[a] * (oneoff ? 1.0 : period_length[ti])
    x = get!(acc, (g, q), [0.0, 0.0]); x[1] += v; x[2] += v * dfac(ti)
end
for a in A, ti in TW
    g = grp(a)
    addflow!(g, "ets2_paid_design", a, ti, ets2(fr, a, ti)); addflow!(g, "ets2_paid_sigma0", a, ti, ets2(fr0, a, ti))
    addflow!(g, "bill_incl_carbon_design", a, ti, bill(fr, a, ti)); addflow!(g, "bill_incl_carbon_sigma0", a, ti, bill(fr0, a, ti))
    if is_rented(a)
        addflow!(g, "rent_increase_paid_design", a, ti, rent(fr, a, ti)); addflow!(g, "rent_increase_paid_sigma0", a, ti, rent(fr0, a, ti))
        l = landlord_of(a)
        addflow!(l, "subsidy_received_design", a, ti, subs_recv(fr, a, ti); oneoff=true)
        addflow!(l, "own_investment_design", a, ti, own_inv(fr, a, ti); oneoff=true); addflow!(l, "own_investment_sigma0", a, ti, own_inv(fr0, a, ti); oneoff=true)
        addflow!(l, "rent_increase_received_design", a, ti, rent(fr, a, ti)); addflow!(l, "rent_increase_received_sigma0", a, ti, rent(fr0, a, ti))
    else
        addflow!(g, "subsidy_received_design", a, ti, subs_recv(fr, a, ti); oneoff=true)
        addflow!(g, "own_investment_design", a, ti, own_inv(fr, a, ti); oneoff=true); addflow!(g, "own_investment_sigma0", a, ti, own_inv(fr0, a, ti); oneoff=true)
    end
end
open("$OUT/E1_incidence_by_group_2026_2050.csv", "w") do io
    println(io, "group,quantity,nominal_M_EUR,discounted_2026_M_EUR,note")
    for g in GROUPS, q in ("ets2_paid_design", "ets2_paid_sigma0", "bill_incl_carbon_design", "bill_incl_carbon_sigma0", "subsidy_received_design",
                           "own_investment_design", "own_investment_sigma0", "rent_increase_paid_design", "rent_increase_paid_sigma0",
                           "rent_increase_received_design", "rent_increase_received_sigma0")
        haskey(acc, (g, q)) || continue
        x = acc[(g, q)]
        @printf(io, "%s,%s,%.1f,%.1f,%s\n", g, q, x[1]/1e6, x[2]/1e6, "cumulative over the periods ending 2030-2050; design = record; sigma0 = no subsidies from 2026")
    end
    # derived: net change of household outlay vs σ = 0 (bill + own investment + rent paid), and ETS2 paid vs subsidy received
    for g in GROUPS
        get(x, k) = haskey(acc, (g, k)) ? acc[(g, k)] : [0.0, 0.0]
        dbill = get(x -> x, "bill_incl_carbon_design") .- get(x -> x, "bill_incl_carbon_sigma0")
        down  = get(x -> x, "own_investment_design") .- get(x -> x, "own_investment_sigma0")
        drent = get(x -> x, "rent_increase_paid_design") .- get(x -> x, "rent_increase_paid_sigma0")
        net = dbill .+ down .+ drent
        @printf(io, "%s,net_outlay_change_vs_sigma0,%.1f,%.1f,%s\n", g, net[1]/1e6, net[2]/1e6, "bill + own investment + rent paid, design minus sigma0 (negative = household better off)")
        e = get(x -> x, "ets2_paid_design"); s = get(x -> x, "subsidy_received_design")
        @printf(io, "%s,ets2_paid_minus_subsidy_received_design,%.1f,%.1f,%s\n", g, (e[1]-s[1])/1e6, (e[2]-s[2])/1e6, "positive = pays more carbon cost than it receives in subsidies")
    end
end
println("E1 written")

# ---------------------------------------------------------------- E2 free-ridership
open("$OUT/E2_free_ridership.csv", "w") do io
    println(io, "period_end,measure_class,adoption_design_Mdw,adoption_sigma0_Mdw,overlap_Mdw,windfall_share_of_subsidised_adoption,subsidy_on_overlap_nominal_M_EUR,subsidy_on_overlap_discounted_M_EUR,subsidy_total_nominal_M_EUR")
    tot = Dict{String,Vector{Float64}}()
    for ti in TW, cls in ("envelope", "hvac")
        ad = a0 = ov = sub_ov = sub_ov_d = sub_tot = 0.0
        for a in A, m in M
            cls_m[m] == cls || continue
            y1 = fr.y[a,m,ti]; y0 = fr0.y[a,m,ti]; ovl = min(y1, y0)
            ad += y1 * dwell_a[a]; a0 += y0 * dwell_a[a]; ov += ovl * dwell_a[a]
            paid_rate = y1 > 1e-12 ? z_leader(σ_rec, fr, a, m, ti) / y1 : 0.0    # subsidy fraction actually paid per unit adoption
            sub_ov += inv_cost(a,m,ti) * paid_rate * ovl * dwell_a[a]; sub_ov_d += inv_cost(a,m,ti) * paid_rate * ovl * dwell_a[a] * dfac(ti)
            sub_tot += inv_cost(a,m,ti) * z_leader(σ_rec, fr, a, m, ti) * dwell_a[a]
        end
        @printf(io, "%d,%s,%.4f,%.4f,%.4f,%.4f,%.1f,%.1f,%.1f\n", end_year[ti], cls, ad/1e6, a0/1e6, ov/1e6, ad > 0 ? ov/ad : NaN, sub_ov/1e6, sub_ov_d/1e6, sub_tot/1e6)
        t = get!(tot, cls, zeros(6)); t .+= [ad, a0, ov, sub_ov, sub_ov_d, sub_tot]
    end
    for (cls, t) in tot
        @printf(io, "2026-2050,%s,%.4f,%.4f,%.4f,%.4f,%.1f,%.1f,%.1f\n", cls, t[1]/1e6, t[2]/1e6, t[3]/1e6, t[1] > 0 ? t[3]/t[1] : NaN, t[4]/1e6, t[5]/1e6, t[6]/1e6)
    end
    tt = sum(values(tot))
    @printf(io, "2026-2050,all,%.4f,%.4f,%.4f,%.4f,%.1f,%.1f,%.1f\n", tt[1]/1e6, tt[2]/1e6, tt[3]/1e6, tt[1] > 0 ? tt[3]/tt[1] : NaN, tt[4]/1e6, tt[5]/1e6, tt[6]/1e6)
end
println("E2 written")

# ---------------------------------------------------------------- E4 decomposition
pef_e20 = pef_elec_at(2020); pef_d20 = pef_dh_at(2020)
pef_base20(a) = is_dh0_a[a] ? pef_d20 : pef_fossil_a[a]
cph20(a) = pef_fossil_a[a] - remain_hp_a[a] * pef_e20
cpd20(a) = pef_fossil_a[a] - remain_dh_a[a] * pef_d20
P0 = sum(pef_base20(a) * base_a[a] * fa_a[a] * dwell_a[a] for a in A) / total_area
function decomp(f, ti)
    p_env = p_heat = p_act = 0.0
    for a in A
        r_env = sum(redfac_amt[a,m,ti] * f.s[a,m,ti] for m in M_env)
        E_env = base_a[a] * (1 - r_env)                              # envelope only, 2020 heating and base demand
        p_env += pef_base20(a) * E_env * fa_a[a] * dwell_a[a]
        p_heat += (pef_base20(a) * f.E_ep[a,ti] - cph20(a) * f.E_ep_hp[a,ti] - cpd20(a) * f.E_ep_dh[a,ti]) * fa_a[a] * dwell_a[a]
        p_act += primary_intensity(f, a, ti) * fa_a[a] * dwell_a[a]
    end
    return (p_env/total_area, p_heat/total_area, p_act/total_area)
end
open("$OUT/E4_primary_energy_decomposition.csv", "w") do io
    println(io, "case,year,baseline_2020,envelope_effect,heating_system_effect,pef_effect,value,check_sum_minus_value,target")
    for (name, f) in (("design", fr), ("sigma0", fr0))
        for ti in T
            end_year[ti] > 2050 && continue
            pe_env, pe_heat, pe_act = decomp(f, ti)
            tgt = get(Dict(zip(traj_years, traj_values)), end_year[ti], NaN)
            @printf(io, "%s,%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.4f,%s\n", name, end_year[ti], P0, pe_env - P0, pe_heat - pe_env, pe_act - pe_heat, pe_act,
                    (P0 + (pe_env - P0) + (pe_heat - pe_env) + (pe_act - pe_heat)) - pe_act, isnan(tgt) ? "" : @sprintf("%.2f", tgt))
        end
    end
end
@printf("E4 written (2020 baseline from factors at 2020: %.2f; model baseline_primary = %.2f)\n", P0, baseline_primary)

# ---------------------------------------------------------------- E3 channels (marginal evaluations around the record)
hi_env_share(f, ti) = begin
    archs = [a for a in A if !is_rented(a) && inc_a[a] == "rich"]; w = sum(dwell_a[a] for a in archs)
    sum(f.y[a,m,ti] * dwell_a[a] for a in archs, m in M_env) / w
end
function evalrow(label, σv)
    σt = copy(σv); enforce_ordering!(σt); e = evaluate_σ(σt)
    f = e.result
    E = f === nothing ? fill(NaN, length(T)) : e.E_primary
    return (label=label, σ=σt, ub=e.ub, feasible=e.feasible, equity=e.equity, E=E, f=f)
end
base = evalrow("record", σ_rec)
channels = Any[]
let s = copy(σ_rec); s[1:3] .-= 0.10; push!(channels, ("low-income envelope −10 pp (all depths)", s)) end
let s = copy(σ_rec); s[1:3] .+= 0.10; push!(channels, ("low-income envelope +10 pp (all depths)", s)) end
let s = copy(σ_rec); s[4:6] .-= 0.10; push!(channels, ("high-income envelope −10 pp (all depths)", s)) end
let s = copy(σ_rec); s[5:6] .+= 0.10; push!(channels, ("high-income envelope medium/deep +10 pp (clamped to caps)", s)) end
let s = copy(σ_rec); s[7] -= 0.10; push!(channels, ("low-income heat pump −10 pp", s)) end
let s = copy(σ_rec); s[9] = 0.20; push!(channels, ("high-income heat pump 0 → 20 %", s)) end
let s = copy(σ_rec); s[9] = 0.40; push!(channels, ("high-income heat pump 0 → 40 % (cap)", s)) end
if n_σ >= 12
    let s = copy(σ_rec); s[11] = 0.50; push!(channels, ("public landlord 0 → 50 %", s)) end
    let s = copy(σ_rec); s[11] = 1.00; push!(channels, ("public landlord 0 → 100 %", s)) end
    let s = copy(σ_rec); s[12] = 0.50; push!(channels, ("private landlord 0 → 50 %", s)) end
    let s = copy(σ_rec); s[12] = 1.00; push!(channels, ("private landlord 0 → 100 %", s)) end
end
i30, i35, i40, i50 = end_t_idx[2030], end_t_idx[2035], end_t_idx[2040], end_t_idx[2050]
open("$OUT/E3_marginal_cost_by_channel.csv", "w") do io
    println(io, "channel,sigma_after_ordering,spending_M_EUR,delta_spending_M_EUR,feasible,equity,E2030,dE2030,E2035,dE2035,E2040,dE2040,E2050,dE2050,EUR_per_kWh_m2yr_2030,EUR_per_kWh_m2yr_2040")
    @printf(io, "%s,%s,%.1f,%.1f,%s,%.4f,%.2f,,%.2f,,%.2f,,%.2f,,,\n", base.label, join(round.(base.σ, digits=4), ";"), base.ub/1e6, 0.0, base.feasible, base.equity, base.E[i30], base.E[i35], base.E[i40], base.E[i50])
    for (lab, s) in channels
        r = evalrow(lab, s)
        d30 = r.E[i30] - base.E[i30]; d40 = r.E[i40] - base.E[i40]; dsp = (r.ub - base.ub)/1e6
        c30 = abs(d30) > 1e-6 ? dsp / (-d30) : NaN; c40 = abs(d40) > 1e-6 ? dsp / (-d40) : NaN
        @printf(io, "%s,%s,%.1f,%.1f,%s,%.4f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f,%.1f\n", lab, join(round.(r.σ, digits=4), ";"), r.ub/1e6, dsp, r.feasible, r.equity,
                r.E[i30], d30, r.E[i35], r.E[i35]-base.E[i35], r.E[i40], d40, r.E[i50], r.E[i50]-base.E[i50], c30, c40)
    end
end
println("E3 written")

# ---------------------------------------------------------------- M13: the 37.09 % high-income medium/deep rate
hi_hp_share(f, ti) = begin
    archs = [a for a in A if !is_rented(a) && inc_a[a] == "rich"]; w = sum(dwell_a[a] for a in archs)
    idx_hp === nothing ? NaN : sum(f.s[a,idx_hp,ti] * dwell_a[a] for a in archs) / w
end
open("$OUT/M13_high_income_envelope_rate_scan.csv", "w") do io
    println(io, "rate_medium,rate_deep,spending_M_EUR,feasible,equity,margin_2030,margin_2040,hi_env_adoption_2030,hi_env_adoption_2035,hi_env_adoption_2040,hi_env_adoption_2050,hi_hp_cum_2050,note")
    tests = Any[]
    for v in (0.30, 0.33, 0.35, 0.36, 0.37, 0.3708, 0.375, 0.38, 0.39, 0.40); push!(tests, (v, v)); end
    for v in (0.42, 0.45, 0.50); push!(tests, (0.3708460394765625, v)); end
    for (vm, vd) in tests
        s = copy(σ_rec); s[5] = vm; s[6] = vd
        r = evalrow("scan", s)
        f = r.f
        m30 = traj_values[findfirst(==(2030), traj_years)] - r.E[i30]; m40 = traj_values[findfirst(==(2040), traj_years)] - r.E[i40]
        note = vm == 0.3708460394765625 && vd == vm ? "record" : ""
        @printf(io, "%.4f,%.4f,%.1f,%s,%.4f,%.3f,%.3f,%.4f,%.4f,%.4f,%.4f,%.4f,%s\n", r.σ[5], r.σ[6], r.ub/1e6, r.feasible, r.equity, m30, m40,
                f === nothing ? NaN : hi_env_share(f, i30), f === nothing ? NaN : hi_env_share(f, i35), f === nothing ? NaN : hi_env_share(f, i40),
                f === nothing ? NaN : hi_env_share(f, i50), f === nothing ? NaN : hi_hp_share(f, i50), note)
    end
end
println("M13 written")
println("#### review evals done -> $OUT")
