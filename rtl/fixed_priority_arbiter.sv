`timescale 1ns/1ps
//======================================================================
// fixed_priority_arbiter.sv
//----------------------------------------------------------------------
// A purely combinational fixed-priority arbiter.
//
//   Convention: LOWER index = HIGHER priority.
//   So req[0] always wins if it is asserted.
//
//   Golden invariant: gnt is one-hot OR all-zero.
//                     Two grants are NEVER high at the same time.
//
//   English rule for each bit:
//     "You get the grant if YOU are asking AND nobody
//      higher-priority (lower index) than you is asking."
//
//   This module has NO clock and NO state -- grants follow
//   requests immediately (after some propagation delay).
//======================================================================
module fixed_priority_arbiter #(
    parameter int N = 4
) (
    input  logic [N-1:0] req,   // request lines, one per requester
    output logic [N-1:0] gnt    // grant lines, one-hot (or all zero)
);

    // higher_pri_reqs[i] == 1  means "at least one requester with a
    // higher priority than i (index < i) is currently asking".
    logic [N-1:0] higher_pri_reqs;

    // Nothing is higher priority than index 0.
    assign higher_pri_reqs[0] = 1'b0;

    // Build the cascade: each bit ORs in every request above it.
    genvar i;
    generate
        for (i = 1; i < N; i++) begin : gen_cascade
            assign higher_pri_reqs[i] = higher_pri_reqs[i-1] | req[i-1];
        end
    endgenerate

    // You win only if you ask AND nobody above you is asking.
    assign gnt = req & ~higher_pri_reqs;

endmodule
