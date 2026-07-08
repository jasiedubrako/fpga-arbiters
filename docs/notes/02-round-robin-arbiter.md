# Phase 2 — Round-Robin Arbiter

## Goal
Fix the starvation of fixed priority. After serving requester `i`, the next
search starts just past `i`, so grants rotate and everyone gets a turn.

## Key insight
Round-robin = the Phase 1 fixed-priority arbiter, reused **twice**, wrapped
around one register:

1. `arb_masked` sees only requesters at/above the pointer (via a mask) — it
   grants the lowest index >= pointer.
2. `arb_full` sees all requesters — it handles wrap-around.
3. A mux picks the masked grant if any masked request exists, else the full grant.

## The only state
A single one-hot `pointer` register marks where the search starts this cycle.
- Reset: pointer = index 0 (cycle 1 behaves like plain fixed priority).
- After a grant: `pointer <= {gnt[N-2:0], gnt[N-1]}` (circular left-rotate).
- Idle cycle (`gnt == 0`): pointer holds.

## The mask trick
`mask = ~(pointer - 1)` turns a one-hot pointer into a thermometer of all bits
at/above it — same two's-complement idea as the Phase 1 lowest-set-bit trick.

## Sequential-logic rules introduced here
- `always_ff @(posedge clk)` for the register (Verilog: `always @(posedge clk)`).
- Non-blocking `<=` for clocked state; blocking `=` for combinational. Never mix.
- Synchronous active-low reset (`rst_n`) to start in a known state.

## Verification
`tb_round_robin_arbiter.sv` drives a clock/reset and checks the one-hot
invariant every cycle. Watch the log/waveform:
- `req = 1111` -> grants rotate r0,r1,r2,r3,...
- `req = 1010` -> grants alternate r1,r3 (fairness, no starvation).
- `req = 0000` -> no grant, pointer holds.
