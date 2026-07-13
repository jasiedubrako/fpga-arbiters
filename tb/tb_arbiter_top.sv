`timescale 1ns/1ps
//======================================================================
// tb_arbiter_top.sv
//----------------------------------------------------------------------
// Sanity-check the board top BEFORE building a bitstream. DIV is
// overridden to a tiny value so several ticks happen in a short sim,
// letting us watch the granted LED rotate among the asserted switches.
//======================================================================
module tb_arbiter_top;

    localparam int N = 16;

    logic         clk, btnC;
    logic [N-1:0] sw, led;
    logic [6:0]   seg;
    logic [3:0]   an;

    arbiter_top #(.N(N), .DIV(4)) dut (   // DIV=4 -> a tick every 4 clocks
        .clk(clk), .btnC(btnC), .sw(sw), .led(led), .seg(seg), .an(an)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;                 // 100 MHz

    always @(led)
        if (!btnC) $display("t=%0t  sw=%b  led=%b", $time, sw, led);

    initial begin
        btnC = 1'b1;  sw = '0;            // hold reset
        repeat (3) @(posedge clk);
        btnC = 1'b0;                      // release reset
        sw = 16'b0000_0000_1000_1011;     // r0, r1, r3, r7 asking
        repeat (40) @(posedge clk);       // watch led rotate r0->r1->r3->r7->...
        $display("Done.");
        $finish;
    end

endmodule
