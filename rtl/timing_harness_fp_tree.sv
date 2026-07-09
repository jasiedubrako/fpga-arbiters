`timescale 1ns/1ps
//======================================================================
// timing_harness_fp_tree.sv
//----------------------------------------------------------------------
// Identical harness to timing_harness_fp.sv, but wrapping the TREE
// arbiter. Same register structure -> an apples-to-apples timing
// comparison of ripple vs tree at the same N.
//======================================================================
module timing_harness_fp_tree #(
    parameter int N = 32          // set to 32 to compare against the ripple at N=32
) (
    input  logic         clk,
    input  logic [N-1:0] req_in,
    output logic [N-1:0] gnt_out
);
    logic [N-1:0] req_q;
    logic [N-1:0] gnt_c;
    logic [N-1:0] gnt_q;

    always_ff @(posedge clk) req_q <= req_in;

    fixed_priority_arbiter_tree #(.N(N)) dut (
        .req (req_q),
        .gnt (gnt_c)
    );

    always_ff @(posedge clk) gnt_q <= gnt_c;

    assign gnt_out = gnt_q;
endmodule
