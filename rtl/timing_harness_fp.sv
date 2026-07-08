`timescale 1ns/1ps
//======================================================================
// timing_harness_fp.sv
//----------------------------------------------------------------------
// Characterization wrapper for timing analysis ONLY (not shipped RTL).
//
// It registers the inputs and outputs around the combinational
// fixed-priority arbiter, creating a register -> logic -> register path
// that static timing analysis can measure against a clock. The slack on
// that path tells us how fast the arbiter can run.
//======================================================================
module timing_harness_fp #(
    parameter int N = 16          // bump this (8, 16, 32) to see the O(N) trend
) (
    input  logic         clk,
    input  logic [N-1:0] req_in,
    output logic [N-1:0] gnt_out
);
    logic [N-1:0] req_q;   // input register
    logic [N-1:0] gnt_c;   // combinational grant (logic under test)
    logic [N-1:0] gnt_q;   // output register

    always_ff @(posedge clk) req_q <= req_in;

    fixed_priority_arbiter #(.N(N)) dut (
        .req (req_q),
        .gnt (gnt_c)
    );

    always_ff @(posedge clk) gnt_q <= gnt_c;

    assign gnt_out = gnt_q;
endmodule
