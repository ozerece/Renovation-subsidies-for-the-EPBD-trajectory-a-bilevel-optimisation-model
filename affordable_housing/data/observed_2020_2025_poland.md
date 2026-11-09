# Observed renovation and heating changes in Poland, 2020–2025 (for the pl11 Phase 2 realism check)

Compiled 6 Nov 2026 from public sources. All numbers are approximate; caveats below each block.

## 1. Czyste Powietrze (single-family houses only, cumulative since Sept 2018)
| Indicator (status July 2026) | Value |
|---|---|
| Grant contracts signed | about 971,000 |
| Projects completed | over 645,000 |
| Inefficient heat sources replaced | over 603,000 |
| Grants paid | almost PLN 22 bn |

Source: summary of NFOŚiGW data published July 2026, https://pewnylokal.pl/czyste-powietrze-pod-lupa-co-dalej-z-najwiekszym-programem-termomodernizacji-domow ; end of May 2026: over 1.1 million applications and over 599,000 completed projects (https://www.gramwzielone.pl/?p=20363231).

Caveats:
- Counts start in 2018, not 2020; the share before 2020 was small (programme started late 2018) but should be subtracted if possible.
- The categories are not a simple funnel: not every contract includes a heat-source replacement, and completed projects cover different scopes.
- **No public figure found for how many projects included envelope insulation.** This is the main gap.
- Heat-source mix changed strongly: heat pumps were close to 60% of funded projects in 2023 but only about 23–25% in 2025 (https://muratordom.pl/...pomp-ciepla...); in 2024 almost half of applications were for biomass boilers (17.8% a year earlier), and biomass boilers dominated applications April–August 2025 (https://www.money.pl/gospodarka/odchodzimy-od-pomp-ciepla-oto-na-co-stawiaja-teraz-polacy-7243291646183904a.html).

## 2. Heat-pump sales in Poland (PORT PC; all buildings, including new buildings)
| Year | Sales | Note |
|---|---|---|
| 2020 | about 42,000 air-to-water (derived: 2021 was +88%) | |
| 2021 | about 93,000 total (79,000 air-to-water) | |
| 2022 | about 188,000 air-to-water (+137%); total over 200,000 | peak year |
| 2023 | roughly 120,000–125,000 (−41% vs 2022) | derived from 2024 figure |
| 2024 | 80,600 total (70,000 air-to-water for central heating), −35% | |
| 2025 | about 72,000 to wholesalers/installers (about 61,000 air-to-water) | |

Sources: globenergia.pl and gramwzielone.pl reports on PORT PC data (2021: https://globenergia.pl/polska-w-2022-r-zainstaluje-180-tys-pomp-ciepla-ograniczenia-w-dostawach-zablokuja-60-tys-instalacji/ ; 2022: https://slaskaopinia.pl/2023/02/08/port-pc-2022-rok-pomp-ciepla-w-polsce ; 2024: https://globenergia.pl/ile-pomp-ciepla-sprzedaje-sie-w-polsce-w-pierwszym-kwartale-roku-widac-odbicie/ ; 2025: https://www.gramwzielone.pl/?p=20358484 and https://www.gramwzielone.pl/?p=20353367).

Caveats: sales include new buildings and domestic-hot-water-only units; only part are retrofits of existing dwellings. Cumulative 2020–2025 sales of space-heating heat pumps are very roughly 0.5–0.6 million units.

## 3. What to compare in the model (pl11, no subsidies and record design, period 2020–2030 scaled to 2020–2025)
1. Heat-source replacements in SFH by 2025: model vs about 0.6 million (CP) plus non-CP replacements (unknown; CP is the main channel).
2. Heat pumps in existing dwellings by 2025: model vs a retrofit share of the 0.5–0.6 million sold.
3. Envelope renovations by 2025: model vs ... (no observed figure found; report the model value and flag it).

## 4. Important observation for the model (not only the realism check)
Most real replacements since 2024 are **new efficient biomass (and earlier gas) boilers**, not heat pumps. The model's heating options are heat pumps and district heat only. Replacing an old coal or wood boiler (efficiency 0.65–0.70) with a modern biomass boiler (about 0.85–0.90) cuts delivered and primary energy by roughly 20–25% at low cost. If this option is missing, the model may understate how much primary energy the stock saved in 2020–2025 and how reachable 2030 is. Please report: (a) whether such an option exists in the model; (b) if not, a quick estimate of its effect on the best reachable 2030 value (fixed-σ evaluation with an added "efficient biomass boiler" option, same cost logic as the other heating systems, cost and efficiency to be sourced). Do not change the production model for this without a decision; record it as OPEN.
