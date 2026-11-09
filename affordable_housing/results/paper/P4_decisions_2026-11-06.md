# P4: model decisions of 6 November 2026 (for the record and for Lukas)

## Why the model changes again
1. **PV error.** In pl10, PV saved 25% of all fuels, including coal and gas. Without it, the 2030 milestone is missed in 38 of 40 scenarios even at maximum subsidies (pl11). All pl10 numbers (EUR 10.2 bn etc.) are superseded.
2. **The model does not reproduce 2020–2025.** It replaces no heating systems before 2030, while about 0.6 million old boilers were replaced in reality (Czyste Powietrze). Real replacements were driven by anti-smog regulations, subsidies and comfort, none of which is in the model.
3. **The design start was unrealistic.** The state designed subsidies from 2020, but 2020–2025 is history.

## Decisions
| # | Decision |
|---|---|
| D1 | **History fixed, design from 2026.** Model start stays 2020 (EPBD baseline). Periods 2020; 2026; 2030; 2035; 2040; 2050 (last to 2060). The first period 2020–2025 is fixed; the state designs subsidies from 2026 (start of the Social Climate Fund). |
| D2 | **Heating systems 2020–2025 from observed data.** Single-family houses only (Czyste Powietrze covers SFH). Number: completed heat-source replacements by end of 2025 (derived from NFOŚiGW: over 603,000 by July 2026). Mix: cumulative requested heat sources, czystepowietrze.gov.pl (to 30 June 2026, 908,581 sources): gas condensing 31.2%, air heat pumps 29.2%, ground heat pumps 2.5%, biomass boilers 29.2%, new coal boilers 6.4%, electric 1.2%, district heat 0.2%, oil 0.1%. Heat pumps and district heat enter as fixed adoption; boilers enter as an update of the incumbent fuel mix and efficiency per archetype in 2025. Replacements are allocated to coal- and wood-heated SFH archetypes in proportion to their dwellings (no data on income or building class). Replacements outside the programme are ignored, so the history is a lower bound. |
| D3 | **Envelope renovation 2020–2025 modelled with the historical subsidy rates.** No observed data exist. A one-off history run with Czyste Powietrze rates (low-income SFH owner-occupiers 70%, high-income 40%, MFH and landlords 0) gives the first-period envelope adoption, which is then fixed. History spending is reported separately, not in the state's objective. |
| D4 | **2030 milestone.** If it can be met from 2026, it is a hard constraint as before. If not, the standard run uses the best value reachable at maximum subsidy rates (with all later milestones met) and the paper reports the gap. A sensitivity finds the smallest increase of the envelope limits (5% steps) that makes the EPBD value reachable, and its cost. |
| D5 | **No future boiler option.** Biomass and gas boilers enter only as history. Future biomass would lock houses in and miss 2040/2050 (pl11 test); EPBD Art. 17(15) ends subsidies for fossil boilers. The fossil-boiler-ban scenario stays. |
| D6 | **Carbon price 2026–2030:** EUR 22.5/t (ETS2 in 2028–2029 at the EUR 45/t price-stability level, spread over four years). Later periods unchanged (70, 120, 200, 350). |
| D7 | **Counting from 2026.** Spending, the equity floor, the worst-performing-building rule and the EED obligation count from 2026. Spending is discounted to 2026 (real 2024 euros). |
| D8 | **Unchanged from pl11:** PV removed; heat-pump learning 2.5%/yr, envelope and district heat 0; heating ≤ envelope + 0.3 rule kept; landlord subsidies allowed in rent-rule scenarios; full scenario set; local proof around the standard design only, no list proofs. |

## What this means for the paper
- The research question becomes: starting from today's stock, what does it cost to meet the remaining EPBD milestones, and how should subsidy rates differ?
- 2030 is decided mostly by what has already happened; the design decides 2035 onwards. If 2030 is out of reach, the capacity needed becomes a central result.
- The literature link is strong: Paper 3 already found that Poland misses 2030 under realistic policies.

---

## Order for Claude Code (copy from here)

New model version pl12 on a new branch from pl11. Implement and run without asking; anything that needs my decision goes into the CHANGELOG as OPEN with your recommendation, and you continue. Pre-register hypotheses; commit named paths only at the end of each phase; report each phase in one short table.

Decisions (fixed, do not ask): see D1–D8 below.
- D1: model start 2020; periods 2020;2026;2030;2035;2040;2050; first period fixed (your option (a): fixed first-period adoption plus subsidy_horizon_start = 2026).
- D2: SFH heating replacements 2020–2025 from data/observed_2020_2025_poland.md and this note: total completed replacements by end-2025 derived from the NFOŚiGW count (over 603,000 by July 2026; take your best estimate for end-2025 and record it), mix as listed in D2. Heat pumps and district heat as fixed adoption; boilers as a 2025 update of incumbent fuel mix and efficiency (condensing gas 0.95, modern biomass 0.87, class-5 coal 0.85, electric 1.0; record sources or mark as assumed). Allocation to coal- and wood-heated SFH archetypes in proportion to dwellings.
- D3: one history run with σ = 0.70 (low-income SFH owner-occupiers, all envelope depths and heating), 0.40 (high-income), 0 (MFH, landlords) for 2020–2025; fix its first-period envelope adoption; report history spending separately.
- D4: test whether 2030 is reachable from 2026 at maximum σ. If yes, keep it hard. If no, set the 2030 target to the best value reachable at the caps (later milestones met) via traj_values_override, and record that this value is a max-σ evaluation. Capacity sensitivity: smallest uniform increase of the envelope limits (5% steps) that makes the EPBD 2030 value reachable, and the minimum spending there.
- D5: no future boiler option.
- D6: carbon price 22.5 EUR/t for 2026–2030; later periods 70, 120, 200, 350.
- D7: spending, equity floor, WPB rule and EED count from 2026; discount spending to 2026.
- D8: as pl11 (PV off, learning as pl11, +0.3 rule, landlord subsidies in rent-rule scenarios, thread cap, no list proofs).

Phases:
1. Implement D1–D7; adapt reporting scripts and tests; new pins. Gates: pl11 reproduced with the new switches off.
2. History run (D3) and the 2025 state: report the 2025 stock primary energy, heating mix and the gap to 2030.
3. 2030 reachability test and capacity sensitivity (D4).
4. Standard run (multi-start as before) and the full scenario set; outcome measures, design table, both figure sets; local proof around the standard design.
5. Final report: headline numbers, what changed vs pl10, OPEN items.


## Decisions added 2026-11-07

- D9 (closes O-pl12-10): the reachability of the 2030 milestone (D4) is presented as CONDITIONAL on the modelled 2020–2025 envelope history. The record (modelled history, 2030 hard) stays the central case; the × 0.75 history variant (2030 unreachable at the caps, miss 3.12) is reported as the lower bracket (SENS-pl12-hist-env).
- D10 (closes O-pl12-6): the equity floor is applied STRICTLY (acceptance test `equity >= 0.30 - 1e-6`, was `- 0.001`) for all scenarios. Scenarios whose floor was binding or exploited (equity < 30.05 %) are re-run with a warm start from their current design (tag `strict`); the standard record (30.01 %, certified under the strict floor) is unchanged.
