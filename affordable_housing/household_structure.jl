########################################################################
# household_structure.jl — export the follower household/archetype
# structure ACTUALLY LOADED by the model (user order 2026-10-09 part 1).
#
# Reads nothing from documentation: every column comes from the model's
# own globals after the scenario config is applied. Default scenario is
# tenure_afford (the D5 configuration of record, wave 8); pass another
# scenario name as ARGS[1] to export its structure instead.
#
# Output: results/household_structure.csv. Part of reproduce_all.sh.
# Share-source strings are the config's recorded source strings (the
# same ones the model prints in its tenure-split warning); "placeholder"
# flags where the README placeholder table says so.
# Usage: julia --project=.. household_structure.jl [scenario]
########################################################################

ENV["P4_SKIP_SEARCH"] = "1"
SCN = isempty(ARGS) ? "tenure_afford" : ARGS[1]
empty!(ARGS); push!(ARGS, SCN)
include("bilevel_model_affordable_housing.jl")

using CSV, DataFrames

total_dwell = sum(dwell_a)

group_of(a) = !is_rented(a) ? "owner-occupier" :
    tenure_a[a] == "rented_public" ? "public rental" : "private rental"

decider_of(a) = !is_rented(a) ? "owner" :
    tenure_a[a] == "rented_public" ? "public landlord" : "private landlord"

bill_payer_of(a) = is_rented(a) ? "tenant" : "owner"

heating_of(a) = hvac_current[a]   # as loaded from archetypes_v2.csv

function parent_of(a)
    is_rented(a) || return ""
    for suf in ("_rent_pub", "_rent_priv_rich", "_rent_priv")
        endswith(arch_id[a], suf) && return replace(arch_id[a], suf => "")
    end
    return "UNMATCHED"
end

# share-source strings: the config's recorded sources (as printed in the
# model's tenure-split warning and the README placeholder table)
SRC_PUB   = "SOURCED: 595,800 municipal (GUS 2024) + TBS/SIM ~110k approximate / 8,609,900 MFH dwellings (Census 2021) = 0.082"
SRC_PRIV  = "DERIVED 0.08: 0.05 x 14.1M households / 8.61M MFH dwellings (Eurostat ilc_lvho02 RENT_MKT 5.0% of persons, GUS household count, Census 2021 MFH count); assumes market-rent tenants live in MFH"
SRC_SPLIT = "SOURCED 16/84 low-/high-income split of private rental (Eurostat EU-SILC, AROP-based, not quintile-based)"
SRC_OWN   = "residual of the raw stock row after the tenure split (archetypes_v2.csv dwellings)"

function share_source_of(a)
    is_rented(a) || return SRC_OWN
    tenure_a[a] == "rented_public" && return SRC_PUB
    inc_a[a] == "rich" && return SRC_PRIV * "; " * SRC_SPLIT
    return SRC_PRIV * "; " * SRC_SPLIT
end

# affordability enforcement, from the model's own gating: the constraint
# binds for low-income archetypes inside afford_in_scope when the mode is on
afford_on = SC.affordability_mode != "off"
enforced_of(a) = afford_on && inc_a[a] == "poor" && afford_in_scope(a)

rows = []
for a in A
    push!(rows, (
        archetype = arch_id[a],
        group = group_of(a),
        building_type = btype_a[a],
        heating_at_start = heating_of(a),
        renovation_decider = decider_of(a),
        energy_bill_payer = bill_payer_of(a),
        income_group = inc_a[a] == "poor" ? "low-income" : "high-income (Q2-Q5)",
        income_eur_yr = income_of(a),
        parent_archetype = parent_of(a),
        share_of_stock_dwellings = round(dwell_a[a] / total_dwell, digits=5),
        dwellings_thousand = round(dwell_a[a], digits=3),
        share_source = share_source_of(a),
        liquidity_cap_eur_yr = isfinite(cap_a[a]) ? string(round(Int, cap_a[a])) : "none",
        affordability_enforced = enforced_of(a) ? "yes" : "no",
        scenario = SCN,
    ))
end
d = DataFrame(rows)

mkpath("results")
CSV.write("results/household_structure.csv", d)
println(d[:, [:archetype, :group, :income_group, :income_eur_yr,
              :share_of_stock_dwellings, :liquidity_cap_eur_yr,
              :affordability_enforced]])

n_mfh_parents = length(unique(parent_of(a) for a in A if is_rented(a)))
n_mfh_total   = count(a -> btype_a[a] == "MFH" && !is_rented(a), A)
println("\nRented variants split from $n_mfh_parents of $n_mfh_total MFH owner archetypes" *
        (n_mfh_parents == n_mfh_total ? " (ALL of them)" : " (NOT all — check!)"))
println("Shares are DWELLING shares (dwellings in thousands, archetypes_v2.csv convention).")
println("✓ results/household_structure.csv written (scenario $SCN)")
