########################################################################
# test_tenure.jl — Level 2 checks (plan §4, "Tests")
#
#  T1  tenure_enabled=false reproduces baseline exactly
#      → covered by test_affordability.jl A1 (full run, KPI comparison);
#        here the cheap structural half: default scenario adds no
#        archetypes and no instruments.
#  T2  pass_through = 0 for both landlord types and no landlord subsidy
#      ⇒ landlords renovate NOTHING (no return). Assert.
#      NOTE: the test scenario pushes the boiler ban beyond the horizon
#      (ban_year=2060), because the ban is regulation that FORCES landlord
#      HVAC swaps from 2040 and would mask the no-return result. This is a
#      test-setup choice, not a model change (recorded in CHANGELOG).
#  T3  pass_through very high, no rent cap ⇒ landlords renovate as much as
#      owner-occupiers with full savings would. Sanity check, not exact.
#  T4  tenant cost with pass_through = 0 equals the energy bill only.
#  Plus structural checks: stock totals preserved by the split, instrument
#  mapping, tenant income, no clawback on landlords.
#
# One Julia process can load the model only once (consts), so the driver
# spawns one subprocess per scenario case.
# Usage: julia --project=.. test_tenure.jl          (driver, runs all cases)
#        julia --project=.. test_tenure.jl <case>   (one case, in-process)
# Exit code 0 = all pass, 1 = at least one failure.
########################################################################

CASES = Dict(
    "baseline_structure" => "baseline",
    "no_return"          => "tenure_test_no_return",
    "high_passthrough"   => "tenure_test_high_passthrough",
)

if isempty(ARGS)  # ---------- driver ----------
    failed = String[]
    for case in ["baseline_structure", "no_return", "high_passthrough"]
        println("\n" * "="^70)
        println("TENURE TESTS — case '$case' (scenario $(CASES[case]))")
        println("="^70)
        cmd = setenv(`$(Base.julia_cmd()) --project=$(dirname(@__DIR__)) $(@__FILE__) $case`,
                     copy(ENV); dir=@__DIR__)
        ok = success(run(ignorestatus(cmd)))
        ok || push!(failed, case)
    end
    println("\n" * "="^70)
    if isempty(failed)
        println("TENURE TESTS: all cases passed")
        exit(0)
    else
        println("TENURE TESTS: FAILED cases: $(join(failed, ", "))")
        exit(1)
    end
end

# ---------- one case, in-process ----------
case = ARGS[1]
haskey(CASES, case) || error("unknown test case '$case'")
ENV["P4_SKIP_SEARCH"] = "1"   # load data + functions, skip the CCG search
empty!(ARGS); push!(ARGS, CASES[case])
include("bilevel_model_affordable_housing.jl")

using Printf

n_pass = Ref(0); n_fail = Ref(0)
function check(name::String, cond::Bool, detail::String="")
    if cond
        n_pass[] += 1; println("  PASS  $name")
    else
        n_fail[] += 1; println("  FAIL  $name   $detail")
    end
end

# Stock totals from the raw CSV (pre-split ground truth)
raw = CSV.read("archetypes_v2.csv", DataFrame)
raw_dwellings = sum(Float64.(raw.dwellings))
raw_area = sum(Float64.(raw.dwellings) .* Float64.(raw.floor_area_m2))

if case == "baseline_structure"
    check("default scenario: no rented archetypes", isempty(A_RENTED))
    check("default scenario: archetype count unchanged", length(A) == nrow(raw),
          "got $(length(A))")
    check("default scenario: 10 instruments", n_σ == 10, "got $n_σ")
    check("default scenario: dwellings total unchanged",
          isapprox(sum(dwell_a), raw_dwellings; rtol=1e-12))
end

if case in ("no_return", "high_passthrough")
    println("\n--- structural checks (tenure split) ---")
    n_mfh = count(==("MFH"), raw.btype)
    # 3 variants per MFH parent since the rich private twin (2026-10-08);
    # 2 when private_rich_tenant_share = 0 (old structure)
    n_var = SC.private_rich_tenant_share > 0 ? 3 : 2
    check("archetype count = raw + $n_var per MFH row",
          length(A) == nrow(raw) + n_var * n_mfh, "got $(length(A))")
    check("dwellings total preserved by the split",
          isapprox(sum(dwell_a), raw_dwellings; rtol=1e-12),
          "got $(sum(dwell_a)) vs $raw_dwellings")
    check("floor area total preserved by the split",
          isapprox(total_area, raw_area; rtol=1e-12), "got $total_area vs $raw_area")
    check("12 instruments with tenure on", n_σ == 12, "got $n_σ")
    # 2026-10-08 decision change: public tenants are poor; private tenants
    # are poor except the rich twin (suffix _rent_priv_rich)
    check("public tenants are poor",
          all(inc_a[a] == "poor" for a in A_RENTED if tenure_a[a] == "rented_public"))
    check("rich tenants exist only as the private rich twin",
          all(endswith(arch_id[a], "_rent_priv_rich")
              for a in A_RENTED if inc_a[a] == "rich"))
    check("no household clawback on landlords",
          all(clawback_of(a) == 0.0 for a in A_RENTED))
    env_m = first(M_env)
    check("rented_public maps to σ[11], rented_private to σ[12]",
          all(σ_index(env_m, a) == (tenure_a[a] == "rented_public" ?
              IDX_LANDLORD_PUBLIC : IDX_LANDLORD_PRIVATE) for a in A_RENTED))
    pv_m = first(M_pv)
    check("PV unsubsidised for landlords too",
          all(σ_index(pv_m, a) === nothing for a in A_RENTED))
end

if case == "no_return"
    println("\n--- T2: zero pass-through + no landlord subsidy ⇒ landlords renovate nothing ---")
    fr0 = solve_follower(zeros(n_σ))
    fr0 === nothing && error("follower failed at σ = 0")
    max_rent_adopt = maximum(fr0.y[a,m,ti] for a in A_RENTED, m in M, ti in T)
    check("rented adoption ≡ 0 at pass_through=0, σ_landlord=0",
          max_rent_adopt <= 1e-6, "max adoption $(max_rent_adopt)")
    check("rent increase ≡ 0", maximum(fr0.rent[a,ti] for a in A_RENTED, ti in T) <= 1e-6)

    println("\n--- T4: tenant cost with pass_through=0 equals the energy bill only ---")
    for a in A_RENTED
        ok_a = all(isapprox(housing_cost_after(fr0, a, ti), annual_bill(fr0, a, ti);
                            rtol=1e-12, atol=1e-9) for ti in T)
        check("$(arch_id[a]): tenant cost = bill", ok_a)
    end

    println("\n--- extra: full landlord subsidy still buys nothing without a return ---")
    σ_full_landlord = zeros(n_σ)
    σ_full_landlord[IDX_LANDLORD_PUBLIC]  = σ_caps[IDX_LANDLORD_PUBLIC]
    σ_full_landlord[IDX_LANDLORD_PRIVATE] = σ_caps[IDX_LANDLORD_PRIVATE]
    fr1 = solve_follower(σ_full_landlord)
    fr1 === nothing && error("follower failed at full landlord subsidy")
    # free capex but positive maintenance and zero return ⇒ still no adoption
    check("rented adoption ≡ 0 even at 100% landlord subsidy (maintenance > 0, return = 0)",
          maximum(fr1.y[a,m,ti] for a in A_RENTED, m in M, ti in T) <= 1e-6)
end

if case == "high_passthrough"
    println("\n--- T3 sanity: very high pass-through, no cap ⇒ landlords renovate like owners ---")
    fr0 = solve_follower(zeros(n_σ))
    fr0 === nothing && error("follower failed at σ = 0")
    ti_last = length(T)
    for a in A_RENTED
        parent = findfirst(id -> arch_id[a] == id * "_rent_pub" ||
                                 arch_id[a] == id * "_rent_priv" ||
                                 arch_id[a] == id * "_rent_priv_rich",  # rich twin (2026-10-08)
                           arch_id)
        parent === nothing && (check("$(arch_id[a]): parent found", false); continue)
        rent_env = sum(fr0.s[a,m,ti_last] for m in M_env)
        own_env  = sum(fr0.s[parent,m,ti_last] for m in M_env)
        check("$(arch_id[a]): envelope adoption ≥ parent owner's − 0.05 " *
              "(rented $(round(rent_env, digits=3)) vs owner $(round(own_env, digits=3)))",
              rent_env >= own_env - 0.05)
    end
    check("rent increase positive where landlords renovated",
          all(sum(fr0.y[a,m,ti] for m in M, ti in T) <= 1e-6 ||
              maximum(fr0.rent[a,ti] for ti in T) > 1e-6 for a in A_RENTED))
end

println("\n" * "-"^70)
println("case '$case': $(n_pass[]) passed, $(n_fail[]) failed")
exit(n_fail[] == 0 ? 0 : 1)
