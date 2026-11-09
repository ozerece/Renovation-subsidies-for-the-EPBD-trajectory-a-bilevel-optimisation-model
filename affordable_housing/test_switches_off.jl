########################################################################
# test_switches_off.jl — regression gate for the 2026-10-27 switches
# (eed_public_obligation, public_tenant_weight): with BOTH OFF (their
# defaults) the model must reproduce the committed results exactly.
#
# For the scenario given in ARGS (default tenure_on; one Julia process
# per scenario — the model file defines globals):
#   1. asserts the new switches default to OFF,
#   2. reads the COMMITTED design from out/scenarios/<scn>/subsidies.csv,
#   3. re-evaluates it (evaluate_σ → one follower solve, no search),
#   4. compares spending / equity / WPB / E2050 against the committed
#      out/scenarios/<scn>/policy_kpis.csv to 1e-6 relative tolerance.
#
# Usage: julia --project=.. test_switches_off.jl [scenario]
#        (run it for: baseline, tenure_on)
# Exit 0 = all pass, 1 = at least one failure.
# STATUS: written 2026-10-27; NOT YET RUN (runs not ordered).
########################################################################

SCN_TEST = isempty(ARGS) ? "tenure_on" : ARGS[1]
ENV["P4_SKIP_SEARCH"] = "1"
# The committed pins were produced WITH the fossil-boiler ban. Since the
# 2026-10-27 option-(b) decision, every scenario of record carries
# fossil_boiler_ban=true PINNED in its definition, so this gate relies on
# the pins alone (no P4_FORCE_BOILER_BAN hook).
empty!(ARGS); push!(ARGS, SCN_TEST)
include("bilevel_model_affordable_housing.jl")

using CSV, DataFrames, Printf

fail = Ref(0)
function check(name, cond, detail="")
    println((cond ? "  PASS  " : "  FAIL  ") * name * (cond ? "" : "   $detail"))
    cond || (fail[] += 1)
end

println("\n=== test_switches_off ($SCN_TEST) ===")

# 1. the new switches default to OFF; the ban is PINNED on scenarios of record
check("eed_public_obligation default false", SC.eed_public_obligation == false)
check("public_tenant_weight default 0.0", Float64(SC.public_tenant_weight) == 0.0)
check("fossil_boiler_ban pinned true (scenario of record)", SC.fossil_boiler_ban == true)

# 2. committed design → σ vector
sub = CSV.read("out/scenarios/$SCN_TEST/subsidies.csv", DataFrame)
rate = Dict((r.group, r.measure) => Float64(r.rate) for r in eachrow(sub))
key_of = Dict(("envelope","light")=>"env_light", ("envelope","medium")=>"env_medium",
              ("envelope","deep")=>"env_deep", ("hvac","standard")=>"hvac_std",
              ("hvac","upgrade")=>"hvac_upg")
σ_test = zeros(n_σ)
for i in 1:n_σ
    k = σ_keys[i]
    if k[1] == "landlord"
        g = k[3] == "public" ? "landlord_public" : "landlord_private"
        σ_test[i] = get(rate, (g, "all_non_pv"), 0.0)
    else
        σ_test[i] = get(rate, (k[3], key_of[(k[1], k[2])]), 0.0)
    end
end
println("  committed σ: ", round.(σ_test, digits=3))

# 3./4. re-evaluate and compare against the committed KPIs
ev = evaluate_σ(σ_test)
check("follower solves at the committed design", ev.result !== nothing)
kpi = CSV.read("out/scenarios/$SCN_TEST/policy_kpis.csv", DataFrame)
rel(a, b) = abs(a - b) / max(abs(b), 1e-9)
RT = 1e-6
check(@sprintf("spending matches committed (%.9f vs %.9f M)",
               ev.ub/1e6, kpi.TotalPublic[1]/1e6),
      rel(ev.ub, kpi.TotalPublic[1]) < RT)
check("equity share matches committed", rel(ev.equity, kpi.EquityShare[1]) < RT,
      "$(ev.equity) vs $(kpi.EquityShare[1])")
check("WPB share matches committed", rel(ev.wpb, kpi.WPBShare[1]) < RT,
      "$(ev.wpb) vs $(kpi.WPBShare[1])")
check("E2050 matches committed", rel(ev.E2050, kpi.E2050_avg[1]) < RT,
      "$(ev.E2050) vs $(kpi.E2050_avg[1])")

println(fail[] == 0 ? "\n✓ all checks passed ($SCN_TEST)" :
        "\n✗ $(fail[]) check(s) FAILED ($SCN_TEST)")
exit(fail[] == 0 ? 0 : 1)
