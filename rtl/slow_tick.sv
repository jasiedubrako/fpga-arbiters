`timescale 1ns/1ps
//======================================================================
// slow_tick.sv
//----------------------------------------------------------------------
// Generates a one-cycle enable pulse every DIV clock cycles.
// On the Basys3's 100 MHz clock, DIV = 50_000_000 -> ~2 pulses/second.
// This is a clock ENABLE, not a divided clock (good FPGA practice).
//======================================================================
module slow_tick #(
    parameter int DIV = 50_000_000
) (
    input  logic clk,
    input  logic rst_n,
    output logic tick
);
    localparam int W = $clog2(DIV);
    logic [W-1:0] cnt;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            cnt  <= '0;
            tick <= 1'b0;
        end else if (cnt == DIV-1) begin
            cnt  <= '0;
            tick <= 1'b1;          // single-cycle pulse
        end else begin
            cnt  <= cnt + 1'b1;
            tick <= 1'b0;
        end
    end
endmodule
