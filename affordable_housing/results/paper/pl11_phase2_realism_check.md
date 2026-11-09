# pl11 Phase 2 — realism check against observed 2020–2025 changes in Poland

Date: 2026-11-06. Inputs: `data/observed_2020_2025_poland.md` (compiled by the author); model evaluations in
`results/cert_logs/realism_pl10.log`, `realism_pl11.log` (fixed-σ follower evaluations, no search; script
`experiments/2026-11-06_review_checks/phase2/realism_eval.jl`). Biomass-boiler estimate: scratch copy only
(`experiments/2026-11-06_review_checks/phase2/biomass/`), production model untouched.

Model period 1 is 2020–2030; the 2020–2025 values below are the period-1 adoption × 0.5 (pro rata), as the
observed file asks. Counts are dwellings. "σ = 0" = no subsidies; "record" = the pl10 design of record;
"all caps" = every subsidy rate at its cap (the best reachable primary-energy path under pl11, where no
feasible design exists).

## 1. Model vs observed (Section 3 of the observed-data file)

| Indicator, 2020–2025 | Observed | pl10 σ=0 | pl10 record | pl11 σ=0 | pl11 all caps |
|---|---|---|---|---|---|
| Heat-source replacements in SFH (HP + DH) | ≈ 0.6 million (Czyste Powietrze, since 2018, mostly biomass/gas boilers and heat pumps) | **0** | **0** | **0** | **0** |
| Heat pumps in existing dwellings (all types) | retrofit share of ≈ 0.5–0.6 million sold (unknown; say 0.2–0.4 million) | 13,900 (MFH public landlords, EED obligation only) | 13,900 | 13,900 | 13,900 |
| Envelope renovations, SFH | no figure (CP: 645,000 completed projects of any scope) | 353,000 (12.6 % of SFH by 2030) | 404,000 (14.4 %) | 353,000 | 673,000 (23.9 % = capacity cap) |
| Envelope renovations, MFH | no figure | 183,000 (11.3 %) | 330,000 (20.4 %) | 183,000 | 330,000 |
| PV on existing dwellings (pl10 only; removed in pl11) | ≈ 1.4 million prosumer micro-installations by 2024 (mostly SFH, new and existing) | 494,000 SFH + 405,000 MFH | 494,000 SFH + 253,000 MFH | – | – |

Findings.

1. **The model replaces no heating system in single-family houses before 2030, in any configuration, even
   with every subsidy at its cap (heat pumps at 100 % for low-income owners).** Reason, from the model's own
   prices: a heat pump's running cost per kWh of heat demand is remain_hp × p_elec = 0.244 × 0.2634 =
   0.064 EUR, slightly above the SFH fossil-mix fuel cost of ≈ 0.060 EUR (coal 0.0594, firewood 0.0523,
   gas 0.0707 at seasonal efficiencies 0.70 / 0.65 / 0.87), and maintenance adds 2 %/yr of the capex.
   Without a carbon price before 2030 (ETS2 enters the model in the period from 2030), a free heat pump
   still raises a coal- or wood-heated household's yearly cost, so nobody installs one. Observed sales of
   0.5–0.6 million heat pumps in 2020–2025 (part of them retrofits) therefore contradict the model's
   pre-2030 behaviour. Mechanisms the model lacks: expectations of gas and coal prices in 2022, PV
   self-consumption (prosumer tariff), gas-boiler and coal-stove replacement driven by anti-smog
   resolutions, and the 2023 subsidy peak. This is an **OPEN** calibration finding (O-pl11-5): the 8 %
   discount rate was calibrated on the envelope renovation rate only, never on heating-system switching.
2. **Envelope renovation is of the right order.** The model's 0.35–0.40 million SFH envelope renovations
   by 2025 without / with the record subsidies compare with 0.6 million CP completed projects of any
   scope (no envelope-only figure exists). At the capacity cap the model allows 0.67 million by 2025.
   Flagged, not contradicted.
3. **PV (pl10 only)** was adopted by ≈ 0.9 million existing dwellings by 2025 in the model, against ≈ 1.4
   million prosumer installations observed (new and existing buildings). The order of magnitude was
   right; the removal of PV in pl11 (brief decision 1) therefore removes a mechanism that also did
   real work in 2020–2025, and it is the single reason the 2030 milestone becomes unreachable in pl11
   (see the wave entry).

## 2. Efficient biomass boiler (Section 4 of the observed-data file)

**(a) Does the option exist?** No. The model's heating measures are `hvac_fossil_to_hp` (fossil boiler →
heat pump, SCOP 3.0) and `hvac_fossil_to_district` (→ district heat). A like-for-like boiler replacement
(old coal/wood boiler → modern biomass or gas boiler) does not exist; the incumbent fossil mix keeps its
seasonal efficiencies (coal 0.70, firewood 0.65, gas 0.87, oil 0.85) for the whole horizon. The fossil-
boiler ban scenario forces switches to heat pump or district heat only.

**(b) Estimate.** A scratch copy of the pl11 model received a seventh measure `hvac_fossil_to_biomass`
(class hvac, from fossil boiler), with the same cost logic as the other heating systems:

| Parameter | Value | Source / status |
|---|---|---|
| Investment per dwelling | SFH EUR 4,767 (PLN 20,500, the Czyste Powietrze maximum eligible cost of a pellet boiler at the 100 % tier, ÷ 4.30); MFH EUR 2,335 (area-scaled like the heat pump) | web sources below; MFH scaling assumed |
| Seasonal efficiency η_bio | 0.87 (base; brief range 0.85–0.90); 0.80 sensitivity (Ecodesign seasonal values of pellet boilers are 78–80 %) | manufacturer data sheets (sources below) |
| Energy effect | delivered energy × η_incumbent / η_bio (SFH mix η 0.731 → −16 %; MFH 0.769 → −12 %); applied like the other heating measures | model convention |
| Fuel | wood price of the model, 0.0523 EUR/kWh (base); 0.068 EUR/kWh pellet sensitivity | model; pellet ≈ PLN 1,400/t ÷ 4.8 kWh/kg |
| CO₂ | 0 (biomass under ETS2) | as the model's firewood |
| Primary energy factor | WOOD_PEF of the scenario = 1.1 (total primary energy, pl11 standard) | model |
| Lifetime / learning / maintenance | 20 yr / 0 / 2 %/yr of capex (hvac class) | model |
| Subsidy | none (no σ key; fz = 0) | fixed-σ question |
| Capacity | shares the 4 %/yr heating-system cap with HP and DH; **excluded** from the heating ≤ envelope + 0.3 rule (a boiler swap needs no insulation) | assumption |

Results (fixed-σ evaluations of pl11; target 2030 = 222.12 kWh/(m²·yr); without the option the best
reachable 2030 value at all caps is 230.39, a miss of 8.26):

| Variant | 2030 at all caps (miss) | 2035 | 2040 (miss) | 2050 (miss) | SFH biomass boilers by 2030 (all caps) | SFH by 2025 pro rata, σ = 0 | HP in SFH by 2050 |
|---|---|---|---|---|---|---|---|
| none (pl11) | 230.39 (−8.26) | +20.6 | 148.9 (+9.8 slack) | 75.1 (+33.3) | 0 | 0 | 37.5 % |
| η 0.87, wood price | **226.11 (−3.98)** | +9.1 | 177.5 (−18.8) | 134.2 (−25.8) | 1.63 million (29 %) | 0.89 million | 5.0 % |
| η 0.80, wood price | 231.22 (−9.09) | +1.7 | 186.6 (−27.9) | 145.6 (−37.2) | 0.86 million (15 %) | 0.49 million | 5.0 % |
| η 0.87, pellet 0.068 | 230.51 (−8.38) | +10.5 | 169.5 (−10.9) | 108.5 (−0.1) | 0 | 0.43 million | 20.9 % |

Reading.

- At the brief's efficiency (0.87) and the model's wood price, the option closes about half of the 2030
  gap (8.26 → 3.98 kWh/(m²·yr)); **2030 stays unreachable** at all caps. At a seasonal efficiency of 0.80
  it makes 2030 slightly worse, because the cheap boiler crowds out envelope renovation (SFH envelope by
  2030 at caps 23.9 % → 14.4 %) and the efficiency gain no longer compensates. At pellet prices nobody
  adopts it before 2030.
- Its σ = 0 uptake (0.4–0.9 million SFH boilers by 2025) is of the same order as the observed 0.6 million
  CP replacements, so the option is the missing realism mechanism for heat-source replacements.
- **But it is a lock-in**: with the biomass primary energy factor at 1.1 (total primary energy, as the
  EPBD trajectory requires in the pl11 standard) and no carbon cost, the biomass boiler removes the only
  driver of heat-pump adoption after 2030. Heat pumps in SFH by 2050 fall from 37.5 % to 5 %, and the
  2040 and 2050 milestones, which pl11 reaches with slack at the caps, are missed by 19–28 and 26–37
  kWh/(m²·yr). Under the non-renewable convention (firewood factor 0.2, scenario `woodpef`) the same
  option would look like a primary-energy saving instead; the two conventions give opposite policy
  readings of a biomass boiler. Not evaluated here.

**OPEN (O-pl11-4, decision 8 of the brief).** Whether to add a biomass-boiler (or gas-boiler) replacement
option to the production model, and under which primary-energy convention and subsidy eligibility
(Czyste Powietrze subsidised pellet boilers until 2025; EPBD Art. 17(15) bans incentives for stand-alone
fossil boilers from 2025, biomass is not fossil), is a user decision. The scratch estimate says: it does
not make 2030 reachable, it improves the realism of 2020–2025 heat-source replacements, and it damages
2040/2050 under the total-primary-energy convention.

## 3. Files

- Evaluations: `results/cert_logs/realism_pl10.log`, `results/cert_logs/realism_pl11.log`
  (production model, branch pl11, fixed σ).
- Biomass scratch copy, patch (`patch_bio.py`), evaluation script and the three logs:
  `experiments/2026-11-06_review_checks/phase2/biomass/`.

Sources for the biomass parameters (web, 2026-11-06): Czyste Powietrze pellet-boiler grant limits 8,200 /
14,350 / 20,500 PLN at 40 / 70 / 100 % ([globenergia.pl](https://globenergia.pl/dotacja-na-kotly-na-pellet-w-czystym-powietrzu-do-likwidacji/),
[muratordom.pl](https://muratordom.pl/instalacje/ogrzewanie-paliwami-stalymi/dofinansowanie-do-pieca-na-pellet-2024-ile-wynosi-i-jak-je-uzyskac-aa-hPyW-Q9ue-VNu2.html));
seasonal efficiency of pellet boilers 78–80 % on Ecodesign data sheets vs 90–95 % nominal
([MCZ Selecta](https://www.mcz.it/en/products/selecta/), [Defro Calori](https://7sun.eu/produkt/kociol-defro-calori-30-kw-2),
[Metal-Fach SEG Pellet](https://kotly.com.pl/produkt-kociol-metal-fach-seg-pellet-25-5567.html?l=en)); class-5 minimum efficiency 88 %
([Nocoń & Jach, Polish Academy of Sciences](https://journals.pan.pl//Content/113287/PDF/08-Jach-Noco%C5%84-i-inni.pdf)).
