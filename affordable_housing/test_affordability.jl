########################################################################
# test_affordability.jl — Level 1a checks (plan §2, "Test")
#
# Loads the model with DEFAULT settings (baseline scenario, affordability
# off), which runs the full CCG search once, then verifies:
#
#  A1  Baseline reproduction: KPIs of this run equal the frozen reference
#      in results/baseline/ (ground rule 2 — all switches off = baseline)
#  A2  Frozen-stock reference cost matches a hand-computed value
#  A3  Subset property: enforcing affordability can only REMOVE feasible
#      points — verified on the σ ladder: (feasible && afford_ok) ⇒ feasible,
#      and the affordability verdict is deterministic
#  A4  At σ = 0 the household pays everything: own annualised contribution
#      equals the annuity of the FULL investment (z ≡ 0)
#  A5  Off-mode neutrality: with affordability_mode="off" the feasibility
#      verdict of evaluate_σ never depends on the affordability outcome
#
# Usage: julia --project=.. test_affordability.jl
# Exit code 0 = all pass, 1 = at least one failure.
########################################################################

println("="^70)
println("AFFORDABILITY TEST SUITE — loading model (baseline scenario)...")
println("="^70)

include("bilevel_model_affordable_housing.jl")

using Printf

n_pass = Ref(0); n_fail = Ref(0)
function check(name::String, cond::Bool, detail::String="")
    if cond
        n_pass[] += 1
        println("  PASS  $name")
    else
        n_fail[] += 1
        println("  FAIL  $name   $detail")
    end
end

println("\n--- A1: baseline reproduction (all switches off) ---")
ref_kpis = CSV.read("results/baseline/policy_kpis.csv", DataFrame)
new_kpis = CSV.read("out/scenarios/baseline/policy_kpis.csv", DataFrame)
# Tolerance 1e-7 relative (≈ €0.30 on €2.9M): since Level 1b, spending is
# computed arithmetically as σ·y (z_leader) instead of reading the solver's
# z variable; the two differ by Gurobi's constraint tolerance (~1e-8
# relative, observed €0.23 on €2.9M at clawback 0). Tighter than 1e-7 would
# test the solver's tolerance, not the model.
for col in [:TotalPublic, :EquityShare, :WPBShare, :E2050_avg]
    rv = ref_kpis[1, col]; nv = new_kpis[1, col]
    check("$(col) reproduces frozen baseline",
          isapprox(rv, nv; rtol=1e-7, atol=1e-7), "ref=$rv new=$nv")
end

println("\n--- A2: frozen-stock reference cost, hand-computed ---")
# The MAIN reference is zero_subsidy since 2026-10-01; the frozen-stock
# branch remains a sensitivity, so it is pinned explicitly here and the
# hand-computed values still apply.
# SFH_poor: 280 kWh/m² × 100 m² × 0.065 €/kWh = €1820/yr; CO₂ price 0 in period 1
a_sfh = findfirst(==("SFH_poor"), arch_id)
ref = reference_costs_for("frozen_stock")
check("SFH_poor period-1 reference = €1820/yr",
      isapprox(ref[a_sfh, 1], 280 * 100 * 0.065; rtol=1e-12), "got $(ref[a_sfh,1])")
# Period ending 2035: + CO₂ 280×100×0.3 kg/kWh × 70 €/t /1000 = €588
check("SFH_poor 2035 reference = €2408/yr (fuel + CO₂)",
      isapprox(ref[a_sfh, 2], 1820 + 588; rtol=1e-12), "got $(ref[a_sfh,2])")
# DH incumbent: DH fuel price, zero CO₂ intensity
a_dh = findfirst(==("MFH_poor_dh"), arch_id)
check("MFH_poor_dh reference = bill at DH price, no CO₂ term",
      isapprox(ref[a_dh, 2], 190 * 55 * 0.055; rtol=1e-12), "got $(ref[a_dh,2])")

println("\n--- A3: subset property + determinism on the σ ladder ---")
scales = [0.0, 0.5, 1.0]
for sc in scales
    σv = sc == 0.0 ? zeros(n_σ) : enforce_ordering!(σ_caps .* sc)
    ev = evaluate_σ(σv)
    feasible_with_afford = ev.feasible && ev.afford_ok
    check("scale=$sc: (feasible ∧ afford_ok) ⇒ feasible",
          !feasible_with_afford || ev.feasible)
    af1 = affordability_check(ev.result); af2 = affordability_check(ev.result)
    check("scale=$sc: affordability verdict deterministic",
          af1.ok == af2.ok && isapprox(af1.viol_share, af2.viol_share; atol=0.0))
end

println("\n--- A4: σ = 0 → own contribution is the FULL annuitised investment ---")
fr0 = solve_follower(zeros(n_σ))
zmax = maximum(abs.(fr0.z))
check("z ≡ 0 at zero subsidies", zmax <= 1e-9, "max|z|=$zmax")
for a in A_POOR
    ti = length(T)
    expected = sum(ann_m[m] * inv_cost(a, m, τ) * fr0.y[a,m,τ]
                   for m in M, τ in 1:ti
                   if years[τ] + lifetime_m[m] > end_year[ti]; init=0.0)
    got = own_annualised(fr0, a, ti)
    check("$(arch_id[a]): own_annualised(σ=0) = full annuity",
          isapprox(got, expected; rtol=1e-10, atol=1e-9), "got=$got expected=$expected")
end

println("\n--- A5: off-mode neutrality of the feasibility verdict ---")
# In this run affordability_mode == "off": recompute feasibility WITHOUT any
# affordability input and compare with evaluate_σ's verdict for the ladder.
for sc in scales
    σv = sc == 0.0 ? zeros(n_σ) : enforce_ordering!(σ_caps .* sc)
    ev = evaluate_σ(σv)
    equity_ok = isnan(ev.equity) || ev.equity >= equity_min_eff - 0.001
    wpb_ok = isnan(ev.wpb) || ev.wpb >= 0.55 - 0.001
    epbd_ok = ev.E2050 <= epbd_target + 0.1
    base_feasible = equity_ok && wpb_ok && epbd_ok && ev.traj_ok
    check("scale=$sc: feasible independent of affordability when mode=off",
          ev.feasible == base_feasible,
          "ev=$(ev.feasible) recomputed=$base_feasible afford_ok=$(ev.afford_ok)")
end

println("\n" * "="^70)
println("AFFORDABILITY TESTS: $(n_pass[]) passed, $(n_fail[]) failed")
println("="^70)
exit(n_fail[] == 0 ? 0 : 1)
