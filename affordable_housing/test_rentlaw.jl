########################################################################
# test_rentlaw.jl — levy-duration + rich-tenant checks (2026-10-08).
#
#  t5t6       T5: pass_through_years = 1 at ρ = 1.0 (rentlaw_test_t5) —
#             an investment's base is repaid EXACTLY within one year.
#             T6: expired vintages are absent from later rent bounds —
#             tenant cost returns to the no-levy level. Plus unit checks
#             on the window arithmetic.
#  twins      rich private tenant (decision change 2026-10-08): the
#             poor/rich private twins have identical building decisions
#             and rents at σ = 0 (the tenant's income never enters the
#             landlord problem); the split preserves the private stock.
#  invariance FULL runs, two pins (rtol 1e-7, the A1 convention):
#             (1) tenure_oldshares_test (D5 config at the pre-2026-10-08
#             placeholder shares, rich twin ACTIVE) must reproduce the
#             COMMITTED pre-archetype tenure_afford results (commit
#             2b5f3fa). This is the user-ordered "landlord problem
#             unchanged" confirmation; it also re-proves the levy-code
#             refactor neutral. (2) tenure_newshares_test (the current
#             D5 default config) must reproduce the wave-8 tenure_afford
#             results — re-pinned 2026-10-08 after the sourced public
#             share 0.082 made wave 8 the data of record, replacing the
#             superseded 3-scenario gate of the first S4 chain.
#
# One Julia process can load the model only once (consts), so the driver
# spawns one subprocess per case.
# Usage: julia --project=.. test_rentlaw.jl          (all cases)
#        julia --project=.. test_rentlaw.jl <case>   (one case)
########################################################################

if isempty(ARGS)  # ---------- driver ----------
    failed = String[]
    for case in ["t5t6", "twins", "invariance"]
        println("\n" * "="^70)
        println("RENT-LAW TESTS — case '$case'")
        println("="^70)
        cmd = setenv(`$(Base.julia_cmd()) --project=$(dirname(@__DIR__)) $(@__FILE__) $case`,
                     copy(ENV); dir=@__DIR__)
        ok = success(run(ignorestatus(cmd)))
        ok || push!(failed, case)
    end
    println("\n" * "="^70)
    if isempty(failed)
        println("RENT-LAW TESTS: all cases passed")
        exit(0)
    else
        println("RENT-LAW TESTS: FAILED cases: $(join(failed, ", "))")
        exit(1)
    end
end

case = ARGS[1]

n_pass = Ref(0); n_fail = Ref(0)
function check(name::String, cond::Bool, detail::String="")
    if cond
        n_pass[] += 1; println("  PASS  $name")
    else
        n_fail[] += 1; println("  FAIL  $name   $detail")
    end
end

if case == "invariance"
    # ---------- committed-results invariance (full runs, subprocess) ----
    using CSV, DataFrames
    # pins: (scenario, spending_M, E2050, label)
    #  1. tenure_oldshares_test → committed tenure_afford, commit 2b5f3fa
    #  2. tenure_newshares_test → wave-8 tenure_afford (data of record
    #     2026-10-08: sourced incomes + public share 0.082 + rich twin)
    PINS = [
        ("tenure_oldshares_test", 2.884618424124881, 74.28039260584107,
         "committed tenure_afford (2b5f3fa)"),
        ("tenure_newshares_test", 2.884618424124881, 74.03638964535507,
         "wave-8 tenure_afford (2026-10-08 data of record)"),
    ]
    for (scn, SP_PIN, E_PIN, label) in PINS
        println("  running $scn (full CCG) ...")
        cmd = setenv(`$(Base.julia_cmd()) --project=$(dirname(@__DIR__)) bilevel_model_affordable_housing.jl $scn`,
                     copy(ENV); dir=@__DIR__)
        logf = "results/cert_logs/rentlaw_invariance_$scn.log"
        ok = open(logf, "w") do io
            success(run(pipeline(ignorestatus(cmd); stdout=io, stderr=io)))
        end
        check("$scn run completes", ok, "see $logf")
        ok || continue
        d = CSV.read("out/scenarios/$scn/scenario_summary.csv", DataFrame)
        # 1e-7: spending is σ·y arithmetic, solver tolerance (A1 convention)
        check("spending reproduces $label",
              isapprox(d.spending_M[1], SP_PIN; rtol=1e-7),
              "got $(d.spending_M[1]) vs pinned $SP_PIN")
        check("E2050 reproduces $label",
              isapprox(d.E2050[1], E_PIN; rtol=1e-7),
              "got $(d.E2050[1]) vs pinned $E_PIN")
        check("feasible", d.feasible[1] == true)
    end
    println("\nINVARIANCE: $(n_pass[]) passed, $(n_fail[]) failed")
    exit(n_fail[] == 0 ? 0 : 1)
end

if case == "twins"
    # ---------- twin equivalence, in-process ----------
    ENV["P4_SKIP_SEARCH"] = "1"
    empty!(ARGS); push!(ARGS, "tenure_oldshares_test")
    include("bilevel_model_affordable_housing.jl")

    poor_tw = Dict{String,Int}(); rich_tw = Dict{String,Int}()
    for a in A
        endswith(arch_id[a], "_rent_priv")      && (poor_tw[replace(arch_id[a], "_rent_priv" => "")] = a)
        endswith(arch_id[a], "_rent_priv_rich") && (rich_tw[replace(arch_id[a], "_rent_priv_rich" => "")] = a)
    end
    check("every private parent has both twins",
          !isempty(poor_tw) && sort(collect(keys(poor_tw))) == sort(collect(keys(rich_tw))),
          "poor: $(keys(poor_tw)), rich: $(keys(rich_tw))")
    for (p, ap) in poor_tw
        ar = rich_tw[p]
        check("[$p] twins split the private stock 50/50",
              isapprox(dwell_a[ap], dwell_a[ar]; rtol=1e-12),
              "$(dwell_a[ap]) vs $(dwell_a[ar])")
        check("[$p] twin incomes poor vs rich",
              inc_a[ap] == "poor" && inc_a[ar] == "rich")
        check("[$p] same landlord type and pass-through",
              tenure_a[ap] == tenure_a[ar] == "rented_private" &&
              pass_through_of(ap) == pass_through_of(ar))
    end
    fr = solve_follower(zeros(n_σ))
    fr === nothing && error("follower failed at σ = 0")
    for (p, ap) in poor_tw
        ar = rich_tw[p]
        for ti in T
            check("[$p] twin rents equal (ti=$ti)",
                  isapprox(fr.rent[ap,ti], fr.rent[ar,ti]; atol=0.5),
                  "$(fr.rent[ap,ti]) vs $(fr.rent[ar,ti])")
        end
        ydiff = maximum(abs(fr.y[ap,m,ti] - fr.y[ar,m,ti]) for m in M, ti in T)
        check("[$p] twin adoption identical (max |Δy| < 1e-4)", ydiff < 1e-4,
              "max |Δy| = $ydiff")
    end
    println("\nTWINS: $(n_pass[]) passed, $(n_fail[]) failed")
    exit(n_fail[] == 0 ? 0 : 1)
end

case == "t5t6" || error("unknown test case '$case'")

# ---------- T5/T6 + unit checks, in-process ----------
ENV["P4_SKIP_SEARCH"] = "1"
empty!(ARGS); push!(ARGS, "rentlaw_test_t5")
include("bilevel_model_affordable_housing.jl")

using Printf

println("\n--- unit checks: levy window arithmetic ---")
a_priv = [a for a in A_RENTED if tenure_a[a] == "rented_private"]
a_fossil_priv = [a for a in a_priv if !is_dh0_a[a]]
check("private rented archetypes exist", !isempty(a_fossil_priv))
ap = a_fossil_priv[1]
check("levy_years_of: integer key honoured", levy_years_of(ap) == 1.0,
      "got $(levy_years_of(ap))")
# periods: 1:[2020,2030) 2:[2030,2035) 3:[2035,2040) 4:[2040,2050) 5:[2050,2060)
check("coverage of own period, 1-year window in a 10-year period",
      isapprox(levy_coverage(4, 4, ap), 0.1; atol=1e-12),
      "got $(levy_coverage(4, 4, ap))")
check("coverage: window expired in the next period",
      levy_coverage(4, 5, ap) == 0.0, "got $(levy_coverage(4, 5, ap))")
check("coverage: 1-year window inside a 5-year period",
      isapprox(levy_coverage(2, 2, ap), 0.2; atol=1e-12),
      "got $(levy_coverage(2, 2, ap))")

println("\n--- T5/T6: follower at σ = 0 (ban forces the 2040 HVAC swap) ---")
fr = solve_follower(zeros(n_σ))
fr === nothing && error("follower failed at σ = 0")

M_PT = SC.pv_in_passthrough_base ? M : [m for m in M if cls_m[m] != "pv"]
base_of(a, τ) = sum(inv_cost(a, m, τ) * (fr.y[a,m,τ] - fr.z[a,m,τ]) for m in M_PT)
bound_finite(a, ti) = pass_through_of(a) *
    sum(levy_coverage(τ, ti, a) * base_of(a, τ) for τ in 1:ti)
bound_permanent(a, ti) = pass_through_of(a) * sum(base_of(a, τ) for τ in 1:ti)

ti_ban  = findfirst(ti -> years[ti] >= SC.ban_year, T)   # 2040 period
ti_last = length(T)                                       # 2050 period
for a in a_fossil_priv
    b4 = base_of(a, ti_ban)
    check("[$a] ban-forced investment exists in the $(years[ti_ban]) period", b4 > 1.0,
          "base = $b4")
    # objective rewards rent, so rent sits AT the (finite-window) bound
    check("[$a] rent equals the finite-window bound in $(years[ti_ban])",
          isapprox(fr.rent[a, ti_ban], bound_finite(a, ti_ban); rtol=1e-5),
          "rent $(fr.rent[a, ti_ban]) vs bound $(bound_finite(a, ti_ban))")
    # T5: ρ = 1, 1-year window → the period's levy total repays the base
    check("[$a] T5: levy over the period repays the vintage base exactly",
          isapprox(fr.rent[a, ti_ban] * period_length[ti_ban],
                   pass_through_of(a) * base_of(a, ti_ban) +
                   pass_through_of(a) * sum(levy_coverage(τ, ti_ban, a) *
                       base_of(a, τ) * period_length[ti_ban] for τ in 1:ti_ban-1; init=0.0);
                   rtol=1e-5),
          "levy total $(fr.rent[a, ti_ban] * period_length[ti_ban]) vs base $(base_of(a, ti_ban))")
    # T6: the 2040 vintage is OUT of the 2050 period's bound
    check("[$a] T6: expired vintage absent from the $(years[ti_last]) bound",
          isapprox(fr.rent[a, ti_last], bound_finite(a, ti_last); rtol=1e-5) &&
          bound_finite(a, ti_last) < bound_permanent(a, ti_last) - 1.0,
          "rent $(fr.rent[a, ti_last]), finite $(bound_finite(a, ti_last)), permanent $(bound_permanent(a, ti_last))")
end

println("\nRENT-LAW T5/T6: $(n_pass[]) passed, $(n_fail[]) failed")
exit(n_fail[] == 0 ? 0 : 1)
