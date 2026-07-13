# Phase 4 - Basys3 Hardware Demo

## What it does
- `sw[15:0]` drive `req`: flipping a switch means "that requester is asking".
- `led[15:0]` show `gnt`: the lit LED is the requester currently granted.
- The 7-segment displays the granted requester's index in hex.
- `btnC` resets the pointer.

The granted LED rotates among **only the active switches**, about twice per
second, skipping inactive ones and never getting stuck. That is round-robin
fairness, visible to the eye.

## The key design decision: clock enable, not clock division
The Basys3 runs at 100 MHz. Rotating the grant at 100 MHz would be invisible, so
the rotation must be slowed to roughly 2 Hz.

The naive approach is to divide the clock down and use the divided signal as a
clock. **Do not do this.** A logic-generated clock does not travel on the FPGA's
dedicated low-skew clock network, it creates a new clock domain for static timing
analysis to reason about, and it invites skew and clock-domain-crossing bugs.

The professional approach, used here, is a **clock enable**:

- Everything stays on the single 100 MHz `clk`.
- `slow_tick` counts 50,000,000 cycles (0.5 s) and emits a **one-cycle-wide pulse**.
- The arbiter's pointer register only advances when that pulse is high
  (`else if (en && |gnt)`).

The arbiter is still clocked at 100 MHz; it simply *chooses* to update its state
twice a second. One clock domain, no skew, and STA stays simple.

This also mirrors real hardware: an arbiter should advance its pointer only when
a grant is actually **consumed** (a transaction completes), not blindly every
cycle. The `en` port is exactly that "transaction done, move on" signal. Tie it
to `1'b1` for free-running use.

## Blocks
| Module | Role |
|--------|------|
| `slow_tick.sv` | Counter producing a 1-cycle enable pulse every `DIV` clocks |
| `round_robin_arbiter.sv` | Arbitration logic, now gated by `en` |
| `arbiter_top.sv` | Board wiring: switches to `req`, `gnt` to LEDs, one-hot to hex index, hex to 7-segment |

## Verification before bitstream
`tb_arbiter_top.sv` overrides `DIV` to a tiny value (4) so several ticks occur in
a short simulation, letting the whole switch -> arbiter -> LED chain be checked in
XSim before spending time on synthesis and programming.
