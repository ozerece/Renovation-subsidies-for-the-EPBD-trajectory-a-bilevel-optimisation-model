########################################################################
# model_bilevel_260207_CCG.jl — Column-and-Constraint Generation
#
# Solves the bilevel problem iteratively WITHOUT single-level reformulation.
# No FAM (682 binaries), no Strong Duality (160 bilinear constraints).
#
# Algorithm:
# 1. Master LP (High-Point Relaxation): gives a lower bound on public spending.
#    Pure LP — no integers, no bilinear terms.
#
# 2. Follower LP: for each σ candidate, solve the follower's optimization.
#    Tiny LP (~200 variables), solves in milliseconds.
#
# 3. σ-space search: coordinate descent + random perturbation to find
#    the minimum-cost σ that produces a bilevel-feasible solution
#    (follower's actual response satisfies upper-level constraints).
#
# The bilevel structure is fully preserved — we literally solve the
# leader and follower problems as separate LPs.
#
# Date: 2026-02-07
########################################################################

using CSV, DataFrames, JuMP, Gurobi
using Statistics
using MathOptInterface
using Dates, Random
const MOI = MathOptInterface

println("\n" * "="^70)
println("BILEVEL OPTIMIZATION — Column-and-Constraint Generation (CCG)")
println("Multiplicative Energy Model with EPBD Renovation Depths")
println("="^70)

# =============================================================================
# 0a) SCENARIO FRAMEWORK
# Each scenario changes ONE policy lever vs baseline (or combines all) so the
# comparison isolates which lever moves E2050 toward the EPBD target.
# Usage: julia --project=. model_bilevel_260207_CCG.jl <scenario>   (default: baseline)
# =============================================================================
# POLAND calibration (2026-07): defaults reflect the fact-checked Polish framework.
# dh caps: SFH networks barely exist (0.64% connected) vs MFH ~70% already on DH;
# residual_value=true by default (removes the end-of-horizon accounting artifact);
# reno_scale multiplies the staged DSRB-informed capacity ceilings;
# pef_frozen freezes the electricity/DH primary-energy factors at 2023 values.
# AFFORDABLE-HOUSING EXTENSION (Level 1a): outcome-based affordability constraint.
# All new keys default to baseline-neutral values (ground rule: with every switch
# at its default, the model reproduces results/baseline/ exactly).
#   affordability_mode: "off" (baseline) | "cost_neutral" | "income_share"
#     cost_neutral : poor household's annual heating cost after the programme
#                    (energy bill + annualised own contribution) must not exceed
#                    affordability_tolerance × reference cost (Domenig et al. 2024, Eq. 5)
#     income_share : ... must not exceed affordability_income_share × annual income
#   affordability_reference: what "no-programme" means for cost_neutral —
#     "zero_subsidy" : cost of the follower's own response at σ = 0 (households
#                      still react to the CO₂ price and the boiler ban).
#                      MAIN CASE (user decision 2026-10-01). Note the Level 2
#                      consequence: a landlord's voluntary renovate-and-levy
#                      happens at σ = 0 too, so it is part of the tenant's
#                      reference — the constraint then asks what the SUBSIDY
#                      changes, not what the renovation changes.
#     "frozen_stock" : bill of the un-renovated building at same-period
#                      prices. SENSITIVITY (reported for D3 and D5x).
#   affordability_scope: which poor archetypes the constraint is ENFORCED for
#     (all are always reported) —
#     "all" (default) : every poor archetype, owners and tenants
#     "owners_and_public_tenants" : private-rental tenants excluded (D5x;
#                      their affordability gap is still reported in €/yr)
#   household_income_by_class: SOURCED (GUS 2024, see the key's comment);
#     the model errors loudly if income_share mode is on and the income is NaN.
#   equity_spending_floor: false disables the ≥30% spending-to-poor floor
#     (needed for the plan's (a)–(d) design comparison; default true = baseline).
scen(; ban_year=2040, co2_scale=1.0, dh_cap_sfh=0.05, dh_cap_mfh=0.80,
       reno_scale=1.0, subsidy_boost=:none, residual_value=true,
       pef_frozen=false, wood_pef=1.1,
       # pl11 (2026-11-06 brief): pv_enabled=false removes the PV option
       # entirely (no adoption possible); learning_rates = Dict m_id =>
       # annual cost-decline rate overriding measures_v2.csv for the
       # listed measures. Defaults = committed behaviour, bit-identical.
       pv_enabled=true, learning_rates=nothing,
       # pl12 (decision record 2026-11-06, D1-D7): fixed history 2020-2025,
       # state designs from 2026. All defaults = committed behaviour.
       period_years=nothing,            # D1: period start years, e.g. (2020,2026,2030,2035,2040,2050); nothing = context.csv
       co2_price_path=nothing,          # D6: EUR/t per period; nothing = context.csv
       history_adoption_file=nothing,   # D2/D3: CSV archetype,measure,y[,period] fixing adoption in the history periods
       history_fix_classes=("envelope", "hvac"),  # measure classes the file fixes (other classes stay free)
       history_subsidy=nothing,         # D3: (sfh_poor=0.70, sfh_rich=0.40) applied to SFH owner adoption in the history periods
       fuel_mix_update=nothing,         # D2: boiler-replacement update of the incumbent mix from the first design period
       subsidy_horizon_start=nothing,   # D7: the state pays and counts (spending, equity, WPB) from this year
       discount_base_year=nothing,      # D7: base year of the state's discounting (nothing = model start)
       affordability_mode="off", affordability_tolerance=1.0,
       affordability_income_share=0.10,
       affordability_reference="zero_subsidy",
       affordability_scope="all",
       # SOURCED (wave 9, user order 2026-10-09): GUS, Budżety gospodarstw
       # domowych w 2024 r., Tablica 2 (persons per household) + Tablica 19
       # (disposable income PLN/person/month), downloaded 2026-10-09.
       # EUR per household per YEAR = PLN/person/month × persons × 12 ÷ FX,
       # FX pinned 4.30 PLN/EUR (2024 annual average, per the source note):
       #   low-income  = Q1: 1,151 × 3.00 × 12 ÷ 4.30 = €9,635
       #   high-income = mean of Q2–Q5 (user CORRECTION 2026-10-11,
       #     superseding Q5 = €33,378): quintile incomes €16,332 / 19,802 /
       #     22,693 / 33,378, weighted by population household count ∝
       #     1/household size (Tabl. 2 sizes 2.63 / 2.50 / 2.26 / 1.97;
       #     each GUS quintile holds 20% of PERSONS, not households).
       #     Check: Σ(income/size) ÷ Σ(1/size) = €23,761 ✓ (23,761.5).
       #     NOT weighted by surveyed household counts (per the order).
       #   Source string: "Mean of Q2–Q5, GUS HBS 2024 tables (Tabl. 2
       #     sizes, per-person income table), weighted by household count
       #     ∝ 1/size, FX 4.30". Display label: "high-income (Q2–Q5)".
       # The 2026-10-08 signal-note values (household sizes 3.60/2.12 →
       # €11,560/€35,920 — sizes not found in the downloaded publication,
       # check PARTLY FAILED 2026-10-09) are kept as the
       # `d5_inc_signalnote` SENSITIVITY and pinned in the repro gates.
       household_income_by_class=(poor=9635.0, rich=23761.0),
       # Which periods the affordability constraint binds in:
       # "all" (default) = every period; "final" = the period ending 2050 only
       # (income_share is applied to the end state, since early periods are
       # dominated by the still-unrenovated stock)
       affordability_periods="all",
       equity_spending_floor=true,
       # Level 1b: share of a nominal subsidy lost to tax and benefit rules
       # before it reaches the household (Martín-Consuegra et al. 2026: Madrid
       # mean ≈ 0.5 for poor households). The household receives
       # σ × (1 − clawback); the state pays the nominal σ — unless
       # clawback_returns_to_budget is true, in which case the clawed-back
       # part is netted out of public spending (it returns via taxes).
       clawback_rate_by_class=(poor=0.0, rich=0.0),
       clawback_returns_to_budget=false,
       # Level 2: landlord/tenant tenure split for multi-family housing.
       # tenure_enabled=false (default) adds NOTHING — baseline reproduced.
       # When true, every MFH archetype row is split: the owner keeps
       # (1 − rented shares) of the dwellings; rented_public and
       # rented_private variants are added with the parent's building
       # physics. Public tenants are poor; the private-rental stock is
       # split into a poor and a rich tenant (decision change 2026-10-08,
       # superseding "tenant always poor" of 2026-10-01; see
       # private_rich_tenant_share). No rich public tenant.
       tenure_enabled=false,
       # rented_public = 0.082 — SOURCED (user note 2026-10-08):
       #   numerator 595,800 municipal dwellings under rental contract
       #   end-2024 (GUS, Gospodarka mieszkaniowa w 2024 r.) + TBS/SIM
       #   ≈ 110,000 FLAGGED APPROXIMATE (range 93,000–120,000; KZN
       #   statement "over 120k"; money.pl/GUS-BGK "over 93k built since
       #   1996"); denominator 8,609,900 dwellings in multi-dwelling
       #   buildings (GUS NSP Census 2021, preliminary results,
       #   31 March 2021). Share = 705,800 / 8,609,900 = 8.2%;
       #   sensitivity 8.1–8.3% as given (model-side check: the TBS
       #   bounds compute to 8.0–8.3%). Replaces the 0.10 placeholder.
       # rented_private = 0.08 — DERIVED (wave 9, user order 2026-10-09):
       #   0.05 × 14.1M households ÷ 8.61M MFH dwellings (Eurostat EU-SILC
       #   ilc_lvho02 geo=PL 2025, tenure=RENT_MKT: 5.0% of persons; GUS
       #   household count; GUS NSP Census 2021 MFH dwelling count).
       #   FLAGGED "derived, assumes market-rent tenants live in MFH".
       #   Replaces the 0.05 placeholder (pinned in the repro gates).
       tenure_share_by_archetype=(rented_public=0.082, rented_private=0.08),
       # Share of the PRIVATE-rental stock whose tenant is rich (high
       # income). 0.84 — SOURCED (wave 9, user order 2026-10-09):
       # Eurostat EU-SILC, share of market-rent tenants below 60% of
       # median income (AROP) → 16/84 split. FLAGGED "AROP-based, not
       # quintile-based". Replaces the 0.5 placeholder of 2026-10-08
       # (pinned in the repro gates). 0.0 reproduces the old
       # single-poor-tenant structure. The rich tenant is reported (cost
       # change, cost-to-income share), never enforced; same building
       # physics and landlord as the poor twin.
       private_rich_tenant_share=0.84,
       # Annual rent increase a landlord may charge = pass_through_rate ×
       # eligible investment base (see passthrough_base_net_of_grants).
       # RULE VALUES (user source note 2026-10-08):
       #   German  (rule_DE): private 0.08 (§559 BGB)
       #   Polish  (rule_PL): private 0.10 — SOURCED, Art. 8a(4b)(b) ustawa
       #     o ochronie praw lokatorów (Dz.U. 2023 poz. 725): 10%/yr of the
       #     owner's outlays for a permanent improvement raising use value.
       #   public 0.02 — OPEN placeholder for both rules (Weber & Wolff 2018
       #     0.8–2.8%; Polish municipal rents are council-set under Art. 7–8,
       #     no pass-through rule found yet).
       # DEFAULT = the Polish private 0.10 (user decision 2026-10-09: the
       # paper's "current law" case is rule_PL; the German values live on
       # explicitly in rule_DE scenarios and in the pinned repro-gate and
       # S2 scenarios, which keep the pre-decision configuration).
       pass_through_rate_by_landlord=(public=0.02, private=0.10),
       # Cap on the annual rent increase, EUR per m² per YEAR.
       #   German (rule_DE): 3 €/m²/yr (§559 cap €2–3).
       #   Polish (rule_PL): NONE — SOURCED, Art. 8a(4) 3%-of-replacement-
       #     value line is a justification threshold, not a ceiling; the
       #     1.0e6 sentinel is the DEFAULT (rule_PL, 2026-10-09). Applied at
       #     the archetype-average level (same convention as liquidity).
       rent_increase_cap_per_m2=1.0e6,
       # Whether PV capex counts toward the pass-through base. true =
       # German-rule reading (§559 covers modernisation incl. PV); Polish:
       # INTERPRETIVE — Art. 8a(4b)(b) "permanent improvement raising use
       # value" plausibly includes PV, not explicit (user source note
       # 2026-10-08). PV never receives a landlord subsidy either way.
       pv_in_passthrough_base=true,
       # How long the levy runs, in YEARS from the investment (booked at
       # the period's start year, the same convention as capex):
       #   "permanent" — levy never expires (German §559 reading; was the
       #     default until 2026-10-09 to keep committed results from being
       #     silently redefined — that deviation from the 2026-10-08 note is
       #     RESOLVED by the user decision making rule_PL the default; the
       #     old-default scenarios of record are pinned explicitly),
       #   "recovery" — SOURCED, Art. 8a(4b)(b): the 10%/yr return runs
       #     until the outlays are recovered, i.e. ceil(1/ρ) years
       #     (10 y at ρ = 0.10); the godziwy-zysk (fair profit) component
       #     is not tied to the investment and is ignored. DEFAULT.
       #   or an integer number of years.
       pass_through_years="recovery",
       # Whether grants are deducted from the pass-through base ("grant-
       # deduction rule"). true — INTERPRETIVE for Poland: Art. 8a(4b)
       # speaks of outlays borne by the owner (nakłady poniesione przez
       # właściciela); a grant-financed share is not borne by the owner
       # (user source note 2026-10-08; German §559a explicit). false is
       # the sensitivity on this reading (S4 rule_PL_gross).
       passthrough_base_net_of_grants=true,
       # Landlord discount-rate sensitivity (user order 2026-10-09 §3d):
       # nothing = landlords discount at the global rate r from context.csv
       # (0.03) — bit-identical to every committed result; a number (e.g.
       # 0.04) applies that rate to the LANDLORD terms of the follower
       # objective only (investment, maintenance, rent flows of rented
       # archetypes). Limitation, recorded: the salvage/residual-value
       # factor (net_capex_factor) keeps the global rate — it is measure×
       # period, not archetype-specific.
       landlord_discount_rate=nothing,
       # PLACEHOLDER, to be discussed: landlord liquidity, EUR per dwelling
       # per year (public = municipal budget constraint; private = none)
       liquidity_cap_by_landlord=(public=5000.0, private=Inf),
       # Upper bound on the two landlord subsidy rates (leader instruments)
       landlord_subsidy_cap=1.0,
       # Whether landlord subsidies for buildings housing poor tenants count
       # toward the ≥30% "spending on the poor" floor (report both)
       landlord_subsidy_counts_as_poor=true,
       # EED Art. 6 public-body renovation obligation (Directive (EU)
       # 2023/1791), added 2026-10-27; AMENDED same day (user decisions):
       # the standard is the nZEB PROXY — DEEP envelope AND heat pump or
       # district heat (Polish nZEB limit for multi-family 65 kWh primary/
       # m²·yr, WT 2021) — and the required share is min(0.03 × years
       # since 2026, what the archetype's envelope/heating/joint capacity
       # allows) — see eed_required_share and the follower constraint.
       # A legal obligation on the landlord → FOLLOWER constraint, never a
       # leader choice. SIMPLIFICATIONS, recorded: applied to ALL
       # public-rental dwellings (250 m² threshold and the possible
       # social-housing exemption ignored); clock starts 2026 (assumed);
       # period-END check instead of the yearly carry-over of Art. 6(3).
       # Default false = every committed result unchanged.
       eed_public_obligation=false,
       # Weight w ∈ [0, 1] the PUBLIC landlord puts on its tenants' costs
       # (energy bill + carbon cost + rent increase) in its own objective,
       # added 2026-10-27 (user order). w = 0 (default) = committed
       # behaviour, bit-identical (the term is not built). w = 1 = the
       # landlord decides fully on the tenants' behalf — the rent increase
       # then cancels against its own rent income. Private landlords are
       # always w = 0. KNOWN INDETERMINACY, recorded: at w = 1 rent_inc
       # has objective coefficient 0, so the optimizer may return ANY
       # feasible rent level — reported tenant costs at w = 1 depend on
       # that arbitrary choice (not resolved; needs a user decision).
       public_tenant_weight=0.0,
       # Fossil-boiler ban as a SCENARIO, not the standard (2026-10-27, user
       # order). false (NEW default): the end-of-life forced-replacement
       # constraints (follower + master mirror) are not built; ban_year is
       # then inert. true: the pre-2026-10-27 behaviour (forced HP/DH
       # replacement of end-of-life boilers from ban_year, default 2040).
       # Source for the ban OPTION: EPBD 2024/1275 aim to phase out fossil
       # boilers by 2040; there is NO binding Polish ban — hence off by
       # default. ALL results committed before 2026-10-27 were produced
       # with the ban ON (labelled in README/CHANGELOG); re-running any
       # pre-existing scenario under the new default will NOT reproduce
       # them. Scenarios whose defined PURPOSE is the ban lever (early_ban,
       # all_levers, boiler_ban) carry fossil_boiler_ban=true explicitly.
       fossil_boiler_ban=false,
       # --- Polish-stock recalibration levers (2026-10-27 order; all
       # defaults reproduce the committed stylised model exactly) ---
       # Stock file the archetypes are read from (cwd-relative).
       stock_file="archetypes_v2.csv",
       # Share of PUBLIC-rental dwellings whose tenant is high-income
       # (mirror of private_rich_tenant_share; 0.0 = committed behaviour,
       # every public tenant low-income — kept as the pl_pubpoor
       # sensitivity). 0.762 in the pl_* scenarios = 23.8% low-income
       # tenants (user decision 2026-10-27).
       public_rich_tenant_share=0.0,
       # EPBD trajectory mode: "absolute" (committed; traj_values from
       # context.csv as absolute kWh primary/m²·yr) or "relative_to_2020"
       # (traj_values = (1−r)×the model's own 2020 stock-average primary,
       # computed at load; the 2050 target scales with the last r).
       # Reductions: −16%/−20% per EPBD Art. 9(2); −40%/−59% keep the
       # committed relative depths, marked ASSUMED.
       traj_mode="absolute",
       traj_reductions=(0.16, 0.20, 0.40, 0.59),
       # 2026-10-27 phase-2 ruling (pl8_kprb): explicit absolute targets
       # replacing both the context.csv values and the relative mode.
       traj_values_override=nothing,
       # Renovation-capacity overrides (nothing = committed staging).
       # env_rate_path / joint_rate_path: 4 stage values for <2030,
       # 2030–34, 2035–39, ≥2040; hvac_rate_const: one annual rate.
       # pl_* scenarios: KPRB operational profile env 2.7/3.2/3.6/3.9 %/yr
       # (single-family renovations per year ÷ 6.93M buildings; same
       # profile ASSUMED for MFH), hvac 4 %/yr (25-yr boiler life;
       # sensitivity 6%), joint = env + 0.4×hvac (user-approved rule:
       # envelope and heating can run at full rates simultaneously; PV
       # competes inside the joint cap; cap LOGIC unchanged).
       env_rate_path=nothing,
       hvac_rate_const=nothing,
       joint_rate_path=nothing,
       # 2026-10-27 (equity-floor sweep on the PL stock): overrides the
       # ≥30% floor VALUE from context.csv (nothing = the context value,
       # bit-identical to every committed result). Only active while
       # equity_spending_floor=true.
       equity_floor_value=nothing,
       # 2026-10-27 diagnostic lever: overrides the GLOBAL discount rate r
       # from context.csv (nothing = 0.03, bit-identical). LIMITATION,
       # recorded: r is single and global (both levels), so this moves the
       # household side AND the leader's spending discounting together —
       # harmless for the σ = 0 feasibility diagnostics it was added for
       # (spending is 0 there).
       discount_rate_override=nothing,
       # 2026-10-27 (user order): HOUSEHOLD discount rates, separate from
       # the state's r (context.csv 0.03, used unchanged for the leader's
       # spending and all leader-side reporting). Applied to the FOLLOWER
       # objective's time discounting per archetype group; `nothing`
       # entries fall back to the committed behaviour (owners: global r;
       # landlords: landlord_discount_rate / r). CALIBRATION of 0.08 and
       # sources: data/PROVENANCE_polish_stock.md. LIMITATION, recorded
       # (same as landlord_discount_rate): net_capex_factor (salvage) and
       # the affordability annuities keep the global rate — they are
       # measure×period, not archetype-specific.
       household_discount_rates=(owner_poor=nothing, owner_rich=nothing,
                                 landlord_public=nothing, landlord_private=nothing),
       # 2026-10-27 step-0 order: subsidies apply only to renovations in
       # periods ENDING at or before this year (nothing = unlimited, the
       # committed behaviour for all pre-existing scenarios). 2050 in the
       # pl_r8 family = the new-run default: post-2050 adoption receives
       # no subsidy (follower fz = 0, leader pays nothing), so reported
       # spending covers 2020–2050. Enforced in the follower, in z_leader
       # and in the master's McCormick block.
       subsidy_horizon_end=nothing,
       # 2026-10-27 carrier-price order (phase 1): sourced per-carrier
       # household energy prices, EUR/kWh of FINAL energy, real EUR 2024,
       # incl. taxes, EXCL. ETS2 (the model adds the carbon cost on the
       # fossil fraction separately), constant in real terms over the
       # horizon. nothing = the legacy hard-coded p_gas/p_dh/p_elec and
       # the near-break-even Δp_hp — every committed scenario reproduces
       # bit-identically. When set, the stock file MUST carry the fossil
       # fuel-mix columns (mix_coal, mix_wood, mix_gas, mix_oil): each
       # archetype's fossil price AND CO₂ intensity are computed from the
       # SAME mix, and Δp_hp/Δp_dh become per-archetype. Values and
       # sources: data/PROVENANCE_polish_stock.md.
       carrier_prices=nothing,
       # ETS2 CO₂ emission factors per fossil carrier, kg/kWh final (used
       # only with carrier_prices; wood counts 0 under ETS2). Values and
       # sources: user order 2026-10-27 + PROVENANCE.
       carrier_co2=(coal=0.34, gas=0.20, oil=0.27, wood=0.0),
       # 2026-10-27 phase-1 correction (1): seasonal heat-generation
       # efficiencies η_H,g per system. nothing = legacy — E0 (final) is
       # implicitly treated as useful heat in the heat-pump link
       # (electricity = E0/SCOP, i.e. η_boiler = 1) and the DH switch uses
       # the measure's fixed 0.70 — every committed scenario reproduces
       # bit-identically. When set (requires carrier_prices): useful heat
       # = E0 × η_a (η_a from the archetype's fossil mix), heat-pump
       # electricity = E0 × η_a / SCOP(3.0), DH-switch delivered heat =
       # E0 × η_a / η_dh — applied to bills AND primary energy. Values
       # PROPOSED from the energy-certificate methodology η_H,g tables
       # (see PROVENANCE), FLAGGED.
       carrier_etas=nothing,
       # 2026-10-29 Polish investment-cost order: optional per-dwelling
       # measure costs, EUR, keyed (btype, m_id) — e.g.
       # ("SFH","envelope_deep") => 18021.0. Sourced from the Czyste
       # Powietrze cost annex (od 20.07.2026, 100% tier eligible unit
       # costs) with a documented envelope geometry; derivation and
       # sources: data/PROVENANCE_polish_stock.md "Investment costs".
       # nothing = the legacy capex_per_m2 × floor_area + fixed_capex
       # from measures_v2.csv — every committed scenario reproduces
       # bit-identically. Pairs not in the Dict keep the legacy formula
       # (DH connection and PV stay legacy by order).
       measure_costs=nothing,
       # 2026-10-29 review change (2): optional per-dwelling envelope
       # saving factors, keyed (btype, m_id) — derived from the SAME
       # component scope and geometry as measure_costs (light = roof
       # only, medium = walls only, deep = walls+roof+windows+doors)
       # with sourced U-values (before: NAPE/TABULA PL 1967–1985
       # catalogue sheets; after: WT 2021 U_max); floor and ventilation
       # stay in the heat balance unrenovated. Derivation:
       # data/PROVENANCE_polish_stock.md "Investment costs". nothing =
       # the legacy measures_v2.csv reduction factors — every committed
       # scenario reproduces bit-identically.
       measure_reductions=nothing,
       descr="") =
    (ban_year=ban_year, co2_scale=co2_scale, dh_cap_sfh=dh_cap_sfh,
     dh_cap_mfh=dh_cap_mfh, reno_scale=reno_scale, subsidy_boost=subsidy_boost,
     residual_value=residual_value, pef_frozen=pef_frozen, wood_pef=wood_pef,
     affordability_mode=affordability_mode,
     affordability_tolerance=affordability_tolerance,
     affordability_income_share=affordability_income_share,
     affordability_reference=affordability_reference,
     affordability_scope=affordability_scope,
     household_income_by_class=household_income_by_class,
     affordability_periods=affordability_periods,
     equity_spending_floor=equity_spending_floor,
     clawback_rate_by_class=clawback_rate_by_class,
     clawback_returns_to_budget=clawback_returns_to_budget,
     tenure_enabled=tenure_enabled,
     tenure_share_by_archetype=tenure_share_by_archetype,
     private_rich_tenant_share=private_rich_tenant_share,
     pass_through_rate_by_landlord=pass_through_rate_by_landlord,
     rent_increase_cap_per_m2=rent_increase_cap_per_m2,
     pv_in_passthrough_base=pv_in_passthrough_base,
     pass_through_years=pass_through_years,
     passthrough_base_net_of_grants=passthrough_base_net_of_grants,
     landlord_discount_rate=landlord_discount_rate,
     liquidity_cap_by_landlord=liquidity_cap_by_landlord,
     landlord_subsidy_cap=landlord_subsidy_cap,
     landlord_subsidy_counts_as_poor=landlord_subsidy_counts_as_poor,
     eed_public_obligation=eed_public_obligation,
     public_tenant_weight=public_tenant_weight,
     fossil_boiler_ban=fossil_boiler_ban,
     stock_file=stock_file,
     public_rich_tenant_share=public_rich_tenant_share,
     traj_mode=traj_mode, traj_reductions=traj_reductions,
     traj_values_override=traj_values_override,
     env_rate_path=env_rate_path, hvac_rate_const=hvac_rate_const,
     joint_rate_path=joint_rate_path,
     equity_floor_value=equity_floor_value,
     discount_rate_override=discount_rate_override,
     household_discount_rates=household_discount_rates,
     subsidy_horizon_end=subsidy_horizon_end,
     carrier_prices=carrier_prices, carrier_co2=carrier_co2,
     carrier_etas=carrier_etas,
     measure_costs=measure_costs,
     measure_reductions=measure_reductions,
     pv_enabled=pv_enabled, learning_rates=learning_rates,
     period_years=period_years, co2_price_path=co2_price_path,
     history_adoption_file=history_adoption_file, history_fix_classes=history_fix_classes,
     history_subsidy=history_subsidy, fuel_mix_update=fuel_mix_update,
     subsidy_horizon_start=subsidy_horizon_start, discount_base_year=discount_base_year,
     descr=descr)

SCENARIO_DEFS = Dict(
    "baseline"       => scen(descr="Poland-calibrated model, current policy levers"),
    "high_subsidy"   => scen(subsidy_boost=:all_100,
                             descr="Money lever: subsidy caps 100% for all non-PV measures"),
    "early_ban"      => scen(ban_year=2030, fossil_boiler_ban=true,
                             descr="Regulation lever: fossil boiler ban from 2030 instead of 2040"),
    "high_co2"       => scen(co2_scale=1.4,
                             descr="Price lever: high ETS2 path (max ~490 EUR/t by 2050)"),
    "dh_expansion"   => scen(dh_cap_sfh=0.10, dh_cap_mfh=0.85,
                             descr="Infrastructure lever: district heat network expansion"),
    "fast_reno"      => scen(reno_scale=1.5,
                             descr="Capacity lever: renovation industry ceilings x1.5"),
    "frozen_pef"     => scen(pef_frozen=true,
                             descr="Sensitivity: electricity/DH primary factors frozen at 2023 values"),
    "no_residual"    => scen(residual_value=false,
                             descr="Sensitivity: no salvage credit for late investments"),
    "all_levers"     => scen(ban_year=2030, fossil_boiler_ban=true,
                             co2_scale=1.4, dh_cap_sfh=0.10, dh_cap_mfh=0.85,
                             reno_scale=1.5, subsidy_boost=:all_100,
                             descr="Feasibility ceiling: all levers combined"),
    # Fossil-boiler ban as a NAMED scenario (2026-10-27, user order): the
    # pre-2026-10-27 standard behaviour, kept available. Every result
    # committed before 2026-10-27 was produced with this constraint ON.
    "boiler_ban"     => scen(fossil_boiler_ban=true,
                             descr="Fossil-boiler ban from 2040 (end-of-life forced replacement; the pre-2026-10-27 standard; EPBD 2024/1275 phase-out aim, no binding Polish ban)"),
    # --- Level 1a design comparison (plan §2): (a)=baseline, (b)=afford_only,
    #     (c)=afford_neutral, (d)=no_floor ---
    "afford_neutral" => scen(affordability_mode="cost_neutral",
                             descr="Affordability: cost-neutral constraint for low-income households, plus 30% spending floor"),
    "afford_only"    => scen(affordability_mode="cost_neutral", equity_spending_floor=false,
                             descr="Affordability: cost-neutral constraint only, 30% spending floor disabled"),
    "no_floor"       => scen(equity_spending_floor=false,
                             descr="Neither affordability constraint nor 30% spending floor"),
    # --- income-share affordability (Table 1 second block; PLACEHOLDER incomes,
    #     GUS to replace). Applied to the end state (period ending 2050) only ---
    "afford_incshare"      => scen(affordability_mode="income_share", affordability_periods="final",
                             descr="Income-share affordability 10% at 2050 end state, plus spending floor [sourced GUS incomes]"),
    "afford_incshare_only" => scen(affordability_mode="income_share", affordability_periods="final",
                             equity_spending_floor=false,
                             descr="Income-share affordability 10% at 2050 end state, floor disabled [sourced GUS incomes]"),
    "afford_incshare_s15"  => scen(affordability_mode="income_share", affordability_periods="final",
                             affordability_income_share=0.15,
                             descr="Income-share affordability 15% at 2050 end state, plus spending floor [sourced GUS incomes]"),
    "afford_incshare_s20"  => scen(affordability_mode="income_share", affordability_periods="final",
                             affordability_income_share=0.20,
                             descr="Income-share affordability 20% at 2050 end state, plus spending floor [sourced GUS incomes]"),
    # --- s = 0.10 diagnostics (heuristic only): where exactly does feasibility
    #     break between s = 0.15 and 0.10, and is industry capacity the binding
    #     constraint at 0.10? ---
    "afford_incshare_s11"  => scen(affordability_mode="income_share", affordability_periods="final",
                             affordability_income_share=0.11,
                             descr="Income-share sweep point s=0.11 [sourced GUS incomes]"),
    "afford_incshare_s12"  => scen(affordability_mode="income_share", affordability_periods="final",
                             affordability_income_share=0.12,
                             descr="Income-share sweep point s=0.12 [sourced GUS incomes]"),
    "afford_incshare_s13"  => scen(affordability_mode="income_share", affordability_periods="final",
                             affordability_income_share=0.13,
                             descr="Income-share sweep point s=0.13 [sourced GUS incomes]"),
    "afford_incshare_s14"  => scen(affordability_mode="income_share", affordability_periods="final",
                             affordability_income_share=0.14,
                             descr="Income-share sweep point s=0.14 [sourced GUS incomes]"),
    "afford_incshare_s10_capacity_relaxed" => scen(affordability_mode="income_share",
                             affordability_periods="final", reno_scale=100.0,
                             descr="DIAGNOSTIC: income-share 10% with industry capacity ceilings relaxed (per-period adoption caps ≈ 1) [sourced GUS incomes]"),
    # --- Level 1b / run S1: clawback sweep (poor class), cost-neutral
    #     affordability + spending floor on; clawback 0 point = afford_neutral ---
    "claw_p10" => scen(affordability_mode="cost_neutral", clawback_rate_by_class=(poor=0.1, rich=0.0),
                       descr="S1: 10% of low-income subsidy lost to tax/benefit clawback"),
    "claw_p20" => scen(affordability_mode="cost_neutral", clawback_rate_by_class=(poor=0.2, rich=0.0),
                       descr="S1: 20% of low-income subsidy lost to tax/benefit clawback"),
    "claw_p30" => scen(affordability_mode="cost_neutral", clawback_rate_by_class=(poor=0.3, rich=0.0),
                       descr="S1: 30% of low-income subsidy lost to tax/benefit clawback"),
    "claw_p40" => scen(affordability_mode="cost_neutral", clawback_rate_by_class=(poor=0.4, rich=0.0),
                       descr="S1: 40% of low-income subsidy lost to tax/benefit clawback"),
    "claw_p50" => scen(affordability_mode="cost_neutral", clawback_rate_by_class=(poor=0.5, rich=0.0),
                       descr="S1: 50% of low-income subsidy lost to tax/benefit clawback (Madrid mean)"),
    "claw_p50_returns" => scen(affordability_mode="cost_neutral", clawback_rate_by_class=(poor=0.5, rich=0.0),
                       clawback_returns_to_budget=true,
                       descr="S1 variant: 50% clawback, clawed-back part netted out of public spending"),
    # --- Level 2: landlord/tenant tenure split (headline-table design cases;
    #     PLACEHOLDER tenure shares, GUS to replace) ---
    "tenure_on"     => scen(tenure_enabled=true,
                       descr="Tenure split on (rented_public + rented_private MFH variants), no affordability constraint [PLACEHOLDER tenure shares]"),
    # Base config for the E1_baseline_rates_tenure_nopass EVALUATION
    # (pre-registered 2026-10-12, Poland-only order): identical to
    # tenure_on except the private pass-through is ZERO — gives the
    # rule_PL vs no-pass-through uptake comparison at the certified D0
    # rates. Used only via the E1 fixed-rate evaluation wrapper (leader
    # never re-optimises); never a CCG scenario of its own.
    "tenure_on_nopass" => scen(tenure_enabled=true,
                       pass_through_rate_by_landlord=(public=0.02, private=0.00),
                       descr="E1-nopass base: tenure on, no affordability, private pass-through 0.00 (no-pass-through counterpart to tenure_on; public 0.02 open)"),
    # --- Public-landlord institution switches (pre-registered 2026-10-27,
    #     user order; defined, NOT run): EED Art. 6 obligation × tenant-cost
    #     weight w. Base = tenure_on (rule_PL defaults, affordability off).
    #     pub_w00 is configured identically to tenure_on (both switches at
    #     their defaults); it is kept as the named w = 0 point of the grid. ---
    "pub_w00"     => scen(tenure_enabled=true, public_tenant_weight=0.0,
                       descr="Public-landlord tenant-cost weight w=0.0 (identical config to tenure_on; EED off)"),
    "pub_w05"     => scen(tenure_enabled=true, public_tenant_weight=0.5,
                       descr="Public-landlord tenant-cost weight w=0.5 (EED off)"),
    "pub_w10"     => scen(tenure_enabled=true, public_tenant_weight=1.0,
                       descr="Public-landlord tenant-cost weight w=1.0 — decides fully on tenants' behalf; the rent increase cancels in its objective (EED off)"),
    "eed_pub_w00" => scen(tenure_enabled=true, eed_public_obligation=true, public_tenant_weight=0.0,
                       descr="EED Art. 6 obligation on the public landlord (3%/yr deep-envelope from 2026, cumulative), w=0.0"),
    "eed_pub_w05" => scen(tenure_enabled=true, eed_public_obligation=true, public_tenant_weight=0.5,
                       descr="EED Art. 6 obligation on the public landlord, w=0.5"),
    "eed_pub_w10" => scen(tenure_enabled=true, eed_public_obligation=true, public_tenant_weight=1.0,
                       descr="EED Art. 6 obligation on the public landlord, w=1.0"),
    "tenure_afford" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       descr="Tenure split + cost-neutral affordability for low-income owners AND tenants [wave-9 data: shares 0.082 sourced / 0.08 derived, split 0.84 AROP-based]"),
    # Wave-9 income sensitivity (user order 2026-10-09): D5 with the
    # 2026-10-08 signal-note incomes (household sizes 3.60/2.12, not
    # found in the downloaded GUS publication — check PARTLY FAILED).
    "d5_inc_signalnote" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       household_income_by_class=(poor=11560.0, rich=35920.0),
                       descr="D5 sensitivity: signal-note incomes 11,560/35,920 (sizes 3.60/2.12) instead of the Tablica-2 incomes 9,635/33,378"),
    # --- Level 2 test scenarios (test_tenure.jl; never used for results) ---
    # T2/T4 need the no-return case isolated from the boiler ban (the ban
    # would FORCE landlord HVAC swaps from 2040), so the ban is pushed
    # beyond the horizon in this test scenario only.
    "tenure_test_no_return" => scen(tenure_enabled=true, ban_year=2060,
                       pass_through_rate_by_landlord=(public=0.0, private=0.0),
                       descr="TEST ONLY: zero pass-through, ban beyond horizon — landlords must renovate nothing"),
    "tenure_test_high_passthrough" => scen(tenure_enabled=true, ban_year=2060,
                       pass_through_rate_by_landlord=(public=0.50, private=0.50),
                       rent_increase_cap_per_m2=1.0e6,   # effectively uncapped, numerically safe
                       pass_through_years="permanent",   # pinned: T3 compares against full-savings owners
                       descr="TEST ONLY: very high pass-through, no rent cap — landlords renovate like owners would"),
    # --- S3 (user request 2026-10-01): clawback × income-share s=0.15,
    #     leader re-optimising; clawback-0 point = afford_incshare_s15.
    #     Direct test of the conditional reading of H3 (clawback should bite
    #     where subsidies are NOT residual). [sourced GUS incomes] ---
    "s3_claw25_incshare15" => scen(affordability_mode="income_share", affordability_periods="final",
                       affordability_income_share=0.15, clawback_rate_by_class=(poor=0.25, rich=0.0),
                       descr="S3: income-share 15% at 2050 + 25% clawback on low-income subsidies [sourced GUS incomes]"),
    "s3_claw50_incshare15" => scen(affordability_mode="income_share", affordability_periods="final",
                       affordability_income_share=0.15, clawback_rate_by_class=(poor=0.5, rich=0.0),
                       descr="S3: income-share 15% at 2050 + 50% clawback on low-income subsidies [sourced GUS incomes]"),
    # --- affordability_reference sensitivities (user decision 2026-10-01:
    #     zero_subsidy is the MAIN case; frozen_stock reported as a
    #     sensitivity for D3 and D5x) ---
    "afford_neutral_frozenref" => scen(affordability_mode="cost_neutral",
                       affordability_reference="frozen_stock",
                       descr="D3 sensitivity: cost-neutral affordability vs the FROZEN-STOCK reference"),
    # --- D5x (user request 2026-10-01, heuristic only): full tenure case,
    #     affordability enforced for owners and PUBLIC tenants only; the
    #     private tenant's affordability gap is reported in EUR/yr ---
    "tenure_afford_scoped" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       descr="D5x: tenure + cost-neutral affordability for low-income owners and public tenants; private tenants reported, not enforced [PLACEHOLDER tenure shares]"),
    "tenure_afford_scoped_frozenref" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       affordability_reference="frozen_stock",
                       descr="D5x sensitivity: as tenure_afford_scoped, FROZEN-STOCK reference [PLACEHOLDER tenure shares]"),
    "tenure_afford_frozenref" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_reference="frozen_stock",
                       descr="D5 sensitivity: tenure + cost-neutral affordability, FROZEN-STOCK reference (the 2026-10-01 morning run's reading) [PLACEHOLDER tenure shares]"),
    # --- tenure-share sensitivity (user request 2026-10-01, heuristic only):
    #     rental shares doubled, for D4 and D5x [PLACEHOLDER shares ×2] ---
    # redefined 2026-10-08 and again 2026-10-11 (wave 9): doubles the
    # CURRENT shares (public sourced 0.082 → 0.164; private derived
    # 0.08 → 0.16). Pre-registered in the wave-9 CHANGELOG entry.
    "tenure_on_shares2x" => scen(tenure_enabled=true,
                       tenure_share_by_archetype=(rented_public=0.164, rented_private=0.16),
                       descr="D4 sensitivity: rental shares doubled (public 0.164 = 2x sourced, private 0.16 = 2x derived)"),
    "tenure_afford_scoped_shares2x" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       tenure_share_by_archetype=(rented_public=0.164, rented_private=0.16),
                       descr="D5x sensitivity: rental shares doubled (public 0.164 = 2x sourced, private 0.16 = 2x derived)"),
    # --- S2 pass-through sweep (plan §3): private landlord's pass-through
    #     rate swept, public held at its default 0.02; tenure on,
    #     cost-neutral affordability enforced for owners and public tenants
    #     (the swept private tenant is REPORTED via the landlord-rate scan,
    #     not enforced, so every sweep point yields an optimum; stated in
    #     the Figure 4 footnote). Leader re-optimises at each point. ---
    "s2_ptr00" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       pass_through_rate_by_landlord=(public=0.02, private=0.00),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2: private pass-through 0.00 [PLACEHOLDER tenure shares]"),
    "s2_ptr01" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       pass_through_rate_by_landlord=(public=0.02, private=0.01),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2: private pass-through 0.01 [PLACEHOLDER tenure shares]"),
    "s2_ptr02" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       pass_through_rate_by_landlord=(public=0.02, private=0.02),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2: private pass-through 0.02 (public-landlord level) [PLACEHOLDER tenure shares]"),
    "s2_ptr03" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       pass_through_rate_by_landlord=(public=0.02, private=0.03),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2: private pass-through 0.03 [PLACEHOLDER tenure shares]"),
    "s2_ptr05" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       pass_through_rate_by_landlord=(public=0.02, private=0.05),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2: private pass-through 0.05 [PLACEHOLDER tenure shares]"),
    "s2_ptr08" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       pass_through_rate_by_landlord=(public=0.02, private=0.08),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2: private pass-through 0.08 (German §559 default) [PLACEHOLDER tenure shares]"),
    "s2_ptr10" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       pass_through_rate_by_landlord=(public=0.02, private=0.10),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2: private pass-through 0.10 [PLACEHOLDER tenure shares]"),
    # --- S2 frozen-stock sensitivity (added 2026-10-01 after the main-case
    #     sweep returned gap ≡ 0 at every point BY CONSTRUCTION — under the
    #     zero_subsidy reference the no-subsidy levy is in the benchmark, so
    #     Figure 4's informative curve exists only under the warm-rent
    #     (frozen_stock) reading. Sensitivity beyond the ordered D3/D5x
    #     scope; labelled as such, cheap to discard.) ---
    "s2f_ptr00" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.00),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2 frozen-stock sensitivity: private pass-through 0.00 [PLACEHOLDER tenure shares]"),
    "s2f_ptr01" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.01),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2 frozen-stock sensitivity: private pass-through 0.01 [PLACEHOLDER tenure shares]"),
    "s2f_ptr02" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.02),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2 frozen-stock sensitivity: private pass-through 0.02 [PLACEHOLDER tenure shares]"),
    "s2f_ptr03" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.03),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2 frozen-stock sensitivity: private pass-through 0.03 [PLACEHOLDER tenure shares]"),
    "s2f_ptr05" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.05),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2 frozen-stock sensitivity: private pass-through 0.05 [PLACEHOLDER tenure shares]"),
    "s2f_ptr08" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.08),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2 frozen-stock sensitivity: private pass-through 0.08 (German §559 default) [PLACEHOLDER tenure shares]"),
    "s2f_ptr10" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.10),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2 frozen-stock sensitivity: private pass-through 0.10 [PLACEHOLDER tenure shares]"),
    # --- diagnostic (user order 2026-10-01): is the ρ=0.05 private uptake
    #     spike PV base-pumping? Same point, PV excluded from the base ---
    "s2f_ptr05_nopv" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_scope="owners_and_public_tenants",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.05),
                       pv_in_passthrough_base=false,
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned German frame (pre-2026-10-09 default; sweep of record)
                       descr="S2 diagnostic: private pass-through 0.05, PV excluded from the pass-through base [PLACEHOLDER tenure shares]"),

    # --- S4 institutional scenarios (user source note 2026-10-08): the
    #     pass-through rule as an institutional scenario — Poland as is,
    #     Germany as is, counterfactual rules. D5 configuration (tenure +
    #     cost-neutral affordability, scope all, leader re-optimising);
    #     s4_* = zero_subsidy MAIN reference, s4f_* = frozen_stock
    #     sensitivity. Polish values: ρ private 0.10 SOURCED Art. 8a(4b)(b);
    #     no cap SOURCED (Art. 8a(4) 3%-of-replacement-value is a
    #     justification threshold, not a ceiling; 1.0e6 sentinel); duration
    #     "recovery" SOURCED (until outlays recovered = 10 y at 0.10);
    #     grants netted INTERPRETIVE (nakłady poniesione przez właściciela);
    #     public 0.02 OPEN placeholder in every row. ---
    "s4_rule_pl" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       pass_through_rate_by_landlord=(public=0.02, private=0.10),
                       rent_increase_cap_per_m2=1.0e6, pass_through_years="recovery",
                       descr="S4 rule_PL: Polish Art. 8a(4b) — 10% private, uncapped, levy until recovery, grants netted (interpretive) [PLACEHOLDER tenure shares; public rate open]"),
    "s4_rule_pl_gross" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       pass_through_rate_by_landlord=(public=0.02, private=0.10),
                       rent_increase_cap_per_m2=1.0e6, pass_through_years="recovery",
                       passthrough_base_net_of_grants=false,
                       descr="S4 rule_PL_gross: Polish rule, grants NOT netted from the base (sensitivity on the interpretive flag) [PLACEHOLDER tenure shares; public rate open]"),
    "s4_rule_de" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       pass_through_rate_by_landlord=(public=0.02, private=0.08),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",
                       descr="S4 rule_DE: German §559 — 8% private, 3 EUR/m2/yr cap, permanent levy, grants netted (= committed D5 configuration) [PLACEHOLDER tenure shares]"),
    "s4_rule_none" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       pass_through_rate_by_landlord=(public=0.02, private=0.00),
                       descr="S4 rule_none: no private pass-through at all (counterfactual) [PLACEHOLDER tenure shares; public rate open]"),
    "s4_rule_pl_capped" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       pass_through_rate_by_landlord=(public=0.02, private=0.10),
                       rent_increase_cap_per_m2=3.0, pass_through_years="recovery",
                       descr="S4 rule_PL_capped: Polish rule + the German 3 EUR/m2/yr cap (counterfactual mix) [PLACEHOLDER tenure shares; public rate open]"),
    "s4_rule_pl_permanent" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       pass_through_rate_by_landlord=(public=0.02, private=0.10),
                       rent_increase_cap_per_m2=1.0e6, pass_through_years="permanent",
                       descr="S4 rule_PL_permanent: Polish rate, uncapped, but levy never expires (counterfactual) [PLACEHOLDER tenure shares; public rate open]"),
    "s4f_rule_pl" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.10),
                       rent_increase_cap_per_m2=1.0e6, pass_through_years="recovery",
                       descr="S4 rule_PL under frozen_stock reference (sensitivity) [PLACEHOLDER tenure shares; public rate open]"),
    "s4f_rule_pl_gross" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.10),
                       rent_increase_cap_per_m2=1.0e6, pass_through_years="recovery",
                       passthrough_base_net_of_grants=false,
                       descr="S4 rule_PL_gross under frozen_stock reference (sensitivity) [PLACEHOLDER tenure shares; public rate open]"),
    "s4f_rule_de" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.08),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",
                       descr="S4 rule_DE under frozen_stock reference (= committed tenure_afford_frozenref configuration) [PLACEHOLDER tenure shares]"),
    "s4f_rule_none" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.00),
                       descr="S4 rule_none under frozen_stock reference (sensitivity) [PLACEHOLDER tenure shares; public rate open]"),
    "s4f_rule_pl_capped" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.10),
                       rent_increase_cap_per_m2=3.0, pass_through_years="recovery",
                       descr="S4 rule_PL_capped under frozen_stock reference (sensitivity) [PLACEHOLDER tenure shares; public rate open]"),
    "s4f_rule_pl_permanent" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       affordability_reference="frozen_stock",
                       pass_through_rate_by_landlord=(public=0.02, private=0.10),
                       rent_increase_cap_per_m2=1.0e6, pass_through_years="permanent",
                       descr="S4 rule_PL_permanent under frozen_stock reference (sensitivity) [PLACEHOLDER tenure shares; public rate open]"),

    # --- Rent-law test scenarios (test_rentlaw.jl T5/T6; never results) ---
    # ρ = 1.0 with a 1-year window: the forced 2040 HVAC swap must repay
    # exactly its base within one year and the levy must be zero by 2050.
    # Ban at the default 2040 FORCES the investment; affordability off.
    "rentlaw_test_t5" => scen(tenure_enabled=true,
                       pass_through_rate_by_landlord=(public=0.0, private=1.0),
                       rent_increase_cap_per_m2=1.0e6, pass_through_years=1,
                       descr="TEST T5/T6: 1-year window at 100% pass-through — base repaid in one year, levy zero after expiry"),
    # Invariance test (decision change 2026-10-08): the D5 configuration at
    # the OLD placeholder shares (0.10/0.05) with the rich twin ACTIVE must
    # reproduce the committed pre-archetype tenure_afford results exactly —
    # the landlord problem cannot depend on the tenant's income, and the
    # 50/50 split only relabels half the private stock.
    "tenure_oldshares_test" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       tenure_share_by_archetype=(rented_public=0.10, rented_private=0.05),
                       pass_through_rate_by_landlord=(public=0.02, private=0.08),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned rule_DE: the committed pins predate the 2026-10-09 rule_PL default
                       household_income_by_class=(poor=11560.0, rich=35920.0),  # pinned wave-8 data: the pins predate the 2026-10-11 wave-9 load
                       private_rich_tenant_share=0.5,                           # (incomes are indicator-only here, pinned for exactness)
                       descr="TEST: D5 config at the pre-2026-10-08 placeholder shares, high-income twin on — must reproduce committed tenure_afford"),
    # Landlord discount-rate sensitivity (user order 2026-10-09 §3d):
    # D5 configuration with landlords discounting at 4% (owners stay at the
    # global r = 0.03); under the Polish (default) and German (pinned) rule.
    "lldisc4_rule_pl" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       landlord_discount_rate=0.04,
                       descr="Sensitivity: landlord discount rate 4% under rule_PL (default rent rule)"),
    "lldisc4_rule_de" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       landlord_discount_rate=0.04,
                       pass_through_rate_by_landlord=(public=0.02, private=0.08),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",
                       descr="Sensitivity: landlord discount rate 4% under rule_DE (pinned German values)"),
    # E2 diagnostic (2026-10-09): German §559 values but GROSS pass-through
    # base — counterfactual, exists only so the E2 landlord-grant diagnostic
    # can cross rule × netting fully; never used for results tables.
    "e2_rule_de_gross" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       passthrough_base_net_of_grants=false,
                       descr="E2 DIAGNOSTIC: German rule, grants NOT netted from the base (counterfactual for the grant-acceptance test)"),
    # Default-config repro gate (re-pinned 2026-10-08 from the wave-8
    # outputs, the data of record after the sourced public share 0.082):
    # identical to tenure_afford but writes to its own directory so the
    # gate never clobbers the results-of-record folder.
    "tenure_newshares_test" => scen(tenure_enabled=true, affordability_mode="cost_neutral",
                       pass_through_rate_by_landlord=(public=0.02, private=0.08),
                       rent_increase_cap_per_m2=3.0, pass_through_years="permanent",  # pinned rule_DE: the wave-8 pins predate the 2026-10-09 rule_PL default
                       tenure_share_by_archetype=(rented_public=0.082, rented_private=0.05),  # pinned wave-8 data:
                       household_income_by_class=(poor=11560.0, rich=35920.0),                # the pins predate the
                       private_rich_tenant_share=0.5,                                         # 2026-10-11 wave-9 load
                       descr="TEST: the wave-8 D5 configuration (rule_DE + wave-8 data pinned) — must reproduce the wave-8 tenure_afford results"),
)
# --- Level 3 lite (2026-10-09, user order): the private rent rule as a
#     discrete leader choice. 48 generated scenarios = rate {0.05,0.08,0.10}
#     × cap {none, 3 EUR/m2} × duration {recovery, permanent} × base
#     {net, gross of grants} × reference {zero_subsidy, frozen_stock}, all
#     on the D5 configuration (public landlord 0.02 open placeholder).
#     Purely additive: no existing scenario changes. Collector:
#     table5_rent_rule_choice.jl; hypotheses H11 in CHANGELOG. ---
for rr in (0.05, 0.08, 0.10),
    (ck, cv) in (("capn", 1.0e6), ("cap3", 3.0)),
    (dk, dv) in (("rec", "recovery"), ("perm", "permanent")),
    (bk, bv) in (("net", true), ("gross", false)),
    (fk, fv) in (("zs", "zero_subsidy"), ("fs", "frozen_stock"))
    name = "l3_r" * lpad(string(Int(round(100 * rr))), 2, '0') *
           "_$(ck)_$(dk)_$(bk)_$(fk)"
    SCENARIO_DEFS[name] = scen(tenure_enabled=true,
        affordability_mode="cost_neutral", affordability_reference=fv,
        pass_through_rate_by_landlord=(public=0.02, private=rr),
        rent_increase_cap_per_m2=cv, pass_through_years=dv,
        passthrough_base_net_of_grants=bv,
        descr="L3-lite rule candidate: rho=$rr cap=$(cv == 3.0 ? "3 EUR/m2" : "none") $dv levy; base $(bv ? "net" : "gross") of grants; $fv reference")
end
# --- S2-PL (2026-10-13, Poland-only order; pre-registered 2026-10-12 in
#     the CHANGELOG next-round run list): the S2 pass-through sweep
#     re-pinned to the POLISH frame — no cap (1.0e6 sentinel), levy until
#     recovery, base net of grants (default), public landlord at its 0.02
#     open placeholder. Same D5x configuration as s2_*/s2f_* (tenure +
#     cost-neutral affordability for owners and public tenants; the swept
#     private tenant reported, not enforced). Figure 4 is rebuilt from
#     these. Purely additive: the German-frame s2_*/s2f_* runs of record
#     stay untouched. ---
for (fk, fv) in (("", "zero_subsidy"), ("f", "frozen_stock")),
    pr in (0.00, 0.01, 0.02, 0.03, 0.05, 0.08, 0.10)
    name = "s2" * fk * "pl_ptr" * lpad(string(Int(round(100 * pr))), 2, '0')
    SCENARIO_DEFS[name] = scen(tenure_enabled=true,
        affordability_mode="cost_neutral",
        affordability_scope="owners_and_public_tenants",
        affordability_reference=fv,
        pass_through_rate_by_landlord=(public=0.02, private=pr),
        rent_increase_cap_per_m2=1.0e6, pass_through_years="recovery",
        descr="S2-PL sweep: private pass-through $pr, Polish frame (no cap, levy until recovery, net of grants); $fv reference")
end
# nopv diagnostic at the frozen-stock rho=0.05 point (counterpart to
# s2f_ptr05_nopv — the PV-base spike it probes is a frozen-frame
# phenomenon; the pre-registered list wrote "s2pl_ptr05_nopv", defined
# here in the frozen frame to match the original diagnostic)
SCENARIO_DEFS["s2fpl_ptr05_nopv"] = scen(tenure_enabled=true,
    affordability_mode="cost_neutral",
    affordability_scope="owners_and_public_tenants",
    affordability_reference="frozen_stock",
    pass_through_rate_by_landlord=(public=0.02, private=0.05),
    pv_in_passthrough_base=false,
    rent_increase_cap_per_m2=1.0e6, pass_through_years="recovery",
    descr="S2-PL diagnostic: private pass-through 0.05, PV excluded from the pass-through base, Polish frame; frozen_stock reference")
# 2026-10-27 user decision, option (b) on the fossil-ban default flip: PIN
# fossil_boiler_ban=true explicitly on every scenario defined up to this
# point — all scenarios of record (behind committed results, tables,
# figures, certificates, test pins) reproduce exactly, AND the
# pre-registered-but-not-yet-run next-round scenarios (tenure_on_nopass,
# s2pl_*/s2fpl_*), whose definitions are anchored to with-ban comparators
# (tenure_on, the original S2 sweep) — leaving them off-default would
# silently redefine pre-registered runs. The ONLY exceptions are the six
# 2026-10-27 public-landlord scenarios (new default OFF applies; their E3
# with-ban evaluations used the explicit P4_FORCE_BOILER_BAN hook).
# Scenarios added BELOW this block get the new default (off).
let new_2026_10_27 = Set(["pub_w00", "pub_w05", "pub_w10",
                          "eed_pub_w00", "eed_pub_w05", "eed_pub_w10"])
    for (k, v) in SCENARIO_DEFS
        k in new_2026_10_27 && continue
        SCENARIO_DEFS[k] = merge(v, (fossil_boiler_ban=true,))
    end
end

# Explicit WITH-BAN variants of the four E3-evaluated public-landlord
# scenarios (user order, 2026-10-27): each matches EXACTLY the config the
# E3 evaluations ran under (the base scenario + fossil_boiler_ban=true,
# which E3 applied via P4_FORCE_BOILER_BAN). Defined BELOW the pin block,
# ban set explicitly; these are the E3 configs of record.
for eb in ("pub_w00", "pub_w05", "eed_pub_w00", "eed_pub_w05")
    SCENARIO_DEFS[eb * "_ban"] = merge(SCENARIO_DEFS[eb],
        (fossil_boiler_ban=true,
         descr=SCENARIO_DEFS[eb].descr * " + fossil-boiler ban ON (E3 evaluation config of record, 2026-10-27)"))
end

# --- Polish-stock NEW STANDARD scenarios (2026-10-27 order; defined below
# the pin block: fossil-boiler ban OFF per the order). Stock: census NSP 2021
# counts + Invert WPB cut re-derived at census weights (user-delivered,
# workbook verification OPEN) — data/PROVENANCE_polish_stock.md. Settings:
# tenure on (public 13.4% / private 8%), tenants 23.8% low-income both
# landlord types, rule_PL, EED obligation ON, w=0, clawback 0, affordability
# off, 30% floor on, EPBD trajectory relative to the model's own 2020 value,
# KPRB capacity profile, joint cap = env + 0.4×hvac. ---
let base = scen(stock_file="archetypes_pl.csv",
        tenure_enabled=true,
        tenure_share_by_archetype=(rented_public=0.134, rented_private=0.08),
        private_rich_tenant_share=0.762, public_rich_tenant_share=0.762,
        eed_public_obligation=true, public_tenant_weight=0.0,
        traj_mode="relative_to_2020", traj_reductions=(0.16, 0.20, 0.40, 0.59),
        env_rate_path=(0.027, 0.032, 0.036, 0.039),
        hvac_rate_const=0.04,
        joint_rate_path=(0.043, 0.048, 0.052, 0.055),
        descr="PL standard: census stock (absolute national), Invert WPB cut at census weights, rule_PL, EED on, w=0, ban off, relative EPBD trajectory, KPRB capacity")
    SCENARIO_DEFS["pl_standard"] = base
    SCENARIO_DEFS["pl_kprb"]     = merge(base, (stock_file="archetypes_pl_kprb.csv",
        descr=base.descr * " | SENSITIVITY: final demand rescaled to KPRB type averages (SFH 177.4 / MFH 162.0 final)"))
    SCENARIO_DEFS["pl_pubpoor"]  = merge(base, (public_rich_tenant_share=0.0,
        descr=base.descr * " | SENSITIVITY: all public tenants low-income"))
    SCENARIO_DEFS["pl_hvac6"]    = merge(base, (hvac_rate_const=0.06,
        joint_rate_path=(0.051, 0.056, 0.060, 0.063),
        descr=base.descr * " | SENSITIVITY: heating-system limit 6%/yr (joint cap adjusted env+0.4×hvac)"))
    # Equity-floor sweep (2026-10-27 order; the 30% floor BINDS in the PL
    # standard run — these quantify its price)
    SCENARIO_DEFS["pl_eqoff"] = merge(base, (equity_spending_floor=false,
        descr=base.descr * " | SENSITIVITY: equity spending floor OFF"))
    SCENARIO_DEFS["pl_eq20"]  = merge(base, (equity_floor_value=0.20,
        descr=base.descr * " | SENSITIVITY: equity spending floor 20%"))
    SCENARIO_DEFS["pl_eq40"]  = merge(base, (equity_floor_value=0.40,
        descr=base.descr * " | SENSITIVITY: equity spending floor 40%"))
    # σ = 0 feasibility diagnostics (2026-10-27 order; EVALUATION-ONLY
    # configs, never searched): behavioural sensitivities of natural
    # adoption — household discounting and the carbon-price path
    SCENARIO_DEFS["pl_diag_r08"] = merge(base, (discount_rate_override=0.08,
        descr=base.descr * " | DIAGNOSTIC: discount rate 8% (σ=0 evaluation only)"))
    SCENARIO_DEFS["pl_diag_r12"] = merge(base, (discount_rate_override=0.12,
        descr=base.descr * " | DIAGNOSTIC: discount rate 12% (σ=0 evaluation only)"))
    SCENARIO_DEFS["pl_diag_co2half"] = merge(base, (co2_scale=0.5,
        descr=base.descr * " | DIAGNOSTIC: carbon price x0.5 (σ=0 evaluation only)"))
    SCENARIO_DEFS["pl_diag_r08co2half"] = merge(base, (discount_rate_override=0.08, co2_scale=0.5,
        descr=base.descr * " | DIAGNOSTIC: discount 8% + carbon price x0.5 (σ=0 evaluation only)"))
    # --- pl_r8 family (2026-10-27 order): household discount rates separate
    #     from the state's 3% — owners and PRIVATE landlords 8% (calibrated,
    #     see data/PROVENANCE_polish_stock.md), PUBLIC landlord 3%. ---
    base8 = merge(base, (household_discount_rates=(owner_poor=0.08, owner_rich=0.08,
                                                   landlord_public=0.03, landlord_private=0.08),
        subsidy_horizon_end=2050,
        descr=base.descr * " | household discount 8% (owners + private landlords; public landlord 3%, state 3%) | subsidy horizon 2050 (spending 2020-2050; default since 2026-10-27 step-0 order)"))
    SCENARIO_DEFS["pl_r8"]       = base8
    SCENARIO_DEFS["pl_r8_eqoff"] = merge(base8, (equity_spending_floor=false,
        descr=base8.descr * " | equity floor OFF"))
    SCENARIO_DEFS["pl_r8_eq20"]  = merge(base8, (equity_floor_value=0.20,
        descr=base8.descr * " | equity floor 20%"))
    SCENARIO_DEFS["pl_r8_eq40"]  = merge(base8, (equity_floor_value=0.40,
        descr=base8.descr * " | equity floor 40%"))
    SCENARIO_DEFS["pl_r8_all12"] = merge(base8, (household_discount_rates=(owner_poor=0.12,
        owner_rich=0.12, landlord_public=0.03, landlord_private=0.12),
        descr=base8.descr * " | SENSITIVITY: all households (owners + private landlords) 12%"))
    SCENARIO_DEFS["pl_r8_split"] = merge(base8, (household_discount_rates=(owner_poor=0.12,
        owner_rich=0.08, landlord_public=0.03, landlord_private=0.08),
        descr=base8.descr * " | SENSITIVITY: low-income 12% / high-income 8%"))
    # --- Sourced carrier prices (phase 1, 2026-10-27 order; values/sources
    #     in data/PROVENANCE_polish_stock.md; EUR/kWh FINAL, real 2024,
    #     incl. taxes, excl. ETS2, constant in real terms): ---
    CARRIER_PRICES_2024 = (elec=0.2634,  # Eurostat nrg_pc_204 PL band DC, 2025 avg (user correction 2026-10-27: 2024 was freeze-capped)
                           gas=0.0707,   # Eurostat nrg_pc_202 PL band D2, 2023 avg (PL confidential 2024+; frozen level)
                           coal=0.0594,  # GUS M.P. 2025 poz. 52: 1703.46 PLN/t ÷ 24 MJ/kg ÷ 4.30
                           wood=0.0523,  # 450 PLN/m³ ÷ 2000 kWh/m³ ÷ 4.30 — FLAGGED, no GUS series
                           oil=0.1065,   # ~4.55 PLN/l ÷ 9.94 kWh/l ÷ 4.30 — FLAGGED, market level, 1% weight
                           dh=0.1151)    # URE 2024: 105.74 + 31.76 PLN/GJ ÷ 277.78 ÷ 4.30
    # Seasonal generation efficiencies η_H,g (PROPOSED from the Polish
    # energy-certificate methodology tables, FLAGGED; PROVENANCE):
    CARRIER_ETAS = (coal=0.70, wood=0.65, gas=0.87, oil=0.85, dh=0.95)
    # --- 2026-10-29 Polish investment costs, EUR per dwelling (PLN ÷ 4.30,
    # house convention). Envelope: Czyste Powietrze cost annex od
    # 20.07.2026, 100%-tier eligible unit costs (roof/attic 220, walls
    # 275, windows 1,320, doors 2,750 zł/m²; envelope total ≤ 83,000 zł —
    # not binding) applied to a documented typical geometry (SFH 108.6 m²
    # two-storey, MFH 53.2 m² per-dwelling share of a 12-dwelling
    # 4-storey block). Heat pump: market level 2026, SFH 37,500 PLN
    # (range 30,000–45,000); MFH scaled by floor area (PROPOSED,
    # FLAGGED). DH connection and PV keep the legacy values by order.
    # Derivation + sources: data/PROVENANCE_polish_stock.md "Investment
    # costs". NOT used by any scenario of record yet (phase 2 awaits the
    # user's OK):
    # Envelope entries × 1.08 (8% VAT on residential renovation; 2026-10-29
    # review change (1) — annex amounts are net). The HP market price is
    # already gross and stays.
    MEASURE_COSTS_PL2026 = Dict(
        ("SFH","envelope_light")    => 3663.0,   # 66.3 m² roof × 220 zł, × 1.08
        ("SFH","envelope_medium")   => 9918.0,   # 143.6 m² walls × 275 zł, × 1.08
        ("SFH","envelope_deep")     => 19463.0,  # walls+roof+windows+doors 77,490 zł net, × 1.08
        ("SFH","hvac_fossil_to_hp") => 8721.0,   # 37,500 PLN market incl. installation (gross)
        ("MFH","envelope_light")    => 735.0,    # 13.3 m² top-ceiling share × 220 zł, × 1.08
        ("MFH","envelope_medium")   => 2670.0,   # 38.7 m² wall share × 275 zł, × 1.08
        ("MFH","envelope_deep")     => 5725.0,   # 22,795 zł net per-dwelling share, × 1.08
        ("MFH","hvac_fossil_to_hp") => 4272.0)   # 18,370 PLN = 37,500 × 53.2/108.6, FLAGGED
    # Component-consistent envelope saving factors (2026-10-29 review
    # change (2)): share of the per-dwelling heat balance (transmission
    # walls+roof+windows+doors+floor + ventilation n=0.5/h) removed by
    # renovating exactly the costed components to WT 2021 U_max.
    # U before: NAPE/TABULA PL catalogue, 1967–1985 sheets (SFH.03 /
    # MFH.03 — the last pre-1983-norm cohort, the WPB frame); legacy
    # values were 0.25/0.45/0.70 for all btypes:
    MEASURE_REDUCTIONS_PL2026 = Dict(
        ("SFH","envelope_light")  => 0.134,  # roof 1.1→0.15 only
        ("SFH","envelope_medium") => 0.367,  # walls 1.4→0.20 only
        ("SFH","envelope_deep")   => 0.576,  # all four components
        ("MFH","envelope_light")  => 0.054,  # top ceiling 0.6→0.15 share
        ("MFH","envelope_medium") => 0.333,  # walls 1.16→0.20 share
        ("MFH","envelope_deep")   => 0.490)  # all four component shares
    # Sensitivity variants (2026-10-29 pl10 batch order):
    # heat-pump market range 30,000 / 45,000 PLN (MFH scaled by area)
    MEASURE_COSTS_PL2026_HP_LO = merge(MEASURE_COSTS_PL2026,
        Dict(("SFH","hvac_fossil_to_hp") => 6977.0,
             ("MFH","hvac_fossil_to_hp") => 3418.0))
    MEASURE_COSTS_PL2026_HP_HI = merge(MEASURE_COSTS_PL2026,
        Dict(("SFH","hvac_fossil_to_hp") => 10465.0,
             ("MFH","hvac_fossil_to_hp") => 5127.0))
    # savings from the 1946–1966 typology sheets (SFH.02 / MFH.02;
    # PROVENANCE "Review changes", period sensitivity)
    MEASURE_REDUCTIONS_PL2026_4666 = Dict(
        ("SFH","envelope_light")  => 0.093,
        ("SFH","envelope_medium") => 0.468,
        ("SFH","envelope_deep")   => 0.629,
        ("MFH","envelope_light")  => 0.082,
        ("MFH","envelope_medium") => 0.304,
        ("MFH","envelope_deep")   => 0.480)
    base9 = merge(base8, (carrier_prices=CARRIER_PRICES_2024,
        carrier_etas=CARRIER_ETAS,
        stock_file="archetypes_pl_mix.csv",
        descr=base8.descr * " | sourced carrier prices (elec 2025 avg) + fossil mixes + seasonal efficiencies (phase 1 corrected)"))
    SCENARIO_DEFS["pl9"] = base9

    # ================= FULL RUN on the new standard (2026-10-27 order;
    # pre-registered in the CHANGELOG). All derive from base9 (pl_r8 incl.
    # subsidy horizon 2050). =================
    # SQ1: affordability — cost-neutral + income-share sweep
    SCENARIO_DEFS["pl8_afford"] = merge(base9, (affordability_mode="cost_neutral",
        descr=base9.descr * " | SQ1: cost-neutral affordability (zero-subsidy reference)"))
    for s in (0.10, 0.12, 0.13, 0.14, 0.15, 0.20)
        SCENARIO_DEFS["pl8_s" * lpad(string(Int(round(100s))), 2, '0')] = merge(base9,
            (affordability_mode="income_share", affordability_income_share=s,
             affordability_periods="final",
             descr=base9.descr * " | SQ1: income-share limit s=$s (end state)"))
    end
    for s in (0.25, 0.30, 0.40)   # 2026-10-27 ruling (1): find the new edge
        SCENARIO_DEFS["pl8_s" * lpad(string(Int(round(100s))), 2, '0')] = merge(base9,
            (affordability_mode="income_share", affordability_income_share=s,
             affordability_periods="final",
             descr=base9.descr * " | SQ1 extension: income-share limit s=$s (end state)"))
    end
    SCENARIO_DEFS["pl8_s10_caprelax"] = merge(SCENARIO_DEFS["pl8_s10"], (reno_scale=100.0,
        descr=SCENARIO_DEFS["pl8_s10"].descr * " | DIAGNOSTIC: renovation limits relaxed (reno_scale=100)"))
    # SQ2: rent rules (no landlord subsidy), gross, w, EED off, private share
    SCENARIO_DEFS["pl8_rule_none"] = merge(base9, (landlord_subsidy_cap=0.0,
        pass_through_rate_by_landlord=(public=0.02, private=0.00),
        descr=base9.descr * " | SQ2: no private pass-through, no landlord subsidy"))
    SCENARIO_DEFS["pl8_rule_pl"] = merge(base9, (landlord_subsidy_cap=0.0,
        descr=base9.descr * " | SQ2: Polish rule, no landlord subsidy"))
    SCENARIO_DEFS["pl8_rule_cap3"] = merge(base9, (landlord_subsidy_cap=0.0,
        rent_increase_cap_per_m2=3.0,
        descr=base9.descr * " | SQ2: Polish rate + 3 EUR/m2/yr cap, no landlord subsidy"))
    SCENARIO_DEFS["pl8_rule_perm"] = merge(base9, (landlord_subsidy_cap=0.0,
        pass_through_years="permanent",
        descr=base9.descr * " | SQ2: Polish rate, permanent levy, no landlord subsidy"))
    SCENARIO_DEFS["pl8_rule_pl_gross"] = merge(base9, (passthrough_base_net_of_grants=false,
        descr=base9.descr * " | SQ2: Polish rule, grants NOT deducted (landlord subsidy allowed)"))
    SCENARIO_DEFS["pl8_w05"] = merge(base9, (public_tenant_weight=0.5,
        descr=base9.descr * " | SQ2: public landlord tenant weight w=0.5"))
    SCENARIO_DEFS["pl8_w10"] = merge(base9, (public_tenant_weight=1.0,
        descr=base9.descr * " | SQ2: public landlord tenant weight w=1.0"))
    SCENARIO_DEFS["pl8_noeed"] = merge(base9, (eed_public_obligation=false,
        descr=base9.descr * " | SQ2: EED obligation OFF"))
    SCENARIO_DEFS["pl8_priv16"] = merge(base9,
        (tenure_share_by_archetype=(rented_public=0.134, rented_private=0.16),
        descr=base9.descr * " | SQ2: private rental share 16%"))
    # Regulation + sensitivities
    SCENARIO_DEFS["pl8_ban2040"] = merge(base9, (fossil_boiler_ban=true,
        descr=base9.descr * " | fossil-boiler ban from 2040"))
    SCENARIO_DEFS["pl8_r12"] = merge(base9, (household_discount_rates=(owner_poor=0.12,
        owner_rich=0.12, landlord_public=0.03, landlord_private=0.12),
        descr=base9.descr * " | SENS: all households 12%"))
    SCENARIO_DEFS["pl8_split"] = merge(base9, (household_discount_rates=(owner_poor=0.12,
        owner_rich=0.08, landlord_public=0.03, landlord_private=0.08),
        descr=base9.descr * " | SENS: low-income 12% / high-income 8%"))
    SCENARIO_DEFS["pl8_kprb"] = merge(base9, (stock_file="archetypes_pl_kprb_mix.csv",
        traj_values_override=(222.12, 211.55, 158.66, 108.42),
        descr=base9.descr * " | SENS: KPRB heat demand, ABSOLUTE standard targets (phase-2 ruling a)"))
    SCENARIO_DEFS["pl8_hvac6"] = merge(base9, (hvac_rate_const=0.06,
        joint_rate_path=(0.051, 0.056, 0.060, 0.063),
        descr=base9.descr * " | SENS: heating limit 6%/yr"))
    SCENARIO_DEFS["pl8_co2half"] = merge(base9, (co2_scale=0.5,
        descr=base9.descr * " | SENS: carbon price x0.5"))
    SCENARIO_DEFS["pl8_peffrozen"] = merge(base9, (pef_frozen=true,
        descr=base9.descr * " | SENS: primary energy factors frozen at 2023"))
    SCENARIO_DEFS["pl8_pubpoor"] = merge(base9, (public_rich_tenant_share=0.0,
        descr=base9.descr * " | SENS: all public tenants low-income"))
    SCENARIO_DEFS["pl9_elec_p20"] = merge(base9,
        (carrier_prices=merge(CARRIER_PRICES_2024, (elec=round(0.2634*1.2, digits=4),)),
         descr=base9.descr * " | SENS: electricity price +20%"))
    SCENARIO_DEFS["pl9_elec_m20"] = merge(base9,
        (carrier_prices=merge(CARRIER_PRICES_2024, (elec=round(0.2634*0.8, digits=4),)),
         descr=base9.descr * " | SENS: electricity price -20%"))

    # ================= pl10 = pl9 + Polish investment costs (annex od
    # 2026-07-20, VAT gross) + component-consistent savings (2026-10-29
    # order, cost branch approved). FULL RERUN batch pre-registered in
    # the CHANGELOG before any run. "Demand adjusted for user behaviour"
    # = pl10_inclusive (Invert inclusive service factor, dist_curve.xlsx
    # XOL Status quo 2020 at census weights; user-delivered values
    # verified against the curve — PROVENANCE). =================
    base10 = merge(base9, (measure_costs=MEASURE_COSTS_PL2026,
        measure_reductions=MEASURE_REDUCTIONS_PL2026,
        descr=base9.descr * " | Polish investment costs (VAT gross) + component savings (pl10)"))
    SCENARIO_DEFS["pl10"] = base10
    # SQ1: affordability — cost-neutral + income-share sweep incl. extension
    SCENARIO_DEFS["pl10_afford"] = merge(base10, (affordability_mode="cost_neutral",
        descr=base10.descr * " | SQ1: cost-neutral affordability (zero-subsidy reference)"))
    for s in (0.10, 0.12, 0.13, 0.14, 0.15, 0.20, 0.25, 0.30, 0.40)
        SCENARIO_DEFS["pl10_s" * lpad(string(Int(round(100s))), 2, '0')] = merge(base10,
            (affordability_mode="income_share", affordability_income_share=s,
             affordability_periods="final",
             descr=base10.descr * " | SQ1: income-share limit s=$s (end state)"))
    end
    # SQ2: rent rules (no landlord subsidy), gross, w, EED off, private share, public tenants
    SCENARIO_DEFS["pl10_rule_none"] = merge(base10, (landlord_subsidy_cap=0.0,
        pass_through_rate_by_landlord=(public=0.02, private=0.00),
        descr=base10.descr * " | SQ2: no private pass-through, no landlord subsidy"))
    SCENARIO_DEFS["pl10_rule_pl"] = merge(base10, (landlord_subsidy_cap=0.0,
        descr=base10.descr * " | SQ2: Polish rule, no landlord subsidy"))
    SCENARIO_DEFS["pl10_rule_cap3"] = merge(base10, (landlord_subsidy_cap=0.0,
        rent_increase_cap_per_m2=3.0,
        descr=base10.descr * " | SQ2: Polish rate + 3 EUR/m2/yr cap, no landlord subsidy"))
    SCENARIO_DEFS["pl10_rule_perm"] = merge(base10, (landlord_subsidy_cap=0.0,
        pass_through_years="permanent",
        descr=base10.descr * " | SQ2: Polish rate, permanent levy, no landlord subsidy"))
    SCENARIO_DEFS["pl10_rule_pl_gross"] = merge(base10, (passthrough_base_net_of_grants=false,
        descr=base10.descr * " | SQ2: Polish rule, grants NOT deducted (landlord subsidy allowed)"))
    SCENARIO_DEFS["pl10_w05"] = merge(base10, (public_tenant_weight=0.5,
        descr=base10.descr * " | SQ2: public landlord tenant weight w=0.5"))
    SCENARIO_DEFS["pl10_w10"] = merge(base10, (public_tenant_weight=1.0,
        descr=base10.descr * " | SQ2: public landlord tenant weight w=1.0"))
    SCENARIO_DEFS["pl10_noeed"] = merge(base10, (eed_public_obligation=false,
        descr=base10.descr * " | SQ2: EED obligation OFF (public landlord own spending reported)"))
    SCENARIO_DEFS["pl10_priv16"] = merge(base10,
        (tenure_share_by_archetype=(rented_public=0.134, rented_private=0.16),
        descr=base10.descr * " | SQ2: private rental share 16%"))
    SCENARIO_DEFS["pl10_pubpoor"] = merge(base10, (public_rich_tenant_share=0.0,
        descr=base10.descr * " | SQ2: all public tenants low-income"))
    # Regulation + sensitivities
    SCENARIO_DEFS["pl10_ban2040"] = merge(base10, (fossil_boiler_ban=true,
        descr=base10.descr * " | fossil-boiler ban from 2040"))
    SCENARIO_DEFS["pl10_r12"] = merge(base10, (household_discount_rates=(owner_poor=0.12,
        owner_rich=0.12, landlord_public=0.03, landlord_private=0.12),
        descr=base10.descr * " | SENS: all households 12%"))
    SCENARIO_DEFS["pl10_split"] = merge(base10, (household_discount_rates=(owner_poor=0.12,
        owner_rich=0.08, landlord_public=0.03, landlord_private=0.08),
        descr=base10.descr * " | SENS: low-income 12% / high-income 8%"))
    SCENARIO_DEFS["pl10_kprb"] = merge(base10, (stock_file="archetypes_pl_kprb_mix.csv",
        traj_values_override=(222.12, 211.55, 158.66, 108.42),
        descr=base10.descr * " | SENS: KPRB heat demand, ABSOLUTE standard targets"))
    SCENARIO_DEFS["pl10_hvac6"] = merge(base10, (hvac_rate_const=0.06,
        joint_rate_path=(0.051, 0.056, 0.060, 0.063),
        descr=base10.descr * " | SENS: heating limit 6%/yr"))
    SCENARIO_DEFS["pl10_co2half"] = merge(base10, (co2_scale=0.5,
        descr=base10.descr * " | SENS: carbon price x0.5"))
    SCENARIO_DEFS["pl10_peffrozen"] = merge(base10, (pef_frozen=true,
        descr=base10.descr * " | SENS: primary energy factors frozen at 2023"))
    SCENARIO_DEFS["pl10_elec_p20"] = merge(base10,
        (carrier_prices=merge(CARRIER_PRICES_2024, (elec=round(0.2634*1.2, digits=4),)),
         descr=base10.descr * " | SENS: electricity price +20%"))
    SCENARIO_DEFS["pl10_elec_m20"] = merge(base10,
        (carrier_prices=merge(CARRIER_PRICES_2024, (elec=round(0.2634*0.8, digits=4),)),
         descr=base10.descr * " | SENS: electricity price -20%"))
    SCENARIO_DEFS["pl10_woodpef"] = merge(base10, (wood_pef=0.2,
        descr=base10.descr * " | SENS: wood primary factor 0.2 (mix-weighted fossil PEF, baseline + trajectory)"))
    # 2026-11-04 paper-analysis wave (user order ~13:20): trajectory and
    # envelope-capacity sensitivities. traj_linear 2040 reduction: straight
    # line from (2035, -20%) to (2050, -59%) evaluated at 2040 =
    # 0.20 + (5/15)*(0.59-0.20) = 0.33 exactly. envcap: env_rate_path
    # x0.8 / x1.2, hvac unchanged 4%/yr, joint recomputed by the standing
    # rule joint = env + 0.4*hvac (interpretation recorded in CHANGELOG).
    SCENARIO_DEFS["pl10_traj_linear"] = merge(base10,
        (traj_reductions=(0.16, 0.20, 0.33, 0.59),
         descr=base10.descr * " | SENS: linear trajectory 2035->2050 (2040 at -33%)"))
    SCENARIO_DEFS["pl10_traj_soft"] = merge(base10,
        (traj_reductions=(0.16, 0.20, 0.35, 0.55),
         descr=base10.descr * " | SENS: soft trajectory (-35% 2040, -55% 2050)"))
    SCENARIO_DEFS["pl10_envcap_m20"] = merge(base10,
        (env_rate_path=(0.0216, 0.0256, 0.0288, 0.0312),
         joint_rate_path=(0.0376, 0.0416, 0.0448, 0.0472),
         descr=base10.descr * " | SENS: envelope capacity x0.8 (joint = env + 0.4*hvac)"))
    SCENARIO_DEFS["pl10_envcap_p20"] = merge(base10,
        (env_rate_path=(0.0324, 0.0384, 0.0432, 0.0468),
         joint_rate_path=(0.0484, 0.0544, 0.0592, 0.0628),
         descr=base10.descr * " | SENS: envelope capacity x1.2 (joint = env + 0.4*hvac)"))
    # 2026-11-04 user order (~15:00): Invert Poland "const" carrier prices
    # (named source 616_pol__const__energy_price.csv, NOT in repo — values
    # from the order verbatim; price year + VAT unknown, see PROVENANCE).
    # Mixes, etas, ETS2 price unchanged; gas HHV=GCV basis, no conversion.
    SCENARIO_DEFS["pl10_invertprices"] = merge(base10,
        (carrier_prices=(elec=0.16655, gas=0.04745, coal=0.03528,
                         wood=0.02907, oil=0.07524, dh=0.05687),
         descr=base10.descr * " | SENS: Invert const carrier prices (all six, constant over time)"))
    SCENARIO_DEFS["pl10_hpcost_lo"] = merge(base10, (measure_costs=MEASURE_COSTS_PL2026_HP_LO,
        descr=base10.descr * " | SENS: heat-pump cost LOW (30,000 PLN SFH, area-scaled MFH)"))
    SCENARIO_DEFS["pl10_hpcost_hi"] = merge(base10, (measure_costs=MEASURE_COSTS_PL2026_HP_HI,
        descr=base10.descr * " | SENS: heat-pump cost HIGH (45,000 PLN SFH, area-scaled MFH)"))
    SCENARIO_DEFS["pl10_sav4666"] = merge(base10, (measure_reductions=MEASURE_REDUCTIONS_PL2026_4666,
        descr=base10.descr * " | SENS: savings from the 1946-1966 typology sheets"))
    SCENARIO_DEFS["pl10_inclusive"] = merge(base10, (stock_file="archetypes_pl_inclusive_mix.csv",
        descr=base10.descr * " | SENS: demand adjusted for user behaviour (Invert inclusive service factor; WPB 50.5/17.2, primary 377/175, 288/165)"))

    # ================= pl11 = pl10 + the 2026-11-06 review-wave brief =========
    # (1) no PV option at all (pv_enabled=false);
    # (2) learning rates: heat pump 2.5%/yr kept (IEA Future of Heat Pumps
    #     2022, MODEL_V2_ASSUMPTIONS.md), envelope and district heat 0;
    #     'no cost decline at all' is the sensitivity pl11_learn0;
    # (3) heating <= envelope + 0.3 rule kept (documented in the follower);
    # (4) rent-rule scenarios keep the standard landlord cap (0-100%).
    # Every pl10_* scenario is mirrored as pl11_*; pl11_rule_pl is then
    # identical to pl11 (kept for the ledger, not run separately).
    PL11_LEARNING = Dict("envelope_light" => 0.0, "envelope_medium" => 0.0,
                         "envelope_deep" => 0.0, "hvac_fossil_to_district" => 0.0)
    PL11_TAG = "(pl11: no PV option; cost decline heat pump 2.5%/yr only)"
    for k in sort(collect(keys(SCENARIO_DEFS)))
        startswith(k, "pl10") || continue
        v = SCENARIO_DEFS[k]
        v11 = merge(v, (pv_enabled=false, learning_rates=PL11_LEARNING,
                        descr=replace(v.descr, "(pl10)" => PL11_TAG)))
        if k in ("pl10_rule_none", "pl10_rule_pl", "pl10_rule_cap3", "pl10_rule_perm")
            v11 = merge(v11, (landlord_subsidy_cap=base10.landlord_subsidy_cap,
                              descr=replace(v11.descr, ", no landlord subsidy" => ", landlord subsidy allowed (pl11 decision 4)")))
        end
        SCENARIO_DEFS[replace(k, "pl10" => "pl11", count=1)] = v11
    end
    base11 = SCENARIO_DEFS["pl11"]
    SCENARIO_DEFS["pl11_learn0"] = merge(base11,
        (learning_rates=merge(PL11_LEARNING, Dict("hvac_fossil_to_hp" => 0.0)),
         descr=base11.descr * " | SENS: no cost decline at all (heat pump learning 0)"))

    # ================= pl12 = pl11 + decision record 2026-11-06 (D1-D7) =======
    # D1 periods 2020;2026;2030;2035;2040;2050 (last to 2060), 2020-2025 fixed
    # history, state designs from 2026; D2 SFH heating history (heat pumps and
    # district heat as fixed adoption, boilers as the 2025 fuel-mix update);
    # D3 envelope history from the history run at the Czyste Powietrze rates;
    # D6 carbon price 22.5 EUR/t in 2026-2030; D7 spending/equity/WPB from
    # 2026, discounted to 2026. Numbers: data/history_2020_2025_pl12.md.
    FUEL_MIX_PL12 = (btype="SFH", hpdh_share=0.03123, boiler_share=0.06668,
        new_mix=(gas_cond=0.312, biomass=0.292, coal5=0.064, electric=0.012, oil=0.001),
        etas=(gas_cond=0.95, biomass=0.87, coal5=0.85, electric=1.0, oil=0.85))
    PL12_COMMON = (period_years=(2020, 2026, 2030, 2035, 2040, 2050),
        co2_price_path=(0.0, 22.5, 70.0, 120.0, 200.0, 350.0),
        subsidy_horizon_start=2026, discount_base_year=2026,
        history_subsidy=(sfh_poor=0.70, sfh_rich=0.40), fuel_mix_update=FUEL_MIX_PL12)
    PL12_TAG = "(pl12: history 2020-2025 fixed, design from 2026, CO2 22.5 EUR/t 2026-30; no PV)"
    # history run (D3): only the heating history is fixed, envelope free at the history rates
    SCENARIO_DEFS["pl12_history"] = merge(SCENARIO_DEFS["pl11"], PL12_COMMON,
        (history_adoption_file="data/history_heating_pl12.csv", history_fix_classes=("hvac",),
         descr=replace(SCENARIO_DEFS["pl11"].descr, "(pl11: no PV option; cost decline heat pump 2.5%/yr only)" => PL12_TAG) *
               " | HISTORY RUN (D3): heating history fixed, envelope free, evaluate at the Czyste Powietrze rates"))
    for k in sort(collect(keys(SCENARIO_DEFS)))
        startswith(k, "pl11") || continue
        v = SCENARIO_DEFS[k]
        SCENARIO_DEFS[replace(k, "pl11" => "pl12", count=1)] = merge(v, PL12_COMMON,
            (history_adoption_file="data/history_adoption_pl12.csv", history_fix_classes=("envelope", "hvac"),
             descr=replace(v.descr, "(pl11: no PV option; cost decline heat pump 2.5%/yr only)" => PL12_TAG)))
    end
    # D4 capacity sensitivity: uniform increase of the envelope limits in 5 % steps
    # (KPRB path 2.7/3.2/3.6/3.9 %/yr), joint workforce cap = env + 0.4 x 4 %/yr hvac
    for mult in (1.05, 1.10, 1.15, 1.20, 1.25, 1.30, 1.35, 1.40, 1.45, 1.50)
        env = (0.027, 0.032, 0.036, 0.039) .* mult
        SCENARIO_DEFS["pl12_envcap_p" * lpad(string(round(Int, 100 * (mult - 1))), 2, '0')] = merge(SCENARIO_DEFS["pl12"],
            (env_rate_path=env, joint_rate_path=env .+ 0.016,
             descr=SCENARIO_DEFS["pl12"].descr * " | D4 capacity sensitivity: envelope limits x$(mult)"))
    end
    # Sensitivity (user request 2026-11-07): the 2020-2025 envelope history is modelled, not
    # observed; scale it to 75 % and 50 % (heating history unchanged, same rates/caps otherwise)
    for (sfx, mult) in (("env075", 0.75), ("env050", 0.50))
        SCENARIO_DEFS["pl12_hist_" * sfx] = merge(SCENARIO_DEFS["pl12"],
            (history_adoption_file="data/history_adoption_pl12_" * sfx * ".csv",
             descr=SCENARIO_DEFS["pl12"].descr * " | SENS: 2020-2025 envelope history x$(mult) (heating history unchanged)"))
    end
    # Phase 2 diagnostics: decomposition of the 2020->2026 drop (evaluated at σ=0)
    SCENARIO_DEFS["pl12_diag_envonly"] = merge(SCENARIO_DEFS["pl12"], (history_fix_classes=("envelope",), fuel_mix_update=nothing,
        descr=SCENARIO_DEFS["pl12"].descr * " | DIAG: envelope history only (heating free, no boiler update)"))
    SCENARIO_DEFS["pl12_diag_noboiler"] = merge(SCENARIO_DEFS["pl12"], (fuel_mix_update=nothing,
        descr=SCENARIO_DEFS["pl12"].descr * " | DIAG: envelope + heating history, no boiler update"))

    # ================= rev12 = review follow-ups of 2026-11-08 (R1, R4, R6) ====
    # Prefix rev12 keeps these OUT of the pl12 summary tables (make_pl11_summary.py
    # globs out/scenarios/pl12*); they are reported in results/review_2026-11-08/.
    # R1: price of the intermediate milestones. A negative "reduction" makes a
    #     milestone value far above any path (never binding); the other
    #     milestones keep the standard's exact relative values.
    # R4: cost of the spending-based equity floor: floor off, 20 %, 40 %.
    # R6: pl12_pubpoor could not run (history file carries the rich public-tenant
    #     twin that this scenario does not create); same history without those rows.
    SCENARIO_DEFS["rev12_no2030"] = merge(SCENARIO_DEFS["pl12"],
        (traj_reductions=(-3.0, 0.20, 0.40, 0.59),
         descr=SCENARIO_DEFS["pl12"].descr * " | REV R1: 2030 milestone dropped (2035/2040/2050 kept)"))
    SCENARIO_DEFS["rev12_2050only"] = merge(SCENARIO_DEFS["pl12"],
        (traj_reductions=(-3.0, -3.0, -3.0, 0.59),
         descr=SCENARIO_DEFS["pl12"].descr * " | REV R1: only the 2050 target kept"))
    SCENARIO_DEFS["rev12_eq00"] = merge(SCENARIO_DEFS["pl12"], (equity_spending_floor=false,
        descr=SCENARIO_DEFS["pl12"].descr * " | REV R4: no equity floor"))
    SCENARIO_DEFS["rev12_eq20"] = merge(SCENARIO_DEFS["pl12"], (equity_floor_value=0.20,
        descr=SCENARIO_DEFS["pl12"].descr * " | REV R4: equity floor 20 %"))
    SCENARIO_DEFS["rev12_eq40"] = merge(SCENARIO_DEFS["pl12"], (equity_floor_value=0.40,
        descr=SCENARIO_DEFS["pl12"].descr * " | REV R4: equity floor 40 %"))
    SCENARIO_DEFS["pl12_pubpoor"] = merge(SCENARIO_DEFS["pl12_pubpoor"],
        (history_adoption_file="data/history_adoption_pl12_pubpoor.csv",))
end

SCENARIO = length(ARGS) >= 1 ? ARGS[1] : "baseline"
haskey(SCENARIO_DEFS, SCENARIO) ||
    error("Unknown scenario '$SCENARIO'. Available: $(join(sort(collect(keys(SCENARIO_DEFS))), ", "))")
SC = SCENARIO_DEFS[SCENARIO]
# Explicit override hook (2026-10-27, user order): evaluations and the
# regression gates may force the fossil-boiler ban ON regardless of the
# scenario's own setting (committed pins were produced WITH the ban).
# Loud, opt-in via ENV — never silent.
if haskey(ENV, "P4_FORCE_BOILER_BAN")
    SC = merge(SC, (fossil_boiler_ban=true,))
    println(">>> P4_FORCE_BOILER_BAN set: fossil_boiler_ban forced TRUE for this load <<<")
end
OUTDIR = "out/scenarios/$SCENARIO"
# P4_OUT_TAG (2026-11-02 multistart order): restart runs write to
# out/scenarios/<scenario>__<tag>/ so they never overwrite the scenario of
# record. Loud, opt-in via ENV — never silent.
if haskey(ENV, "P4_OUT_TAG")
    OUTDIR = "out/scenarios/$(SCENARIO)__$(ENV["P4_OUT_TAG"])"
    println(">>> P4_OUT_TAG=$(ENV["P4_OUT_TAG"]) — outputs redirected to $OUTDIR <<<")
end
# P4_SIGMA_START (2026-11-02 multistart order): path to a file with one σ
# value per line (comments with # allowed), canonical σ_keys order, length
# n_σ. When set, the Phase-2 candidate list is REPLACED by this single
# start (clamped to caps + depth-ordered by enforce_ordering!); an
# infeasible start falls through to the existing upward-adjustment
# fallback; Phases 3–5 run unchanged. Parsed here (length checked after
# n_σ is known) so P4_SKIP_SEARCH smoke loads exercise the parsing.
SIGMA_START_RAW = if haskey(ENV, "P4_SIGMA_START")
    let f = ENV["P4_SIGMA_START"]
        isfile(f) || error("P4_SIGMA_START file not found: $f")
        v = [parse(Float64, strip(l)) for l in eachline(f)
             if !isempty(strip(l)) && !startswith(strip(l), "#")]
        println(">>> P4_SIGMA_START=$f read: $v <<<")
        v
    end
else
    nothing
end
# Reproducibility: every run stores its full configuration next to its outputs
mkpath(OUTDIR)
# Test/export loads (P4_SKIP_SEARCH=1) must not re-stamp a run's config:
# stamps only change when a run does (user order 2026-10-09).
haskey(ENV, "P4_SKIP_SEARCH") || open("$OUTDIR/config_used.txt", "w") do io
    println(io, "scenario: $SCENARIO")
    haskey(ENV, "P4_OUT_TAG") && println(io, "out_tag: $(ENV["P4_OUT_TAG"])")
    haskey(ENV, "P4_SIGMA_START") && println(io, "sigma_start_file: $(ENV["P4_SIGMA_START"])")
    println(io, "model_file: bilevel_model_affordable_housing.jl")
    println(io, "timestamp: $(Dates.now())")
    for (k, v) in pairs(SC)
        println(io, "$k: $v")
    end
    println(io, "julia_version: $(VERSION)")
    githash = try strip(read(`git rev-parse HEAD`, String)) catch; "unavailable" end
    println(io, "git_commit: $githash")
    # A commit hash alone does not pin uncommitted code — record tree state
    ndirty = try
        st = strip(read(`git status --porcelain`, String))
        st == "" ? 0 : count(==('\n'), st) + 1
    catch; -1 end
    println(io, "git_tree: ", ndirty == 0 ? "clean" :
        ndirty == -1 ? "unavailable" :
        "DIRTY ($ndirty changed/untracked paths — hash does not pin this code)")
end

println("\nSCENARIO: $SCENARIO — $(SC.descr)")
println("  fossil_boiler_ban=$(SC.fossil_boiler_ban ? "ON (ban_year=$(SC.ban_year))" : "OFF (ban_year inert)")" *
        "  co2_scale=$(SC.co2_scale)  dh_caps=$(SC.dh_cap_sfh)/$(SC.dh_cap_mfh)" *
        "  reno_scale=$(SC.reno_scale)  subsidy_boost=$(SC.subsidy_boost)" *
        "  residual_value=$(SC.residual_value)  pef_frozen=$(SC.pef_frozen)")

# =============================================================================
# 0) LOAD DATA (identical to other model versions)
# =============================================================================
archetypes = CSV.read(SC.stock_file, DataFrame)
SC.stock_file != "archetypes_v2.csv" &&
    println(">>> STOCK FILE: $(SC.stock_file) (Polish-stock recalibration; committed default is archetypes_v2.csv) <<<")
measures   = CSV.read("measures_v2.csv", DataFrame)
ctx        = CSV.read("context.csv", DataFrame)

# =============================================================================
# Level 2: TENURE SPLIT (plan §4). Each MFH archetype row is split into an
# owner part (dwellings × (1 − rented shares), behaviour unchanged) and two
# rented variants with the SAME building physics: rented_public and
# rented_private. The tenant is always poor (user decision 2026-10-01), so
# income="poor" on rented rows — it drives the affordability check only;
# clawback and the equity floor treat rented rows separately (see below).
# Totals (dwellings, floor area, baseline energy) are unchanged by the split.
# With tenure_enabled=false (default) this block adds nothing — baseline.
# =============================================================================
archetypes[!, :tenure] = fill("owner", nrow(archetypes))
if SC.tenure_enabled
    sh_pub  = Float64(SC.tenure_share_by_archetype.rented_public)
    sh_priv = Float64(SC.tenure_share_by_archetype.rented_private)
    sh_rich = Float64(SC.private_rich_tenant_share)   # of the PRIVATE stock
    (sh_pub >= 0 && sh_priv >= 0 && sh_pub + sh_priv < 1.0) ||
        error("tenure_share_by_archetype shares must be ≥0 and sum to <1, got $(SC.tenure_share_by_archetype)")
    (0.0 <= sh_rich <= 1.0) ||
        error("private_rich_tenant_share must be in [0, 1], got $sh_rich")
    @warn "tenure split: rented_public=$(sh_pub) SOURCED (GUS 2024/Census 2021; TBS part approximate); " *
          "rented_private=$(sh_priv) DERIVED (Eurostat ilc_lvho02 x GUS households x Census 2021 MFH; " *
          "assumes market-rent tenants live in MFH); low-/high-income private-tenant split " *
          "$(1-sh_rich)/$(sh_rich) SOURCED (Eurostat EU-SILC, AROP-based, not quintile-based). " *
          "Wave-9 data of record (2026-10-11); public landlord pass-through 0.02 still open."
    liq_of_landlord = Dict("rented_public"  => Float64(SC.liquidity_cap_by_landlord.public),
                           "rented_private" => Float64(SC.liquidity_cap_by_landlord.private))
    # fractional dwelling splits and an Inf liquidity cap need Float columns;
    # suffixed arch_ids outgrow CSV.jl's inline string types, so widen to String
    archetypes[!, :dwellings] = Float64.(archetypes.dwellings)
    archetypes[!, :annual_liquidity_cap] = Float64.(archetypes.annual_liquidity_cap)
    archetypes[!, :income] = String.(archetypes.income)
    archetypes[!, :arch_id] = String.(archetypes.arch_id)
    mfh_parents = [NamedTuple(row) for row in eachrow(archetypes) if row.btype == "MFH"]
    for row in mfh_parents
        archetypes[findfirst(==(row.arch_id), archetypes.arch_id), :dwellings] =
            row.dwellings * (1 - sh_pub - sh_priv)
        # Private rental splits into a poor- and a rich-tenant twin
        # (decision change 2026-10-08): SAME building physics, SAME
        # landlord type and subsidy instrument — only the tenant's income
        # differs (it never enters the landlord's problem; tested).
        # A zero share adds no row, so sh_rich=0 reproduces the old
        # structure exactly.
        # 2026-10-27: the public-rental stock splits into a poor and a rich
        # tenant twin exactly like the private one (public_rich_tenant_share;
        # 0.0 default = the committed single-poor-public-tenant structure)
        sh_rich_pub = Float64(SC.public_rich_tenant_share)
        (0.0 <= sh_rich_pub <= 1.0) ||
            error("public_rich_tenant_share must be in [0, 1], got $sh_rich_pub")
        for (ten, suffix, share, tinc) in (
                ("rented_public",  "_rent_pub",       sh_pub * (1 - sh_rich_pub), "poor"),
                ("rented_public",  "_rent_pub_rich",  sh_pub * sh_rich_pub,       "rich"),
                ("rented_private", "_rent_priv",      sh_priv * (1 - sh_rich),    "poor"),
                ("rented_private", "_rent_priv_rich", sh_priv * sh_rich,          "rich"))
            share > 0.0 || continue
            push!(archetypes, merge(row, (arch_id = row.arch_id * suffix,
                income = tinc,                       # the TENANT's income class
                dwellings = row.dwellings * share,
                annual_liquidity_cap = liq_of_landlord[ten],
                tenure = ten)))
        end
    end
    println("  Level 2 tenure split: $(length(mfh_parents)) MFH archetypes split → " *
            "$(nrow(archetypes)) archetypes total (owner shares reduced accordingly; totals unchanged)")
end

years = parse.(Int, split(ctx.years[1], ";"))
if haskey(SC, :period_years) && SC.period_years !== nothing
    years = collect(Int, SC.period_years)   # pl12 D1
    println(">>> period_years override (pl12 D1): $(years), last period to $(years[end] + 10) <<<")
end
t0 = minimum(years)
n_years = length(years)

r             = ctx.discount_rate[1]
if SC.discount_rate_override !== nothing
    r = Float64(SC.discount_rate_override)
    println(">>> discount_rate_override: r = $r (context.csv value replaced for this load) <<<")
end
equity_min    = ctx.equity_min_share_low[1]
epbd_target   = ctx.epbd_target[1]

# Effective equity floor (Level 1a: the spending floor is switchable so the
# plan's four design cases can be compared; default reproduces baseline)
equity_min_eff = SC.equity_spending_floor ?
    (SC.equity_floor_value === nothing ? equity_min : Float64(SC.equity_floor_value)) : 0.0

# Validate affordability configuration up front — fail loudly, never silently
SC.affordability_mode in ("off", "cost_neutral", "income_share") ||
    error("affordability_mode must be off / cost_neutral / income_share, got '$(SC.affordability_mode)'")
SC.affordability_reference in ("frozen_stock", "zero_subsidy") ||
    error("affordability_reference must be frozen_stock / zero_subsidy, got '$(SC.affordability_reference)'")
SC.affordability_scope in ("all", "owners_and_public_tenants") ||
    error("affordability_scope must be all / owners_and_public_tenants, got '$(SC.affordability_scope)'")
SC.affordability_periods in ("all", "final") ||
    error("affordability_periods must be all / final, got '$(SC.affordability_periods)'")
(SC.pass_through_years in ("permanent", "recovery") ||
 (SC.pass_through_years isa Integer && SC.pass_through_years >= 1)) ||
    error("pass_through_years must be \"permanent\", \"recovery\" or an integer ≥ 1, got '$(SC.pass_through_years)'")
SC.passthrough_base_net_of_grants isa Bool ||
    error("passthrough_base_net_of_grants must be true/false, got '$(SC.passthrough_base_net_of_grants)'")
(0.0 <= SC.private_rich_tenant_share <= 1.0) ||
    error("private_rich_tenant_share must be in [0, 1], got $(SC.private_rich_tenant_share)")
(0.0 <= SC.clawback_rate_by_class.poor < 1.0 && 0.0 <= SC.clawback_rate_by_class.rich < 1.0) ||
    error("clawback rates must be in [0, 1), got $(SC.clawback_rate_by_class)")
if SC.affordability_mode == "income_share"
    isnan(SC.household_income_by_class.poor) &&
        error("affordability_mode=income_share needs household_income_by_class")
    @info "income_share mode: SOURCED incomes (GUS HBS 2024 tables, wave 9 loaded 2026-10-11) — " *
          "low-income €$(SC.household_income_by_class.poor) (Q1), high-income €$(SC.household_income_by_class.rich) " *
          "(Q2–Q5 mean, weighted by household count ∝ 1/size) per household per year."
end
if SC.affordability_mode != "off" || !SC.equity_spending_floor
    println("  Level 1a: affordability_mode=$(SC.affordability_mode)" *
            (SC.affordability_mode == "cost_neutral" ?
             " (tolerance=$(SC.affordability_tolerance), reference=$(SC.affordability_reference))" : "") *
            (SC.affordability_mode == "income_share" ?
             " (share=$(SC.affordability_income_share), income_poor=$(SC.household_income_by_class.poor))" : "") *
            "  equity_spending_floor=$(SC.equity_spending_floor)")
end

# Validate the 2026-10-27 public-landlord switches up front — fail loudly,
# never silently (same convention as the affordability validation above)
SC.eed_public_obligation isa Bool ||
    error("eed_public_obligation must be Bool, got $(SC.eed_public_obligation)")
(SC.public_tenant_weight isa Real && 0.0 <= Float64(SC.public_tenant_weight) <= 1.0) ||
    error("public_tenant_weight must be a number in [0, 1], got $(SC.public_tenant_weight)")
if (SC.eed_public_obligation || Float64(SC.public_tenant_weight) > 0.0) && !SC.tenure_enabled
    error("eed_public_obligation / public_tenant_weight require tenure_enabled=true " *
          "(no public landlord exists otherwise)")
end
if SC.eed_public_obligation || Float64(SC.public_tenant_weight) > 0.0
    println("  Level 2 switches: eed_public_obligation=$(SC.eed_public_obligation)" *
            "  public_tenant_weight=$(SC.public_tenant_weight)")
end

co2_price_per_ton = parse.(Float64, split(ctx.co2_price_eur_per_ton[1], ";")) .* SC.co2_scale
if haskey(SC, :co2_price_path) && SC.co2_price_path !== nothing
    co2_price_per_ton = collect(Float64, SC.co2_price_path) .* SC.co2_scale   # pl12 D6
    println(">>> co2_price_path override (pl12 D6): $(co2_price_per_ton) EUR/t per period <<<")
end
length(co2_price_per_ton) == length(years) ||
    error("carbon-price path has $(length(co2_price_per_ton)) entries for $(length(years)) periods")

BOILER_LIFE      = 25     # average fossil boiler lifetime (years)
# pl12 D7: the state's spending is discounted to discount_base_year (nothing = t0).
# Follower discounting (fdisc) keeps t0; the follower optimum is base-year invariant.
DISC_BASE = (haskey(SC, :discount_base_year) && SC.discount_base_year !== nothing) ? Int(SC.discount_base_year) : t0
disc(yr::Int) = (1 + r)^(-(yr - DISC_BASE))
# Landlord discount-rate sensitivity (2026-10-09 §3d): nothing → the global
# r, so disc_ll ≡ disc and every committed result is bit-identical; a number
# applies only to the LANDLORD terms of the follower objective (see there).
LL_R = SC.landlord_discount_rate === nothing ? r : Float64(SC.landlord_discount_rate)
disc_ll(yr::Int) = (1 + LL_R)^(-(yr - t0))

M = 1:size(measures, 1)
T = 1:length(years)
A = 1:size(archetypes, 1)

println("\nData loaded: $(length(A)) archetypes × $(length(M)) measures × $(length(T)) periods")

# =============================================================================
# 1) PARAMETERS (identical to other versions)
# =============================================================================
m_id      = String.(measures.m_id)
cls_m     = lowercase.(strip.(String.(measures.class)))
depth_m   = lowercase.(strip.(String.(measures.depth)))
cpm2_m    = Float64.(measures.capex_per_m2)
cfix_m    = Float64.(measures.fixed_capex)
redfac_m  = Float64.(measures.reduction_factor)
lifetime_m = Float64.(measures.lifetime)
learning_m = Float64.(measures.learning_rate_annual)
# pl11 (2026-11-06 brief, decision 2): per-measure learning-rate override.
if haskey(SC, :learning_rates) && SC.learning_rates !== nothing
    let mids = String.(measures.m_id)
        for (mid, lr) in SC.learning_rates
            k = findfirst(==(mid), mids)
            k === nothing && error("learning_rates: unknown measure id $mid")
            learning_m[k] = Float64(lr)
        end
        println("  Learning-rate override ACTIVE: ", join(["$(mids[k])=$(learning_m[k])" for k in eachindex(mids)], ", "))
    end
end
hvac_from = uppercase.(strip.(String.(measures.from_hvac)))
hvac_to   = uppercase.(strip.(String.(measures.to_hvac)))

inc_a        = lowercase.(strip.(String.(archetypes.income)))
fa_a         = Float64.(archetypes.floor_area_m2)
cap_a        = Float64.(archetypes.annual_liquidity_cap)
base_a       = Float64.(archetypes.baseline_kWh_m2)
dwell_a      = Float64.(archetypes.dwellings)
wpb_a        = Int.(archetypes.is_WPB) .== 1
arch_id      = String.(archetypes.arch_id)
btype_a      = String.(archetypes.btype)
hvac_current = lowercase.(strip.(String.(archetypes.current_hvac)))
co2_int_a    = Float64.(archetypes.co2_intensity_kg_per_kWh)
pef_a        = Float64.(archetypes.primary_energy_factor)
pv_kWp_a     = Float64.(archetypes.pv_capacity_kWp)
pv_cost_a    = Float64.(archetypes.pv_cost_eur)

# Level 2: tenure per archetype ("owner" everywhere unless tenure_enabled)
tenure_a = String.(archetypes.tenure)
is_rented(a::Int) = tenure_a[a] != "owner"
A_RENTED = [a for a in A if is_rented(a)]
pass_through_of(a::Int) = tenure_a[a] == "rented_public"  ? Float64(SC.pass_through_rate_by_landlord.public) :
                          tenure_a[a] == "rented_private" ? Float64(SC.pass_through_rate_by_landlord.private) : 0.0
# Public-landlord tenant-cost weight per archetype (2026-10-27): w on
# rented_public rows, 0 everywhere else (private landlords and owners)
pubw_a = [tenure_a[a] == "rented_public" ? Float64(SC.public_tenant_weight) : 0.0 for a in A]
# Tie-break (2026-10-27 decision 2): at w = 1 the rent increase leaves the
# landlord's objective (−rent + w·rent = 0); a SMALL penalty on rent_inc
# makes the optimizer choose rent_inc = 0 there, so "the landlord decides
# fully on the tenants' behalf" means NO rent increase is charged. Inactive
# for w < 1 (the net rent coefficient is then strictly negative anyway).
RENT_TIEBREAK_EPS = 1e-6

# Household/landlord discount rates per archetype (2026-10-27): the
# FOLLOWER objective discounts each archetype's cost stream at this rate;
# the leader's spending keeps the state rate r. `nothing` entries fall
# back to the committed behaviour (owners → r, landlords → LL_R).
let H = SC.household_discount_rates
    for v in values(H)
        v === nothing || (0.0 < Float64(v) < 1.0) ||
            error("household_discount_rates entries must be in (0,1) or nothing, got $v")
    end
    global fdisc_r_a = [begin
        if tenure_a[a] == "rented_public"
            H.landlord_public  === nothing ? LL_R : Float64(H.landlord_public)
        elseif tenure_a[a] == "rented_private"
            H.landlord_private === nothing ? LL_R : Float64(H.landlord_private)
        elseif inc_a[a] == "poor"
            H.owner_poor === nothing ? r : Float64(H.owner_poor)
        else
            H.owner_rich === nothing ? r : Float64(H.owner_rich)
        end
    end for a in A]
end
fdisc(a::Int, yr::Int) = (1 + fdisc_r_a[a])^(-(yr - t0))
if any(fdisc_r_a .!= r)
    println("  Follower discount rates by group (state r = $r): owners poor/rich = " *
            "$(SC.household_discount_rates.owner_poor === nothing ? r : SC.household_discount_rates.owner_poor)/" *
            "$(SC.household_discount_rates.owner_rich === nothing ? r : SC.household_discount_rates.owner_rich), " *
            "landlords public/private = " *
            "$(SC.household_discount_rates.landlord_public === nothing ? LL_R : SC.household_discount_rates.landlord_public)/" *
            "$(SC.household_discount_rates.landlord_private === nothing ? LL_R : SC.household_discount_rates.landlord_private)")
end

# Levy duration (Polish rent law, Art. 8a(4b): the 10%/yr return runs only
# until the outlays are recovered, then stops; user source note 2026-10-08).
# levy_years_of(a): "permanent" → Inf (German §559 reading, default);
# "recovery" → ceil(1/ρ) years per landlord type (10 y at ρ = 0.10; the
# fair-profit component is not tied to the investment and is ignored);
# integer → that many years.
function levy_years_of(a::Int)
    pty = SC.pass_through_years
    pty == "permanent" && return Inf
    if pty == "recovery"
        ρ = pass_through_of(a)
        ρ <= 0 && return Inf   # no levy at ρ = 0 anyway; window irrelevant
        return Float64(ceil(Int, 1 / ρ))
    end
    return Float64(pty)
end
# Fraction of period ti's years still inside the levy window of an
# investment made in period τ ≤ ti. The investment is booked at period τ's
# START year (same convention as capex); the window is
# [years[τ], years[τ] + Y). rent_inc[a,ti] is the period-AVERAGE annual
# levy, so a partially covered period carries the pro-rated amount; the
# €/m² cap also binds this average (documented convention). With
# Y = Inf this is identically 1.0 and the constraint reduces exactly to
# the committed cumulative form.
function levy_coverage(τ::Int, ti::Int, a::Int)
    Y = levy_years_of(a)
    isinf(Y) && return 1.0
    overlap = min(Float64(end_year[ti]), years[τ] + Y) - Float64(years[ti])
    return clamp(overlap / period_length[ti], 0.0, 1.0)
end

# Spending-floor mask: poor OWNERS always count; landlord subsidies for
# buildings housing POOR tenants count iff landlord_subsidy_counts_as_poor
# (plan §4 leader changes — report both definitions in the summary).
# A rich tenant's building (2026-10-08) never counts toward the poor floor.
lowmask_a = [is_rented(a) ?
             (SC.landlord_subsidy_counts_as_poor && inc_a[a] == "poor" ? 1.0 : 0.0) :
             (inc_a[a] == "poor" ? 1.0 : 0.0) for a in A]
wpbmask_a = [wpb_a[a] ? 1.0 : 0.0 for a in A]

# Level 1b: tax/benefit clawback per archetype (share of the nominal subsidy
# that never reaches the household). Landlord subsidies carry no household
# tax/benefit clawback — rented archetypes always 0.
clawback_of(a::Int) = is_rented(a) ? 0.0 :
                      inc_a[a] == "poor" ? SC.clawback_rate_by_class.poor :
                                           SC.clawback_rate_by_class.rich
# What the state pays per unit of adoption: the nominal rate — or, with
# clawback_returns_to_budget, only the part the household keeps
leader_rate_factor(a::Int) = SC.clawback_returns_to_budget ? (1 - clawback_of(a)) : 1.0

traj_years  = hasproperty(ctx, :traj_years)  ? parse.(Int, split(ctx.traj_years[1], ";")) : Int[]
traj_values = hasproperty(ctx, :traj_values) ? parse.(Float64, split(ctx.traj_values[1], ";")) : Float64[]
# Measure classification
M_env  = findall(x -> x == "envelope", cls_m)
M_hvac = findall(x -> x == "hvac", cls_m)
M_pv   = findall(x -> x == "pv", cls_m)

# HVAC measure indices (for carrier-dependent PEF)
idx_hp   = findfirst(i -> cls_m[i] == "hvac" && lowercase(hvac_to[i]) == "heat_pump", collect(M))
idx_dist = findfirst(i -> cls_m[i] == "hvac" && lowercase(hvac_to[i]) == "district_heat", collect(M))

# Carrier-dependent primary energy factors — POLAND, time-varying.
# Electricity wi falls as the coal-heavy grid decarbonizes (Dz.U. 2023 poz. 697:
# wi = 2.5 today, 3.0 before 2023; NECP outlook implies ~0.8 floor by 2050).
# District heat: coal-CHP-dominated stock average ~0.85 today, declining as
# efficient-DH requirements bind. Fossil boilers (coal/gas): 1.1 constant.
# The frozen_pef scenario lever keeps 2023 values fixed (sensitivity case).
PEF_FOSSIL = 1.1
pef_elec_at(yr) = SC.pef_frozen ? 2.5 :
    yr <= 2020 ? 3.0 :
    yr <= 2030 ? 3.0 + (1.9 - 3.0) * (yr - 2020) / 10 :
    yr <= 2035 ? 1.9 + (1.5 - 1.9) * (yr - 2030) / 5 :
    yr <= 2040 ? 1.5 + (1.1 - 1.5) * (yr - 2035) / 5 :
    yr <= 2050 ? 1.1 + (0.8 - 1.1) * (yr - 2040) / 10 : 0.8
pef_dh_at(yr) = SC.pef_frozen ? 0.85 :
    yr <= 2020 ? 0.85 :
    yr <= 2030 ? 0.85 + (0.75 - 0.85) * (yr - 2020) / 10 :
    yr <= 2035 ? 0.75 + (0.70 - 0.75) * (yr - 2030) / 5 :
    yr <= 2040 ? 0.70 + (0.60 - 0.70) * (yr - 2035) / 5 :
    yr <= 2050 ? 0.60 + (0.45 - 0.60) * (yr - 2040) / 10 : 0.40

# Reduction factor bounds per class (for multiplicative model)
r_env_max_val  = maximum(redfac_m[m] for m in M_env)    # 0.70
r_hvac_max_val = maximum(redfac_m[m] for m in M_hvac)   # 0.65 (raised below in η mode)
r_pv_max_val   = maximum(redfac_m[m] for m in M_pv)     # 0.25

# Cost parameters — Poland (EUR per kWh delivered)
p_gas  = 0.065   # fossil boiler fuel (coal/gas mix, household price)
p_dh   = 0.055   # district heat
p_elec = 0.22    # household electricity (explicit — no break-even construction)
# 2026-10-27 carrier-price order: with SC.carrier_prices set, the three
# legacy scalars above are replaced by sourced per-carrier prices and a
# per-archetype fossil MIX (stock-file columns mix_coal/mix_wood/mix_gas/
# mix_oil, summing to 1 on fossil-heated rows), from which BOTH the fossil
# fuel price and the ETS2 CO₂ intensity of each archetype are computed —
# price and carbon factor always come from the same mix. Legacy default:
# every committed scenario reproduces bit-identically.
if SC.carrier_prices !== nothing
    CP = SC.carrier_prices
    for c in (:elec, :gas, :coal, :wood, :oil, :dh)
        haskey(CP, c) || error("carrier_prices must provide $c (EUR/kWh final)")
    end
    for c in (:mix_coal, :mix_wood, :mix_gas, :mix_oil)
        hasproperty(archetypes, c) ||
            error("carrier_prices set but the stock file $(SC.stock_file) lacks column $c")
    end
    mixmat = [(Float64(archetypes.mix_coal[a]), Float64(archetypes.mix_wood[a]),
               Float64(archetypes.mix_gas[a]),  Float64(archetypes.mix_oil[a])) for a in A]
    for a in A
        s = sum(mixmat[a])
        is_dh0_a_early = lowercase(strip(String(archetypes.current_hvac[a]))) == "district_heat"
        (is_dh0_a_early ? s < 1e-9 : abs(s - 1.0) < 1e-6) ||
            error("fossil mix of $(archetypes.arch_id[a]) must sum to 1 (fossil) or 0 (DH incumbent), got $s")
    end
    p_gas  = Float64(CP.gas)
    p_dh   = Float64(CP.dh)
    p_elec = Float64(CP.elec)
    # per-archetype fossil-mix price (EUR/kWh final); DH incumbents use p_dh below
    p_fossilmix_a = [mixmat[a][1]*Float64(CP.coal) + mixmat[a][2]*Float64(CP.wood) +
                     mixmat[a][3]*Float64(CP.gas)  + mixmat[a][4]*Float64(CP.oil) for a in A]
    # CO₂ intensity from the SAME mix (kg/kWh final; wood 0 under ETS2);
    # overrides the stock file's co2_intensity_kg_per_kWh column
    CF = SC.carrier_co2
    co2_int_a = [mixmat[a][1]*Float64(CF.coal) + mixmat[a][3]*Float64(CF.gas) +
                 mixmat[a][4]*Float64(CF.oil) + mixmat[a][2]*Float64(CF.wood) for a in A]
    println("  Carrier prices (EUR/kWh final, real 2024): elec=$(CP.elec) gas=$(CP.gas) " *
            "coal=$(CP.coal) wood=$(CP.wood) oil=$(CP.oil) dh=$(CP.dh)")
    println("  Fossil-mix prices (unique): " *
            join(unique(round.([p for (a, p) in enumerate(p_fossilmix_a) if sum(mixmat[a]) > 0.5], digits=4)), ", ") *
            "  CO₂ intensities (unique): " *
            join(unique(round.([c for (a, c) in enumerate(co2_int_a) if sum(mixmat[a]) > 0.5], digits=4)), ", "))
end

# pl10_woodpef (2026-11-04 user order): wood counts with its biomass primary
# factor in the per-archetype fossil-mix PEF (coal/gas/oil stay at
# PEF_FOSSIL = 1.1); applied to the BASELINE (pef_a override below) and the
# TRAJECTORY accounting (c_prim_*/pef_base_at), so relative targets follow
# the new baseline. Invert WPB shares untouched. Default wood_pef = 1.1
# keeps pef_fossil_a ≡ PEF_FOSSIL: every other scenario is bit-identical.
WOOD_PEF = haskey(SC, :wood_pef) ? Float64(SC.wood_pef) : PEF_FOSSIL
pef_fossil_a = if WOOD_PEF == PEF_FOSSIL || SC.carrier_prices === nothing
    fill(PEF_FOSSIL, length(A))
else
    [sum(mixmat[a]) > 0.5 ?
         mixmat[a][1]*PEF_FOSSIL + mixmat[a][2]*WOOD_PEF +
         mixmat[a][3]*PEF_FOSSIL + mixmat[a][4]*PEF_FOSSIL : PEF_FOSSIL
     for a in A]
end
if WOOD_PEF != PEF_FOSSIL
    SC.carrier_prices === nothing && error("wood_pef needs carrier_prices (fossil mix columns)")
    for a in A
        if sum(mixmat[a]) > 0.5   # fossil-heated rows only; DH incumbents keep the stock value
            pef_a[a] = pef_fossil_a[a]
        end
    end
    println("  wood_pef = $WOOD_PEF: fossil-mix PEFs (unique): " *
            join(unique(round.([pef_fossil_a[a] for a in A if sum(mixmat[a]) > 0.5], digits=4)), ", "))
end

# Remaining energy factors per HVAC type (fraction of demand consumed as delivered energy)
remain_hp  = idx_hp   !== nothing ? (1 - redfac_m[idx_hp])   : 0.33  # ≈ 1/SCOP 3.0
remain_dh  = idx_dist !== nothing ? (1 - redfac_m[idx_dist]) : 0.70  # boiler-efficiency gain only

# Archetypes already on district heating (current_hvac == district_heat):
# no fossil fraction, no switching measures, fuel at DH price, DH primary factor.
is_dh0_a = [lowercase(hvac_current[a]) == "district_heat" for a in A]
# Base fuel price per archetype: legacy = p_gas for every fossil archetype;
# carrier-price mode = that archetype's own fossil-MIX price (2026-10-27)
pfuel_a = SC.carrier_prices === nothing ?
    [is_dh0_a[a] ? p_dh : p_gas for a in A] :
    [is_dh0_a[a] ? p_dh : p_fossilmix_a[a] for a in A]
# Carrier-cost deltas for SWITCHERS, per archetype (2026-10-27): heat-pump
# electricity at the sourced price (delivered = heat ÷ SCOP via remain_hp),
# district heat at the URE price — relative to the archetype's own base
# fuel price. Legacy mode reproduces the committed scalars for every
# archetype (Δp vs p_gas), bit-identical.
# 2026-10-27 correction (1): per-archetype seasonal generation efficiency
# η_a and the corrected E0→useful→carrier chain. Legacy (carrier_etas =
# nothing): remain factors are the committed scalars for every archetype.
if SC.carrier_etas !== nothing
    SC.carrier_prices !== nothing || error("carrier_etas requires carrier_prices")
    ET = SC.carrier_etas
    for c in (:coal, :wood, :gas, :oil, :dh)
        haskey(ET, c) && 0.3 < Float64(ET[c]) <= 1.2 ||
            error("carrier_etas must provide $c in (0.3, 1.2]")
    end
    global η_a = [is_dh0_a[a] ? Float64(ET.dh) :
        mixmat[a][1]*Float64(ET.coal) + mixmat[a][2]*Float64(ET.wood) +
        mixmat[a][3]*Float64(ET.gas)  + mixmat[a][4]*Float64(ET.oil) for a in A]
    SCOP_HP = 3.0
    global remain_hp_a = [η_a[a] / SCOP_HP for a in A]
    global remain_dh_a = [η_a[a] / Float64(ET.dh) for a in A]
    println("  Seasonal efficiencies η_a (unique): ", unique(round.(η_a, digits=4)),
            "  remain_hp_a: ", unique(round.(remain_hp_a, digits=4)),
            "  remain_dh_a: ", unique(round.(remain_dh_a, digits=4)))
else
    global remain_hp_a = fill(remain_hp, length(A))
    global remain_dh_a = fill(remain_dh, length(A))
end
Δp_hp_a = [remain_hp_a[a] * p_elec - (SC.carrier_prices === nothing ? p_gas : pfuel_a[a]) for a in A]
Δp_dh_a = [remain_dh_a[a] * p_dh   - (SC.carrier_prices === nothing ? p_gas : pfuel_a[a]) for a in A]
# Per-archetype HVAC reduction factors (final-energy accounting of the
# switch, consistent with the remain factors above); legacy ≡ redfac_m.
redfac_am = [m == idx_hp   ? 1 - remain_hp_a[a] :
             m == idx_dist ? 1 - remain_dh_a[a] : redfac_m[m] for a in A, m in M]
r_hvac_max_val = max(r_hvac_max_val,
    maximum(redfac_am[a,m] for a in A, m in M_hvac; init=0.0))
# 2026-10-29 review change (2): per-(btype, measure) envelope saving
# factors override redfac_am (used by the follower r_env and master
# mr_env sums). Values must stay within the precomputed r_env_max_val
# bound (0.70), which is enforced here so the E lower bounds remain
# valid. nothing = legacy, bit-identical.
if SC.measure_reductions !== nothing
    for ((bt, mid), rv) in SC.measure_reductions
        bt in btype_a || error("measure_reductions: btype $bt not in the stock file")
        midx = findfirst(==(mid), m_id)
        midx !== nothing || error("measure_reductions: unknown measure id $mid")
        cls_m[midx] == "envelope" || error("measure_reductions: $mid is not an envelope measure")
        (0.0 < rv <= r_env_max_val) || error("measure_reductions: $mid=$rv outside (0, $r_env_max_val]")
    end
    for a in A, m in M
        if haskey(SC.measure_reductions, (btype_a[a], m_id[m]))
            redfac_am[a,m] = SC.measure_reductions[(btype_a[a], m_id[m])]
        end
    end
    println("  Envelope-saving override ACTIVE: ", join(sort(["$bt/$mid=$(SC.measure_reductions[(bt,mid)])"
        for (bt,mid) in keys(SC.measure_reductions)]), ", "))
end
println("  Carrier pricing: p_elec=$(round(p_elec, digits=4)), Δp_hp(unique)=$(unique(round.(Δp_hp_a, digits=4))), Δp_dh(unique)=$(unique(round.(Δp_dh_a, digits=4)))")

function annuity_factor(lt::Float64, rate::Float64)
    rate ≈ 0.0 ? 1.0 / lt : rate / (1 - (1 + rate)^(-lt))
end
ann_m = [annuity_factor(lifetime_m[m], r) for m in M]
maintenance_rate = Dict("envelope" => 0.005, "hvac" => 0.02, "pv" => 0.01)
period_length = [i < length(T) ? years[i+1] - years[i] : 10 for i in T]

# Per-class annual renovation-capacity ceilings (Poland, DSRB-informed, staged:
# envelope capacity must build up; heating swaps bounded by installer base; PV fastest).
# On top, a JOINT labor-weighted cap prevents the per-class ceilings from adding up
# to implausible total activity (one deep-envelope job ≈ 2.5 heating swaps ≈ 5 PV jobs).
# SC.reno_scale is the capacity scenario lever.
# 2026-10-27: env/hvac/joint rates are scenario-overridable (KPRB profile in
# the pl_* scenarios); nothing = the committed staging below, bit-identical.
stage4(p, yr) = yr < 2030 ? p[1] : (yr < 2035 ? p[2] : (yr < 2040 ? p[3] : p[4]))
env_rate(yr)   = SC.env_rate_path !== nothing ? stage4(SC.env_rate_path, yr) :
                 (yr < 2030 ? 0.015 : (yr < 2040 ? 0.030 : 0.035))
hvac_rate(yr)  = SC.hvac_rate_const !== nothing ? Float64(SC.hvac_rate_const) : 0.030
pv_rate(yr)    = 0.040
joint_rate(yr) = SC.joint_rate_path !== nothing ? stage4(SC.joint_rate_path, yr) :
                 (yr < 2030 ? 0.025 : (yr < 2040 ? 0.040 : 0.050))
W_CLS = Dict("envelope" => 1.0, "hvac" => 0.4, "pv" => 0.2)
cap_from_rate(rt, len) = 1 - (1 - min(SC.reno_scale * rt, 0.999))^len
adopt_cap_env   = [cap_from_rate(env_rate(years[ti]),   period_length[ti]) for ti in T]
adopt_cap_hvac  = [cap_from_rate(hvac_rate(years[ti]),  period_length[ti]) for ti in T]
adopt_cap_pv    = [cap_from_rate(pv_rate(years[ti]),    period_length[ti]) for ti in T]
adopt_cap_joint = [cap_from_rate(joint_rate(years[ti]), period_length[ti]) for ti in T]
adopt_cap_of(cls, ti) = cls == "envelope" ? adopt_cap_env[ti] :
                        cls == "hvac"     ? adopt_cap_hvac[ti] : adopt_cap_pv[ti]
# Fraction of fossil boilers reaching end-of-life per period
boiler_break = [1 - (1 - 1/BOILER_LIFE)^period_length[ti] for ti in T]
println("  Adoption caps env/hvac/pv/joint: ",
        [round(adopt_cap_env[ti], digits=3) for ti in T], " / ",
        [round(adopt_cap_hvac[ti], digits=3) for ti in T], " / ",
        [round(adopt_cap_pv[ti], digits=3) for ti in T], " / ",
        [round(adopt_cap_joint[ti], digits=3) for ti in T],
        " (periods: ", period_length, "yr)")
println("  Boiler break rates: ", [round(boiler_break[ti], digits=3) for ti in T])

# End-of-period years (physical year when period-ti decisions take effect)
# Period 1 (2020-2030) → state at 2030, Period 4 (2040-2050) → state at 2050
end_year = [i < length(T) ? years[i+1] : years[i] + period_length[i] for i in T]
println("  End-of-period years: ", end_year)

# Map physical year → period index via end_year (for trajectory checks)
end_t_idx = Dict(end_year[i] => i for i in T)

# ---- pl12 D1/D7: leader accounting window and fixed history ----------------
SUB_START = (haskey(SC, :subsidy_horizon_start) && SC.subsidy_horizon_start !== nothing) ?
            Int(SC.subsidy_horizon_start) : years[1]
T_LEADER = findfirst(ti -> years[ti] >= SUB_START, collect(T))
T_LEADER === nothing && error("subsidy_horizon_start $SUB_START lies after the last period start")
HIST_ON = haskey(SC, :history_adoption_file) && SC.history_adoption_file !== nothing
T_HIST = HIST_ON ? T_LEADER - 1 : 0            # periods 1..T_HIST are fixed history
HIST_ON && T_HIST < 1 && error("history_adoption_file needs subsidy_horizon_start after the first period")
HIST_CLASSES = haskey(SC, :history_fix_classes) ? collect(String.(SC.history_fix_classes)) : String[]
y_hist = zeros(length(A), length(M), max(T_HIST, 1))
hist_fixed = falses(length(A), length(M))
if HIST_ON
    hdf = CSV.read(SC.history_adoption_file, DataFrame)
    for row in eachrow(hdf)
        a = findfirst(==(String(row.archetype)), arch_id); m = findfirst(==(String(row.measure)), m_id)
        (a === nothing || m === nothing) && error("history_adoption_file: unknown $(row.archetype)/$(row.measure)")
        ti = hasproperty(hdf, :period) ? Int(row.period) : 1
        1 <= ti <= T_HIST || error("history_adoption_file: period $ti outside the history periods 1..$T_HIST")
        y_hist[a, m, ti] = Float64(row.y)
    end
    for a in A, m in M
        hist_fixed[a, m] = cls_m[m] in HIST_CLASSES
    end
    println(">>> HISTORY FIXED (pl12 D1): adoption in periods 1..$T_HIST fixed from $(SC.history_adoption_file) " *
            "for classes $(HIST_CLASSES); the state pays and counts from $SUB_START (period $T_LEADER); " *
            "spending discounted to $DISC_BASE <<<")
end
# D3: subsidy rates of the history (SFH owner-occupiers only; 0 for MFH and landlords)
function σ_hist(m::Int, a::Int)
    (haskey(SC, :history_subsidy) && SC.history_subsidy !== nothing) || return 0.0
    (is_rented(a) || btype_a[a] != "SFH" || cls_m[m] == "pv") && return 0.0
    inc_a[a] == "poor" ? Float64(SC.history_subsidy.sfh_poor) : Float64(SC.history_subsidy.sfh_rich)
end
hist_class_fixed(cls::String, ti::Int) = HIST_ON && ti <= T_HIST && cls in HIST_CLASSES

# EED Art. 6 required nZEB share per public-rental archetype and period
# (2026-10-27 user decisions). Target path: linear 3%/yr of floor area from
# 2026 (EED Art. 6(1); base = floor area not nZEB on 1 Jan 2024 — here ALL
# public-rental dwellings, since no archetype starts at nZEB). The target is
# CLIPPED to what the archetype's envelope and heating-system capacity
# allows (decision 1b).
# CORRECTION (2026-10-27, same day — recorded in the CHANGELOG): the first
# formulation clipped with AGGREGATE cumulative capacity
# (min(Σenv, Σhvac, Σjoint/1.4)); that ignores per-period scheduling and
# made the follower INFEASIBLE at the 2040 milestone (the joint labour cap
# binds period by period, so both components cannot reach the aggregate
# bound simultaneously once earlier milestones are enforced). Now the
# requirement is the exact greedy max path: per period end, a small LP
# maximises the reachable nZEB share (envelope and heating scheduled
# separately under the per-period class caps and the joint labour cap,
# weights env 1.0 / hvac 0.4) subject to the already-fixed earlier
# requirements; the requirement is min(target, that maximum − 1e-6 safety
# margin when capacity binds). DH incumbents need only the envelope.
# Period-END check, not a yearly carry-over (Art. 6(3) simplification).
# pl12: in the fixed-history periods the reachable share is the FIXED adoption of
# the public-rental archetypes (deep envelope / heating), not the capacity cap.
function _eed_hist_bound(cls::String, ti::Int)
    (HIST_ON && ti <= T_HIST && cls in HIST_CLASSES) || return nothing
    pubs = [a for a in A if tenure_a[a] == "rented_public"]
    isempty(pubs) && return nothing
    if cls == "envelope"
        idx_deep = findfirst(i -> cls_m[i] == "envelope" && depth_m[i] == "deep", collect(M))
        return minimum(y_hist[a, idx_deep, ti] for a in pubs)
    else
        return minimum(sum(y_hist[a, m, ti] for m in M_hvac) for a in pubs)
    end
end
function _eed_max_path(needs_heat::Bool)
    req = zeros(length(T))
    for tk in T
        lp = Model(Gurobi.Optimizer)
        set_optimizer_attribute(lp, "OutputFlag", 0)
        @variable(lp, 0 <= e[ti in 1:tk] <= (_eed_hist_bound("envelope", ti) === nothing ? adopt_cap_env[ti] : _eed_hist_bound("envelope", ti)))
        @variable(lp, 0 <= s <= 1)
        @constraint(lp, s <= sum(e))
        if needs_heat
            @variable(lp, 0 <= h[ti in 1:tk] <= (_eed_hist_bound("hvac", ti) === nothing ? adopt_cap_hvac[ti] : _eed_hist_bound("hvac", ti)))
            @constraint(lp, [ti in 1:tk],
                W_CLS["envelope"] * e[ti] + W_CLS["hvac"] * h[ti] <= adopt_cap_joint[ti])
            @constraint(lp, s <= sum(h))
            for tj in 1:tk-1
                req[tj] > 0 || continue
                @constraint(lp, sum(e[ti] for ti in 1:tj) >= req[tj])
                @constraint(lp, sum(h[ti] for ti in 1:tj) >= req[tj])
            end
        else
            @constraint(lp, [ti in 1:tk], W_CLS["envelope"] * e[ti] <= adopt_cap_joint[ti])
            for tj in 1:tk-1
                req[tj] > 0 || continue
                @constraint(lp, sum(e[ti] for ti in 1:tj) >= req[tj])
            end
        end
        @objective(lp, Max, s)
        optimize!(lp)
        termination_status(lp) == OPTIMAL ||
            error("EED max-path LP failed at period $tk: $(termination_status(lp))")
        smax = objective_value(lp)
        tgt = min(1.0, 0.03 * max(0, end_year[tk] - 2026))
        req[tk] = tgt <= smax ? tgt : max(0.0, smax - 1e-6)
    end
    return req
end
if SC.eed_public_obligation
    EED_REQ_FOSSIL = _eed_max_path(true)
    EED_REQ_DH     = _eed_max_path(false)
    println("  EED required nZEB share by period end $(end_year):")
    println("    fossil-heated public archetypes: ", round.(EED_REQ_FOSSIL, digits=4))
    println("    DH-incumbent public archetypes:  ", round.(EED_REQ_DH, digits=4))
end
eed_required_share(a::Int, ti::Int) =
    (is_dh0_a[a] ? EED_REQ_DH : EED_REQ_FOSSIL)[ti]

# EPBD 2050 index: find period whose END is 2050
TI2050 = findfirst(==(2050), end_year)
if TI2050 === nothing
    @warn "No period ends at 2050 — EPBD 2050 check disabled"
end

# Scenario lever: residual value. A measure adopted in period ti with lifetime
# beyond the horizon end keeps (unused lifetime / lifetime) of its capex as
# salvage value, credited at the horizon end. net_capex_factor scales the
# follower's upfront investment: 1 = no credit (baseline), <1 = late adoption
# is not punished for benefits the horizon cuts off.
HORIZON_END = end_year[end]
net_capex_factor = ones(length(M), length(T))
if SC.residual_value
    for m in M, ti in T
        used_frac = min(1.0, (HORIZON_END - years[ti]) / lifetime_m[m])
        salvage_frac = 1.0 - used_frac
        net_capex_factor[m, ti] = 1.0 - salvage_frac * disc(HORIZON_END) / disc(years[ti])
    end
end

# Per-period primary-energy coefficients (evaluated at each period's END year,
# when the period's stock state is measured):
#   E_primary[a,ti] = pef_base_at(a,ti)·E_ep − c_prim_hp_t[ti]·E_ep_hp − c_prim_dh_t[ti]·E_ep_dh
# pef_base: 1.1 for fossil-heated archetypes; the (declining) DH factor for
# archetypes already on district heating (their carrier splits stay zero).
pef_elec_t = [pef_elec_at(end_year[ti]) for ti in T]
pef_dh_t   = [pef_dh_at(end_year[ti]) for ti in T]
# ---- pl12 D2: per-period incumbent parameters -----------------------------
# Legacy values are copied to every period (bit-identical). fuel_mix_update
# replaces, from the first design period on, the fossil-mix of the listed
# archetypes by the mix after the observed 2020-2025 boiler replacements:
# a share hpdh_share of the dwellings switched to heat pump / district heat
# (tracked as fixed adoption, removed from the coal+wood shares here), a
# share boiler_share replaced an old coal/wood boiler by a new boiler of the
# kinds in new_mix (shares of the boiler replacements) with efficiencies etas.
# The archetype's delivered base demand scales with η_2020/η_new, so the
# useful heat is unchanged and heat-pump / DH dwellings keep their energy.
base_at       = [base_a[a] for a in A, ti in T]
remain_hp_at  = [remain_hp_a[a] for a in A, ti in T]
remain_dh_at  = [remain_dh_a[a] for a in A, ti in T]
pfuel_at      = [pfuel_a[a] for a in A, ti in T]
co2_int_at    = [co2_int_a[a] for a in A, ti in T]
pef_fossil_at = [pef_fossil_a[a] for a in A, ti in T]
η_at          = [(@isdefined η_a) ? η_a[a] : NaN for a in A, ti in T]
FUEL_MIX_AFTER = Dict{Int,NamedTuple}()
if haskey(SC, :fuel_mix_update) && SC.fuel_mix_update !== nothing
    FU = SC.fuel_mix_update
    (SC.carrier_prices !== nothing && SC.carrier_etas !== nothing) ||
        error("fuel_mix_update needs carrier_prices and carrier_etas")
    HIST_ON || error("fuel_mix_update needs a fixed history (history_adoption_file)")
    nm = FU.new_mix; et = FU.etas
    nmsum = sum(values(nm))
    for a in A
        (btype_a[a] == FU.btype && !is_dh0_a[a]) || continue
        coal, wood, gas, oil = mixmat[a]
        x = Float64(FU.hpdh_share) + Float64(FU.boiler_share)
        coal + wood >= x - 1e-9 || error("fuel_mix_update: $(arch_id[a]) has only $(coal+wood) coal+wood, cannot remove $x")
        coal2 = coal - x * coal / (coal + wood); wood2 = wood - x * wood / (coal + wood)
        b = Float64(FU.boiler_share)
        sh = Dict("coal" => coal2, "wood" => wood2, "gas" => gas, "oil" => oil,
                  "gas_cond" => b * nm.gas_cond / nmsum, "biomass" => b * nm.biomass / nmsum,
                  "coal5" => b * nm.coal5 / nmsum, "electric" => b * nm.electric / nmsum,
                  "oil_new" => b * nm.oil / nmsum)
        pop = 1.0 - Float64(FU.hpdh_share)   # dwellings still on an own boiler
        for k in keys(sh); sh[k] /= pop; end
        ET = SC.carrier_etas; CP = SC.carrier_prices; CF = SC.carrier_co2
        ηk = Dict("coal" => ET.coal, "wood" => ET.wood, "gas" => ET.gas, "oil" => ET.oil,
                  "gas_cond" => et.gas_cond, "biomass" => et.biomass, "coal5" => et.coal5,
                  "electric" => et.electric, "oil_new" => et.oil)
        pk = Dict("coal" => CP.coal, "wood" => CP.wood, "gas" => CP.gas, "oil" => CP.oil,
                  "gas_cond" => CP.gas, "biomass" => CP.wood, "coal5" => CP.coal,
                  "electric" => CP.elec, "oil_new" => CP.oil)
        ck = Dict("coal" => CF.coal, "wood" => CF.wood, "gas" => CF.gas, "oil" => CF.oil,
                  "gas_cond" => CF.gas, "biomass" => CF.wood, "coal5" => CF.coal,
                  "electric" => 0.0, "oil_new" => CF.oil)
        η_new  = sum(sh[k] * Float64(ηk[k]) for k in keys(sh))
        p_new  = sum(sh[k] * Float64(pk[k]) for k in keys(sh))
        c_new  = sum(sh[k] * Float64(ck[k]) for k in keys(sh))
        for ti in (T_HIST+1):length(T)
            pef_new = sum(sh[k] * (k == "electric" ? pef_elec_t[ti] : (k in ("wood", "biomass") ? WOOD_PEF : PEF_FOSSIL)) for k in keys(sh))
            η_at[a,ti] = η_new
            base_at[a,ti] = base_a[a] * η_a[a] / η_new
            remain_hp_at[a,ti] = η_new / (η_a[a] / remain_hp_a[a])   # SCOP = η_2020 / remain_hp
            remain_dh_at[a,ti] = η_new / Float64(ET.dh)
            pfuel_at[a,ti] = p_new
            co2_int_at[a,ti] = c_new
            pef_fossil_at[a,ti] = pef_new
        end
        FUEL_MIX_AFTER[a] = (shares=sh, eta=η_new, price=p_new, co2=c_new)
    end
    println(">>> fuel_mix_update (pl12 D2) ACTIVE for $(length(FUEL_MIX_AFTER)) archetypes from period $(T_HIST+1): " *
            join(["$(arch_id[a]): η $(round(η_a[a], digits=3))→$(round(FUEL_MIX_AFTER[a].eta, digits=3)), " *
                  "price $(round(pfuel_a[a], digits=4))→$(round(FUEL_MIX_AFTER[a].price, digits=4)), " *
                  "CO2 $(round(co2_int_a[a], digits=3))→$(round(FUEL_MIX_AFTER[a].co2, digits=3))" for a in sort(collect(keys(FUEL_MIX_AFTER)))], "; ") * " <<<")
end
redfac_amt = [m == idx_hp   ? 1 - remain_hp_at[a,ti] :
              m == idx_dist ? 1 - remain_dh_at[a,ti] : redfac_am[a,m] for a in A, m in M, ti in T]
r_hvac_max_val = max(r_hvac_max_val, maximum(redfac_amt[a,m,ti] for a in A, m in M_hvac, ti in T; init=0.0))
Δp_hp_at = [remain_hp_at[a,ti] * p_elec - (SC.carrier_prices === nothing ? p_gas : pfuel_at[a,ti]) for a in A, ti in T]
Δp_dh_at = [remain_dh_at[a,ti] * p_dh   - (SC.carrier_prices === nothing ? p_gas : pfuel_at[a,ti]) for a in A, ti in T]
c_prim_hp_at = [pef_fossil_at[a,ti] - remain_hp_at[a,ti] * pef_elec_t[ti] for a in A, ti in T]
c_prim_dh_at = [pef_fossil_at[a,ti] - remain_dh_at[a,ti] * pef_dh_t[ti] for a in A, ti in T]
pef_base_at(a::Int, ti::Int) = is_dh0_a[a] ? pef_dh_t[ti] : pef_fossil_at[a,ti]
println("  PEF elec path: ", [round(pef_elec_t[ti], digits=2) for ti in T],
        "  PEF DH path: ", [round(pef_dh_t[ti], digits=2) for ti in T])

# Baseline primary energy (pre-renovation)
# Computed later after total_area is available

cost_multiplier = zeros(length(M), length(T))
for m in M, ti in T
    cost_multiplier[m, ti] = (1 - learning_m[m])^(years[ti] - years[1])
end

# 2026-10-29 Polish investment-cost order: with SC.measure_costs set, the
# listed (btype, m_id) pairs take sourced per-dwelling totals (EUR); all
# other pairs keep the legacy formula. Stored as per-dwelling totals
# because these costs scale with ENVELOPE area, not floor area — a
# capex_per_m2 × floor_area + fixed_capex fit to the two dwelling types
# of record would need negative fixed costs (light −1,923 €, medium
# −3,971 €, deep −6,914 €). The learning-rate cost multiplier applies
# unchanged. nothing = legacy, bit-identical.
if SC.measure_costs !== nothing
    for (bt, mid) in keys(SC.measure_costs)
        bt in btype_a || error("measure_costs: btype $bt not in the stock file")
        mid in m_id   || error("measure_costs: unknown measure id $mid")
    end
    println("  Measure-cost override ACTIVE: ", join(sort(["$bt/$mid=$(SC.measure_costs[(bt,mid)])"
        for (bt,mid) in keys(SC.measure_costs)]), ", "))
end
function base_inv_cost(a::Int, m::Int)
    if SC.measure_costs !== nothing && haskey(SC.measure_costs, (btype_a[a], m_id[m]))
        return SC.measure_costs[(btype_a[a], m_id[m])]
    end
    cls_m[m] == "pv" ? pv_cost_a[a] : cpm2_m[m] * fa_a[a] + cfix_m[m]
end
inv_cost_base = [base_inv_cost(a, m) for a in A, m in M]
inv_cost(a::Int, m::Int, ti::Int) = inv_cost_base[a, m] * cost_multiplier[m, ti]

# Subsidy caps
subsidy_cap = Dict{Tuple{String,String,String}, Float64}()
# Poland: Czyste Powietrze tier structure (basic 40% / elevated 70% / highest 100%;
# income differentiation applies to ALL measures; StopSmog reaches 100% for the poor).
# "poor" caps track the elevated..highest tiers, "rich" caps the basic tier
# (deep renovation slightly higher per EPBD Art. 17(16) deep-renovation priority).
subsidy_cap[("envelope","light","poor")]  = 0.70
subsidy_cap[("envelope","medium","poor")] = 0.85
subsidy_cap[("envelope","deep","poor")]   = 1.00
subsidy_cap[("envelope","light","rich")]  = 0.40
subsidy_cap[("envelope","medium","rich")] = 0.40
subsidy_cap[("envelope","deep","rich")]   = 0.50
subsidy_cap[("hvac","standard","poor")]   = 1.00
subsidy_cap[("hvac","standard","rich")]   = 0.40
subsidy_cap[("hvac","upgrade","poor")]    = 1.00
subsidy_cap[("hvac","upgrade","rich")]    = 0.40
subsidy_cap[("pv","standard","poor")]     = 0.0
subsidy_cap[("pv","standard","rich")]     = 0.0

# Scenario lever: subsidy generosity
if SC.subsidy_boost == :all_100
    for k in keys(subsidy_cap)
        if k[1] != "pv"
            subsidy_cap[k] = 1.0
        end
    end
elseif SC.subsidy_boost == :rich_to_poor
    for k in collect(keys(subsidy_cap))
        if k[3] == "rich"
            subsidy_cap[k] = subsidy_cap[(k[1], k[2], "poor")]
        end
    end
end

function get_subsidy_cap(m::Int, a::Int)
    # Level 2: rented archetypes face the landlord instruments — one rate per
    # landlord type across all non-PV measures (PV stays unsubsidised)
    if is_rented(a)
        return cls_m[m] == "pv" ? 0.0 : Float64(SC.landlord_subsidy_cap)
    end
    get(subsidy_cap, (cls_m[m], depth_m[m], inc_a[a]), 0.0)
end

# HVAC compatibility
hvac_compatible = trues(length(A), length(M))
for a in A, m in M
    if cls_m[m] == "hvac"
        req = hvac_from[m]; curr = uppercase(hvac_current[a])
        if req != "ANY" && req != curr
            hvac_compatible[a, m] = false
        end
        # District heat network coverage: SFH=30%, MFH=50% (Germany-wide ~14% coverage)
        # Caps enforced via cumulative adoption limit in follower + master
    end
end

# Feasibility per (a,m,ti): post-subsidy capex of a period's adoption must fit
# within the liquidity accumulated over that period (annual cap × period years)
liquidity_feasible = trues(length(A), length(M), length(T))
for a in A, m in M, ti in T
    max_sub = get_subsidy_cap(m, a)
    if inv_cost(a, m, ti) * adopt_cap_of(cls_m[m], ti) * (1 - max_sub) > cap_a[a] * period_length[ti]
        liquidity_feasible[a, m, ti] = false
    end
end

# 3D y_upper: per archetype, measure, AND period
# pl11 (2026-11-06 brief, decision 1): pv_enabled=false zeroes the PV bound
# everywhere, so no PV can be adopted (follower and master alike).
PV_ENABLED = !haskey(SC, :pv_enabled) || SC.pv_enabled
PV_ENABLED || println("  PV option REMOVED (pv_enabled=false): PV adoption bound 0 for all archetypes and periods")
y_upper = zeros(length(A), length(M), length(T))
for a in A, m in M, ti in T
    y_upper[a, m, ti] = (!hvac_compatible[a,m] || !liquidity_feasible[a,m,ti] ||
                         (cls_m[m] == "pv" && !PV_ENABLED)) ? 0.0 : adopt_cap_of(cls_m[m], ti)
end
if HIST_ON   # pl12: fixed history adoption is the bound (and the value) in the history periods
    for a in A, m in M, ti in 1:T_HIST
        hist_fixed[a, m] && (y_upper[a, m, ti] = y_hist[a, m, ti])
    end
end

# Energy savings
saving_kwh = [redfac_m[m] * base_a[a] for a in A, m in M]
total_area = sum(fa_a[a] * dwell_a[a] for a in A)
baseline_primary = sum(base_a[a] * pef_a[a] * fa_a[a] * dwell_a[a] for a in A) / total_area
println("  Baseline primary energy: $(round(baseline_primary, digits=1)) kWh/m²")

# 2026-10-27: relative EPBD trajectory (traj_mode="relative_to_2020").
# traj_values and the 2050 target are recomputed from the model's OWN
# 2020 stock-average primary: target_k = (1 − r_k) × baseline_primary.
# −16%/−20% per EPBD Art. 9(2); −40%/−59% keep the committed relative
# depths (ASSUMED). "absolute" (default) leaves the context.csv values
# untouched — every committed result bit-identical.
if SC.traj_mode == "relative_to_2020"
    length(SC.traj_reductions) == length(traj_values) ||
        error("traj_reductions must have $(length(traj_values)) entries, got $(length(SC.traj_reductions))")
    global traj_values = [(1 - r) * baseline_primary for r in SC.traj_reductions]
    global epbd_target = (1 - SC.traj_reductions[end]) * baseline_primary
    println("  EPBD trajectory RELATIVE to 2020 ($(round(baseline_primary, digits=1))): " *
            join(["$(y)→$(round(v, digits=1))" for (y, v) in zip(traj_years, traj_values)], ", ") *
            "  (2050 target $(round(epbd_target, digits=1)))")
elseif SC.traj_mode != "absolute"
    error("traj_mode must be \"absolute\" or \"relative_to_2020\", got $(SC.traj_mode)")
end
if SC.traj_values_override !== nothing
    length(SC.traj_values_override) == length(traj_values) ||
        error("traj_values_override needs $(length(traj_values)) values")
    global traj_values = collect(Float64, SC.traj_values_override)
    global epbd_target = Float64(SC.traj_values_override[end])
    println("  EPBD trajectory OVERRIDDEN (absolute): " *
            join(["$(y)→$(round(v, digits=1))" for (y, v) in zip(traj_years, traj_values)], ", "))
end

# Subsidy variable index mapping: (class, depth, income) → index 1..10.
# Level 2 adds two landlord instruments (indices 11, 12) when tenure is on:
# one rate per landlord type, applied to ALL non-PV measures of that type's
# rented archetypes (plan §4: subsidy_rate_landlord_by_type).
σ_keys = Any[
    ("envelope","light","poor"), ("envelope","medium","poor"), ("envelope","deep","poor"),
    ("envelope","light","rich"), ("envelope","medium","rich"), ("envelope","deep","rich"),
    ("hvac","standard","poor"), ("hvac","upgrade","poor"),
    ("hvac","standard","rich"), ("hvac","upgrade","rich")
]
σ_caps = Float64[get(subsidy_cap, k, 0.0) for k in σ_keys]
if SC.tenure_enabled
    push!(σ_keys, ("landlord","all","public"));  push!(σ_caps, Float64(SC.landlord_subsidy_cap))
    push!(σ_keys, ("landlord","all","private")); push!(σ_caps, Float64(SC.landlord_subsidy_cap))
end
n_σ = length(σ_keys)
IDX_LANDLORD_PUBLIC  = SC.tenure_enabled ? n_σ - 1 : nothing
IDX_LANDLORD_PRIVATE = SC.tenure_enabled ? n_σ     : nothing
if SIGMA_START_RAW !== nothing
    length(SIGMA_START_RAW) == n_σ ||
        error("P4_SIGMA_START needs $n_σ values in σ_keys order (got $(length(SIGMA_START_RAW)))")
    println(">>> P4_SIGMA_START length OK ($n_σ rates; tenure_enabled=$(SC.tenure_enabled)) <<<")
end

# Map (m, a) → σ index
function σ_index(m::Int, a::Int)
    if is_rented(a)
        cls_m[m] == "pv" && return nothing
        return tenure_a[a] == "rented_public" ? IDX_LANDLORD_PUBLIC : IDX_LANDLORD_PRIVATE
    end
    key = (cls_m[m], depth_m[m], inc_a[a])
    idx = findfirst(==(key), σ_keys)
    return idx  # nothing for PV
end

n_infeasible = sum(y_upper[a,m,1] == 0.0 for a in A, m in M)
println("Setup complete. $(n_infeasible)/$(length(A)*length(M)) infeasible (a,m) pairs")

# =============================================================================
# 2) BUILD FOLLOWER LP (for fixed σ values)
# =============================================================================
function solve_follower(σ_vals::Vector{Float64})
    fmodel = Model(Gurobi.Optimizer)
    set_optimizer_attribute(fmodel, "OutputFlag", 0)
    set_optimizer_attribute(fmodel, "NonConvex", 2)  # Enable bilinear constraints
    haskey(ENV, "P4_GRB_THREADS") && set_optimizer_attribute(fmodel, "Threads", parse(Int, ENV["P4_GRB_THREADS"]))

    # Variables
    @variable(fmodel, 0 <= fy[a in A, m in M, ti in T] <= y_upper[a, m, ti])
    @variable(fmodel, 0 <= fs[a in A, m in M, ti in T] <= 1)
    @variable(fmodel, 0 <= fz[a in A, m in M, ti in T] <= y_upper[a, m, ti])
    @variable(fmodel, 0 <= fE[a in A, ti in T] <= base_at[a,ti])

    # State dynamics
    @constraint(fmodel, [a in A, m in M], fs[a,m,1] == fy[a,m,1])
    @constraint(fmodel, [a in A, m in M, ti in 2:n_years],
        fs[a,m,ti] == fs[a,m,ti-1] + fy[a,m,ti])
    # pl12 D1: fixed history adoption
    if HIST_ON
        for a in A, m in M, ti in 1:T_HIST
            hist_fixed[a, m] && @constraint(fmodel, fy[a,m,ti] == y_hist[a,m,ti])
        end
    end

    # HVAC precedence — KEPT (2026-11-06 brief, decision 3): the share of
    # dwellings with a new heating system may exceed the share with an
    # envelope renovation by at most 0.3. Proxy for the minimum insulation
    # level a heat pump needs (reduced heat load / lower flow temperature);
    # the 0.3 slack allows switches in dwellings that are already adequate.
    @constraint(fmodel, [a in A, ti in T],
        sum(fs[a,m,ti] for m in M_hvac) <= sum(fs[a,m,ti] for m in M_env) + 0.3)

    # HVAC compatibility
    for a in A, m in M, ti in T
        if !hvac_compatible[a, m]
            @constraint(fmodel, fy[a,m,ti] == 0)
        end
    end

    # Per-class adoption rate caps (staged capacity ceilings)
    # (pl12: a class whose history adoption is fixed is exempt from its cap in the history periods)
    @constraint(fmodel, [a in A, ti in T; !hist_class_fixed("envelope", ti)], sum(fy[a,m,ti] for m in M_env) <= adopt_cap_env[ti])
    @constraint(fmodel, [a in A, ti in T; !hist_class_fixed("hvac", ti)], sum(fy[a,m,ti] for m in M_hvac) <= adopt_cap_hvac[ti])
    @constraint(fmodel, [a in A, ti in T], sum(fy[a,m,ti] for m in M_pv) <= adopt_cap_pv[ti])
    # Joint labor-weighted capacity cap across all classes
    @constraint(fmodel, [a in A, ti in T; !(hist_class_fixed("envelope", ti) && hist_class_fixed("hvac", ti))],
        sum(W_CLS[cls_m[m]] * fy[a,m,ti] for m in M) <= adopt_cap_joint[ti])

    # Level 2: landlord subsidy uptake is a BINARY choice per rented archetype
    # and period (apply / not apply — Öko-Institut 2021 mechanism): applying
    # reduces the investment cost but also the pass-through base. Owners have
    # no such choice (their fz is pinned directly below).
    @variable(fmodel, apply_sub[a in A_RENTED, ti in T], Bin)

    # Subsidy product (σ is FIXED here, so the product is exactly linear:
    # fz = σ_val·fy — no McCormick needed in the follower; for rented
    # archetypes fz = σ_val·apply·fy is binary×continuous, handled by the
    # NonConvex=2 setting already required for the energy bilinearities)
    for a in A, m in M, ti in T
        idx = σ_index(m, a)
        σ_val = idx !== nothing ? σ_vals[idx] : 0.0
        if HIST_ON && ti <= T_HIST
            σ_val = σ_hist(m, a)   # pl12 D3: history rates, not the state's design
        end
        # Level 1b: the household only keeps σ × (1 − clawback); fz is the
        # RECEIVED subsidy fraction (drives liquidity, private cost, and the
        # affordability check). The leader's spending stays at the nominal σ
        # and is computed separately (z_leader). clawback_of ≡ 0 for rented
        # archetypes (landlords face no household tax/benefit clawback).
        σ_val *= (1 - clawback_of(a))
        if y_upper[a,m,ti] > 0.001 && cls_m[m] != "pv" && get_subsidy_cap(m, a) > 0 &&
           (SC.subsidy_horizon_end === nothing || end_year[ti] <= SC.subsidy_horizon_end)
            if is_rented(a)
                @constraint(fmodel, fz[a,m,ti] == σ_val * apply_sub[a,ti] * fy[a,m,ti])
            else
                @constraint(fmodel, fz[a,m,ti] == σ_val * fy[a,m,ti])
            end
        else
            @constraint(fmodel, fz[a,m,ti] == 0)
        end
    end

    # Liquidity (annual cap × period years = budget available within the
    # period). Skipped where the cap is Inf (private landlords, plan §4).
    for a in A, ti in T
        isfinite(cap_a[a]) || continue
        (HIST_ON && ti <= T_HIST) && continue   # pl12: history adoption is data, not a budget choice
        @constraint(fmodel,
            sum(inv_cost(a,m,ti) * (fy[a,m,ti] - fz[a,m,ti]) for m in M) <= cap_a[a] * period_length[ti])
    end

    # Level 2: annual rent increase per rented archetype (average dwelling).
    # The landlord may charge up to pass_through_rate × cumulative ELIGIBLE
    # investment (energy-related investment NET of subsidy received — grants
    # deducted before pass-through), capped at rent_increase_cap_per_m2 × area.
    # The objective rewards rent income, so rent_inc sits at the smaller of
    # the two bounds in any optimal solution. Aggregation note: both the
    # pass-through base and the cap are applied at the archetype-average
    # level, the same convention the model uses for liquidity.
    @variable(fmodel, rent_inc[a in A_RENTED, ti in T] >= 0)
    # pv_in_passthrough_base=false removes PV capex from the eligible base
    # (S2 diagnostic: is the ρ=0.05 uptake spike PV base-pumping?); default
    # true = German §559 reading, all modernisation eligible.
    M_PT_BASE = SC.pv_in_passthrough_base ? M : [m for m in M if cls_m[m] != "pv"]
    # passthrough_base_net_of_grants=false keeps the GROSS investment in the
    # base (S4 sensitivity on the interpretive Polish reading — Art. 8a(4b)
    # "outlays borne by the owner"); true (default) deducts received grants
    # (fz), the committed German grant-deduction behaviour.
    # levy_coverage pro-rates each vintage τ's contribution by how much of
    # period ti its levy window still covers (≡ 1 under "permanent").
    PT_NET = SC.passthrough_base_net_of_grants
    for a in A_RENTED, ti in T
        @constraint(fmodel, rent_inc[a,ti] <=
            pass_through_of(a) * sum(levy_coverage(τ, ti, a) * inv_cost(a,m,τ) *
                (PT_NET ? fy[a,m,τ] - fz[a,m,τ] : fy[a,m,τ] + 0.0 * fz[a,m,τ])
                for m in M_PT_BASE, τ in 1:ti))
        @constraint(fmodel, rent_inc[a,ti] <= SC.rent_increase_cap_per_m2 * fa_a[a])
    end

    # Multiplicative energy model: E = base * (1-r_env) * (1-r_hvac) * (1-r_pv)
    # Aggregate reduction per class (linear in fs)
    @variable(fmodel, 0 <= r_env[a in A, ti in T] <= r_env_max_val)
    @variable(fmodel, 0 <= r_hvac[a in A, ti in T] <= r_hvac_max_val)
    @variable(fmodel, 0 <= r_pv[a in A, ti in T] <= r_pv_max_val)

    @constraint(fmodel, [a in A, ti in T],
        r_env[a,ti] == sum(redfac_amt[a,m,ti] * fs[a,m,ti] for m in M_env))
    @constraint(fmodel, [a in A, ti in T],
        r_hvac[a,ti] == sum(redfac_amt[a,m,ti] * fs[a,m,ti] for m in M_hvac))
    @constraint(fmodel, [a in A, ti in T],
        r_pv[a,ti] == sum(redfac_m[m] * fs[a,m,ti] for m in M_pv))

    # Step 1: Energy after envelope (linear: base*(1-r_env))
    @variable(fmodel, 0 <= fE_env[a in A, ti in T] <= base_at[a,ti])
    @constraint(fmodel, [a in A, ti in T],
        fE_env[a,ti] == base_at[a,ti] * (1 - r_env[a,ti]))

    # Step 2: Energy after HVAC (bilinear: fE_env * (1-r_hvac))
    @variable(fmodel, 0 <= fE_hvac[a in A, ti in T] <= base_at[a,ti])
    @constraint(fmodel, [a in A, ti in T],
        fE_hvac[a,ti] == fE_env[a,ti] * (1 - r_hvac[a,ti]))

    # Step 3: Final energy (bilinear: fE_hvac * (1-r_pv))
    @constraint(fmodel, [a in A, ti in T],
        fE[a,ti] == fE_hvac[a,ti] * (1 - r_pv[a,ti]))

    # Carrier-specific energy decomposition for fuel cost
    # fE_ep = energy after envelope + PV, before HVAC carrier split
    @variable(fmodel, 0 <= fE_ep[a in A, ti in T] <= base_at[a,ti])
    @constraint(fmodel, [a in A, ti in T],
        fE_ep[a,ti] == fE_env[a,ti] * (1 - r_pv[a,ti]))

    # Energy × carrier adoption share (bilinear, for fuel cost decomposition)
    @variable(fmodel, 0 <= fE_ep_hp[a in A, ti in T] <= base_at[a,ti])
    @variable(fmodel, 0 <= fE_ep_dh[a in A, ti in T] <= base_at[a,ti])
    if idx_hp !== nothing
        @constraint(fmodel, [a in A, ti in T],
            fE_ep_hp[a,ti] == fE_ep[a,ti] * fs[a,idx_hp,ti])
    else
        @constraint(fmodel, [a in A, ti in T], fE_ep_hp[a,ti] == 0)
    end
    if idx_dist !== nothing
        @constraint(fmodel, [a in A, ti in T],
            fE_ep_dh[a,ti] == fE_ep[a,ti] * fs[a,idx_dist,ti])
    else
        @constraint(fmodel, [a in A, ti in T], fE_ep_dh[a,ti] == 0)
    end

    # Exclusivity (physical: only one renovation depth, only one HVAC system)
    @constraint(fmodel, [a in A, ti in T], sum(fs[a,m,ti] for m in M_env) <= 1.0)
    @constraint(fmodel, [a in A, ti in T], sum(fs[a,m,ti] for m in M_hvac) <= 1.0)

    # DH network coverage cap (Germany-wide ~14% coverage)
    if idx_dist !== nothing
        for a in A, ti in T
            if btype_a[a] == "SFH"
                @constraint(fmodel, fs[a, idx_dist, ti] <= SC.dh_cap_sfh)
            elseif btype_a[a] == "MFH"
                @constraint(fmodel, fs[a, idx_dist, ti] <= SC.dh_cap_mfh)
            end
        end
    end

    # Fossil-boiler ban — a SCENARIO since 2026-10-27 (fossil_boiler_ban,
    # default OFF; EPBD 2024/1275 phase-out AIM, no binding Polish ban).
    # When ON: boilers reaching end-of-life (avg 25 yr) must be replaced
    # with HP or DH from SC.ban_year (default 2040); before that, HVAC
    # switching is voluntary (subsidy-driven). Per-period minimum =
    # (remaining fossil fraction) × boiler break rate. All results
    # committed before 2026-10-27 carry this constraint ON.
    if SC.fossil_boiler_ban
        for a in A, ti in T
            if is_dh0_a[a]; continue; end   # already fossil-free (district heat incumbent)
            if years[ti] >= SC.ban_year  # ban applies from scenario ban year onward
                if ti == 1
                    @constraint(fmodel,
                        sum(fy[a,m,ti] for m in M_hvac) >= boiler_break[ti])
                else
                    @constraint(fmodel,
                        sum(fy[a,m,ti] for m in M_hvac) >=
                        (1 - sum(fs[a,m,ti-1] for m in M_hvac)) * boiler_break[ti])
                end
            end
        end
    end

    # EED Art. 6 (Directive (EU) 2023/1791): public-body renovation
    # obligation (2026-10-27, user order). Cumulative DEEP-envelope share of
    # each public-rental archetype ≥ 3%/yr of its floor area from 2026
    # (per-archetype share ≡ floor-area share within the archetype). A legal
    # obligation on the landlord → FOLLOWER constraint; the master omits it
    # (a pure follower RESTRICTION, so the master stays a valid relaxation —
    # the same argument as for the apply binary and the rent cap above).
    # SIMPLIFICATION, recorded: applied to ALL public-rental dwellings (the
    # 250 m² threshold and the possible social-housing exemption ignored).
    # 2026-10-27 decisions (1a)+(1b): the renovation standard is the nZEB
    # PROXY — a dwelling counts only with DEEP envelope AND a heat pump or
    # district-heat connection (Polish nZEB limit for multi-family: 65 kWh
    # primary/m²·yr, WT 2021; the proxy is not checked against 65 directly).
    # With archetype-level adoption fractions the joint share is not
    # tracked; CONVENTION (recorded): comonotone bundling — the nZEB share
    # is min(deep share, heating share), so BOTH components must reach the
    # requirement. DH incumbents satisfy the heating condition by
    # incumbency (their switching measures do not exist). The requirement
    # itself is capacity-clipped via eed_required_share (decision 1b).
    if SC.eed_public_obligation
        idx_deep = findfirst(i -> cls_m[i] == "envelope" && depth_m[i] == "deep", collect(M))
        idx_deep === nothing && error("eed_public_obligation: no deep envelope measure found")
        for a in A_RENTED, ti in T
            tenure_a[a] == "rented_public" || continue
            req = eed_required_share(a, ti)
            req <= 0.0 && continue
            @constraint(fmodel, fs[a, idx_deep, ti] >= req)
            if !is_dh0_a[a]
                @constraint(fmodel, sum(fs[a,m,ti] for m in M_hvac) >= req)
            end
        end
    end

    # Follower objective (carrier-specific fuel + CO₂ costs)
    # Investment: FULL capex at adoption, net of subsidy — the same convention
    # as the leader's spending (grant = σ × capex), so both levels price the
    # same investment identically. Recurring flows scale with period length.
    # Level 2: rented archetypes carry the LANDLORD's objective instead —
    # investment net of received subsidy + maintenance MINUS rent income;
    # the tenant pays the energy bill, so fuel and CO₂ do not enter (this is
    # the split incentive). Owner archetypes are byte-identical to before.
    @objective(fmodel, Min, sum(
        (is_rented(a) ?
            (
                sum(inv_cost(a,m,ti) * net_capex_factor[m,ti] * (fy[a,m,ti] - fz[a,m,ti]) for m in M)
                + period_length[ti] * (
                    sum(inv_cost(a,m,ti) * get(maintenance_rate, cls_m[m], 0.01) * fs[a,m,ti] for m in M)
                    - rent_inc[a,ti]
                    # Public-landlord tenant-cost weight (2026-10-27): + w ×
                    # (tenant energy bill + carbon cost + rent increase) —
                    # the same fuel/CO₂ terms as annual_bill, discounted the
                    # same way as the other landlord terms (disc_ll below).
                    # Built only when w > 0, so w = 0 adds a literal 0.0 and
                    # the objective stays bit-identical to the committed one.
                    # At w = 1 the rent increase cancels: −rent + w·rent = 0.
                    + (pubw_a[a] > 0.0 ? pubw_a[a] * (
                          (fE_ep[a,ti] * pfuel_at[a,ti] + fE_ep_hp[a,ti] * Δp_hp_at[a,ti] + fE_ep_dh[a,ti] * Δp_dh_at[a,ti]) * fa_a[a]
                        + (fE_ep[a,ti] - fE_ep_hp[a,ti] - fE_ep_dh[a,ti]) * fa_a[a] * co2_int_at[a,ti] * co2_price_per_ton[ti] / 1000
                        + rent_inc[a,ti]) : 0.0)
                    # w = 1 tie-break (decision 2026-10-27): rent_inc → 0
                    + (pubw_a[a] >= 1.0 ? RENT_TIEBREAK_EPS * rent_inc[a,ti] : 0.0)
                )
            )
        :
            (
                # Investment cost (full capex at adoption, net of subsidy;
                # net_capex_factor credits salvage value under residual_value lever)
                sum(inv_cost(a,m,ti) * net_capex_factor[m,ti] * (fy[a,m,ti] - fz[a,m,ti]) for m in M)
                + period_length[ti] * (
                    # Maintenance cost
                    sum(inv_cost(a,m,ti) * get(maintenance_rate, cls_m[m], 0.01) * fs[a,m,ti] for m in M)
                    # Carrier-specific fuel cost: base fuel price per archetype
                    # (p_gas for fossil-heated, p_dh for DH incumbents), switchers
                    # adjusted by Δp on their carrier fraction
                    + (fE_ep[a,ti] * pfuel_at[a,ti] + fE_ep_hp[a,ti] * Δp_hp_at[a,ti] + fE_ep_dh[a,ti] * Δp_dh_at[a,ti]) * fa_a[a]
                    # CO₂ cost (fossil fraction only — HP and DH have zero direct emissions)
                    + (fE_ep[a,ti] - fE_ep_hp[a,ti] - fE_ep_dh[a,ti]) * fa_a[a] * co2_int_at[a,ti] * co2_price_per_ton[ti] / 1000
                )
            )
        ) * fdisc(a, years[ti])   # per-archetype follower discounting
                                  # (2026-10-27): ≡ the committed
                                  # disc_ll/disc split at the defaults
        for a in A, ti in T
    ))
    # disc_ll ≡ disc unless landlord_discount_rate is set (sensitivity §3d):
    # landlords may discount their investment/maintenance/rent flows at a
    # different rate; owner archetypes always use the global rate.

    optimize!(fmodel)

    if termination_status(fmodel) != OPTIMAL
        return nothing
    end

    # Extract results
    y_sol = [value(fy[a,m,ti]) for a in A, m in M, ti in T]
    s_sol = [value(fs[a,m,ti]) for a in A, m in M, ti in T]
    z_sol = [value(fz[a,m,ti]) for a in A, m in M, ti in T]
    E_sol = [value(fE[a,ti]) for a in A, ti in T]
    Eep_sol   = [value(fE_ep[a,ti]) for a in A, ti in T]
    Eephp_sol = [value(fE_ep_hp[a,ti]) for a in A, ti in T]
    Eepdh_sol = [value(fE_ep_dh[a,ti]) for a in A, ti in T]
    obj_val = objective_value(fmodel)

    # Level 2: rent increase and subsidy-uptake decision per rented archetype
    # (zeros on owner rows, so downstream code can index generically)
    rent_sol  = zeros(length(A), length(T))
    apply_sol = zeros(length(A), length(T))
    for a in A_RENTED, ti in T
        rent_sol[a,ti]  = value(rent_inc[a,ti])
        apply_sol[a,ti] = round(value(apply_sub[a,ti]))
    end

    # Note: Duals not available for NonConvex QCQP (Benders cuts are
    # provably ineffective for this bilevel problem anyway)

    return (y=y_sol, s=s_sol, z=z_sol, E=E_sol,
            E_ep=Eep_sol, E_ep_hp=Eephp_sol, E_ep_dh=Eepdh_sol,
            rent=rent_sol, apply=apply_sol, obj=obj_val)
end

# =============================================================================
# 3) BUILD MASTER LP (High-Point Relaxation + Benders cuts)
# =============================================================================
println("\n" * "="^70)
println("BUILDING MASTER LP (High-Point Relaxation)")
println("="^70)

master = Model(Gurobi.Optimizer)
set_optimizer_attribute(master, "OutputFlag", 0)
set_optimizer_attribute(master, "Method", 2)
# pl11 (2026-11-06 brief, decision 7): P4_GRB_THREADS caps the Gurobi threads of
# every model in this process (the wrappers set 8 so parallel runs do not
# oversubscribe the machine). Unset = Gurobi default = committed behaviour.
if haskey(ENV, "P4_GRB_THREADS")
    set_optimizer_attribute(master, "Threads", parse(Int, ENV["P4_GRB_THREADS"]))
    println(">>> P4_GRB_THREADS=$(ENV["P4_GRB_THREADS"]): Gurobi thread limit applied to follower and master models <<<")
end

# --- Subsidy variables ---
@variable(master, 0 <= σ[i in 1:n_σ] <= σ_caps[i])

# Depth ordering constraints
# σ_keys indices: 1=env_light_poor, 2=env_medium_poor, 3=env_deep_poor,
#                 4=env_light_rich, 5=env_medium_rich, 6=env_deep_rich,
#                 7=hvac_std_poor, 8=hvac_upg_poor, 9=hvac_std_rich, 10=hvac_upg_rich
@constraint(master, σ[3] >= σ[1] + 0.10)  # deep_poor ≥ light_poor + 0.10
@constraint(master, σ[2] >= σ[1] + 0.05)  # medium_poor ≥ light_poor + 0.05
@constraint(master, σ[6] >= σ[4] + 0.10)  # deep_rich ≥ light_rich + 0.10
@constraint(master, σ[5] >= σ[4] + 0.05)  # medium_rich ≥ light_rich + 0.05

# --- Lower-level variables ---
@variable(master, 0 <= my[a in A, m in M, ti in T] <= y_upper[a, m, ti])
@variable(master, 0 <= ms[a in A, m in M, ti in T] <= 1)
@variable(master, 0 <= mz[a in A, m in M, ti in T] <= y_upper[a, m, ti])
# --- Multiplicative energy (McCormick relaxation) ---
# Reduction factor variables (linear in ms)
@variable(master, 0 <= mr_env[a in A, ti in T] <= r_env_max_val)
@variable(master, 0 <= mr_hvac[a in A, ti in T] <= r_hvac_max_val)
@variable(master, 0 <= mr_pv[a in A, ti in T] <= r_pv_max_val)

@constraint(master, [a in A, ti in T],
    mr_env[a,ti] == sum(redfac_amt[a,m,ti] * ms[a,m,ti] for m in M_env))
@constraint(master, [a in A, ti in T],
    mr_hvac[a,ti] == sum(redfac_amt[a,m,ti] * ms[a,m,ti] for m in M_hvac))
@constraint(master, [a in A, ti in T],
    mr_pv[a,ti] == sum(redfac_m[m] * ms[a,m,ti] for m in M_pv))

# Step 1: Energy after envelope (LINEAR: base*(1-mr_env))
@variable(master, mE_env[a in A, ti in T])
for a in A, ti in T
    set_lower_bound(mE_env[a,ti], base_at[a,ti] * (1 - r_env_max_val))
    set_upper_bound(mE_env[a,ti], base_at[a,ti])
end
@constraint(master, [a in A, ti in T],
    mE_env[a,ti] == base_at[a,ti] * (1 - mr_env[a,ti]))

# Step 2: Energy after HVAC — McCormick for mE_hvac = mE_env * (1 - mr_hvac)
@variable(master, mE_hvac[a in A, ti in T])
for a in A, ti in T
    B = base_at[a,ti]
    set_lower_bound(mE_hvac[a,ti], B * (1-r_env_max_val) * (1-r_hvac_max_val))
    set_upper_bound(mE_hvac[a,ti], B)
end
for a in A, ti in T
    B = base_at[a,ti]
    xL = B * (1 - r_env_max_val)
    xU = B
    rH = r_hvac_max_val
    wL = 1 - rH
    @constraint(master, mE_hvac[a,ti] >= xL*rH - xL*mr_hvac[a,ti] + mE_env[a,ti]*wL)
    @constraint(master, mE_hvac[a,ti] >= mE_env[a,ti] - xU*mr_hvac[a,ti])
    @constraint(master, mE_hvac[a,ti] <= xU*rH - xU*mr_hvac[a,ti] + mE_env[a,ti]*wL)
    @constraint(master, mE_hvac[a,ti] <= mE_env[a,ti] - xL*mr_hvac[a,ti])
end

# Step 3: Final energy — McCormick for mE = mE_hvac * (1 - mr_pv)
@variable(master, mE[a in A, ti in T])
for a in A, ti in T
    B = base_at[a,ti]
    set_lower_bound(mE[a,ti], B * (1-r_env_max_val) * (1-r_hvac_max_val) * (1-r_pv_max_val))
    set_upper_bound(mE[a,ti], B)
end
for a in A, ti in T
    B = base_at[a,ti]
    xL2 = B * (1-r_env_max_val) * (1-r_hvac_max_val)
    xU2 = B
    rP = r_pv_max_val
    wL2 = 1 - rP
    @constraint(master, mE[a,ti] >= xL2*rP - xL2*mr_pv[a,ti] + mE_hvac[a,ti]*wL2)
    @constraint(master, mE[a,ti] >= mE_hvac[a,ti] - xU2*mr_pv[a,ti])
    @constraint(master, mE[a,ti] <= xU2*rP - xU2*mr_pv[a,ti] + mE_hvac[a,ti]*wL2)
    @constraint(master, mE[a,ti] <= mE_hvac[a,ti] - xL2*mr_pv[a,ti])
end

# --- Follower feasibility constraints ---
# State dynamics
@constraint(master, [a in A, m in M], ms[a,m,1] == my[a,m,1])
@constraint(master, [a in A, m in M, ti in 2:n_years],
    ms[a,m,ti] == ms[a,m,ti-1] + my[a,m,ti])
if HIST_ON   # pl12 D1 mirror
    for a in A, m in M, ti in 1:T_HIST
        hist_fixed[a, m] && @constraint(master, my[a,m,ti] == y_hist[a,m,ti])
    end
end

# HVAC precedence (mirror of the follower rule; kept, see there)
@constraint(master, [a in A, ti in T],
    sum(ms[a,m,ti] for m in M_hvac) <= sum(ms[a,m,ti] for m in M_env) + 0.3)

# HVAC compatibility
for a in A, m in M, ti in T
    if !hvac_compatible[a, m]
        @constraint(master, my[a,m,ti] == 0)
    end
end

# Per-class adoption rate caps + joint labor cap (mirrors follower)
@constraint(master, [a in A, ti in T; !hist_class_fixed("envelope", ti)], sum(my[a,m,ti] for m in M_env) <= adopt_cap_env[ti])
@constraint(master, [a in A, ti in T; !hist_class_fixed("hvac", ti)], sum(my[a,m,ti] for m in M_hvac) <= adopt_cap_hvac[ti])
@constraint(master, [a in A, ti in T], sum(my[a,m,ti] for m in M_pv) <= adopt_cap_pv[ti])
@constraint(master, [a in A, ti in T; !(hist_class_fixed("envelope", ti) && hist_class_fixed("hvac", ti))],
    sum(W_CLS[cls_m[m]] * my[a,m,ti] for m in M) <= adopt_cap_joint[ti])

# McCormick (σ is a VARIABLE here — but constraints are LINEAR in σ and z)
for a in A, m in M, ti in T
    if y_upper[a,m,ti] > 0.001 && cls_m[m] != "pv"
        idx = σ_index(m, a)
        σ_max = get_subsidy_cap(m, a)
        ȳ = y_upper[a, m, ti]
        if HIST_ON && ti <= T_HIST
            @constraint(master, mz[a,m,ti] == σ_hist(m, a) * my[a,m,ti])   # pl12: history rates
        elseif SC.subsidy_horizon_end !== nothing && end_year[ti] > SC.subsidy_horizon_end
            # Subsidy horizon (2026-10-27): mirror the follower — no subsidy
            # product after the horizon
            @constraint(master, mz[a,m,ti] == 0)
        elseif idx !== nothing && σ_max > 0
            @constraint(master, mz[a,m,ti] <= σ_max * my[a,m,ti])
            @constraint(master, mz[a,m,ti] <= σ[idx] * ȳ)          # LINEAR: σ[idx] * constant
            @constraint(master, mz[a,m,ti] >= σ[idx] * ȳ + σ_max * (my[a,m,ti] - ȳ))
        else
            @constraint(master, mz[a,m,ti] == 0)
        end
    elseif cls_m[m] == "pv"
        @constraint(master, mz[a,m,ti] == 0)
    end
end

# Liquidity (annual cap × period years — mirrors follower; skipped where the
# cap is Inf, i.e. private landlords). Level 2 note: the master omits the
# landlord apply binary and the rent-increase cap — both only RESTRICT the
# follower's choices, so the master remains a valid relaxation (its LB holds).
for a in A, ti in T
    isfinite(cap_a[a]) || continue
    @constraint(master,
        sum(inv_cost(a,m,ti) * (my[a,m,ti] - mz[a,m,ti]) for m in M) <= cap_a[a] * period_length[ti])
end

# (Energy is now defined via McCormick relaxation above — no additive constraint)

# --- Upper-level constraints ---
# Envelope exclusivity
@constraint(master, [a in A, ti in T], sum(ms[a,m,ti] for m in M_env) <= 1.0)
# HVAC exclusivity
@constraint(master, [a in A, ti in T], sum(ms[a,m,ti] for m in M_hvac) <= 1.0)

# DH network coverage cap (Germany-wide ~14% coverage)
if idx_dist !== nothing
    for a in A, ti in T
        if btype_a[a] == "SFH"
            @constraint(master, ms[a, idx_dist, ti] <= SC.dh_cap_sfh)
        elseif btype_a[a] == "MFH"
            @constraint(master, ms[a, idx_dist, ti] <= SC.dh_cap_mfh)
        end
    end
end

# Fossil-boiler ban, master mirror of the follower constraint — a SCENARIO
# since 2026-10-27 (fossil_boiler_ban, default OFF; see the follower block)
if SC.fossil_boiler_ban
    for a in A, ti in T
        if is_dh0_a[a]; continue; end   # already fossil-free (district heat incumbent)
        if years[ti] >= SC.ban_year
            if ti == 1
                @constraint(master,
                    sum(my[a,m,ti] for m in M_hvac) >= boiler_break[ti])
            else
                @constraint(master,
                    sum(my[a,m,ti] for m in M_hvac) >=
                    (1 - sum(ms[a,m,ti-1] for m in M_hvac)) * boiler_break[ti])
            end
        end
    end
end

# Total public spending
TotalPublic = @expression(master,
    sum(inv_cost(a,m,ti) * mz[a,m,ti] * disc(years[ti]) * dwell_a[a]
        for a in A, m in M, ti in T_LEADER:length(T)))   # pl12 D7: from the design start

# Equity
PublicLow = @expression(master,
    sum(lowmask_a[a] * inv_cost(a,m,ti) * mz[a,m,ti] * disc(years[ti]) * dwell_a[a]
        for a in A, m in M, ti in T_LEADER:length(T)))
@constraint(master, PublicLow >= equity_min_eff * TotalPublic)

# WPB
# pl12 D7: savings counted from the design start, relative to the state at the end of the history
TotalSav = @expression(master, sum(((T_LEADER == 1 ? base_a[a] : mE[a,T_LEADER-1]) - mE[a,ti]) * fa_a[a] * dwell_a[a] for a in A, ti in T_LEADER:length(T)))
WPBSav = @expression(master, sum(wpbmask_a[a] * ((T_LEADER == 1 ? base_a[a] : mE[a,T_LEADER-1]) - mE[a,ti]) * fa_a[a] * dwell_a[a] for a in A, ti in T_LEADER:length(T)))
@constraint(master, WPBSav >= 0.55 * TotalSav)

# --- Carrier-weighted primary energy (linear in carrier splits) ---
# Mirrors the follower's exact decomposition: E_primary = PEF_f·E_ep −
# c_prim_hp·E_ep_hp − c_prim_dh·E_ep_dh, with E_ep = mE_env·(1−mr_pv) and
# E_ep_hp/dh = carrier share × E_ep. Only the two share×energy products need
# McCormick; the primary-energy formula itself is linear (no E×PEF product).

# mE_ep = mE_env * (1 − mr_pv)  (McCormick)
@variable(master, mE_ep[a in A, ti in T])
for a in A, ti in T
    B = base_at[a,ti]
    xL = B * (1 - r_env_max_val); xU = B
    wL = 1 - r_pv_max_val;        wU = 1.0
    set_lower_bound(mE_ep[a,ti], xL * wL)
    set_upper_bound(mE_ep[a,ti], xU * wU)
    @constraint(master, mE_ep[a,ti] >= xL*(1 - mr_pv[a,ti]) + mE_env[a,ti]*wL - xL*wL)
    @constraint(master, mE_ep[a,ti] >= xU*(1 - mr_pv[a,ti]) + mE_env[a,ti]*wU - xU*wU)
    @constraint(master, mE_ep[a,ti] <= xU*(1 - mr_pv[a,ti]) + mE_env[a,ti]*wL - xU*wL)
    @constraint(master, mE_ep[a,ti] <= xL*(1 - mr_pv[a,ti]) + mE_env[a,ti]*wU - xL*wU)
end

# Carrier splits: mE_ep_hp = mE_ep·s_hp, mE_ep_dh = mE_ep·s_dh  (McCormick)
@variable(master, mE_ep_hp[a in A, ti in T] >= 0)
@variable(master, mE_ep_dh[a in A, ti in T] >= 0)
for a in A, ti in T
    B = base_at[a,ti]
    xL = B * (1 - r_env_max_val) * (1 - r_pv_max_val)
    xU = B
    # heat pump split (share ∈ [0,1])
    if idx_hp !== nothing
        s_hp = ms[a, idx_hp, ti]
        set_upper_bound(mE_ep_hp[a,ti], xU)
        @constraint(master, mE_ep_hp[a,ti] >= xL*s_hp)
        @constraint(master, mE_ep_hp[a,ti] >= xU*s_hp + mE_ep[a,ti] - xU)
        @constraint(master, mE_ep_hp[a,ti] <= xU*s_hp)
        @constraint(master, mE_ep_hp[a,ti] <= xL*s_hp + mE_ep[a,ti] - xL)
    else
        @constraint(master, mE_ep_hp[a,ti] == 0)
    end
    # district heat split (share ∈ [0, DH coverage cap])
    if idx_dist !== nothing
        s_dh = ms[a, idx_dist, ti]
        sU = btype_a[a] == "SFH" ? 0.30 : 0.50
        set_upper_bound(mE_ep_dh[a,ti], xU * sU)
        @constraint(master, mE_ep_dh[a,ti] >= xL*s_dh)
        @constraint(master, mE_ep_dh[a,ti] >= xU*s_dh + sU*mE_ep[a,ti] - xU*sU)
        @constraint(master, mE_ep_dh[a,ti] <= xU*s_dh)
        @constraint(master, mE_ep_dh[a,ti] <= xL*s_dh + sU*mE_ep[a,ti] - xL*sU)
    else
        @constraint(master, mE_ep_dh[a,ti] == 0)
    end
end

# Primary energy intensity — LINEAR, no McCormick needed
# (period-dependent coefficients; per-archetype base PEF for DH incumbents)
@expression(master, mE_primary[a in A, ti in T],
    pef_base_at(a, ti) * mE_ep[a,ti] - c_prim_hp_at[a,ti] * mE_ep_hp[a,ti] - c_prim_dh_at[a,ti] * mE_ep_dh[a,ti])

# EPBD 2050 (using carrier-dependent primary energy)
if TI2050 !== nothing
    Num2050 = @expression(master, sum(mE_primary[a,TI2050] * fa_a[a] * dwell_a[a] for a in A))
    @constraint(master, Num2050 <= epbd_target * total_area)
end

# EPBD trajectory (map target year → period via end_year)
for (k, yr) in enumerate(traj_years)
    tidx = get(end_t_idx, yr, nothing)
    if tidx !== nothing
        Num_t = @expression(master, sum(mE_primary[a,tidx] * fa_a[a] * dwell_a[a] for a in A))
        @constraint(master, Num_t <= traj_values[k] * total_area)
    end
end

# --- Valid inequalities ---
# Temporal dominance
for a in A, m in M, ti in 2:n_years
    @constraint(master, ms[a,m,ti] >= ms[a,m,ti-1])
end
# Energy monotonicity
for a in A, ti in 2:n_years
    @constraint(master, mE[a,ti] <= mE[a,ti-1])
end
# (Energy savings cap removed — redundant with multiplicative McCormick bounds)
# NOTE (Jul 2026): two former "tightenings" removed as mathematically invalid:
#  - "Σ ms_env ≥ 0.3 by 2050" was an unproven guess (HP+PV alone can satisfy
#    the aggregate EPBD constraint), so the master was not a true relaxation.
#  - EXPLICIT_LB hand-estimate (€6.01M) was binding and masqueraded as the
#    relaxation bound; it double-counted mutually exclusive measures and
#    ignored discounting. The LB reported now is the honest HPR bound.

# Liquidity-based y tightening (per-period)
for a in A, m in M, ti in T
    if y_upper[a,m,ti] > 0 && cls_m[m] != "pv"
        inv = inv_cost(a, m, ti)
        max_sub = get_subsidy_cap(m, a)
        min_pay = 1 - max_sub
        if min_pay > 0.001
            tighter = min(y_upper[a,m,ti], cap_a[a] * period_length[ti] / (inv * min_pay))
            if tighter < y_upper[a,m,ti] - 0.001
                set_upper_bound(my[a,m,ti], tighter)
            end
        end
    end
end

# Objective (follower optimality enforced by σ-search, not Benders cuts)
@objective(master, Min, TotalPublic)

n_master_vars = num_variables(master)
n_master_cons = sum(num_constraints(master, F, S) for (F, S) in list_of_constraint_types(master))
println("  Master LP: $(n_master_vars) variables, $(n_master_cons) constraints")

# =============================================================================
# 4) BILEVEL SEARCH (HPR bound + σ-space coordinate descent)
#
# Strategy:
#   Phase 1: Solve HPR master → lower bound on public spending
#   Phase 2: Evaluate multiple σ candidates → find initial feasible solution
#   Phase 3: Coordinate descent → reduce each σ_i to minimum feasible value
#   Phase 4: Random perturbation → escape local optima
#
# Each follower LP (~200 vars) solves in milliseconds, so we can
# evaluate hundreds of σ candidates cheaply.
# =============================================================================

# --- Utility functions ---

# Carrier-weighted primary energy intensity per m² (kWh/m² primary).
# Linear in the follower's carrier splits — the exact stock-mix accounting,
# NOT the (avg energy)×(avg PEF) product, which understates primary energy
# at mixed adoption (the low-PEF buildings are also the low-energy ones).
function primary_intensity(fr, a::Int, ti::Int)
    return pef_base_at(a, ti) * fr.E_ep[a,ti] -
           c_prim_hp_at[a,ti] * fr.E_ep_hp[a,ti] - c_prim_dh_at[a,ti] * fr.E_ep_dh[a,ti]
end

# =============================================================================
# Level 1a: OUTCOME-BASED AFFORDABILITY (plan §2)
# Annual housing energy cost of a POOR household after the programme must not
# exceed a threshold. Cost = energy bill (fuel + CO₂ at that period's prices)
# + annualised own contribution (capex net of subsidy, annuitised over the
# measure lifetime, counted while the annuity is still running).
# Maintenance is NOT included — the plan defines exactly these two terms.
# The check is leader-side only: it never changes the follower problem.
# =============================================================================

# Annual energy bill per dwelling (EUR/yr) at the follower's chosen state —
# the same fuel and CO₂ terms as the follower objective, per year (no period scaling)
function annual_bill(fr, a::Int, ti::Int)
    fuel = (fr.E_ep[a,ti] * pfuel_at[a,ti] + fr.E_ep_hp[a,ti] * Δp_hp_at[a,ti] + fr.E_ep_dh[a,ti] * Δp_dh_at[a,ti]) * fa_a[a]
    co2  = (fr.E_ep[a,ti] - fr.E_ep_hp[a,ti] - fr.E_ep_dh[a,ti]) * fa_a[a] *
           co2_int_at[a,ti] * co2_price_per_ton[ti] / 1000
    return fuel + co2
end

# Annualised own contribution per dwelling (EUR/yr): annuity on the household's
# own share of each adopted measure, counted only while the annuity is running
# (adoption year + lifetime still beyond the period's evaluation year)
function own_annualised(fr, a::Int, ti::Int)
    tot = 0.0
    for m in M, τ in 1:ti
        if years[τ] + lifetime_m[m] > end_year[ti]
            tot += ann_m[m] * inv_cost(a, m, τ) * (fr.y[a,m,τ] - fr.z[a,m,τ])
        end
    end
    return tot
end

# Reference ("no-programme") annual heating cost per dwelling and period.
# frozen_stock: the un-renovated building at same-period prices (warm-rent-
#   neutrality reading of Domenig et al. Eq. 5).
# zero_subsidy: the follower's own response at σ = 0 — households still react
#   to the CO₂ price and the boiler ban; their full capex is own contribution.
const AFFORD_REF_CACHE = Dict{String,Matrix{Float64}}()
function reference_costs_for(kind::String)
    if !haskey(AFFORD_REF_CACHE, kind)
        ref = zeros(length(A), length(T))
        if kind == "frozen_stock"
            for a in A, ti in T
                ref[a,ti] = base_at[a,ti] * pfuel_at[a,ti] * fa_a[a] +
                            base_at[a,ti] * fa_a[a] * co2_int_at[a,ti] * co2_price_per_ton[ti] / 1000
            end
        else  # zero_subsidy
            fr0 = solve_follower(zeros(n_σ))
            fr0 === nothing && error("affordability reference: follower failed at σ = 0")
            for a in A, ti in T
                ref[a,ti] = housing_cost_after(fr0, a, ti)
            end
        end
        AFFORD_REF_CACHE[kind] = ref
    end
    return AFFORD_REF_CACHE[kind]
end
affordability_reference_costs() = reference_costs_for(SC.affordability_reference)

const A_POOR = [a for a in A if inc_a[a] == "poor"]
const AFFORD_TOL_EUR = 1e-6   # numerical slack on cost comparisons (EUR/yr)

# Reporting group of an archetype (Figure 2, Table 3): owners by income,
# rented archetypes by landlord type; the rich private tenant (2026-10-08)
# is its own reporting group (same landlord, indicator-only affordability)
tenure_group(a::Int) = is_rented(a) ?
    (tenure_a[a] == "rented_private" && inc_a[a] == "rich" ?
        "rented_private_rich" : tenure_a[a]) :
    (inc_a[a] == "poor" ? "owner_poor" : "owner_rich")

# Household income of an archetype's DECIDING-or-PAYING household: the
# owner for owner rows, the tenant for rented rows (SOURCED GUS 2024)
income_of(a::Int) = inc_a[a] == "poor" ?
    Float64(SC.household_income_by_class.poor) :
    Float64(SC.household_income_by_class.rich)

# Footnote carried by every tenure output (user request 2026-10-01 (c),
# status updated 2026-10-08 after the source notes):
const TENURE_FOOTNOTE = "Rent rule: Polish Art. 8a (rule_PL, sourced 2026-10-08) " *
    "is the DEFAULT since 2026-10-09; German §559 values only where a " *
    "scenario pins rule_DE explicitly. Incomes sourced (GUS HBS 2024 tables, wave 9: " *
    "low-income = Q1 EUR 9,635; high-income = Q2-Q5 mean EUR 23,761, weighted by " *
    "household count prop. 1/size). Public-landlord share sourced (GUS 2024 / Census 2021; TBS part " *
    "approximate); private rental share 0.08 DERIVED (Eurostat ilc_lvho02 x GUS " *
    "x Census 2021; assumes market-rent tenants live in MFH); tenant split 0.16/0.84 " *
    "AROP-based, not quintile-based (Eurostat EU-SILC). Public landlord rate 0.02 open."

# Annual housing energy cost per dwelling after the programme (EUR/yr).
# Owner-occupier: energy bill + annualised own contribution (Level 1a).
# Tenant (Level 2): energy bill at the landlord's chosen building state +
# the rent increase — the tenant decides nothing and pays no capex.
housing_cost_after(fr, a::Int, ti::Int) = is_rented(a) ?
    annual_bill(fr, a, ti) + fr.rent[a,ti] :
    annual_bill(fr, a, ti) + own_annualised(fr, a, ti)

# Per-archetype affordability record for one follower solution.
# Returned for ALL poor archetypes regardless of mode, so the reporting can
# always say "would this design have passed"; enforcement is mode-gated.
# Periods the constraint is enforced in: every period, or only the period
# ending 2050 ("final" — used for income_share, which addresses the end state)
afford_checked_periods() = SC.affordability_periods == "final" ?
    [TI2050 === nothing ? length(T) : TI2050] : collect(T)

# Rows are produced for every poor archetype AND for rich TENANTS
# (2026-10-08: the rich private tenant is reported — cost change and
# cost-to-income share — but never enforced; see afford_in_scope).
const A_AFFORD_REPORT = sort(vcat(A_POOR,
    [a for a in A if is_rented(a) && inc_a[a] == "rich"]))

function affordability_details(fr)
    ref = affordability_reference_costs()
    checked = afford_checked_periods()
    rows = NamedTuple[]
    for a in A_AFFORD_REPORT
        cost_after = [housing_cost_after(fr, a, ti) for ti in T]
        if SC.affordability_mode == "income_share"
            # per-archetype income: the rich tenant's indicator uses the
            # rich income (enforcement is poor-only via afford_in_scope)
            limit = [SC.affordability_income_share * income_of(a) for ti in T]
        else  # cost_neutral thresholds (also reported when mode is off)
            limit = [SC.affordability_tolerance * ref[a,ti] for ti in T]
        end
        ok = all(cost_after[ti] <= limit[ti] + AFFORD_TOL_EUR for ti in checked)
        push!(rows, (a=a, cost_after=cost_after, cost_ref=[ref[a,ti] for ti in T],
                     own_ann=[is_rented(a) ? 0.0 : own_annualised(fr, a, ti) for ti in T],
                     rent_inc=[is_rented(a) ? fr.rent[a,ti] : 0.0 for ti in T],
                     bill_after=[annual_bill(fr, a, ti) for ti in T],
                     limit=limit, ok=ok))
    end
    return rows
end

# Aggregate verdict: (constraint satisfied for every poor archetype IN SCOPE,
# stock-weighted share of poor households in violating in-scope archetypes).
# All archetypes are always REPORTED via rows; enforcement respects
# affordability_scope ("owners_and_public_tenants" leaves the private-rental
# tenant out of the verdict — D5x).
# Rich tenants are NEVER enforced (2026-10-08 decision: the constraint
# applies to poor tenants only; rich rows are indicators). The scope key
# then decides whether poor PRIVATE tenants are enforced (D5x excludes).
afford_in_scope(a::Int) = !(is_rented(a) && inc_a[a] == "rich") &&
    (SC.affordability_scope == "all" ||
     !(is_rented(a) && tenure_a[a] == "rented_private"))
function affordability_check(fr)
    rows = affordability_details(fr)
    total_poor = sum(dwell_a[a] for a in A_POOR if afford_in_scope(a); init=0.0)
    viol = sum(dwell_a[r.a] for r in rows if afford_in_scope(r.a) && !r.ok; init=0.0)
    return (ok=all(r.ok for r in rows if afford_in_scope(r.a)),
            viol_share=total_poor > 0 ? viol / total_poor : 0.0, rows=rows)
end

# Leader's grant fraction per unit stock for (a,m,ti): nominal σ × adoption
# (× (1 − clawback) only under clawback_returns_to_budget). This is what
# public spending counts; fr.z is what the household RECEIVES — the two
# coincide exactly when clawback is zero.
function z_leader(σ_vals, fr, a::Int, m::Int, ti::Int)
    idx = σ_index(m, a)
    (idx === nothing || get_subsidy_cap(m, a) <= 0) && return 0.0
    # Subsidy horizon (2026-10-27): no payment for adoption after it
    SC.subsidy_horizon_end !== nothing && end_year[ti] > SC.subsidy_horizon_end && return 0.0
    years[ti] < SUB_START && return 0.0   # pl12 D7: history is not the state's spending
    # Level 2: for rented archetypes the state pays exactly what the landlord
    # receives — no household clawback, and nothing when the landlord chose
    # not to apply — which is the follower's fz value.
    is_rented(a) && return fr.z[a,m,ti]
    return σ_vals[idx] * leader_rate_factor(a) * fr.y[a,m,ti]
end

# pl12 D7: reference state for the WPB savings — the 2020 base, or the state at
# the end of the fixed history when the design starts later
E_sav_ref(fr, a::Int) = T_LEADER == 1 ? base_a[a] : fr.E[a, T_LEADER-1]
function evaluate_σ(σ_vals)
    fr = solve_follower(σ_vals)
    if fr === nothing
        return (ub=Inf, feasible=false, result=nothing, E2050=NaN, equity=NaN, wpb=NaN,
                traj_ok=false, E_primary=Float64[], afford_ok=false, afford_viol=NaN)
    end

    ub = sum(inv_cost(a,m,ti) * z_leader(σ_vals,fr,a,m,ti) * disc(years[ti]) * dwell_a[a] for a in A, m in M, ti in T)
    pub_low = sum(lowmask_a[a] * inv_cost(a,m,ti) * z_leader(σ_vals,fr,a,m,ti) * disc(years[ti]) * dwell_a[a] for a in A, m in M, ti in T)
    equity = ub > 0 ? pub_low / ub : NaN
    equity_ok = isnan(equity) || equity >= equity_min_eff - 1e-6   # 2026-11-07 (D10): strict floor; was 0.001

    total_sav = sum((E_sav_ref(fr, a) - fr.E[a,ti]) * fa_a[a] * dwell_a[a] for a in A, ti in T_LEADER:length(T))
    wpb_sav = sum(wpbmask_a[a] * (E_sav_ref(fr, a) - fr.E[a,ti]) * fa_a[a] * dwell_a[a] for a in A, ti in T_LEADER:length(T))
    wpb = total_sav > 0 ? wpb_sav / total_sav : NaN
    wpb_ok = isnan(wpb) || wpb >= 0.55 - 0.001

    # Carrier-dependent primary energy per period (exact carrier-weighted)
    E_primary = [sum(primary_intensity(fr, a, ti) * fa_a[a] * dwell_a[a]
                     for a in A) / total_area for ti in T]

    # EPBD 2050 check
    E2050 = TI2050 !== nothing ? E_primary[TI2050] : 0.0
    epbd_ok = E2050 <= epbd_target + 0.1

    # EPBD trajectory check (all milestones — map via end_year)
    traj_ok = true
    for (k, yr) in enumerate(traj_years)
        tidx = get(end_t_idx, yr, nothing)
        if tidx !== nothing && E_primary[tidx] > traj_values[k] + 0.1
            traj_ok = false
        end
    end

    # Level 1a: affordability check (leader-side feasibility on the poor's
    # outcome; enforced only when the mode is on — subset property holds by
    # construction because the check can only remove feasible points)
    afford = affordability_check(fr)
    afford_binding = SC.affordability_mode != "off"
    afford_ok = !afford_binding || afford.ok

    feasible = equity_ok && wpb_ok && epbd_ok && traj_ok && afford_ok
    return (ub=ub, feasible=feasible, result=fr, E2050=E2050, equity=equity, wpb=wpb,
            traj_ok=traj_ok, E_primary=E_primary,
            afford_ok=afford.ok, afford_viol=afford.viol_share)
end

function enforce_ordering!(σv)
    # PLAIN depth ordering since 2026-10-27 (user decision): deep ≥ medium ≥
    # light, ZERO allowed everywhere. The previous rule (medium ≥ light+0.05,
    # deep ≥ light+0.10) acted as an absolute 5%/10% FLOOR on medium/deep at
    # light = 0 — every result committed before this date is a CONDITIONAL
    # optimum subject to that floor (recorded in the CHANGELOG; nothing
    # re-certified).
    σv[2] = max(σv[2], σv[1])   # medium_poor ≥ light_poor
    σv[3] = max(σv[3], σv[2])   # deep_poor ≥ medium_poor
    σv[5] = max(σv[5], σv[4])   # medium_rich ≥ light_rich
    σv[6] = max(σv[6], σv[5])   # deep_rich ≥ medium_rich
    for i in 1:n_σ
        σv[i] = clamp(σv[i], 0.0, σ_caps[i])
    end
    return σv
end

function σ_lower_bound(i, σ_ref)
    # 2026-11-08 (review housekeeping, methods F1): aligned with the PLAIN
    # ordering of enforce_ordering! (deep >= medium >= light). The previous
    # +0.05/+0.10 offsets were the superseded "spread" rule of before
    # 2026-10-27 and kept the binary search from lowering medium below
    # light + 5 pp (the record design has light = medium = 42.9 %, which only
    # the proof could reach). Searches before this date carried the offsets.
    i == 2 && return σ_ref[1]
    i == 3 && return σ_ref[2]
    i == 5 && return σ_ref[4]
    i == 6 && return σ_ref[5]
    return 0.0
end

# Test hook: with P4_SKIP_SEARCH=1 the file loads all data and functions but
# skips the CCG search and reporting (test_tenure.jl calls solve_follower
# directly per scenario). Top-level `if` adds no scope, so everything below
# stays global and behaves exactly as before when the variable is unset.
SKIP_SEARCH = get(ENV, "P4_SKIP_SEARCH", "0") == "1"
SKIP_SEARCH && println("\nP4_SKIP_SEARCH=1 — model loaded, CCG search skipped (test mode)")

if !SKIP_SEARCH

println("\n" * "="^70)
println("BILEVEL SEARCH")
println("="^70)

start_time = now()
# pl12: P4_FIXED_SIGMA=<file> evaluates ONE design (no search) and writes the
# full result folder (record dirs of proven designs; run_e1 pattern generalised)
FIXED_SIGMA_FILE = get(ENV, "P4_FIXED_SIGMA", nothing)
if FIXED_SIGMA_FILE !== nothing
    σ_fixed = [parse(Float64, strip(l)) for l in eachline(FIXED_SIGMA_FILE) if !isempty(strip(l)) && !startswith(strip(l), "#")]
    length(σ_fixed) == n_σ || error("P4_FIXED_SIGMA: $(length(σ_fixed)) rates, model has $n_σ")
    println(">>> P4_FIXED_SIGMA=$FIXED_SIGMA_FILE: fixed-design evaluation, NO search; full outputs written <<<")
    LB = 0.0
    ev_fixed = evaluate_σ(σ_fixed)
    ev_fixed.result === nothing && error("P4_FIXED_SIGMA: follower infeasible")
    best_UB = ev_fixed.ub; best_σ = copy(σ_fixed); best_follower = ev_fixed.result; n_eval = 1
    println("  fixed design: spending €$(round(best_UB/1e6, digits=3))M, feasible=$(ev_fixed.feasible)")
else

# ---- Phase 1: HPR lower bound ----
println("\n--- Phase 1: HPR lower bound ---")
optimize!(master)
master_status = termination_status(master)
if master_status != OPTIMAL && master_status != LOCALLY_SOLVED
    error("Master LP infeasible/error: $master_status")
end
LB = objective_value(master)
σ_HPR = [value(σ[i]) for i in 1:n_σ]
println("  LB = €$(round(LB/1e6, digits=3))M")
println("  σ_HPR: ", [round(σ_HPR[i], digits=3) for i in 1:n_σ])

# Diagnostic: master LP solution values
println("\n  Master LP diagnostics (period ending 2050):")
ti4 = TI2050 !== nothing ? TI2050 : length(T)
for a in A
    println("    Arch $a ($(arch_id[a])): mE=$(round(value(mE[a,ti4]), digits=1))" *
            "  mE_primary=$(round(value(mE_primary[a,ti4]), digits=1))" *
            "  r_env=$(round(value(mr_env[a,ti4]), digits=2))" *
            "  r_hvac=$(round(value(mr_hvac[a,ti4]), digits=2))" *
            "  r_pv=$(round(value(mr_pv[a,ti4]), digits=2))")
end
if TI2050 !== nothing
    master_E2050 = sum(value(mE_primary[a,TI2050]) * fa_a[a] * dwell_a[a] for a in A) / total_area
    println("  Master EPBD at 2050: $(round(master_E2050, digits=1)) kWh/m² (target: $epbd_target)")
end

# ---- Phase 2: Evaluate initial σ candidates ----
println("\n--- Phase 2: Evaluating σ candidates ---")
best_UB = Inf
best_σ = nothing
best_follower = nothing
n_eval = 0

candidates = Pair{String,Vector{Float64}}[]
push!(candidates, "HPR" => copy(σ_HPR))
push!(candidates, "Max subsidies" => copy(σ_caps))
push!(candidates, "90% of max" => enforce_ordering!(σ_caps * 0.90))
push!(candidates, "75% of max" => enforce_ordering!(σ_caps * 0.75))
push!(candidates, "50% of max" => enforce_ordering!(σ_caps * 0.50))
push!(candidates, "25% of max" => enforce_ordering!(σ_caps * 0.25))
push!(candidates, "HPR-Max mid" => enforce_ordering!((σ_HPR + σ_caps) / 2))

# Also try poor-focused: high subsidies for poor, low for rich
σ_poor_focused = copy(σ_caps)
σ_poor_focused[4:6] .= 0.0  # zero rich envelope subsidies
σ_poor_focused[9:10] .= 0.0  # zero rich HVAC subsidies
enforce_ordering!(σ_poor_focused)
push!(candidates, "Poor-focused" => σ_poor_focused)

# District-heat focused: max district heat subsidies, zero HP
# σ indices: 7=HP_poor, 8=dist_poor, 9=HP_rich, 10=dist_rich
σ_district = copy(σ_caps)
σ_district[7] = 0.0   # no HP subsidy for poor
σ_district[9] = 0.0   # no HP subsidy for rich
enforce_ordering!(σ_district)
push!(candidates, "District-focus" => σ_district)

# Deep envelope + district heat: max envelope + max district, zero HP
σ_deep_dist = copy(σ_caps)
σ_deep_dist[7] = 0.0; σ_deep_dist[9] = 0.0  # no HP
σ_deep_dist[1] = 0.0; σ_deep_dist[4] = 0.0  # no light envelope
enforce_ordering!(σ_deep_dist)
push!(candidates, "Deep+District" => σ_deep_dist)

# Structured class-focused candidates: cover corners of the σ-space (low envelope +
# targeted HVAC, and vice versa) that uniform scalings of the caps never visit,
# so coordinate descent starts in the right basin.
# σ index map: 1-6 envelope (poor l/m/d, rich l/m/d), 7-8 HVAC poor, 9-10 HVAC rich.
for (nm, env_f, hvac_f) in [("Env-only", 0.6, 0.0), ("HVAC-only", 0.0, 1.0),
                            ("Env+HVAC mid", 0.4, 0.5), ("Env-low HVAC-high", 0.2, 1.0)]
    σc = zeros(n_σ)
    for i in 1:6;  σc[i] = env_f  * σ_caps[i]; end
    for i in 7:10; σc[i] = hvac_f * σ_caps[i]; end
    push!(candidates, nm => enforce_ordering!(σc))
end
let σc = zeros(n_σ)   # poor-targeted HVAC, minimal envelope
    σc[7] = σ_caps[7]; σc[8] = σ_caps[8]
    push!(candidates, "HVAC-poor only" => enforce_ordering!(σc))
end

# Coarse seed grid over the four aggregate dimensions (env/hvac × poor/rich).
# The follower response is near-threshold (all-or-nothing), so coordinate descent
# needs a start in the right basin; 3 levels per dimension = 81 cheap probes.
for ep in (0.0, 0.5, 1.0), er in (0.0, 0.5, 1.0), hp in (0.0, 0.5, 1.0), hr in (0.0, 0.5, 1.0)
    σc = zeros(n_σ)
    for i in 1:3;  σc[i] = ep * σ_caps[i]; end
    for i in 4:6;  σc[i] = er * σ_caps[i]; end
    for i in 7:8;  σc[i] = hp * σ_caps[i]; end
    for i in 9:10; σc[i] = hr * σ_caps[i]; end
    push!(candidates, "seed($ep,$er,$hp,$hr)" => enforce_ordering!(σc))
end

# Level 2: landlord-rate seeds. The owner seeds above leave the landlord
# rates at 0, and coordinate descent only LOWERS rates, so the search needs
# starting points with landlord subsidies switched on.
if SC.tenure_enabled
    for lv in (0.5, 1.0), (nm, σbase) in [("zero-owner", zeros(n_σ)),
                                          ("mid-owner", enforce_ordering!(σ_caps * 0.5))]
        σc = copy(σbase)
        σc[IDX_LANDLORD_PUBLIC]  = lv * σ_caps[IDX_LANDLORD_PUBLIC]
        σc[IDX_LANDLORD_PRIVATE] = lv * σ_caps[IDX_LANDLORD_PRIVATE]
        push!(candidates, "landlord($lv)+$nm" => enforce_ordering!(σc))
    end
end

# P4_SIGMA_START (2026-11-02 multistart order): replace the whole candidate
# list with the forced start, so Phases 3–5 descend from exactly this basin.
# The miss mechanism this addresses (pl9 certificate finding): Phase 2 keeps
# only the cheapest feasible INITIAL, descent only lowers rates, and the
# multiplicative perturbation keeps zero rates at zero — so a basin whose
# starting corner is expensive or infeasible is unreachable.
if SIGMA_START_RAW !== nothing
    σ_forced = enforce_ordering!(copy(SIGMA_START_RAW))
    empty!(candidates)
    push!(candidates, "P4_SIGMA_START" => σ_forced)
    println("  P4_SIGMA_START ACTIVE — candidate list replaced; start (clamped/ordered): " *
            "$(round.(σ_forced, digits=3))")
end

# Track best infeasible (by E2050 closeness) as fallback
best_infeasible_σ = nothing
best_infeasible_E2050 = Inf

for (name, σ_cand) in candidates
    global n_eval, best_UB, best_σ, best_follower, best_infeasible_σ, best_infeasible_E2050
    ev = evaluate_σ(σ_cand)
    n_eval += 1
    flag = ev.feasible ? "✓" : "✗"
    # Show which constraint fails
    fail_str = ""
    if !ev.feasible && ev.result !== nothing
        fails = String[]
        equity_ok = isnan(ev.equity) || ev.equity >= equity_min_eff - 1e-6   # 2026-11-07 (D10): strict floor; was 0.001
        wpb_ok = isnan(ev.wpb) || ev.wpb >= 0.55 - 0.001
        !equity_ok && push!(fails, "eq")
        !wpb_ok && push!(fails, "wpb")
        ev.E2050 > epbd_target + 0.1 && push!(fails, "E2050")
        !ev.traj_ok && push!(fails, "traj")
        SC.affordability_mode != "off" && !ev.afford_ok && push!(fails, "afford")
        fail_str = isempty(fails) ? "" : " [$(join(fails,","))]"
    end
    println("  $flag $(rpad(name, 16)): UB=€$(ev.ub < Inf ? lpad(round(ev.ub/1e6, digits=2), 8) : "     Inf")M" *
            "  E2050=$(lpad(round(ev.E2050, digits=1), 5))" *
            "  Eq=$(isnan(ev.equity) ? " N/A" : "$(lpad(round(100*ev.equity, digits=1), 5))%")" *
            "  WPB=$(isnan(ev.wpb) ? " N/A" : "$(lpad(round(100*ev.wpb, digits=1), 5))%")" *
            fail_str)
    if ev.feasible && ev.ub < best_UB
        best_UB = ev.ub
        best_σ = copy(σ_cand)
        best_follower = ev.result
    elseif !ev.feasible && ev.E2050 < best_infeasible_E2050 && ev.result !== nothing
        best_infeasible_E2050 = ev.E2050
        best_infeasible_σ = copy(σ_cand)
    end
end

# If no feasible candidate, try upward σ adjustment from best infeasible
if best_σ === nothing && best_infeasible_σ !== nothing
    println("\n  No feasible candidate yet. Trying upward σ adjustment from best infeasible (E2050=$(round(best_infeasible_E2050, digits=1)))...")
    σ_start = copy(best_infeasible_σ)

    # Try increasing each σ toward its cap to push E2050 down
    for round_up in 1:5
        global n_eval, best_UB, best_σ, best_follower, σ_start
        improved = false
        for i in 1:n_σ
            lo = σ_start[i]
            hi = σ_caps[i]
            if hi - lo < 0.01; continue; end

            while hi - lo > 0.005
                mid = (lo + hi) / 2
                σ_try = copy(σ_start)
                σ_try[i] = mid
                enforce_ordering!(σ_try)
                ev = evaluate_σ(σ_try)
                n_eval += 1
                if ev.feasible
                    hi = mid  # can be lower → cheaper
                    if best_σ === nothing || ev.ub < best_UB
                        best_UB = ev.ub
                        best_σ = copy(σ_try)
                        best_follower = ev.result
                    end
                else
                    lo = mid  # need higher σ
                end
            end
            if best_σ !== nothing
                σ_start = copy(best_σ)
                improved = true
            end
        end
        if best_σ !== nothing
            println("  ✓ Found feasible solution: €$(round(best_UB/1e6, digits=2))M (E2050=$(round(evaluate_σ(best_σ).E2050, digits=1)))")
            n_eval += 1
            break
        end
        if !improved; break; end
    end
end

if best_σ === nothing
    println("\n  ✗ No feasible solution found. Check EPBD targets and model parameters.")
    println("  Closest E2050: $(round(best_infeasible_E2050, digits=1)) kWh/m² (target: $epbd_target)")
else
    gap0 = (best_UB - LB) / max(abs(best_UB), 1.0)
    println("\n  Best initial: €$(round(best_UB/1e6, digits=2))M (gap $(round(100*gap0, digits=1))%)")

    # ---- Phase 3: Coordinate descent ----
    println("\n--- Phase 3: Coordinate descent (minimizing public spending) ---")
    for outer in 1:10
        global best_UB, best_σ, best_follower, n_eval
        improved = false
        for i in 1:n_σ
            lo = σ_lower_bound(i, best_σ)
            hi = best_σ[i]
            if hi - lo < 0.01
                continue
            end

            # Binary search: minimum σ[i] keeping feasibility
            best_val_i = hi
            best_ub_i = best_UB
            best_fr_i = best_follower

            while hi - lo > 0.005
                mid = (lo + hi) / 2
                σ_try = copy(best_σ)
                σ_try[i] = mid
                enforce_ordering!(σ_try)
                ev = evaluate_σ(σ_try)
                n_eval += 1

                if ev.feasible
                    hi = mid
                    if ev.ub < best_ub_i
                        best_ub_i = ev.ub
                        best_val_i = mid
                        best_fr_i = ev.result
                    end
                else
                    lo = mid
                end
            end

            if best_ub_i < best_UB
                best_σ[i] = best_val_i
                enforce_ordering!(best_σ)
                # Re-evaluate to get consistent result with final σ
                ev_final = evaluate_σ(best_σ)
                n_eval += 1
                if ev_final.feasible
                    best_UB = ev_final.ub
                    best_follower = ev_final.result
                    improved = true
                end
            end
        end

        local _gap = (best_UB - LB) / max(abs(best_UB), 1.0)
        println("  Round $outer: UB=€$(round(best_UB/1e6, digits=2))M  Gap=$(round(100*_gap, digits=1))%  ($n_eval evals)")
        if !improved
            println("  Converged — no further improvement.")
            break
        end
    end

    # ---- Phase 4: Random perturbation ----
    println("\n--- Phase 4: Random perturbation (100 trials) ---")
    Random.seed!(parse(Int, get(ENV, "P4_SEED", "42")))  # P4_SEED: search-noise check (2026-10-27); default 42 = committed behaviour
    haskey(ENV, "P4_SEED") && println(">>> P4_SEED=$(ENV["P4_SEED"]) — perturbation RNG reseeded (search-noise check) <<<")
    n_improved_phase4 = 0
    for trial in 1:100
        global best_UB, best_σ, best_follower, n_eval, n_improved_phase4
        σ_try = copy(best_σ)
        for i in 1:n_σ
            δ = σ_try[i] * 0.25 * (2*rand() - 1)  # ±25% perturbation
            σ_try[i] = clamp(σ_try[i] + δ, 0.0, σ_caps[i])
        end
        enforce_ordering!(σ_try)
        ev = evaluate_σ(σ_try)
        n_eval += 1
        if ev.feasible && ev.ub < best_UB
            best_UB = ev.ub
            best_σ = copy(σ_try)
            best_follower = ev.result
            n_improved_phase4 += 1
            println("  Trial $trial: improved to €$(round(best_UB/1e6, digits=2))M")
        end
    end
    local _gap = (best_UB - LB) / max(abs(best_UB), 1.0)
    println("  After perturbation: UB=€$(round(best_UB/1e6, digits=2))M  Gap=$(round(100*_gap, digits=1))%  ($n_improved_phase4 improvements)")

    # ---- Phase 5: Second coordinate descent from perturbed solution ----
    if n_improved_phase4 > 0
        println("\n--- Phase 5: Coordinate descent round 2 ---")
        for outer in 1:5
            global best_UB, best_σ, best_follower, n_eval
            improved = false
            for i in 1:n_σ
                lo = σ_lower_bound(i, best_σ)
                hi = best_σ[i]
                if hi - lo < 0.01; continue; end

                best_val_i = hi
                best_ub_i = best_UB
                best_fr_i = best_follower

                while hi - lo > 0.005
                    mid = (lo + hi) / 2
                    σ_try = copy(best_σ)
                    σ_try[i] = mid
                    enforce_ordering!(σ_try)
                    ev = evaluate_σ(σ_try)
                    n_eval += 1
                    if ev.feasible
                        hi = mid
                        if ev.ub < best_ub_i
                            best_ub_i = ev.ub
                            best_val_i = mid
                            best_fr_i = ev.result
                        end
                    else
                        lo = mid
                    end
                end

                if best_ub_i < best_UB
                    best_σ[i] = best_val_i
                    enforce_ordering!(best_σ)
                    ev_final = evaluate_σ(best_σ)
                    n_eval += 1
                    if ev_final.feasible
                        best_UB = ev_final.ub
                        best_follower = ev_final.result
                        improved = true
                    end
                end
            end

            local _gap = (best_UB - LB) / max(abs(best_UB), 1.0)
            println("  Round $outer: UB=€$(round(best_UB/1e6, digits=2))M  Gap=$(round(100*_gap, digits=1))%")
            if !improved; break; end
        end
    end
end   # FIXED_SIGMA else
end

elapsed_total = now() - start_time
gap_final = best_UB < Inf ? (best_UB - LB) / max(abs(best_UB), 1.0) : Inf
println("\n" * "="^70)
println("CCG COMPLETE")
println("="^70)
println("  Total time: $(round(Dates.value(elapsed_total)/1000, digits=1))s")
println("  Follower evaluations: $n_eval")
println("  Lower bound: €$(round(LB/1e6, digits=3))M")
println("  Upper bound: €$(best_UB < Inf ? round(best_UB/1e6, digits=3) : "N/A")M")
println("  Final gap:   $(best_UB < Inf ? round(100*gap_final, digits=1) : "N/A")%")
println("  Best σ: ", best_σ !== nothing ? [round(best_σ[i], digits=3) for i in 1:n_σ] : "none")

# =============================================================================
# 5) RESULTS
# =============================================================================
mkpath(OUTDIR)

if best_σ !== nothing && best_follower !== nothing
    tot_pub = best_UB
    pub_low = sum(
        lowmask_a[a] * inv_cost(a,m,ti) * z_leader(best_σ,best_follower,a,m,ti) * disc(years[ti]) * dwell_a[a]
        for a in A, m in M, ti in T)
    equity_share = tot_pub > 0 ? pub_low / tot_pub : NaN

    # Level 2: the spending floor under BOTH definitions (plan §4: report both)
    # — poor owners only, and poor owners + landlord subsidies for buildings
    # housing poor tenants. equity_share above is the ENFORCED definition.
    pub_poor_owner = sum(
        (!is_rented(a) && inc_a[a] == "poor" ? 1.0 : 0.0) *
        inv_cost(a,m,ti) * z_leader(best_σ,best_follower,a,m,ti) * disc(years[ti]) * dwell_a[a]
        for a in A, m in M, ti in T)
    pub_landlord = sum(
        (is_rented(a) ? 1.0 : 0.0) *
        inv_cost(a,m,ti) * z_leader(best_σ,best_follower,a,m,ti) * disc(years[ti]) * dwell_a[a]
        for a in A, m in M, ti in T)
    equity_excl_landlord = tot_pub > 0 ? pub_poor_owner / tot_pub : NaN
    equity_incl_landlord = tot_pub > 0 ? (pub_poor_owner + pub_landlord) / tot_pub : NaN

    total_sav = sum((E_sav_ref(best_follower, a) - best_follower.E[a,ti]) * fa_a[a] * dwell_a[a] for a in A, ti in T_LEADER:length(T))
    wpb_sav = sum(wpbmask_a[a] * (E_sav_ref(best_follower, a) - best_follower.E[a,ti]) * fa_a[a] * dwell_a[a] for a in A, ti in T_LEADER:length(T))
    wpb_share = total_sav > 0 ? wpb_sav / total_sav : NaN

    E2050_avg = TI2050 !== nothing ?
        sum(primary_intensity(best_follower, a, TI2050) * fa_a[a] * dwell_a[a] for a in A) / total_area : NaN

    gap_final = (best_UB - LB) / max(abs(best_UB), 1.0)

    # Level 1a: affordability diagnostics at the final design (always computed;
    # binding only when affordability_mode != "off")
    afford_final = affordability_check(best_follower)

    # Primary energy path (exact carrier-weighted)
    E_primary_path = [sum(primary_intensity(best_follower, a, ti) * fa_a[a] * dwell_a[a]
                         for a in A) / total_area for ti in T]

    println("\n" * "="^70)
    println("RESULTS SUMMARY")
    println("="^70)
    println("  Public spending: €$(round(tot_pub/1e6, digits=2))M")
    println("  Equity share:    $(round(100*equity_share, digits=1))%")
    println("  WPB share:       $(round(100*wpb_share, digits=1))%")
    println("  E2050 (avg):     $(round(E2050_avg, digits=1)) kWh/m² primary")
    println("  Gap:             $(round(100*gap_final, digits=1))%")
    println("  Affordability ($(SC.affordability_mode == "off" ? "not enforced" : SC.affordability_mode)): " *
            (afford_final.ok ? "satisfied for all low-income archetypes" :
             "VIOLATED — $(round(100*afford_final.viol_share, digits=1))% of low-income households in violating archetypes"))
    for rrow in afford_final.rows
        worst_ti = argmax([rrow.cost_after[ti] - rrow.limit[ti] for ti in T])
        println("    $(rpad(arch_id[rrow.a], 16)) $(rrow.ok ? "ok " : "VIOL") " *
                "worst period $(end_year[worst_ti]): cost €$(round(rrow.cost_after[worst_ti], digits=0))/yr " *
                "(bill €$(round(rrow.bill_after[worst_ti], digits=0)) + own €$(round(rrow.own_ann[worst_ti], digits=0))) " *
                "vs limit €$(round(rrow.limit[worst_ti], digits=0))")
    end
    println("\n  Primary energy trajectory (end-of-period):")
    println("    $(years[1]) (baseline): $(round(baseline_primary, digits=1)) kWh/m²")
    for ti in T
        target_str = ""
        for (k, yr) in enumerate(traj_years)
            if yr == end_year[ti]
                target_str = "  (target: $(traj_values[k]))"
            end
        end
        println("    $(end_year[ti]): $(round(E_primary_path[ti], digits=1)) kWh/m²$target_str")
    end

    println("\n  Subsidies:")
    for i in 1:n_σ
        println("    $(σ_keys[i]): $(round(100*best_σ[i], digits=1))%")
    end

    # Save CSVs
    CSV.write("$OUTDIR/policy_kpis.csv", DataFrame(
        TotalPublic=[tot_pub], EquityShare=[equity_share], WPBShare=[wpb_share],
        E2050_avg=[E2050_avg], Gap=[gap_final], Mode=["CCG_Multiplicative"],
        TerminationStatus=["CONVERGED"], ElapsedTime=[string(elapsed_total)],
        EPBD_target=[epbd_target]))

    CSV.write("$OUTDIR/scenario_summary.csv", DataFrame(
        scenario=[SCENARIO], descr=[SC.descr], feasible=[true],
        spending_M=[tot_pub/1e6], E2050=[E2050_avg], best_E2050=[E2050_avg],
        equity=[equity_share], wpb=[wpb_share], LB_M=[LB/1e6],
        epbd_target=[epbd_target],
        affordability_mode=[SC.affordability_mode],
        equity_spending_floor=[SC.equity_spending_floor],
        afford_ok=[afford_final.ok],
        afford_viol_share=[afford_final.viol_share],
        tenure_enabled=[SC.tenure_enabled],
        equity_excl_landlord=[equity_excl_landlord],
        equity_incl_landlord=[equity_incl_landlord],
        landlord_subsidy_eur=[pub_landlord]))

    # Level 1a: per-archetype affordability report (poor archetypes × periods).
    # cost_after = bill_after + own_annualised; limit is the active threshold
    # (tolerance × reference for cost_neutral, income share for income_share;
    # the cost_neutral threshold is reported even when the mode is off).
    afford_rows = []
    for rrow in afford_final.rows, ti in T
        push!(afford_rows, (archetype=arch_id[rrow.a], tenure=tenure_a[rrow.a],
            income=inc_a[rrow.a],
            income_eur_yr=income_of(rrow.a),
            year=end_year[ti],
            dwellings=dwell_a[rrow.a], floor_area_m2=fa_a[rrow.a],
            # "bill before" for Table 3: the un-renovated building's bill at
            # same-period prices (frozen stock), whatever the run's reference
            frozen_bill_eur_yr=round(reference_costs_for("frozen_stock")[rrow.a,ti], digits=1),
            bill_after_eur_yr=round(rrow.bill_after[ti], digits=1),
            own_annualised_eur_yr=round(rrow.own_ann[ti], digits=1),
            rent_increase_eur_yr=round(rrow.rent_inc[ti], digits=1),
            cost_after_eur_yr=round(rrow.cost_after[ti], digits=1),
            cost_reference_eur_yr=round(rrow.cost_ref[ti], digits=1),
            # cost-to-income indicator (2026-10-08): reported for every
            # row; it is the rich tenant's headline indicator
            cost_share_of_income=round(rrow.cost_after[ti] / income_of(rrow.a), digits=4),
            limit_eur_yr=round(rrow.limit[ti], digits=1),
            satisfied=rrow.cost_after[ti] <= rrow.limit[ti] + AFFORD_TOL_EUR,
            archetype_ok_all_periods=rrow.ok,
            mode=SC.affordability_mode,
            reference=SC.affordability_reference,
            enforced=SC.affordability_mode != "off" && afford_in_scope(rrow.a)))
    end
    CSV.write("$OUTDIR/affordability_by_archetype.csv", DataFrame(afford_rows))

    subs_df = DataFrame(
        group=vcat(fill("poor",6), fill("rich",6)),
        measure=repeat(["env_light","env_medium","env_deep","hvac_std","hvac_upg","pv"], 2),
        rate=[best_σ[1], best_σ[2], best_σ[3], best_σ[7], best_σ[8], 0.0,
              best_σ[4], best_σ[5], best_σ[6], best_σ[9], best_σ[10], 0.0])
    if SC.tenure_enabled
        append!(subs_df, DataFrame(
            group=["landlord_public", "landlord_private"],
            measure=["all_non_pv", "all_non_pv"],
            rate=[best_σ[IDX_LANDLORD_PUBLIC], best_σ[IDX_LANDLORD_PRIVATE]]))
    end
    CSV.write("$OUTDIR/subsidies.csv", subs_df)

    # pl12: history spending (NOT in the state's objective) and the state after the history
    if HIST_ON
        hist_rows = Any[]
        for a in A, m in M, ti in 1:T_HIST
            yv = best_follower.y[a,m,ti]; yv > 1e-9 || continue
            nom = inv_cost(a,m,ti) * σ_hist(m, a) * yv * dwell_a[a]
            push!(hist_rows, (archetype=arch_id[a], measure=m_id[m], period_end=end_year[ti], y=yv,
                              subsidy_rate=σ_hist(m, a), spending_nominal_eur=nom, spending_disc_eur=nom * disc(years[ti])))
        end
        if !isempty(hist_rows)
            CSV.write("$OUTDIR/history_spending.csv", DataFrame(hist_rows))
            println("  History (periods 1..$T_HIST, fixed): subsidy spending nominal €$(round(sum(r.spending_nominal_eur for r in hist_rows)/1e6, digits=1))M, " *
                    "discounted to $DISC_BASE €$(round(sum(r.spending_disc_eur for r in hist_rows)/1e6, digits=1))M — NOT in the state's objective")
        end
        st_rows = [(archetype=arch_id[a], dwellings=dwell_a[a],
                    E_primary_after_history=primary_intensity(best_follower, a, T_HIST),
                    E_delivered_after_history=best_follower.E[a,T_HIST],
                    env_share=sum(best_follower.s[a,m,T_HIST] for m in M_env),
                    hp_share=idx_hp === nothing ? 0.0 : best_follower.s[a,idx_hp,T_HIST],
                    dh_share=idx_dist === nothing ? 0.0 : best_follower.s[a,idx_dist,T_HIST],
                    eta_incumbent_before=η_at[a,1], eta_incumbent_after=η_at[a,T_HIST+1],
                    pfuel_before=pfuel_at[a,1], pfuel_after=pfuel_at[a,T_HIST+1]) for a in A]
        CSV.write("$OUTDIR/state_after_history.csv", DataFrame(st_rows))
        println("  Stock primary energy after the history ($(end_year[T_HIST])): " *
                "$(round(sum(primary_intensity(best_follower, a, T_HIST) * fa_a[a] * dwell_a[a] for a in A) / total_area, digits=2)) kWh/m²")
    end

    # Energy path: prepend baseline at start year, then end-of-period values
    energy_data = [(year=years[1], Eavg=baseline_primary)]  # baseline before renovation
    for ti in T
        push!(energy_data, (year=end_year[ti],
            Eavg=sum(primary_intensity(best_follower, a, ti)*fa_a[a]*dwell_a[a] for a in A)/total_area))
    end
    CSV.write("$OUTDIR/energy_path.csv", DataFrame(energy_data))

    CSV.write("$OUTDIR/public_spend_split.csv", DataFrame(
        group=["low-income","high-income (Q2-Q5)"], spend=[pub_low, tot_pub-pub_low]))

    adoption_data = []
    for a in A, m in M, ti in T
        push!(adoption_data, (
            archetype=arch_id[a], income=inc_a[a], tenure=tenure_a[a], measure=m_id[m],
            measure_class=cls_m[m], measure_depth=depth_m[m], year=end_year[ti],
            y=best_follower.y[a,m,ti], s=best_follower.s[a,m,ti],
            z=best_follower.z[a,m,ti], E=best_follower.E[a,ti]))
    end
    CSV.write("$OUTDIR/adoption_values.csv", DataFrame(adoption_data))

    # --- Extended outputs ---
    # (1) Total uptake per measure: dwellings, stock share, investment, subsidy (nominal EUR)
    measure_rows = []
    for m in M
        dwellings_done = sum(best_follower.y[a,m,ti] * dwell_a[a] for a in A, ti in T)
        inv_tot = sum(inv_cost(a,m,ti) * best_follower.y[a,m,ti] * dwell_a[a] for a in A, ti in T)
        sub_tot = sum(inv_cost(a,m,ti) * z_leader(best_σ,best_follower,a,m,ti) * dwell_a[a] for a in A, ti in T)
        push!(measure_rows, (measure=m_id[m], class=cls_m[m],
            dwellings_adopting=round(dwellings_done, digits=0),
            stock_share_pct=round(100 * dwellings_done / sum(dwell_a), digits=1),
            investment_eur=round(inv_tot, digits=0),
            subsidy_eur=round(sub_tot, digits=0)))
    end
    CSV.write("$OUTDIR/measure_totals.csv", DataFrame(measure_rows))

    # (2) Subsidy use by archetype / income group
    sub_arch = []
    for a in A
        s_disc = sum(inv_cost(a,m,ti) * z_leader(best_σ,best_follower,a,m,ti) * disc(years[ti]) * dwell_a[a] for m in M, ti in T)
        s_nom  = sum(inv_cost(a,m,ti) * z_leader(best_σ,best_follower,a,m,ti) * dwell_a[a] for m in M, ti in T)
        push!(sub_arch, (archetype=arch_id[a], income=inc_a[a], dwellings=dwell_a[a],
            subsidy_discounted_eur=round(s_disc, digits=0), subsidy_nominal_eur=round(s_nom, digits=0),
            subsidy_per_dwelling_eur=round(s_nom / dwell_a[a], digits=0)))
    end
    CSV.write("$OUTDIR/subsidy_by_archetype.csv", DataFrame(sub_arch))

    # (3) ETS2 carbon-price revenue from households vs subsidy outlays per period
    ets_rows = []
    for ti in T
        rev = sum((best_follower.E_ep[a,ti] - best_follower.E_ep_hp[a,ti] - best_follower.E_ep_dh[a,ti]) *
                  fa_a[a] * co2_int_at[a,ti] * co2_price_per_ton[ti] / 1000 * dwell_a[a] for a in A) * period_length[ti]
        sub = sum(inv_cost(a,m,ti) * z_leader(best_σ,best_follower,a,m,ti) * dwell_a[a] for a in A, m in M)
        push!(ets_rows, (period_end=end_year[ti], co2_price_eur_t=co2_price_per_ton[ti],
            ets2_revenue_eur=round(rev, digits=0), subsidy_paid_eur=round(sub, digits=0),
            revenue_over_subsidy=round(sub > 1e-6 ? rev / sub : NaN, digits=2)))
    end
    CSV.write("$OUTDIR/ets2_revenue_vs_subsidy.csv", DataFrame(ets_rows))

    # (4) Heating-system shares and energy demand over time
    heat_rows = []
    for a in A, ti in T
        s_hp = idx_hp !== nothing ? best_follower.s[a,idx_hp,ti] : 0.0
        s_dh_new = idx_dist !== nothing ? best_follower.s[a,idx_dist,ti] : 0.0
        dh_share = is_dh0_a[a] ? 1.0 : s_dh_new
        fossil_share = is_dh0_a[a] ? 0.0 : max(0.0, 1 - s_hp - s_dh_new)
        push!(heat_rows, (archetype=arch_id[a], income=inc_a[a], tenure=tenure_a[a], year=end_year[ti],
            fossil_share=round(fossil_share, digits=3),
            heatpump_share=round(s_hp, digits=3),
            district_heat_share=round(dh_share, digits=3),
            site_energy_kwh_m2=round(best_follower.E[a,ti], digits=1),
            primary_energy_kwh_m2=round(primary_intensity(best_follower, a, ti), digits=1)))
    end
    CSV.write("$OUTDIR/heating_energy_path.csv", DataFrame(heat_rows))

    # (5) Investment flows by archetype × measure × period (who invests what, when)
    inv_rows = []
    for a in A, m in M, ti in T
        if best_follower.y[a,m,ti] > 1e-6
            invt = inv_cost(a,m,ti) * best_follower.y[a,m,ti] * dwell_a[a]
            sub_nom = inv_cost(a,m,ti) * z_leader(best_σ,best_follower,a,m,ti) * dwell_a[a]
            sub_rec = inv_cost(a,m,ti) * best_follower.z[a,m,ti] * dwell_a[a]
            push!(inv_rows, (archetype=arch_id[a], income=inc_a[a], tenure=tenure_a[a], measure=m_id[m],
                year=end_year[ti],
                adoption_share=round(best_follower.y[a,m,ti], digits=4),
                investment_eur=round(invt, digits=0),
                subsidy_paid_eur=round(sub_nom, digits=0),
                subsidy_received_eur=round(sub_rec, digits=0),
                own_payment_eur=round(invt - sub_rec, digits=0)))
        end
    end
    CSV.write("$OUTDIR/investment_flows.csv", DataFrame(inv_rows))

    # ------------------------------------------------------------------
    # Level 2 reporting (plan §4): tenant costs, landlord uptake, and the
    # landlord rate needed to make each rented type affordability-feasible
    # ------------------------------------------------------------------
    if SC.tenure_enabled
        ref_costs = affordability_reference_costs()
        ten_rows = []
        for a in A_RENTED, ti in T
            bill = annual_bill(best_follower, a, ti)
            push!(ten_rows, (archetype=arch_id[a], tenure=tenure_a[a], year=end_year[ti],
                tenant_bill_eur_yr=round(bill, digits=1),
                rent_increase_eur_yr=round(best_follower.rent[a,ti], digits=1),
                tenant_cost_eur_yr=round(bill + best_follower.rent[a,ti], digits=1),
                reference_bill_eur_yr=round(ref_costs[a,ti], digits=1),
                landlord_applied_for_subsidy=best_follower.apply[a,ti] > 0.5,
                envelope_share=round(sum(best_follower.s[a,m,ti] for m in M_env), digits=3),
                hvac_share=round(sum(best_follower.s[a,m,ti] for m in M_hvac; init=0.0), digits=3)))
        end
        CSV.write("$OUTDIR/tenant_costs.csv", DataFrame(ten_rows))

        println("\n  Level 2 — rented archetypes at the final design:")
        println("    Spending floor: enforced definition $(round(100*equity_share, digits=1))% | " *
                "low-income owners only $(round(100*equity_excl_landlord, digits=1))% | " *
                "incl. landlord subsidies $(round(100*equity_incl_landlord, digits=1))% " *
                "(landlord_subsidy_counts_as_poor=$(SC.landlord_subsidy_counts_as_poor))")
        ti_last = TI2050 !== nothing ? TI2050 : length(T)
        for a in A_RENTED
            env50 = sum(best_follower.s[a,m,ti_last] for m in M_env)
            println("    $(rpad(arch_id[a], 28)) env@2050=$(round(100*env50, digits=1))%  " *
                    "tenant cost €$(round(annual_bill(best_follower,a,ti_last) + best_follower.rent[a,ti_last], digits=0))/yr " *
                    "(bill €$(round(annual_bill(best_follower,a,ti_last), digits=0)) + rent €$(round(best_follower.rent[a,ti_last], digits=0))) " *
                    "vs reference €$(round(ref_costs[a,ti_last], digits=0))/yr  " *
                    "applied=$(join([best_follower.apply[a,ti] > 0.5 ? "Y" : "n" for ti in T]))")
        end

        # Minimum landlord rate (0.1 scan, SEARCH BOUND — other rates held at
        # the optimum; separability makes the scan exact per rented archetype,
        # but the leader is not re-optimised) making each rented type's
        # tenants affordability-feasible under the active (or, when mode=off,
        # the cost-neutral) threshold. The scan covers the FULL rate range
        # (no early exit) so it also yields the minimum affordability gap in
        # EUR/yr — the smallest worst-period shortfall any landlord rate can
        # reach (user request 2026-10-01, D5x reporting).
        checked_ti = afford_checked_periods()
        gap_of(det, archs) = maximum(det[k].cost_after[ti] - det[k].limit[ti]
                                     for k in eachindex(det), ti in checked_ti
                                     if det[k].a in archs)
        det_opt = affordability_details(best_follower)
        landlord_rate_rows = []
        scan_rows = []
        for (ten, idx) in (("rented_public", IDX_LANDLORD_PUBLIC),
                           ("rented_private", IDX_LANDLORD_PRIVATE))
            archs = [a for a in A_RENTED if tenure_a[a] == ten]
            found = NaN; min_gap = Inf; min_gap_rate = NaN
            for rate in 0.0:0.1:σ_caps[idx]
                σ_try = copy(best_σ); σ_try[idx] = rate
                fr_try = solve_follower(σ_try)
                fr_try === nothing && continue
                det = affordability_details(fr_try)
                gap = gap_of(det, archs)
                ti50 = TI2050 !== nothing ? TI2050 : length(T)
                env50 = sum(fr_try.s[a,m,ti50] * dwell_a[a] for a in archs, m in M_env) /
                        sum(dwell_a[a] for a in archs)
                push!(scan_rows, (landlord_type=ten, rate=rate,
                    gap_eur_yr=round(gap, digits=1),
                    affordable=gap <= AFFORD_TOL_EUR,
                    env_share_2050=round(env50, digits=4)))
                if gap < min_gap
                    min_gap = gap; min_gap_rate = rate
                end
                if isnan(found) && gap <= AFFORD_TOL_EUR
                    found = rate
                end
            end
            push!(landlord_rate_rows, (landlord_type=ten,
                min_rate_for_tenant_affordability=found,
                min_gap_eur_yr=round(min_gap, digits=1),
                rate_at_min_gap=min_gap_rate,
                gap_at_optimum_eur_yr=round(gap_of(det_opt, archs), digits=1),
                threshold=SC.affordability_mode == "off" ? "cost_neutral (reported only)" : SC.affordability_mode,
                reference=SC.affordability_reference,
                enforced=SC.affordability_mode != "off" &&
                         (SC.affordability_scope == "all" || ten != "rented_private"),
                note="search bound, 10% scan, other rates at optimum"))
            println("    min landlord rate for tenant affordability ($ten): " *
                    (isnan(found) ? "NONE ≤ cap $(σ_caps[idx]) — min gap €$(round(min_gap, digits=0))/yr at rate $(min_gap_rate)" :
                     "$(round(100*found, digits=0))%") *
                    "  (gap at optimum €$(round(gap_of(det_opt, archs), digits=0))/yr)")
        end
        CSV.write("$OUTDIR/landlord_afford_rates.csv", DataFrame(landlord_rate_rows))
        CSV.write("$OUTDIR/landlord_rate_scan.csv", DataFrame(scan_rows))

        # Figure 2/2b data: cumulative envelope renovation share by tenure
        # group, floor-area weighted (plan §5)
        grp_rows = []
        for g in ("owner_poor", "owner_rich", "rented_public", "rented_private")
            archs = [a for a in A if tenure_group(a) == g]
            isempty(archs) && continue
            area = sum(fa_a[a] * dwell_a[a] for a in archs)
            for ti in T
                env = sum(best_follower.s[a,m,ti] * fa_a[a] * dwell_a[a]
                          for a in archs, m in M_env) / area
                push!(grp_rows, (group=g, year=end_year[ti],
                    cum_envelope_area_share=round(env, digits=5)))
            end
        end
        CSV.write("$OUTDIR/uptake_by_group.csv", DataFrame(grp_rows))

        open("$OUTDIR/tenure_footnotes.txt", "w") do io
            println(io, TENURE_FOOTNOTE)
        end
    end

    println("\n✓ Results saved to $OUTDIR/")
else
    println("\n  No feasible solution found.")
    CSV.write("$OUTDIR/scenario_summary.csv", DataFrame(
        scenario=[SCENARIO], descr=[SC.descr], feasible=[false],
        spending_M=[NaN], E2050=[NaN], best_E2050=[best_infeasible_E2050],
        equity=[NaN], wpb=[NaN], LB_M=[LB/1e6],
        epbd_target=[epbd_target],
        affordability_mode=[SC.affordability_mode],
        equity_spending_floor=[SC.equity_spending_floor],
        afford_ok=[missing], afford_viol_share=[NaN]))
    if best_infeasible_σ !== nothing
        CSV.write("$OUTDIR/best_infeasible_sigma.csv", DataFrame(
            sigma_key=[string(k) for k in σ_keys], rate=best_infeasible_σ))
    end
    println("  Summary saved to $OUTDIR/scenario_summary.csv")
end
println("✓ CCG run complete")

end  # !SKIP_SEARCH (test hook)
