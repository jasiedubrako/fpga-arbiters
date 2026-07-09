# fpga-arbiters

Parameterizable hardware arbiters in SystemVerilog for the Xilinx Basys3 (Artix-7), working from a combinational fixed-priority design up to round-robin, with self-checking testbenches, real static-timing characterization, and an O(log N) prefix-tree optimization.

![SystemVerilog](https://img.shields.io/badge/SystemVerilog-IEEE%201800-blue)
![Tool](https://img.shields.io/badge/tool-Vivado-orange)
![Board](https://img.shields.io/badge/board-Basys3%20Artix--7-green)
![Status](https://img.shields.io/badge/status-in%20progress-yellow)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Features

- Parameterizable `N`-input fixed-priority arbiter (`rtl/fixed_priority_arbiter.sv`) — purely combinational.
- Parameterizable `N`-input round-robin arbiter (`rtl/round_robin_arbiter.sv`) — reuses the fixed-priority block twice around a one-hot pointer register; fair, no starvation.
- Kogge-Stone parallel-prefix variant (`rtl/fixed_priority_arbiter_tree.sv`) — O(log N) depth, exhaustively equivalence-checked against the ripple version.
- One-hot-or-zero grant invariant on all designs, checked automatically in the testbenches.
- Self-checking testbenches (combinational and clocked) running in Vivado XSim.
- Static timing analysis on Artix-7 — Fmax and bandwidth characterized across N.

## Usage

Fixed-priority (combinational):

```systemverilog
fixed_priority_arbiter #(.N(4)) u_fp (
    .req (req),
    .gnt (gnt)
);
```

Round-robin (clocked — needs a clock and an active-low reset):

```systemverilog
round_robin_arbiter #(.N(4)) u_rr (
    .clk   (clk),
    .rst_n (rst_n),
    .req   (req),
    .gnt   (gnt)
);
```

## Simulation

Fixed-priority — the grant follows the highest-priority active request; a busy high-priority line starves the ones below it:

![Fixed-priority arbiter waveform](docs/images/fixed_priority_arbiter.png)

Round-robin — under constant demand (`req = 1111`) the grant rotates `r0 → r1 → r2 → r3` and the pointer follows one step ahead, so no requester is starved:

![Round-robin arbiter waveform](docs/images/round_robin_arbiter.png)

## Results

Characterized on Artix-7 in Vivado by registering the I/O around the combinational arbiter and reading setup **WNS** against a 100 MHz constraint. `Fmax = 1000 / (10 − WNS)`. Full write-up: [docs/notes/03-timing-analysis.md](docs/notes/03-timing-analysis.md).

| N  | WNS (ns) | Min period (ns) | Fmax (MHz) | Logic levels |
|----|----------|-----------------|------------|--------------|
| 4  | 8.320    | 1.680           | 595        | 1            |
| 8  | 7.531    | 2.469           | 405        | —            |
| 16 | 7.199    | 2.801           | 357        | —            |
| 32 | 3.848    | 6.152           | 163        | 6            |

![Fmax vs N](docs/images/fmax_vs_n.png)

Fmax falls as N grows — the O(N) priority cascade lengthening the critical path. Re-coding the cascade as an **O(log N) Kogge-Stone prefix tree** (equivalence-checked) halves the depth at N=32 (6 → 3 logic levels) and raises Fmax from 163 MHz to **219 MHz (~34%)**. Bandwidth (1 grant/cycle × a 32-bit word) ranges from ~19.0 Gbit/s aggregate at N=4 down to ~5.2 Gbit/s at N=32.

**Fairness cost (N=4):** round-robin raises the critical path from 1.68 ns to 3.04 ns, cutting Fmax from ~595 MHz to ~330 MHz (~45%). The extra delay is the mask + output mux that round-robin layers on the shared cascade — fixed priority is faster but starves; round-robin is fair but slower.

## Build & simulate

**Vivado GUI**
1. Add `rtl/` as design sources and `tb/` as simulation sources.
2. Set the testbench you want to run as the simulation-set top (e.g. `tb_round_robin_arbiter`, `tb_arbiter_equiv`).
3. Flow Navigator -> Run Simulation -> Run Behavioral Simulation.

**Command line (Vivado XSim)** — from a shell with Vivado on your `PATH`:

```bash
cd sim
./run_xsim.sh tb_round_robin_arbiter   # or tb_fixed_priority_arbiter, tb_arbiter_equiv
```

A clean run prints the per-cycle grant table with no `$error` lines.

## Repository layout

```
rtl/           synthesizable design sources (+ timing harnesses)
tb/            testbenches / verification
constraints/   XDC pin & timing files
sim/           simulation scripts (XSim batch)
scripts/       project-generation Tcl (added later)
docs/notes/    per-phase concept & analysis write-ups
docs/images/   waveform screenshots, diagrams, plots
```

## Roadmap

- [x] Phase 1 — Fixed-priority arbiter + self-checking testbench
- [x] Phase 2 — Round-robin arbiter (fairness, no starvation)
- [x] Phase 3 — Timing + bandwidth analysis, and an O(log N) Kogge-Stone tree cascade (6 → 3 logic levels, ~34% higher Fmax at N=32)
- [ ] Phase 4 — Basys3 hardware demo (clock divider, live LEDs / 7-segment)

Possible future extensions: weighted round-robin, matrix arbiter.

## Status

In progress. Phases 1–3 complete: fixed-priority and round-robin arbiters verified in simulation and characterized on Artix-7 via static timing analysis (fixed-priority Fmax ~595 MHz at N=4 to ~163 MHz at N=32; round-robin trades ~45% frequency for starvation-free fairness), plus a Kogge-Stone prefix-tree variant that restores ~34% of the Fmax lost to the O(N) cascade at N=32. Next: Phase 4 — a live demo on the Basys3 board.

## License

MIT — see [LICENSE](LICENSE).
