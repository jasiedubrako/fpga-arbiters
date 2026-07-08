//======================================================================
// tb_round_robin_arbiter.sv
//----------------------------------------------------------------------
// Clocked, self-checking testbench for round_robin_arbiter.
//
// New vs the Phase 1 testbench: we now need a CLOCK and a RESET, and we
// drive stimulus on the falling edge / sample on the rising edge so the
// checks are race-free.
//
// What to watch:
//   * req = 1111 : grants should rotate r0 -> r1 -> r2 -> r3 -> r0 ...
//   * req = 1010 : grants should alternate r1 <-> r3 (fairness)
//   * req = 0000 : no grant, and the pointer holds its value
//======================================================================
`timescale 1ns/1ps

module tb_round_robin_arbiter;

    localparam int N = 4;

    logic         clk, rst_n;
    logic [N-1:0] req, gnt;

    round_robin_arbiter #(.N(N)) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .req   (req),
        .gnt   (gnt)
    );

    // ---- clock: 10 ns period ---------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ---- invariant checks, every cycle -----------------------------
    always @(posedge clk) if (rst_n) begin
        if ((gnt & (gnt - 1'b1)) != '0)
            $error("[t=%0t] more than one grant! req=%b gnt=%b", $time, req, gnt);
        if ((gnt & ~req) != '0)
            $error("[t=%0t] illegal grant! req=%b gnt=%b", $time, req, gnt);
    end

    // ---- per-cycle log (shows the pointer rotating) ----------------
    always @(posedge clk) if (rst_n)
        $display("t=%3t | ptr=%b req=%b -> gnt=%b", $time, dut.pointer, req, gnt);

    // ---- drive stimulus on the falling edge (race-free) ------------
    task automatic apply(input logic [N-1:0] stim, input int cycles);
        @(negedge clk);
        req = stim;
        repeat (cycles) @(posedge clk);
    endtask

    initial begin
        rst_n = 1'b0;
        req   = '0;
        repeat (2) @(posedge clk);      // hold reset across two edges
        @(negedge clk); rst_n = 1'b1;   // release reset cleanly

        $display("--- req=1111 : expect rotation r0,r1,r2,r3,... ---");
        apply(4'b1111, 8);

        $display("--- req=1010 : expect r1,r3 alternating ---");
        apply(4'b1010, 6);

        $display("--- req=0000 : expect no grant, pointer holds ---");
        apply(4'b0000, 2);

        $display("Done. No $error above means invariants held every cycle.");
        $finish;
    end

endmodule
