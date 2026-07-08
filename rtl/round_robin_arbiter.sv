//======================================================================
// round_robin_arbiter.sv
//----------------------------------------------------------------------
// A round-robin arbiter built by REUSING the Phase 1 fixed-priority
// arbiter twice, wrapped around a single pointer register.
//
//   Fairness rule: after serving requester i, the search next cycle
//   starts just past i, so everyone gets a turn -- no starvation.
//
//   State: one register only -- a one-hot `pointer` marking where the
//          priority search starts this cycle.
//
//   Invariant (unchanged from Phase 1): gnt is one-hot or all-zero.
//======================================================================
module round_robin_arbiter #(
    parameter int N = 4
) (
    input  logic         clk,
    input  logic         rst_n,   // active-low synchronous reset
    input  logic [N-1:0] req,
    output logic [N-1:0] gnt
);

    // ---- the only stored state -------------------------------------
    logic [N-1:0] pointer;        // one-hot: highest-priority position now

    // ---- start the search at the pointer ---------------------------
    // mask = ~(pointer - 1) is a thermometer of all bits >= pointer.
    //   pointer = 0100  ->  pointer-1 = 0011  ->  mask = 1100
    logic [N-1:0] mask;
    logic [N-1:0] masked_req;
    assign mask       = ~(pointer - 1'b1);
    assign masked_req = req & mask;

    // ---- reuse the Phase 1 arbiter, twice --------------------------
    logic [N-1:0] gnt_masked;   // grant among requesters at/above pointer
    logic [N-1:0] gnt_full;     // grant among ALL requesters (wrap-around)

    fixed_priority_arbiter #(.N(N)) arb_masked (
        .req (masked_req),
        .gnt (gnt_masked)
    );

    fixed_priority_arbiter #(.N(N)) arb_full (
        .req (req),
        .gnt (gnt_full)
    );

    // ---- select: masked grant if anyone was eligible, else wrap ----
    assign gnt = (|masked_req) ? gnt_masked : gnt_full;

    // ---- advance the pointer one seat past whoever we granted -------
    // Circular left-rotate of the one-hot grant.
    logic [N-1:0] next_pointer;
    assign next_pointer = {gnt[N-2:0], gnt[N-1]};

    always_ff @(posedge clk) begin
        if (!rst_n)
            pointer <= {{(N-1){1'b0}}, 1'b1};  // reset: start at index 0
        else if (|gnt)
            pointer <= next_pointer;           // advance only when a grant occurred
        // else: hold (idle cycle, nobody served)
    end

endmodule
