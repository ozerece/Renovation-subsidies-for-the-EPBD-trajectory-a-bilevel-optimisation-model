# Input provenance — affordable-housing model (Poland calibration)

Written 2026-10-12 (user order, documentation only). Covers every input in
`archetypes_v2.csv`, `measures_v2.csv`, `context.csv` (all at the package
root, not in this folder) plus the renovation-capacity rates hard-coded in
`bilevel_model_affordable_housing.jl:1094-1104`, and the other hard-coded
numeric inputs a reader needs to judge the same question.

Status labels: **sourced** (external citation exists), **derived** (computed
from sourced numbers — calculation shown), **assumed** (chosen in
calibration; rationale given where one was recorded), **no source** (no
citation or rationale recorded anywhere in the repo or session notes).
Citations marked *(session notes)* come from the 2026-07 Poland fact-check
recorded in the assistant's session memory, not from a file in this repo;
they were not re-verified for this document.

## archetypes_v2.csv

| Column | Values | Unit | Status / source |
|---|---|---|---|
| `dwellings` | 1,500 / 3,000 / 700 / 300 / 3,150 / 1,350 (total 10,000) | dwellings | **assumed, no source** — stylised synthetic stock of 10,000 dwellings. Neither the total nor the SFH:MFH (45:55) or poor:rich splits carry a recorded source. Exception: the MFH DH:fossil split 70:30 (3,850/5,500) is **derived** from "~67–70% of Polish MFH connected to district heat" *(session notes, 2026-07 fact-check; no formal citation stored)*. |
| `floor_area_m2` | SFH 100 / 130; MFH 55 / 65 | m² per dwelling | **assumed, no source** — no TABULA type, GUS table or other citation recorded. |
| `baseline_kWh_m2` | SFH 280 / 210; MFH 190 (dh) / 220 (fossil) / 160 (dh) / 190 (fossil) | kWh delivered /m²·yr | **assumed, no source** — chosen in the 2026-07 recalibration so the stock-average *primary* intensity lands near the Polish (DSRB-era) level; the model prints the resulting baseline primary average (`:1316-1317`). No per-archetype citation recorded. |
| `annual_liquidity_cap` | 5,000 (poor) / 12,000 (rich) | EUR per dwelling·yr | **assumed with recorded rationale** *(session notes)*: poor €5k/yr as a pre-financing proxy (Czyste Powietrze Plus pays a 50% advance); rich €12k/yr set from GUS average household saving surplus ≈ €10.8k/yr and NBP median liquid assets €3.6k (replaced an earlier €50k). No verbatim citation strings stored. |
| `is_WPB` | 1 for SFH_poor, SFH_rich, MFH_poor_fossil (= 48% of dwellings) | flag | **assumed** — motivated by EPBD Art. 9(2) (≥55% of savings from the worst ~43% of stock) *(session notes)*; the actual assignment (which rows, 48% vs 43%) has no source. |
| `co2_intensity_kg_per_kWh` | 0.30 (fossil) / 0.0 (district heat) | kg CO₂ /kWh delivered | **assumed, no source** — CO₂ price is applied to the fossil fraction only; DH archetypes carry 0 by design. |
| `primary_energy_factor` | 1.1 (fossil) / 0.85 (DH) | – | **assumed** — base-year values matching the in-code comment "fossil 1.1 constant; DH coal-CHP stock average ~0.85" (`:1043-1048`); the *time path* used in the solve comes from the in-code functions (see "in-code inputs"). No citation for the DH 0.85. |
| `pv_capacity_kWp` | 4.0 / 6.0 / 1.0 / 1.5 | kWp per dwelling | **assumed, no source**. |
| `pv_cost_eur` | 4,500 / 6,500 / 1,100 / 1,600 | EUR per dwelling | **assumed, no source** — consistent with a flat ≈ €1,080–1,125/kWp across rows (4,500/4.0 = 1,125 etc.), but that unit price itself has no recorded source. |

## measures_v2.csv

| Row / column | Values | Unit | Status / source |
|---|---|---|---|
| envelope `capex_per_m2` (light/medium/deep) | 45 / 100 / 200 | EUR/m² | **assumed, no source**. |
| envelope `fixed_capex` | 800 / 1,500 / 3,000 | EUR per dwelling | **assumed, no source** — flat per-dwelling adder, identical for SFH and MFH (see §"MFH fixed costs" below). |
| envelope `reduction_factor` | 0.25 / 0.45 / 0.70 | fraction of heat demand | **assumed** — depth ladder consistent with the EU light/medium/deep (<30 / 30–60 / >60%) renovation-depth convention; no citation recorded. |
| `hvac_fossil_to_hp`: capex 30 €/m² + fixed 12,000 € | | EUR | **assumed, no source**. |
| `hvac_fossil_to_hp` `reduction_factor` = 0.67 | | – | **derived**: remaining delivered energy = 1/SCOP with retrofit SCOP ≈ 3.0 *(session notes, 2026-07 fact-check)* → reduction 1 − 1/3.0 ≈ 0.67. |
| `hvac_fossil_to_district`: capex 15 €/m² + fixed 4,000 €; reduction 0.30 | | | **assumed, no source** — 0.30 represents the boiler-efficiency gain only (remaining factor 0.70, `:1075`). |
| `pv` `reduction_factor` = 0.25 | | – | **assumed, no source**. |
| `lifetime` | 30/35/40 (env), 20 (HP), 30 (DH), 25 (PV) | years | **assumed, no source**. |
| `learning_rate_annual` | 0.005 (env), 0.025 (HP), 0.010 (DH), 0.050 (PV) | /yr cost decline | **assumed, no source**. |
| `learning_rates` (scenario key, pl11 family) | envelope 0, DH 0, HP 0.025 kept; PV removed (`pv_enabled=false`) | /yr cost decline | 2026-11-06 user brief; HP rate: IEA Future of Heat Pumps 2022 + Applied Energy 2024 range (MODEL_V2_ASSUMPTIONS.md); `pl11_learn0` sets HP 0 as sensitivity. |

Investment cost per dwelling = `capex_per_m2 × floor_area_m2 + fixed_capex`
(PV: `pv_cost_eur` directly) — `bilevel_model_affordable_housing.jl:1235-1239`.

## context.csv

| Field | Value | Unit | Status / source |
|---|---|---|---|
| `years` | 2020;2030;2035;2040;2050 | – | design choice (5 periods). |
| `energy_price` = 0.35, `co2_factor` = 0.2 | — | — | **UNUSED legacy columns** — not read by the model (`grep ctx.` shows only years, discount_rate, equity_min_share_low, epbd_target, co2_price, traj_*). Fuel prices are hard-coded instead (see below). |
| `discount_rate` | 0.03 | /yr | **assumed** — single global rate, both levels (landlord default = same rate). No source. |
| `equity_min_share_low` | 0.30 | share of subsidy spending | **assumed with recorded support** *(session notes)*: EPBD Art. 17(18) vulnerable-household prioritisation; Social Climate Fund Poland earmark ≈ €11.4bn; "30–40% defensible". Exact 0.30 is a choice. |
| `epbd_target` | 90.0 | kWh primary /m²·yr (2050) | **assumed, DSRB-informed** *(session notes, 2026-07 fact-check: Polish long-term renovation strategy trajectory ≈ 230 → 90)*. No verbatim DSRB citation stored. |
| `traj_years` / `traj_values` | 2030/2035/2040/2050 → 180/170/130/90 | kWh primary /m²·yr, absolute | **assumed, DSRB-informed** — intermediate points chosen in the recalibration; only the 2050 endpoint traces to the session fact-check. |
| `co2_price_eur_per_ton` | 0;70;120;200;350 (per period) | EUR/tCO₂ | **assumed, ETS2-informed** *(session notes: ETS2 heating carbon price from ~2028; central path 0/70/120/200/350–400 judged OK; high-scenario cap ~500)*. Applied to the fossil fraction only. |

## Renovation-capacity rates (in code, `bilevel_model_affordable_housing.jl:1094-1104`)

| Parameter | Value | Unit | Status / source |
|---|---|---|---|
| envelope rate | 1.5%/yr (<2030), 3.0% (2030s), 3.5% (≥2040) | fraction of each archetype's stock /yr | **assumed, "DSRB-informed"** (code comment `:1094`; session note: DSRB average renovation rate ≈ 3.8%/yr). Staging (build-up of envelope capacity) is an assumption. |
| HVAC rate | 3.0%/yr | same | **assumed** (installer-base bound; no source). |
| PV rate | 4.0%/yr | same | **assumed, no source**. |
| joint labour-weighted cap | 2.5%/yr (<2030), 4.0% (2030s), 5.0% (≥2040) | weighted fraction /yr | **assumed** — introduced so the per-class ceilings cannot stack to implausible total activity. |
| labour weights `W_CLS` | envelope 1.0, HVAC 0.4, PV 0.2 | – | **assumed** — "one deep-envelope job ≈ 2.5 heating swaps ≈ 5 PV jobs" (code comment `:1097`); no source. |
| `reno_scale` | 1.0 default (scenario lever, `:74`) | multiplier | design choice. |

All capacity constraints are per archetype and per class
(`:1382-1388`, master mirror `:1766` ff.). Summed over archetypes they bound
national activity at the same rate × total stock; they are *tighter* than a
single national pool because slack in one archetype cannot be reallocated to
another.

## Other hard-coded numeric inputs (for completeness)

| Parameter | Value | Status / source |
|---|---|---|
| fuel prices `p_gas` / `p_dh` / `p_elec` (`:1069-1071`) | 0.065 / 0.055 / 0.22 EUR/kWh | **assumed, no source** (comment: household prices, coal/gas mix). |
| electricity PEF path (`:1050-1055`) | 3.0 (2020) → 1.9 (2030) → 1.5 → 1.1 → 0.8 (2050) | **sourced base, assumed path**: wi = 2.5 today, 3.0 before 2023 per Dz.U. 2023 poz. 697 (in-code citation `:1044-1045`); the decline path is an NECP-outlook assumption. |
| DH PEF path (`:1056-1061`) | 0.85 → 0.45 (2050) | **assumed** (coal-CHP stock average; no citation). |
| fossil PEF (`:1049`) | 1.1 constant | **assumed** (convention; no citation). |
| `maintenance_rate` (`:1091`) | envelope 0.005, HVAC 0.02, PV 0.01 of capex /yr | **assumed, no source**. |
| `BOILER_LIFE` (`:924`) | 25 yr | **assumed, no source**. |
| subsidy-rate caps (`:1241-1253` ff.) | e.g. deep-env rich 0.50 | **assumed with recorded support** *(session notes: Czyste Powietrze tiers 40/70/100%)*; exact values are choices. |

## Scenario switches (not data inputs) — added 2026-10-27

| Switch | Default | Status / source |
|---|---|---|
| `eed_public_obligation` (scen kwarg; constraint in `solve_follower`, requirement in `eed_required_share`) | false | **sourced rule, simplified implementation** (amended 2026-10-27, user decisions): Directive (EU) 2023/1791 (EED recast) Art. 6. **Base** = floor area not nZEB on 1 January 2024 (Art. 6(1)) — here ALL public-rental floor area, no archetype starts at nZEB. **Path**: linear 3%/yr; **start 2026 assumed**. **Standard**: nZEB — Polish limit for multi-family buildings 65 kWh primary/(m²·yr), WT 2021 — PROXIED as deep envelope AND heat pump or district-heat connection (the 65 value itself is not checked); joint share by comonotone-bundling convention (both components ≥ requirement; DH incumbents satisfy heating by incumbency). **Requirement clipped to capacity** (decision 1b): min with the cumulative envelope cap, heating cap and joint labour cap (env 1.0 + hvac 0.4 for fossil-heated archetypes). SIMPLIFICATIONS, recorded: all public-rental dwellings included (250 m² threshold and the possible social-housing exemption ignored); **period-END check instead of the yearly carry-over of Art. 6(3)**. |
| `public_tenant_weight` (scen kwarg; follower-objective term) | 0.0 | **assumed — modelling device, no empirical source**: weight w ∈ [0, 1] on the public tenant's energy bill + carbon cost + rent increase in the public landlord's objective; w = 1 = full tenant-welfare internalisation (the rent increase cancels). The sweep values 0 / 0.5 / 1 are a design choice. |
| proof grid (`enumerate_exact.jl`, "hybrid" default since 2026-10-27) | 0/5/10/15/20/25/30%, then 10% steps to each cap (cap included); same list for the two landlord rates (caps 100%); depth ordering unchanged | **design choice (user order 2026-10-27)**: fine resolution where committed optima live (0–30%), coarse above; legacy uniform grids remain selectable by numeric argument, so existing certificates stay valid as recorded. |
| `fossil_boiler_ban` (scen kwarg; end-of-life forced-replacement constraints in `solve_follower` + master mirror) | false (since 2026-10-27; was unconditionally ON before) | **sourced AIM, no binding rule**: EPBD 2024/1275 states the aim to phase out fossil-fuel boilers by 2040; there is NO binding Polish ban — hence OFF by default. The ON behaviour (default `ban_year` 2040, `early_ban` 2030) is kept as the named scenario `boiler_ban`; ALL results committed before 2026-10-27 were produced with the ban ON. Implementation note (pre-existing, recorded): the ban forces replacement of end-of-life boilers (33.5%/decade at 25-yr life), which exceeds the HVAC adoption cap (26.3%/decade) and therefore silently forces pre-ban switching. |

## What the archetypes do NOT specify

Building size is **not in the model**: no TABULA archetype mapping, storey
count, or dwellings-per-building exists anywhere in the repo. Floor areas
and baseline intensities are per-dwelling values only; MFH is a per-dwelling
abstraction with no building-level structure (see also fixed costs above).
The repo also nowhere states whether "MFH" includes or excludes apartment
blocks; the shares loaded for the tenure split (public 0.082, private 0.08)
use the Census-2021 denominator 8,609,900 "dwellings in multi-dwelling
buildings", which includes apartment blocks
(`bilevel_model_affordable_housing.jl:125-140`).
