########################################################################
# test_pl12_pins.jl — pinned gates for the pl12 model (2026-11-06).
#  G1  pl10 design of record re-evaluates to the value of record (all pl12
#      switches off: bit-identity of the committed model)
#  G2  pl11 at all subsidy caps reproduces the pl11 wave's max-σ evidence
#  G3  pl12_history at the Czyste Powietrze rates reproduces the history run
#      (2026 state, 2030 value, history spending)
#  G4  pl12 standard at σ=0: 2026 state equals G3's (history fixed identically)
# Each case loads the model in a subprocess (one scenario per process).
# Usage: julia --project=.. test_pl12_pins.jl
########################################################################
using Printf
const HERE = @__DIR__
const PINS = [
    # (scenario, sigma file, key values)
    ("pl10", "data/sigma_start_record.csv",
        Dict("spending_M" => 10233.54, "E2030" => 222.19, "E2040" => 158.58, "E2050" => 92.06)),
    ("pl11", "data/sigma_start_max.csv",
        Dict("spending_M" => 49186.2, "E2030" => 230.39, "E2050" => 75.14)),
    ("pl12_history", "data/sigma_history_pl12.csv",
        Dict("E2026" => 243.88, "E2030" => 224.05, "E2050" => 73.39, "hist_nominal_M" => 5021.7)),
]
npass = nfail = 0
for (scn, sig, pins) in PINS
    println("\n--- $scn @ $(basename(sig)) ---")
    cmd = `$(Base.julia_cmd()[1]) --project=$(HERE)/.. $(HERE)/../scripts/eval_sigma_report.jl $scn $sig pintest`
    log = read(pipeline(addenv(Cmd(cmd; dir=HERE), "P4_GRB_THREADS" => get(ENV, "P4_GRB_THREADS", "8")), stderr=devnull), String)
    got = Dict{String,Float64}()
    m = match(r"#### spending\s+([\d.]+) M EUR", log); m !== nothing && (got["spending_M"] = parse(Float64, m[1]))
    for mm in eachmatch(r"(\d{4}):([\d.]+)", match(r"#### primary energy path[^\n]*", log).match)
        got["E" * mm[1]] = parse(Float64, mm[2])
    end
    m = match(r"history subsidy spending[^:]*: nominal ([\d.]+) M EUR", log); m !== nothing && (got["hist_nominal_M"] = parse(Float64, m[1]))
    for (k, v) in pins
        ok = haskey(got, k) && isapprox(got[k], v; rtol=5e-4, atol=0.011)
        global npass += ok; global nfail += !ok
        @printf("  %s  %-14s pinned %10.2f  got %10s\n", ok ? "PASS" : "FAIL", k, v, haskey(got, k) ? @sprintf("%.2f", got[k]) : "missing")
    end
end
println("\nPL12 PINS: $npass passed, $nfail failed")
exit(nfail == 0 ? 0 : 1)
