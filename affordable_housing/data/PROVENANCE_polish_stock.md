# PROVENANCE — Polish stock input packet

Provenance for the Polish building-stock inputs (the "Polish stock input
packet" the stock-rescaling round waits for). Entries are recorded as
delivered by the user; source strings verbatim. Companion to
`PROVENANCE.md` (which covers the stylised inputs currently loaded).
Nothing in this file is loaded into the model yet — loading happens only
on explicit order, with its own CHANGELOG entry.

## Worst-performing buildings and energy performance

*(recorded 2026-10-27, user-delivered)*

**Source:** Invert/EE-Lab (TU Wien), Poland (XOL), Status quo 2020, output
of 17 Oct 2025 (file `Auswertung_Verteilung_Ergebnisse_XOL_output_25_10_17.xlsx`).
The data cover single-family and multi-family houses only.

**Metric:** primary energy demand in kWh/(m²·yr) per gross floor area,
calculated demand ("exclusive service factor") in the main run; demand
adjusted for user behaviour ("inclusive service factor") as a sensitivity.

**Method:** both building types are merged and ranked by primary energy
demand; the worst-performing buildings are the worst 43% of the combined
floor area (EPBD Art. 9(2)). Threshold: about 240 kWh/(m²·yr).

**Result:** 62.6% of single-family and 18.2% of multi-family floor area are
worst-performing; average primary energy demand:

| Segment | Worst-performing | Rest |
|---|---|---|
| Single-family | 393 kWh/(m²·yr) | 139 kWh/(m²·yr) |
| Multi-family | 262 kWh/(m²·yr) | 120 kWh/(m²·yr) |

**Source split:** dwelling counts and floor areas come from the 2021
census; only the shares and average values come from Invert.

**Scope note:** the EPBD defines the 43% over the whole residential stock;
we apply it to the modelled stock (single- and multi-family houses).

**Hot-water note (2026-10-27):** the delivered workbook
(`Auswertung_Verteilung_Ergebnisse_XOL_output_25_10_17.xlsx`) is not in the
repo, so whether the primary-energy values include domestic hot water
could NOT be verified here. Invert/EE-Lab stock outputs conventionally
cover space heating plus hot water, but this must be confirmed against
the workbook — OPEN.

## Stock scope and dwelling counts (census) — DRAFT 2026-10-27, CHECKS FAILED, NOT LOADED

**Scope (user order 2026-10-27):** single-family houses (1–2 dwellings) and
multi-family houses (3–19 dwellings); apartment blocks (20+) excluded;
inhabited dwellings only; absolute national stock.

**Source:** GUS, *Warunki mieszkaniowe w Polsce w świetle wyników
Narodowego Spisu Powszechnego Ludności i Mieszkań 2021* (final results),
tables workbook downloaded 2026-10-27 from stat.gov.pl, stored as
`data/gus_nsp2021_warunki_mieszkaniowe_tablice.xlsx`. Used: buildings
Tabl. 5 (buildings/dwellings/floor area, urban & rural, incl. inhabited)
and buildings Tabl. 2 (dwellings by number of dwellings per building —
**urban areas only**; no rural size split exists in the publication);
publication text: 97.5% of rural inhabited buildings are single-family.

| Quantity | Value | Source / derivation |
|---|---|---|
| Urban dwellings by building size (2021) | 1 dw: 1,798,547; 2 dw: 320,438; 3–5: 410,967; 6–9: 760,710; 10–19: 1,747,675; 20–49: 2,344,344; 50–99: 1,729,410; 100+: 994,973 | sourced, Tabl. 2 |
| Urban SFH (1–2) / MFH (3–19) / blocks (20+) | 2,118,985 / 2,919,352 / 5,068,727 | derived from Tabl. 2 |
| Rural residential dwellings / buildings | 4,433,501 / 3,772,676 | sourced, Tabl. 5 |
| Rural SFH dwellings | 3,979,234 | **DERIVED WITH ASSUMPTIONS**: 97.5% of rural buildings SFH (publication text) × urban dwellings-per-SFH-building ratio 1.0818 (Tabl. 2) |
| Rural MFH (3–19) dwellings | 454,267 | residual; **ASSUMPTION**: no rural 20+ blocks |
| Inhabited shares | urban 0.8994, rural 0.9735 | sourced, Tabl. 5 (applied per urban/rural, finer than one overall share) |
| **Inhabited SFH / MFH(3–19)** | **5,779,627 / 3,067,781** (8,847,407 total) | derived as above |
| Floor area per dwelling | SFH 108.6 m², MFH 53.2 m² | user order (census) |
| Floor areas | SFH 627.7M m² (79.4%), MFH 163.2M m², total 790.9M m² | derived |

**Energy conversion (order):** final = Invert primary ÷ base-year PEF
(fossil 1.1, DH 0.85); **ASSUMPTION**: uniform primary within each
performance group across heating carriers. Heating at start (order,
assumption): SFH 100% fossil (≈2% DH ignored); MFH wpb 25% DH / 75%
fossil, MFH rest 48% / 52% (overall 43.8% ≈ the 44% census-based
estimate). Tenure (MFH only): public 13.4%, private 8%, equal across
performance groups (assumption). Income: owners 15% low-income, tenants
23% (GUS HBS 2024 lowest quintile + Eurostat ilc_lvho02 2024 tenant
ratio 1.5×); resulting total 15.59% of households.

**Draft table:** `data/archetypes_pl_DRAFT.csv` (12 rows; tenure split
would add rented twins at runtime). **NOT loaded into the model.**

## Resolution and stock of record (2026-10-27, user decisions) — LOADED into `archetypes_pl.csv`

1. **WPB cut re-derived at census floor-area weights** (user-delivered;
   method: Invert status-quo-2020 distributions "exclusive SF" per building
   type, rescaled to the census floor-area shares, merged, ranked by
   primary energy demand, cut at 43% of combined floor area):
   threshold ≈ **275 kWh/(m²·yr)**; WPB shares **52.5% SFH / 7.1% MFH**;
   averages **421/162** (SFH worst/rest), **281/135** (MFH worst/rest)
   primary. **VERIFICATION OPEN**: the Invert workbook named in the order
   ("attached") did not arrive on this machine and is NOT in data/; the
   numbers are recorded from the order and verified only arithmetically
   (internally consistent: at the pre-decision census weights they give
   exactly 43.1% and 266.5). The "inclusive SF" sensitivity is BLOCKED
   until the workbook arrives.
2. **Rural split, dwelling-based** (user decision; replaces the
   building-share estimate): 14% of rural dwellings in multi-dwelling
   buildings, no rural 20+ blocks → rural SFH 3,812,811 / rural MFH
   620,690. NOTE: the order cites this estimate as "already in
   PROVENANCE"; it was not previously recorded here — recorded now from
   the order.
3. **Incomes**: owners 15.9% low-income, tenants 23.8% (keeps the 1.5
   Eurostat ratio; GUS HBS 2024 lowest quintile ≈16.2% benchmark).
4. **Hot water**: Invert values treated as TOTAL heat demand for now —
   OPEN (see hot-water note above).
5. **KPRB demand sensitivity** (`archetypes_pl_kprb.csv`): final demand
   per building type rescaled so type averages match the KPRB finals
   **SFH 177.4 / MFH 162.0 kWh/(m²·yr)** (user-delivered; cited as "in
   PROVENANCE" but not previously recorded — recorded now), worst/rest
   ratio kept; scales ×0.6549 (SFH), ×1.0830 (MFH).

**Stock of record** (inhabited, national absolute): SFH **5,617,609**,
MFH(3–19) **3,229,798**, total **8,847,407**; areas 610.1M / 171.8M m²
(SFH share 78.0%). Final-energy intensities = primary ÷ base-year PEF
(fossil 1.1 / DH 0.85; uniform primary within performance group —
assumption): SFH 382.7/147.3; MFH-DH 330.6/158.8; MFH-fossil 255.5/122.7.
Heating splits and tenure/income as ordered (MFH DH overall now 46.4%;
the earlier ≈44% figure corresponded to the superseded 18.2% WPB share).

### UPDATED CHECKS (2026-10-27, after the decisions) — PASS
| Check | Result | Target |
|---|---|---|
| Totals match census | ✓ 8,847,407 dwellings, areas above | — |
| WPB share of floor area | **42.52%** ✓ (0.5 pp below 43 — effect of the ordered rural-split change: SFH area share 79.4% → 78.0%) | ≈43% |
| Stock-average primary | **264.4** ✓ (−0.8%, same cause); model prints 264.4 at load | ≈266.5 |
| Low-income total | **16.52%** ✓ (+0.3 pp) | ≈16.2% |
| Existing scenarios reproduce | gate run at implementation (see CHANGELOG) | pass |

### Household discount rates (pl_r8 family, 2026-10-27 user order)

| Group | Rate | Status / source |
|---|---|---|
| State (leader; spending, reporting) | 3% | unchanged (context.csv `discount_rate`, assumed). |
| Owner-occupiers, private landlords | **8%** | **CALIBRATED (user order, 2026-10-27)**: chosen so the zero-subsidy envelope renovation pace before 2030 (≈0.9%/yr in the σ=0 diagnostic at r=8%) matches the observed EU energy renovation rate of about 1%/yr (EC comprehensive renovation study 2019). Literature context: Schleich et al. 2016, Kubiak 2016 (household implicit discount rates). |
| Public landlord | 3% | assumed = the state rate (municipal actor). |
| Sensitivities | all households 12% (`pl_r8_all12`); low-income 12% / high-income 8% (`pl_r8_split`) | design choices, literature-motivated spread (poorer households discount more heavily — Schleich et al. 2016). |

Implementation: follower-objective discounting per archetype
(`household_discount_rates`, `fdisc`); the leader keeps the state rate.
LIMITATION, recorded: the salvage credit (`net_capex_factor`) and the
affordability annuities keep the global state rate (measure×period, not
archetype-specific).

### Carrier energy prices and fossil fuel mixes (phase 1, 2026-10-27 user order)

Household prices per kWh of FINAL energy, **real EUR 2024** (FX pinned
4.30 PLN/EUR, house convention), **including taxes, excluding ETS2** (the
model adds the carbon cost on the fossil fraction separately), **held
constant in real terms** over the horizon (user order; electricity ±20%
defined as a sensitivity). Final energy = fuel energy content; no
separate boiler-efficiency adjustment (same convention as the Invert
final-demand calibration).

| Carrier | EUR/kWh | Source / derivation |
|---|---|---|
| Electricity | **0.2634** | Eurostat `nrg_pc_204`, PL, band DC (2,500–4,999 kWh), all taxes, EUR/kWh: **2025 average** (S1 0.2559 / S2 0.2709; API pull 2026-10-27). **USER CORRECTION 2026-10-27**: the 2024 average (0.2284) sat fully under the household price freeze (energy component capped at 500 PLN/MWh), so the 2025 average is used as the base value; the continuing unwind (2026-S1 0.2999) and the freeze level are covered by the ±20% sensitivities (0.3161 / 0.2107). |
| Natural gas | **0.0707** | Eurostat `nrg_pc_202`, PL, band D2 (20–200 GJ), all taxes: 2023 avg (S1 0.0683 / S2 0.0730). PL is CONFIDENTIAL in the series from 2024; household gas tariffs were frozen at the 2023 level (200.17 PLN/MWh net) through mid-2024, so the 2023 value is carried as the 2024 price — documented. |
| Hard coal | **0.0594** | GUS official annual average retail price: **1,703.46 PLN/t for 2024** (communiqué 15 Jan 2025, M.P. 2025 poz. 52) ÷ 24 MJ/kg (6.667 kWh/kg; household-sortiment calorific convention, ASSUMED, stated) ÷ 4.30. |
| Firewood | **0.0523 — FLAGGED** | **No GUS average retail price series exists for firewood** (unlike coal). Market reports 2024: consumer seasoned split logs ≈ 400–700 PLN/m³ (Czyste-Powietrze-program market summary; budujemydom 200–550), forest-gate S4 ≈ 150–250 PLN/m³. Central value used: **450 PLN/m³** ÷ ≈2,000 kWh/m³ (seasoned hardwood) ÷ 4.30. FLAGGED for replacement; bills of wood-heated dwellings scale with it. |
| Heating oil | **0.1065 — FLAGGED** | market level ≈ 4.55 PLN/l ÷ 9.94 kWh/l ÷ 4.30; no official average found; weight only ≈1% of fossil heating — immaterial, flagged. |
| District heat | **0.1151** | URE, *Energetyka cieplna w liczbach 2024*: average heat price, all licensed sources **105.74 PLN/GJ** + average transmission charge **31.76 PLN/GJ** = 137.50 PLN/GJ ÷ 277.78 kWh/GJ ÷ 4.30. Revenue-averaged, so fixed charges are included per GJ by construction (user-ordered reading); household-specific end tariffs are not published separately. DH consumer prices were also shielded ("mrożenie", compensated generation price 119.39 PLN/GJ net H2-2024). |

**Fossil fuel mixes (price and ETS2 CO₂ factor from the SAME mix; stock
files `archetypes_pl_mix.csv` / `archetypes_pl_kprb_mix.csv`):**
- Coal/wood split WITHIN solid fuels: GUS *Zużycie energii w
  gospodarstwach domowych w 2024 r.* (signal publication 09.01.2026,
  stored `data/gus_zewgd_2024_sygnalna.pdf`): households heating with
  hard coal 17.1%, lignite 1.0%, coke 0.3%, firewood 17.1% → coal-like
  18.4 / wood 17.1 = **51.8% / 48.2%** (household-count based, not
  energy-based — limitation stated; the publication itself notes the
  small survey sample).
- **SFH fossil mix**: census solid 68.9% / gas 26.5% / oil 1.0% of
  individually heated dwellings (user order; verified against NSP 2021
  Tabl. 24: 3,586,767 / 1,380,744 / 50,827 of 5,207,390 excl.
  not-established ✓), renormalized over fossil carriers and split →
  **coal 0.3702, wood 0.3445, gas 0.2749, oil 0.0104**.
- **MFH fossil mix — PROPOSED (assumption, 2026-10-27)**: NSP 2021
  Tabl. 24 URBAN individually-heated fuel structure (solid 985,191 /
  gas 882,138 / oil 21,385 → fossil-only 52.2/46.7/1.1%), same
  coal/wood split → **coal 0.2704, wood 0.2516, gas 0.4670,
  oil 0.0110**. Rationale: our MFH stock is 85% urban and MFH individual
  heating is gas-heavier than the national (SFH-dominated) mix; caveat:
  urban individual heating still includes urban SFH, so the coal share
  for MFH may be overstated — flagged.
- **ETS2 CO₂ factors (kg/kWh final; user order, KOBiZE/IPCC-consistent;
  wood counts 0 under ETS2):** coal 0.34, gas 0.20, oil 0.27, wood 0.
  Resulting archetype intensities: SFH fossil **0.1837**, MFH fossil
  **0.1883** (replace the stylised 0.30 whenever carrier prices are on).
- Resulting fossil-mix prices: SFH **0.0606**, MFH **0.0634** EUR/kWh.
- **Δp_hp ≡ 0 removed** and **seasonal generation efficiencies added
  (phase-1 correction (1), 2026-10-27)**. Before the correction the model
  carried NO explicit boiler efficiency: E0 (Invert final energy) was
  implicitly treated as useful heat in the heat-pump link (electricity
  = E0 × 0.33 = E0/SCOP, i.e. η_boiler = 1), and the DH switch used the
  measure's fixed 0.70 remain factor (code comment "boiler-efficiency
  gain only") — the only two places an efficiency notion existed. Now,
  with `carrier_etas` set: useful heat = E0 × η_a (η_a = Σ mix × η_fuel),
  heat-pump electricity = E0 × η_a ÷ SCOP 3.0, DH-switch delivered heat
  = E0 × η_a ÷ η_dh — applied to the bills (per-archetype Δp), the
  final-energy switch accounting (per-archetype HVAC reduction factors)
  AND the primary energy (per-archetype carrier coefficients).
- **η_H,g of record (PROPOSED stock averages, FLAGGED):** coal boilers/
  stoves **0.70**, wood **0.65**, gas (mixed conventional/condensing
  stock) **0.87**, oil **0.85**, DH substation **0.95**. Source frame:
  the Polish energy-performance-certificate methodology's η_H,g tables
  (rozporządzenie on the methodology, Dz.U. 2015 poz. 376 as amended;
  table values corroborated via certification-software documentation:
  coal boilers post-2000 ≈ 0.82, 1980–2000 ≈ 0.65–0.75; the regulation
  text itself was not retrievable online — exact table citation OPEN).
  Resulting η: SFH **0.7311**, MFH **0.7685**; remain_hp 0.2437 / 0.2562
  (was 0.33); remain_dh 0.770 / 0.809 (was 0.70). Δp_hp (SFH) =
  0.2437×0.2634 − 0.0606 = **+0.0036 EUR/kWh heat** — heat pumps now
  roughly bill-neutral vs the coal/wood mix at 2025 electricity prices,
  and clearly cheaper than a boiler once the CO₂ price is added.
- **Pinning:** `carrier_etas=nothing` (default) keeps the legacy
  implicit-η=1 behaviour for every scenario of record, gate-verified.
- **Pinning:** `carrier_prices=nothing` (the default) keeps the legacy
  hard-coded prices and scalar Δp for every scenario of record —
  bit-identical, gate-verified; the new prices enter only the pl9
  scenarios (phase 2 reruns pending user OK).

### Capacity and trajectory settings of record (pl_* scenarios)
- Envelope limit (KPRB operational scenario; single-family renovations
  per year ÷ 6.93M buildings; same profile ASSUMED for MFH): 2.7%/yr to
  2030, 3.2% 2030–35, 3.6% 2035–40, 3.9% from 2040 (held at peak).
- Heating-system limit 4%/yr (25-yr boiler lifetime); sensitivity 6%.
- Joint labour cap = envelope + 0.4 × heating (user-approved):
  4.3/4.8/5.2/5.5 %/yr (6%-sens: 5.1/5.6/6.0/6.3); PV competes inside
  it; cap logic unchanged.
- EPBD trajectory relative to the model's own 2020 stock average
  (264.4): −16% (2030) / −20% (2035) SOURCED EPBD Art. 9(2); −40%
  (2040) / −59% (2050) ASSUMED (committed relative depths) →
  222.1/211.5/158.7/108.4 kWh primary/m²·yr.
- Costs, energy prices, PEF paths unchanged — **assumed, to be
  replaced** (user order 2026-10-27).

### Superseded: first construction (same day) — two FAILURES, work STOPPED before any run

| Check | Result | Target |
|---|---|---|
| Totals match census | ✓ by construction (8,847,406 dwellings; areas above) | — |
| WPB share of combined floor area | **53.4% — FAIL** | 43% |
| 2020 stock-average primary energy | **266.6 kWh/m²·yr — FAIL** | ≈232 |
| Low-income total | 15.59% — near-miss (−0.6 pp) | ≈16.2% |
| MFH DH share overall | 43.8% ✓ | ≈44% |
| Existing scenarios reproduce | not re-run (stopped at the stock checks; last gate 2026-10-27 PASSED 8/8 ×2) | pass |

**Diagnosis:** Invert's 43% WPB cut with segment shares 62.6%/18.2%
implies an SFH share of the combined floor area of **55.9%**; the census
SFH(1–2)+MFH(3–19) scope gives **79.4%**. At Invert's implied weights the
stock-average primary is 230.8 (≈232 ✓); at census weights it is 266.6.
Even including apartment blocks in MFH (against the ordered scope) gives
only SFH 60.7% / WPB 45.2% / avg 238.3. The Invert XOL stock frame and
the census SFH+MFH(3–19) scope are structurally different — the segment
shares/averages cannot be transplanted onto the census counts without a
decision. Not resolved here (recorded as a finding, per the standing
rule).

## Investment costs (2026-10-29 order) — Polish sources, scen kwarg `measure_costs`, NOT yet on any scenario of record

All PLN→EUR at **4.30 PLN/EUR** (house convention, same as the carrier
prices above). Implemented as scen kwarg `measure_costs` (nothing =
legacy measures_v2.csv values, bit-identical); constant
`MEASURE_COSTS_PL2026` in the model file. DH connection and PV keep the
legacy values by order.

### Sources (files stored in data/)

- **Czyste Powietrze cost annex**: "Załącznik nr 2 do Programu
  Priorytetowego Czyste Powietrze. Koszty kwalifikowane oraz maksymalny
  poziom dofinansowania", **valid from 20.07.2026**, czystepowietrze.gov.pl
  → `czyste_powietrze_zalacznik2_od_2026_07_20.pdf` (downloaded
  2026-10-29 with full TLS verification; the server omits its
  intermediate certificate, which was fetched from the leaf's AIA URL at
  repository.certum.pl and the chain verified OK against the system
  roots). Tiers: podstawowy/podwyższony/najwyższy = **do 40% / do 70% /
  do 100% kosztów kwalifikowanych** — the highest-tier grant amount
  equals the eligible (net) unit cost.
- **KPO/FEnIKS unit-cost table**: "Tabela kosztów jednostkowych dla
  termomodernizacji domu" (MKiŚ/NFOŚiGW + 16 WFOŚiGW, introduced
  June 2025, used to assess payment requests in the KPO/FEnIKS-funded
  programme) → `czyste_powietrze_kpo_tabela_kosztow_jednostkowych.pdf`
  (copy from bip.wfosigw.rzeszow.pl). Its "koszt kwalifikowany
  rekomendowany" values (walls 250, attic ceilings/floors 150, windows
  1,200, doors 2,500 zł/m²) are the market-analysis basis; the ANNEX
  values govern here (user order: unit costs at the 100% tier of the
  annex).

### Eligible unit costs used (annex od 20.07.2026, 100% tier)

| Item (annex row, verbatim) | zł/m² |
|---|---|
| Ocieplenie stropów/poddaszy (roof over heated top floor / top ceiling) | **220** |
| Ocieplenie ścian | **275** |
| Stolarka okienna | **1,320** |
| Stolarka drzwiowa | **2,750** |
| (Ocieplenie podłóg — NOT in the ordered deep bundle) | 165 |
| Envelope total (przedsięwzięcie nr 3, highest tier, grant cap) | **83,000 zł** |

FINDING: the current annex lists only ONE air-water heat-pump row —
"Pompa ciepła powietrze/woda **o podwyższonej klasie efektywności
energetycznej**", 14,080/24,640/**35,200 zł** at 40/70/100%. A
standard-class air-water row (eligible 30,000 zł) is NOT in this
version — since 20.07.2026 only higher-efficiency-class air-water HPs
are eligible. The order's "30,000–35,200" range therefore spans the
former standard-class and the current higher-class eligible costs.
District heat connection ("Podłączenie do sieci ciepłowniczej wraz z
przyłączem"): highest grant **22,250 zł** (= eligible cost at 100%).

NOTE: annex amounts are **net of VAT** ("kosztów kwalifikowanych
netto"). Household market prices include 8% VAT (reduced rate for
residential renovation); the derived costs below follow the order
("eligible cost") and are NOT grossed up — flagged.

### Typical envelope geometry (documented assumption)

- **SFH, 108.6 m²** (stock-of-record average usable area): two heated
  storeys ("kostka"-type), square footprint 54.3 m² (side 7.37 m,
  perimeter 29.48 m), storey height 2.7 m → gross external wall
  159.2 m²; windows 13.58 m² (window:floor = 1:8, the daylighting
  minimum of the Polish technical conditions, taken as typical);
  external door 2.0 m² (the annex's own "standardowe drzwi ok. 2 m²")
  → net wall **143.6 m²**; pitched roof over heated attic at 35° =
  54.3/cos 35° = **66.3 m²**.
- **MFH, 53.2 m² per dwelling**: representative block of **12 dwellings
  on 4 storeys** (census band is 3–19 dwellings), total heated area
  638.4 m², square footprint 159.6 m² (perimeter 50.53 m — the
  perimeter-minimal convention, i.e. a LOWER bound on wall area),
  height 10.8 m → gross wall 545.8 m²; windows 79.8 m² (1:8); one
  entrance door 2.0 m² → net wall 464.0 m². Per dwelling (÷12): walls
  **38.66 m²**, flat roof/top ceiling **13.30 m²**, windows
  **6.65 m²**, doors 0.167 m².

### Derived per-dwelling costs (PLN and EUR), vs legacy

| Measure | mapping | SFH PLN | SFH EUR | legacy | MFH PLN | MFH EUR | legacy |
|---|---|---|---|---|---|---|---|
| envelope_light | roof/attic insulation | 14,583 | **3,391** | 5,687 | 2,926 | **680** | 3,194 |
| envelope_medium | wall insulation | 39,488 | **9,183** | 12,360 | 10,632 | **2,473** | 6,820 |
| envelope_deep | walls+roof+windows+doors | 77,490 (< cap 83,000) | **18,021** | 24,720 | 22,795 | **5,301** | 13,640 |
| hvac_fossil_to_hp | air-water HP | 37,500 | **8,721** | 15,258 | 18,370 | **4,272** | 13,596 |
| hvac_fossil_to_district | DH connection | KEPT | 5,629 | 5,629 | KEPT | 4,798 | 4,798 |

- Heat pump SFH: **37,500 PLN market level 2026 incl. installation**
  (user-given; market range 30,000–45,000 → EUR sensitivities
  **6,977 / 10,465**). Annex eligible cost (higher efficiency class)
  35,200 zł = 8,186 EUR sits inside the range.
- Heat pump MFH: **PROPOSED, FLAGGED** — 37,500 × 53.2/108.6 =
  18,370 PLN (**4,272 EUR**): per-dwelling capacity scales with heated
  area at equal specific demand; economies of a central/cascade system
  are assumed to offset the per-kW premium of smaller units. No Polish
  MFH heat-pump cost series exists; Ciepłe Mieszkanie (the MFH
  counterpart programme) secondary sources conflict (per-flat air-water
  HP grant caps 15,000/25,000/37,500 zł in call 1, 16,500/27,500/41,000
  in call 2). Sensitivities from the SFH range scaled the same way:
  14,696 / 22,044 PLN = **3,418 / 5,127 EUR**.
- DH connection: KEPT at legacy (15 €/m² + 4,000 € → SFH 5,629 / MFH
  4,798 EUR); documented source: the annex's highest grant 22,250 zł =
  **5,174 EUR** brackets both values (−8% / +8%).

### Structure decision

The ordered €/m² + fixed form does NOT fit: these costs scale with
ENVELOPE area, not floor area. An exact two-point fit to the two
dwelling types of record gives negative fixed costs (light −1,923,
medium −3,971, deep −6,914 EUR), so `measure_costs` stores per-dwelling
TOTALS per (btype, m_id); the learning-rate multiplier and every other
use of inv_cost are unchanged.

FLAG (cost–benefit mismatch, recorded, not tuned): envelope_light for
MFH now costs only the top-ceiling share (680 EUR) while the measure's
reduction factor (0.25 of whole-dwelling demand) is calibrated for a
whole-dwelling light retrofit — top-ceiling insulation does not deliver
0.25 to mid-floor dwellings. Decision on the MFH light-measure mapping
is the user's.

### Review changes (2026-10-29, user order after branch review)

**(1) VAT.** The annex eligible costs are net; the ENVELOPE per-dwelling
costs are multiplied by **1.08** (8% reduced VAT rate on residential
renovation in Poland). The heat-pump market price (37,500 PLN incl.
installation) is already gross and stays; MFH heat pump accepted as
flagged. VAT'd values of record (EUR): SFH light **3,663** / medium
**9,918** / deep **19,463**; MFH light **735** / medium **2,670** /
deep **5,725**.

**(2) Component-consistent envelope saving factors** (scen kwarg
`measure_reductions`, constant MEASURE_REDUCTIONS_PL2026; nothing =
legacy 0.25/0.45/0.70 from measures_v2.csv, bit-identical).

Method: share of the per-dwelling steady-state heat balance removed by
renovating exactly the costed components —
r = Σ_renovated A_i (U_before,i − U_after,i) / H_total, with
H_total = Σ_all A_i U_before,i + 0.34·n·V (transmission through walls,
roof, windows, doors, floor + ventilation at n = 0.5 h⁻¹, ASSUMPTION,
natural ventilation; net room height 2.6 m). Floor and ventilation stay
UNRENOVATED in the balance (the cost scope has no floor insulation or
ventilation measure). Solar/internal gains are not modelled — the loss
ratio is used as the demand ratio (documented proxy). Geometry: same as
the cost derivation above.

U-values (W/m²K), sourced:

| Component | SFH before | MFH before | after (both) |
|---|---|---|---|
| Walls | 1.40 | 1.16 | **0.20** |
| Roof / top ceiling | 1.10 | 0.60 | **0.15** |
| Windows | 3.30 | 2.60 | **0.90** |
| Doors | 2.60 | 2.60 | **1.30** |
| Floor (unrenovated) | 1.80 | 1.30 | — |

- Before: **NAPE "Podręcznik typologii budynków mieszkalnych"** (the
  Polish TABULA/EPISCOPE deliverable; stored as
  `nape_tabula_typologia_budynkow_podrecznik.pdf`), STAN WYJŚCIOWY of
  the **1967–1985 catalogue sheets PL.N.SFH.03.gen / PL.N.MFH.03.gen**
  — the last cohort under the pre-1983 insulation norms (PN-64/PN-74
  walls U ≤ 1.16–1.40), i.e. the WPB frame. Doors: the handbook's old
  WT requirement row "Drzwi i wrota w przegrodach zewnętrznych 2,6".
- After: **WT 2021** U_max (Rozporządzenie in sprawie warunków
  technicznych, załącznik 2, values in force from 31.12.2020: walls
  0.20, roofs 0.15, windows 0.90, external doors 1.30) — the same
  standard the Czyste Powietrze annex requires renovated components to
  meet, so costs and savings describe the same retrofit.

Resulting factors (legacy 0.25/0.45/0.70 for every archetype):

| Measure | SFH new | MFH new | legacy |
|---|---|---|---|
| envelope_light (roof only) | **0.134** | **0.054** | 0.25 |
| envelope_medium (walls only) | **0.367** | **0.333** | 0.45 |
| envelope_deep (all four) | **0.576** | **0.490** | 0.70 |

Plausibility: deep removes 83.5% (SFH) / 77.4% (MFH) of the loss
through the four renovated components; the whole-dwelling factor is
lower because the unrenovated floor + ventilation remain (24.6% of the
SFH balance, 36.6% of the MFH balance). After-deep final energy for the
WPB SFH: 382.7 × (1−0.576) = 162 kWh/m² — the "modernizacja
standardowa" level of the NAPE sheets (envelope-only retrofit, no
ventilation heat recovery), plausible. Period-choice sensitivity (the
1946–1966 sheets instead): SFH 0.093/0.468/0.629, MFH
0.082/0.304/0.480 — deep moves by ±0.05, light/medium shift with the
period's wall/roof construction.

CONSEQUENCE FLAG (recorded, not tuned): the new deep factors (0.576 /
0.490) are materially below the stylised 0.70 while costs also fell —
net effect on EPBD-trajectory feasibility is an empirical phase-2
question; if milestones become infeasible that is a finding.
Implementation: redfac_am override (follower r_env + master mr_env);
`test_invariants.jl` recomputes r_env/r_hvac from the raw
measures_v2.csv factors and is valid at DEFAULTS only (pre-existing
condition since the η change for HVAC).

## Inclusive-service-factor stock (pl10_inclusive, 2026-10-29) — and VERIFICATION of the standard cut

**Source found on this machine** (user pointer): the Invert/EE-Lab
distribution curves are in
`../../writing/epbd.wise_paper/data/dist_curve.xlsx` (country XOL =
"Poland (updated building stock)", scenario "Status quo 2020",
Residential, service_factor ∈ {excluding, including}, 100
area-percentile points per building type with ranked primary energy
demand). The 2026-10-27 note that "the workbook did not arrive" was
about the named Auswertung file; the same distributions live in this
curve export. A related aggregate export is
`WPB_data_POL.xlsx` (PED by year/portion, both SFs, no type split).

**Method** (same as the standard): within-type distributions rescaled
to the census floor-area shares, merged, ranked by primary energy,
cut at 43% of combined area. At the record weights (SFH 78.0%):

| | threshold | SFH wpb | SFH worst/rest | MFH wpb | MFH worst/rest | stock avg |
|---|---|---|---|---|---|---|
| EXCL (re-derived) | 274.6 | 52.9% | 424.2/161.9 | 7.9% | 283.2/135.1 | 266.8 |
| EXCL (delivered, stock of record) | ≈275 | 52.5% | 421/162 | 7.1% | 281/135 | ≈266.5 |
| INCL (re-derived) | 266.1 | 50.7% | 378.6/175.7 | 15.9% | 291.5/167.0 | 258.3 |
| INCL (user check, used for the stock) | ≈264 | 50.5% | 377/175 | 17.2% | 288/165 | ≈256.8 |

The re-derivation **verifies the delivered exclusive-SF values** —
the "VERIFICATION OPEN" flag (above) is CLOSED. Agreement is within
~1% everywhere except the MFH WPB share (±1pp both SFs): the MFH curve
is flat near the threshold and the export quantises area in
1%-of-type-area percentiles, so that share is resolution-limited.
The Invert curves' own SFH area share is 56.5% (totals 744,679 /
572,652 in the export's area unit), consistent with the recorded
55.9%-frame diagnosis.

**Stock file** `archetypes_pl_inclusive_mix.csv`: built from the
committed `archetypes_pl_mix.csv` template with the USER-DELIVERED
inclusive values (same convention as the standard stock); splits kept:
poor 15.9% everywhere, MFH DH 25% within WPB / 48% within rest
(ordered values → overall 44.0% at WPB 17.2%), final = primary ÷ PEF
(fossil 1.1 / DH 0.85). CHECKS: total 8,847,407.0 exact; WPB
floor-area share 43.2%; stock-average primary 257.0 (≈256.8 ✓).
Hot-water inclusion stays OPEN as for the standard stock. Builder:
session scratchpad `build_inclusive_stock.py` (method fully stated
here; the file reproduces from this section).

## FLAG — wood/biomass primary-energy factor (2026-11-03, paper question)

The model has NO biomass carrier in primary energy: `PEF_FOSSIL = 1.1`
applies to the ENTIRE fossil-boiler final energy including the wood
share of the fuel mix (SFH mix_wood 0.3445, MFH 0.2516), and the
baseline primary energy uses the stock file's `primary_energy_factor`
column (1.1 for fossil-mix archetypes, 0.85 for DH incumbents). The
Polish certificate regulation (rozporządzenie on energy performance
methodology) uses wi ≈ 0.2 for biomass; under that convention the
SFH primary energy (≈34% wood) would be materially lower, in the
baseline and along the whole path. mix_wood currently affects ONLY the
fuel price (0.0523 EUR/kWh — itself flagged, no GUS series), the ETS2
CO₂ factor (wood = 0) and the seasonal efficiency (0.65). FLAGGED as
an open methodological choice for the paper; no model change made
(read-only question, 2026-11-03).

UPDATE 2026-11-04 (pl10_woodpef sensitivity, user-ordered): the flag is
now QUANTIFIED. With wood at wi = 0.2 in a mix-weighted fossil PEF
(coal/gas/oil stay 1.1; multistart-worktree lever `wood_pef`), the 2020
baseline falls 264.4 → 195.3 kWh/(m²·yr) (relative targets 164.0 /
156.2 / 117.2 / 80.1) and the cost-minimal spending falls €10.4bn →
€9.0bn (−13.5%, search bound); the optimal design shifts to the cheaper
family (low-income envelope medium/deep ≈48%, high-income heat pumps
≈21%, landlords 0). USER RULING: treat as a KEY SENSITIVITY in results
and discussion — the national biomass primary factor changes how
demanding the EPBD trajectory is. Whether the STANDARD run should use
0.2 stays OPEN (%% CHECK): depends on the Polish certificate method and
on Invert's factor.

DECIDED 2026-11-04 (user ruling): the STANDARD stays wi = 1.1 for the
wood share — the recast EPBD requires TOTAL primary energy; the
Commission's biomass default is 1.0 renewable + 0.2 non-renewable
≈ 1.2 total, and Poland is moving its certificate method to total
primary energy (draft regulation, May 2025). The 0.2 of the current
Polish method (Dz.U. 2015 poz. 376, amended 2023) counts only
non-renewable primary energy; pl10_woodpef remains the named
sensitivity for that convention. The open methodological flag above is
CLOSED.

## Invert "const" carrier prices — pl10_invertprices sensitivity
## (2026-11-04, user order)

Source named by the user: Invert/EE-Lab Poland constant energy-price
file `616_pol__const__energy_price.csv`. **The file itself is NOT in
the repository or any local download folder at the time of the run**
(checked 2026-11-04); the six values below were transcribed verbatim
from the user's order and should be reconciled against the file when it
is added. **Price year and VAT treatment are UNKNOWN — to be confirmed
by the Invert team (%% CHECK).**

| carrier | Invert €/MWh | model €/kWh | standard (CARRIER_PRICES_2024) | ratio |
|---|---|---|---|---|
| electricity | 166.55 | 0.16655 | 0.2634 | 0.63 |
| natural gas | 47.45 | 0.04745 | 0.0707 | 0.67 |
| coal | 35.28 | 0.03528 | 0.0594 | 0.59 |
| firewood (wood log) | 29.07 | 0.02907 | 0.0523 | 0.56 |
| heating oil | 75.24 | 0.07524 | 0.1065 | 0.71 |
| district heat | 56.87 | 0.05687 | 0.1151 | 0.49 |

Treatment (user order): all six replace the standard's prices, constant
over time like the standard; fuel mixes, seasonal efficiencies
(CARRIER_ETAS) and the ETS2 carbon-price path unchanged. Gas is used
as-is: Invert prices gas per HHV, the same calorific basis as the
Eurostat GCV value the standard uses — no conversion. Every Invert
price is below the standard's (29–51%); relative prices shift toward
district heat (dh/gas 1.20 vs the standard's 1.63). Scenario
`pl10_invertprices` (multistart worktree), search only, warm starts
from the two pl10 designs; no certificate ordered.
