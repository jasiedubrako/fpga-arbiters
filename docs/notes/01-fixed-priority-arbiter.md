# Phase 1 — Fixed-Priority Arbiter

## What it does
An arbiter grants a shared resource to one of `N` requesters and guarantees
that **at most one** requester is granted at a time (the grant vector is
one-hot or all-zero).

Fixed-priority rule (lower index = higher priority):

> "You win the grant if *you* are asking **and** nobody higher-priority than
> you is asking."

It is purely **combinational** — no clock, no state. Grants follow requests
immediately (after propagation delay).

## The invariant (and how the testbench checks it)
`gnt` must be one-hot or zero. The self-checking testbench verifies:

- `(g & (g - 1)) == 0` — at most one bit set (the classic power-of-two-or-zero test).
- `(g & ~req) == 0`   — a grant only ever goes to a line that actually requested.

## Three equivalent implementations
All three synthesize to the same priority-encoder logic:

1. **Priority `if/else` chain** — the most readable; literally encodes the English rule.
2. **Cascade of masks** (used in `rtl/fixed_priority_arbiter.sv`):
   `higher_pri_reqs[i] = OR of all req below i`, then `gnt = req & ~higher_pri_reqs`.
3. **Bit trick**: `gnt = req & (~req + 1) == req & (-req)` isolates the lowest set bit.

## Key tradeoff: starvation
A high-priority requester that asserts continuously locks out lower-priority
requesters **indefinitely**. That is the defining weakness of fixed priority,
and the reason round-robin (Phase 2) exists.

## Timing note (revisited in Phase 3)
The mask cascade is an `O(N)` ripple chain, structurally like a ripple-carry
adder. As `N` grows the propagation delay grows, so the maximum clock
frequency **falls**. A tree / lookahead restructuring reduces the delay to
`O(log N)` — the same idea as carry-lookahead. Real delay in nanoseconds is
measured from Vivado's timing report in Phase 3.
