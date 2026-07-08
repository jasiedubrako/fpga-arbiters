# fpga-arbiters

Parameterizable hardware arbiters in SystemVerilog for the Xilinx Basys3 (Artix-7), working from a combinational fixed-priority design up to round-robin, each with a self-checking testbench.

![SystemVerilog](https://img.shields.io/badge/SystemVerilog-IEEE%201800-blue)
![Tool](https://img.shields.io/badge/tool-Vivado-orange)
![Board](https://img.shields.io/badge/board-Basys3%20Artix--7-green)
![Status](https://img.shields.io/badge/status-in%20progress-yellow)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Features

- Parameterizable `N`-input fixed-priority arbiter (`rtl/fixed_priority_arbiter.sv`), purely combinational.
- Grant logic upholds the one-hot-or-zero invariant: at most one grant is ever asserted.
- Self-checking testbench that flags any violation — multiple grants, or a grant to a non-requester.
- Runs in Vivado's XSim simulator via the GUI or the command line.

## Usage

```systemverilog
fixed_priority_arbiter #(.N(4)) u_arb (
    .req (req),   // input  [N-1:0] : requester i wants the resource
    .gnt (gnt)    // output [N-1:0] : one-hot grant (or all zero)
);
```

## Build & simulate

**Vivado GUI**
1. Add `rtl/` and `tb/` as design sources.
2. Set `tb_fixed_priority_arbiter` as the simulation-set top module.
3. Flow Navigator -> Run Simulation -> Run Behavioral Simulation.

**Command line (Vivado XSim)** — from a shell with Vivado on your `PATH`:

```bash
cd sim
./run_xsim.sh
```

A clean run prints the request -> grant table with no `$error` lines.

## Simulation

![Fixed-priority arbiter waveform](docs/images/fixed_priority_arbiter_waveform.png)

`req` drives the arbiter; `gnt` is the resulting one-hot grant. Note requester 3
staying starved at t=70 ns while requester 0 keeps winning.

## Repository layout

```
rtl/           synthesizable design sources
tb/            testbenches / verification
constraints/   XDC pin & timing files (Phase 4, Basys3)
sim/           simulation scripts (XSim batch)
scripts/       project-generation Tcl (added later)
docs/notes/    per-phase concept write-ups
docs/images/   waveform screenshots, diagrams
```

## Roadmap

- [x] Phase 1 — Fixed-priority arbiter + self-checking testbench
- [x] Phase 2 — Round-robin arbiter (fairness, no starvation)
- [ ] Phase 3 — Datapath, bandwidth analysis, Vivado timing report (Fmax, critical path)
- [ ] Phase 4 — Basys3 demo (clock divider, LEDs / 7-segment)
- [ ] Phase 5 — Weighted round-robin, matrix arbiter, interview drills

## Status

Early / in progress — Phase 1 complete and simulating cleanly. No performance numbers yet; measured Fmax and bandwidth arrive in Phase 3.

## License

MIT — see [LICENSE](LICENSE).
