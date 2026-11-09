########################################################################
# make_pl12_outcomes.jl — outcome measures of one scenario at its design of
# record and at σ = 0 (fixed-σ follower evaluations; the leader is not
# re-optimised). Counting window = the state's window (from SUB_START).
#   CO2: cumulative Mt over the design periods ending <= 2050, with and
#        without the programme; avoided; EUR per t avoided (discounted
#        spending / avoided CO2).
#   Energy: primary energy saved in 2050 vs σ=0 (TWh/yr); EUR per kWh.
#   Energy-cost shares of income in 2050 for low-income groups.
#   Spending by measure class and by group (discounted).
# Usage (cwd = affordable_housing): julia --project=.. make_pl12_outcomes.jl <scn> <sigma_csv> <out_csv>
#   sigma_csv: a run dir's subsidies.csv (group,measure,rate) or a 12-value file.
########################################################################
SCN = ARGS[1]; SIGF = ARGS[2]; OUTCSV = ARGS[3]
ENV["P4_SKIP_SEARCH"] = "1"; ENV["P4_OUT_TAG"] = "outcomes"
empty!(ARGS); push!(ARGS, SCN)
include(joinpath(pwd(), "bilevel_model_affordable_housing.jl"))
using Printf
function read_sigma(f)
    lines = [strip(l) for l in eachline(f) if !isempty(strip(l)) && !startswith(strip(l), "#")]
    if startswith(lines[1], "group,")
        rate = Dict((String(r.group), String(r.measure)) => Float64(r.rate) for r in eachrow(CSV.read(f, DataFrame)))
        key(k) = (k[1] == "envelope" ? (k[3], "env_" * k[2]) : k[1] == "hvac" ? (k[3], k[2] == "standard" ? "hvac_std" : "hvac_upg") : ("landlord_" * k[3], "all_non_pv"))
        return [get(rate, key(σ_keys[i]), 0.0) for i in 1:n_σ]
    end
    return parse.(Float64, lines)
end
σ = read_sigma(SIGF)
ev = evaluate_σ(σ); ev0 = evaluate_σ(zeros(n_σ))
fr, fr0 = ev.result, ev0.result
(fr === nothing || fr0 === nothing) && error("follower infeasible")
TW = [ti for ti in T if ti >= T_LEADER && end_year[ti] <= 2050]
co2_of(f) = sum((f.E_ep[a,ti] - f.E_ep_hp[a,ti] - f.E_ep_dh[a,ti]) * fa_a[a] * co2_int_at[a,ti] * dwell_a[a] * period_length[ti] for a in A, ti in TW) / 1e9  # Mt
co2_rec, co2_zero = co2_of(fr), co2_of(fr0)
avoided = co2_zero - co2_rec
ti50 = end_t_idx[2050]
pe(f, ti) = sum(primary_intensity(f, a, ti) * fa_a[a] * dwell_a[a] for a in A)   # kWh/yr
pe_saved_2050 = (pe(fr0, ti50) - pe(fr, ti50)) / 1e9   # TWh/yr
spend_disc = ev.ub
spend_nom = sum(inv_cost(a,m,ti) * z_leader(σ,fr,a,m,ti) * dwell_a[a] for a in A, m in M, ti in T)
cls_spend = Dict(c => sum(inv_cost(a,m,ti) * z_leader(σ,fr,a,m,ti) * disc(years[ti]) * dwell_a[a] for a in A, m in M, ti in T if cls_m[m] == c) for c in ("envelope", "hvac"))
grp(a) = is_rented(a) ? String(tenure_a[a]) : (inc_a[a] == "poor" ? "owner_low" : "owner_high")
grp_spend = Dict(g => sum(inv_cost(a,m,ti) * z_leader(σ,fr,a,m,ti) * disc(years[ti]) * dwell_a[a] for a in A, m in M, ti in T if grp(a) == g) for g in ("owner_low", "owner_high", "rented_public", "rented_private"))
# low-income energy-cost shares of income in 2050 (dwelling-weighted), after the programme and at σ = 0
af, af0 = affordability_details(fr), affordability_details(fr0)
g4(a) = is_rented(a) ? (tenure_a[a] == "rented_public" ? "tenant_public" : "tenant_private") : (occursin("_wpb_", arch_id[a]) ? "owner_low_wpb" : "owner_low_rest")
shares = Dict{String,Tuple{Float64,Float64}}()
for g in ("owner_low_wpb", "owner_low_rest", "tenant_public", "tenant_private")
    w = s1 = s0 = 0.0
    for (r, r0) in zip(af, af0)
        (inc_a[r.a] == "poor" && g4(r.a) == g) || continue
        w += dwell_a[r.a]; s1 += dwell_a[r.a] * r.cost_after[ti50] / Float64(SC.household_income_by_class.poor)
        s0 += dwell_a[r.a] * r0.cost_after[ti50] / Float64(SC.household_income_by_class.poor)
    end
    shares[g] = w > 0 ? (s1 / w, s0 / w) : (NaN, NaN)
end
row = (scenario=SCN, sigma_file=basename(SIGF), feasible=ev.feasible, spending_disc_M=spend_disc/1e6, spending_nominal_M=spend_nom/1e6,
       co2_record_Mt=co2_rec, co2_zero_Mt=co2_zero, co2_avoided_Mt=avoided, co2_avoided_pct=100*avoided/co2_zero,
       eur_per_t=avoided > 0 ? spend_disc/(avoided*1e6) : NaN, pe_saved_2050_TWh=pe_saved_2050,
       eur_per_kwh_2050=pe_saved_2050 > 0 ? spend_disc/(pe_saved_2050*1e9) : NaN,
       E2030=ev.E_primary[end_t_idx[2030]], E2050=ev.E2050, E2050_zero=ev0.E2050,
       spend_envelope_M=cls_spend["envelope"]/1e6, spend_hvac_M=cls_spend["hvac"]/1e6,
       spend_owner_low_M=grp_spend["owner_low"]/1e6, spend_owner_high_M=grp_spend["owner_high"]/1e6,
       spend_landlords_M=(grp_spend["rented_public"]+grp_spend["rented_private"])/1e6,
       share_owner_low_wpb_2050=shares["owner_low_wpb"][1], share_owner_low_wpb_2050_zero=shares["owner_low_wpb"][2],
       share_owner_low_rest_2050=shares["owner_low_rest"][1], share_owner_low_rest_2050_zero=shares["owner_low_rest"][2],
       share_tenant_public_2050=shares["tenant_public"][1], share_tenant_public_2050_zero=shares["tenant_public"][2],
       share_tenant_private_2050=shares["tenant_private"][1], share_tenant_private_2050_zero=shares["tenant_private"][2])
CSV.write(OUTCSV, DataFrame([row]))
@printf("#### %s: spending %.1f M, CO2 %.1f vs %.1f Mt (avoided %.1f, %.1f%%), %.0f EUR/t, %.2f TWh saved 2050, %.2f EUR/kWh\n",
        SCN, spend_disc/1e6, co2_rec, co2_zero, avoided, 100*avoided/co2_zero, row.eur_per_t, pe_saved_2050, row.eur_per_kwh_2050)
