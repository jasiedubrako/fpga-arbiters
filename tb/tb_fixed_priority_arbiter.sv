//======================================================================
// tb_fixed_priority_arbiter.sv
//----------------------------------------------------------------------
// Self-checking testbench for fixed_priority_arbiter.
//
// It drives a sequence of request patterns and, after each one,
// automatically checks the two properties that matter:
//
//   1) ONE-HOT / ZERO : at most one grant bit may be high.
//   2) SUBSET         : a grant may only go to a line that requested.
//
// If either is ever violated, you get a $error with the time and
// the offending vectors. If the run is silent, the arbiter is behaving.
//
// How to see the "timing diagram": run this in Vivado's simulator,
// then add req and gnt to the waveform window. You'll see the exact
// square-wave picture we discussed.
//======================================================================
`timescale 1ns/1ps

module tb_fixed_priority_arbiter;

    localparam int N = 4;

    logic [N-1:0] req;
    logic [N-1:0] gnt;

    // Device Under Test
    fixed_priority_arbiter #(.N(N)) dut (
        .req (req),
        .gnt (gnt)
    );

    // ---- self-check task -------------------------------------------
    // (g & (g-1)) == 0  is the classic "power of two or zero" trick:
    // it is true exactly when g has at most one bit set. Nice bit of
    // arithmetic-as-logic to have in your pocket for interviews.
    task automatic check(input logic [N-1:0] r, input logic [N-1:0] g);
        if ((g & (g - 1'b1)) != '0)
            $error("[t=%0t] INVARIANT BROKEN: more than one grant! req=%b gnt=%b", $time, r, g);
        if ((g & ~r) != '0)
            $error("[t=%0t] ILLEGAL GRANT: granted a non-requester! req=%b gnt=%b", $time, r, g);
    endtask

    // ---- stimulus --------------------------------------------------
    initial begin
        $display("  time | req  -> gnt   (comment)");
        $display("-------|------------------------------------");

        req = 4'b0000; #10 check(req,gnt); $display("%5t | %b -> %b   idle", $time, req, gnt);
        req = 4'b0001; #10 check(req,gnt); $display("%5t | %b -> %b   only r0", $time, req, gnt);
        req = 4'b0011; #10 check(req,gnt); $display("%5t | %b -> %b   r0 & r1, r0 wins", $time, req, gnt);
        req = 4'b0010; #10 check(req,gnt); $display("%5t | %b -> %b   only r1", $time, req, gnt);
        req = 4'b1100; #10 check(req,gnt); $display("%5t | %b -> %b   r2 & r3, r2 wins", $time, req, gnt);
        req = 4'b1000; #10 check(req,gnt); $display("%5t | %b -> %b   only r3", $time, req, gnt);
        req = 4'b1001; #10 check(req,gnt); $display("%5t | %b -> %b   r0 & r3, r3 STARVED", $time, req, gnt);
        req = 4'b1111; #10 check(req,gnt); $display("%5t | %b -> %b   all ask, r0 wins", $time, req, gnt);
        req = 4'b0000; #10 check(req,gnt); $display("%5t | %b -> %b   idle", $time, req, gnt);

        $display("-------|------------------------------------");
        $display("Done. If no $error printed above, the arbiter held its invariants.");
        $finish;
    end

endmodule
