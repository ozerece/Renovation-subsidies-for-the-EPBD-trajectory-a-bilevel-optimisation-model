########################################################################
# test_invariants.jl — Automated invariant checks for the CCG model
#
# Loads the full model (runs the baseline scenario once), then verifies
# mathematical properties that must hold for ANY correct implementation:
#
#  T1  Follower's optimal private cost is weakly decreasing in σ (theorem:
#      raising subsidies lowers cost coefficients and relaxes liquidity)
#  T2  z == σ·y componentwise in every follower solution (regression test
#      for the fz-McCormick bug)
#  T3  Spending identity: Σ inv·z·disc·dwell == Σ inv·σ·y·disc·dwell
#  T4  Energy physics: fE, fE_ep, carrier splits and primary intensity
#      recomputed from adoption s must match the solver's values
#  T5  Follower solution satisfies all follower constraints (dynamics,
#      exclusivity, caps, DH cap, liquidity, fossil ban, precedence)
#  T6  Zero subsidy → exactly zero public spending
#  T7  Relaxation property: master LB ≤ cost of every FEASIBLE candidate
#  T8  Master-membership: every true follower solution satisfies the
#      master's McCormick envelopes (i.e. the master is a relaxation)
#
# Usage: julia --project=. test_invariants.jl
# Exit code 0 = all pass, 1 = at least one failure.
########################################################################

println("="^70)
println("INVARIANT TEST SUITE — loading model (baseline scenario)...")
println("="^70)

include("bilevel_model_affordable_housing.jl")

const TOL  = 1e-5      # absolute tolerance for identities
const RTOL = 1e-4      # relative tolerance
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

# σ ladder: uniform scaling of the caps, ordering enforced
scales = [0.0, 0.25, 0.5, 0.75, 1.0]
σ_ladder = [scale == 0.0 ? zeros(n_σ) : enforce_ordering!(σ_caps .* scale) for scale in scales]
ladder = [(σv, solve_follower(σv)) for σv in σ_ladder]

println("\n--- T1: follower optimal cost weakly decreasing in σ ---")
for k in 1:length(ladder)-1
    o1 = ladder[k][2].obj; o2 = ladder[k+1][2].obj
    check("obj(scale=$(scales[k+1])) ≤ obj(scale=$(scales[k]))",
          o2 <= o1 + RTOL*abs(o1) + TOL, "o1=$(round(o1)), o2=$(round(o2))")
end

println("\n--- T2: z == σ·y componentwise ---")
for (σv, fr) in ladder
    worst = 0.0
    for a in A, m in M, ti in T
        idx = σ_index(m, a)
        σ_val = (idx !== nothing && y_upper[a,m,ti] > 0.001 &&
                 cls_m[m] != "pv" && get_subsidy_cap(m, a) > 0) ? σv[idx] : 0.0
        worst = max(worst, abs(fr.z[a,m,ti] - σ_val * fr.y[a,m,ti]))
    end
    check("max|z − σ·y| ≤ tol (scale run)", worst <= 1e-5, "worst=$worst")
end

println("\n--- T3: spending identity (z-based == σ·y-based) ---")
for (σv, fr) in ladder
    spend_z = sum(inv_cost(a,m,ti) * fr.z[a,m,ti] * disc(years[ti]) * dwell_a[a]
                  for a in A, m in M, ti in T)
    spend_σy = sum(begin
            idx = σ_index(m, a)
            σ_val = (idx !== nothing && y_upper[a,m,ti] > 0.001 &&
                     cls_m[m] != "pv" && get_subsidy_cap(m, a) > 0) ? σv[idx] : 0.0
            inv_cost(a,m,ti) * σ_val * fr.y[a,m,ti] * disc(years[ti]) * dwell_a[a]
        end for a in A, m in M, ti in T)
    check("Σinv·z·disc·dwell == Σinv·σy·disc·dwell",
          abs(spend_z - spend_σy) <= RTOL*max(abs(spend_z), 1.0),
          "z-based=$(round(spend_z)), σy-based=$(round(spend_σy))")
end

println("\n--- T4: energy physics recomputed from adoption s ---")
for (σv, fr) in ladder[3:3]  # mid-σ run is the interesting mixed case
    worst_E = worst_ep = worst_split = worst_prim = 0.0
    for a in A, ti in T
        r_env  = sum(redfac_m[m] * fr.s[a,m,ti] for m in M_env)
        r_hvac = sum(redfac_m[m] * fr.s[a,m,ti] for m in M_hvac)
        r_pv   = sum(redfac_m[m] * fr.s[a,m,ti] for m in M_pv)
        E_true  = base_a[a] * (1-r_env) * (1-r_hvac) * (1-r_pv)
        Ep_true = base_a[a] * (1-r_env) * (1-r_pv)
        worst_E  = max(worst_E,  abs(fr.E[a,ti]    - E_true)  / base_a[a])
        worst_ep = max(worst_ep, abs(fr.E_ep[a,ti] - Ep_true) / base_a[a])
        s_hp = idx_hp   !== nothing ? fr.s[a,idx_hp,ti]   : 0.0
        s_dh = idx_dist !== nothing ? fr.s[a,idx_dist,ti] : 0.0
        worst_split = max(worst_split,
            abs(fr.E_ep_hp[a,ti] - s_hp*fr.E_ep[a,ti]) / base_a[a],
            abs(fr.E_ep_dh[a,ti] - s_dh*fr.E_ep[a,ti]) / base_a[a])
        # primary energy: brute-force stock-mix accounting (period-dependent PEFs;
        # DH incumbents carry the DH factor on all their site energy)
        prim_true = is_dh0_a[a] ? pef_dh_t[ti] * fr.E_ep[a,ti] :
            fr.E_ep[a,ti] * ((1 - s_hp - s_dh) * PEF_FOSSIL +
                             s_hp * remain_hp * pef_elec_t[ti] +
                             s_dh * remain_dh * pef_dh_t[ti])
        worst_prim = max(worst_prim, abs(primary_intensity(fr, a, ti) - prim_true) / base_a[a])
    end
    check("fE == base·(1-r_env)(1-r_hvac)(1-r_pv)", worst_E  <= 1e-4, "rel dev=$worst_E")
    check("fE_ep == base·(1-r_env)(1-r_pv)",        worst_ep <= 1e-4, "rel dev=$worst_ep")
    check("carrier splits == s·fE_ep",              worst_split <= 1e-4, "rel dev=$worst_split")
    check("primary == stock-mix brute force",       worst_prim  <= 1e-6, "rel dev=$worst_prim")
end

println("\n--- T5: follower constraints hold at solution ---")
for (σv, fr) in ladder[3:3]
    ok_dyn = all(abs(fr.s[a,m,1] - fr.y[a,m,1]) <= TOL for a in A, m in M) &&
             all(abs(fr.s[a,m,ti] - fr.s[a,m,ti-1] - fr.y[a,m,ti]) <= TOL
                 for a in A, m in M, ti in 2:n_years)
    check("state dynamics s_t = s_{t-1} + y_t", ok_dyn)
    check("exclusivity Σs_env ≤ 1, Σs_hvac ≤ 1",
          all(sum(fr.s[a,m,ti] for m in M_env)  <= 1 + TOL for a in A, ti in T) &&
          all(sum(fr.s[a,m,ti] for m in M_hvac) <= 1 + TOL for a in A, ti in T))
    check("per-class adoption caps",
          all(sum(fr.y[a,m,ti] for m in M_env)  <= adopt_cap_env[ti] + TOL for a in A, ti in T) &&
          all(sum(fr.y[a,m,ti] for m in M_hvac) <= adopt_cap_hvac[ti] + TOL for a in A, ti in T) &&
          all(sum(fr.y[a,m,ti] for m in M_pv)   <= adopt_cap_pv[ti] + TOL for a in A, ti in T))
    check("joint labor-weighted capacity cap",
          all(sum(W_CLS[cls_m[m]] * fr.y[a,m,ti] for m in M) <= adopt_cap_joint[ti] + TOL
              for a in A, ti in T))
    check("DH coverage caps",
          idx_dist === nothing ||
          all(fr.s[a,idx_dist,ti] <= (btype_a[a]=="SFH" ? SC.dh_cap_sfh : SC.dh_cap_mfh) + TOL
              for a in A, ti in T))
    check("liquidity ≤ cap·period_length",
          all(sum(inv_cost(a,m,ti)*(fr.y[a,m,ti]-fr.z[a,m,ti]) for m in M)
              <= cap_a[a]*period_length[ti] + 1.0 for a in A, ti in T))
    ok_ban = true
    for a in A, ti in T
        if is_dh0_a[a]; continue; end
        if years[ti] >= SC.ban_year
            prev = ti == 1 ? 0.0 : sum(fr.s[a,m,ti-1] for m in M_hvac)
            if sum(fr.y[a,m,ti] for m in M_hvac) < (1 - prev)*boiler_break[ti] - TOL
                ok_ban = false
            end
        end
    end
    check("fossil ban replacement floor", ok_ban)
    check("HVAC precedence s_hvac ≤ s_env + 0.3",
          all(sum(fr.s[a,m,ti] for m in M_hvac) <=
              sum(fr.s[a,m,ti] for m in M_env) + 0.3 + TOL for a in A, ti in T))
end

println("\n--- T6: zero subsidy → zero spending ---")
fr0 = ladder[1][2]
spend0 = sum(inv_cost(a,m,ti) * fr0.z[a,m,ti] * disc(years[ti]) * dwell_a[a]
             for a in A, m in M, ti in T)
check("spending(σ=0) == 0", abs(spend0) <= 1.0, "spend0=$spend0")

println("\n--- T7: LB ≤ cost of every feasible candidate ---")
any_feas = false
for (σv, fr) in ladder
    ev = evaluate_σ(σv)
    if ev.feasible
        global any_feas = true
        check("LB ≤ UB($(round(ev.ub/1e6, digits=1))M)", LB <= ev.ub + 1.0)
    end
end
check("LB ≥ 0 (spending cannot be negative)", LB >= -1.0, "LB=$LB")
any_feas || println("  (no feasible candidate on the σ ladder — LB≤UB checks skipped)")

println("\n--- T8: true follower points satisfy master McCormick envelopes ---")
mc(x, w, xL, xU, wL, wU) = begin  # true product p=x·w must satisfy all 4 envelopes
    p = x*w
    (p >= xL*w + x*wL - xL*wL - TOL) && (p >= xU*w + x*wU - xU*wU - TOL) &&
    (p <= xU*w + x*wL - xU*wL + TOL) && (p <= xL*w + x*wU - xL*wU + TOL)
end
for (σv, fr) in ladder
    ok = true
    for a in A, ti in T
        B = base_a[a]
        r_env  = sum(redfac_m[m]*fr.s[a,m,ti] for m in M_env)
        r_hvac = sum(redfac_m[m]*fr.s[a,m,ti] for m in M_hvac)
        r_pv   = sum(redfac_m[m]*fr.s[a,m,ti] for m in M_pv)
        E_env = B*(1-r_env)
        # chain products as the master relaxes them
        ok &= mc(E_env, 1-r_hvac, B*(1-r_env_max_val), B, 1-r_hvac_max_val, 1.0)
        ok &= mc(E_env*(1-r_hvac), 1-r_pv,
                 B*(1-r_env_max_val)*(1-r_hvac_max_val), B, 1-r_pv_max_val, 1.0)
        ok &= mc(E_env, 1-r_pv, B*(1-r_env_max_val), B, 1-r_pv_max_val, 1.0)
        E_ep = E_env*(1-r_pv)
        xL = B*(1-r_env_max_val)*(1-r_pv_max_val); xU = B
        if idx_hp !== nothing
            ok &= mc(E_ep, fr.s[a,idx_hp,ti], xL, xU, 0.0, 1.0)
        end
        if idx_dist !== nothing
            sU = btype_a[a]=="SFH" ? SC.dh_cap_sfh : SC.dh_cap_mfh
            ok &= mc(E_ep, fr.s[a,idx_dist,ti], xL, xU, 0.0, sU)
        end
        # mz envelope at true z = σ·y
        for m in M
            idx = σ_index(m, a)
            if idx !== nothing && y_upper[a,m,ti] > 0.001 && cls_m[m] != "pv" && get_subsidy_cap(m,a) > 0
                ok &= mc(fr.y[a,m,ti], σv[idx], 0.0, y_upper[a,m,ti], 0.0, get_subsidy_cap(m,a))
            end
        end
    end
    check("McCormick envelopes valid at true point (one σ run)", ok)
end

println("\n" * "="^70)
println("RESULT: $(n_pass[]) passed, $(n_fail[]) failed")
println("="^70)
exit(n_fail[] == 0 ? 0 : 1)
