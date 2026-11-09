# Invert/EE-Lab-derived inputs in this release

Several inputs of the Polish stock calibration were not taken from public statistics but from
the **Invert/EE-Lab** building-stock model (TU Wien; Poland "XOL", scenario *Status quo 2020*,
output of 17 October 2025). Invert/EE-Lab and its outputs are owned by **e-think**. The paper's
data statement says that these derived quantities are shared *subject to the permission of
e-think*. **That permission is pending.** Until it is granted, the files listed below must not be
redistributed; the rest of the release (code, census-based and publicly sourced inputs, scripts)
is not affected.

The dwelling counts and floor areas of every archetype come from the 2021 census (GUS, NSP 2021);
only *shares* and *average intensities* come from Invert. Full derivation:
`affordable_housing/data/PROVENANCE_polish_stock.md` (sections "Worst-performing buildings and
energy performance", "Resolution and stock of record", "Inclusive-service-factor stock").

## How the Invert quantities were derived and applied

1. Invert's within-type distributions of primary energy demand (per gross floor area, space heating
   incl. hot water as far as known — the hot-water scope is recorded as OPEN) for single-family (SFH)
   and multi-family (MFH) houses were rescaled to the census floor-area shares (SFH 78.0 %), merged
   and ranked; the worst 43 % of the combined floor area (EPBD 2024/1275 Art. 9(2)) defines the
   worst-performing buildings (WPB). Result of record (*exclusive service factor*, i.e. calculated
   demand): threshold ≈ 275 kWh/(m²·yr); **WPB share 52.5 % of SFH and 7.1 % of MFH floor area**;
   average primary energy **421 / 162 kWh/(m²·yr)** (SFH worst / rest) and **281 / 135** (MFH worst /
   rest); stock average ≈ 266.5 (model prints 264.4 at the census weights).
2. The WPB shares split each census dwelling count into a `*_wpb_*` and a `*_rest_*` archetype;
   the average intensities became the archetype's delivered-energy column
   (`baseline_kWh_m2 = Invert primary ÷ base-year PEF`, fossil 1.1 / district heat 0.85).
3. The *inclusive service factor* variant (demand adjusted for user behaviour; WPB 50.5 % / 17.2 %,
   primary 377 / 175 and 288 / 165) gives the `inclusive` sensitivity stock.
4. The KPRB sensitivity rescales the Invert-derived intensities so that the type averages match the
   KPRB final-energy figures (× 0.6549 SFH, × 1.0830 MFH); the worst/rest ratio is Invert's.
5. A separate Invert output, the Poland "const" carrier-price set (file
   `616_pol__const__energy_price.csv`, not in the repository), is hard-coded as the
   `pl10_invertprices` / `pl11_invertprices` / `pl12_invertprices` scenario.
6. The first Invert cut at Invert's own stock frame (62.6 % / 18.2 % WPB; 393 / 139 and 262 / 120
   kWh/(m²·yr)) was recorded but never loaded; it survives only in the provenance text and in the
   excluded draft stock file.

## Files and columns that carry Invert-derived values

| File (relative to `affordable_housing/`) | Invert-derived content |
|---|---|
| `archetypes_pl.csv` | `dwellings` of the `*_wpb_*` vs `*_rest_*` rows (census count × WPB share 52.5 % / 7.1 %); `baseline_kWh_m2` (421/162 and 281/135 primary ÷ PEF → 382.7/147.3 SFH, 330.6/158.8 MFH-DH, 255.5/122.7 MFH-fossil); `is_WPB` flag by construction |
| `archetypes_pl_mix.csv` (stock of record for pl9–pl12) | same columns as above (plus fuel-mix columns from GUS/census, not Invert) |
| `archetypes_pl_inclusive_mix.csv` (`pl12_inclusive`) | same columns from the inclusive-service-factor cut (WPB 50.5 % / 17.2 %; 377/175, 288/165) |
| `archetypes_pl_kprb.csv`, `archetypes_pl_kprb_mix.csv` (`pl12_kprb`) | `baseline_kWh_m2` = Invert-derived intensities rescaled to KPRB type averages; `dwellings` split as in the stock of record |
| `data/PROVENANCE_polish_stock.md` | quotes every Invert number above (shares, averages, thresholds, the distribution-curve verification table, the Invert carrier prices) |
| `bilevel_model_affordable_housing.jl` | the six Invert "const" carrier prices in the `pl10_invertprices` scenario definition (elec 0.16655, gas 0.04745, coal 0.03528, wood 0.02907, oil 0.07524, dh 0.05687 EUR/kWh); scenario descriptions that cite the Invert WPB cut |
| `CHANGELOG.md`, `results/README.md`, `results/paper/*.md`, `MODEL_MAP.md` | prose that repeats the Invert shares and averages |
| `out/scenarios/*/state_after_history.csv`, `affordability_by_archetype.csv`, `subsidy_by_archetype.csv`, `config_used.txt` (`descr`) and all other per-archetype outputs | per-archetype baseline intensities and dwelling counts, i.e. the Invert-derived inputs transformed by the model; the aggregate results (spending, stock-average paths, uptake shares) depend on them but do not reproduce them |
| `results/paper/pl12_paper_numbers.csv` | rows `dwellings_*` and the 2020 stock-average primary energy (264.4) are downstream of the Invert split |

Not in the release (and not in the source repository): the Invert workbooks
`Auswertung_Verteilung_Ergebnisse_XOL_output_25_10_17.xlsx`, `dist_curve.xlsx`, `WPB_data_POL.xlsx`
and `616_pol__const__energy_price.csv`. The excluded `data/archetypes_pl_DRAFT.csv` carried the
first Invert cut and is used by no scenario.

## Condition for sharing

Per the paper's data statement these Invert-derived inputs are shared subject to the permission of
e-think (owner of Invert/EE-Lab). **Status: permission pending (2026-11-09).** Do not redistribute
the files in the table above before the permission is granted. Everything else in this release is
licensed as stated in `LICENSE` (code, MIT) and `LICENSE-data` (data, results, figures, CC BY 4.0).
