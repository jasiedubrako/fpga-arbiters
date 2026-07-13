`timescale 1ns/1ps
//======================================================================
// arbiter_top.sv  -- Basys3 demo top level
//----------------------------------------------------------------------
//   sw[15:0]  -> requests        (flip a switch = that requester asks)
//   led[15:0] -> grants          (the lit LED walks around, fairly)
//   seg/an    -> 7-seg shows the granted requester index (hex)
//   btnC      -> reset (active-high button)
//
// A slow_tick advances the round-robin pointer ~2x/second so the
// rotation is visible to the eye.
//======================================================================
module arbiter_top #(
    parameter int N   = 16,
    parameter int DIV = 50_000_000   // ~2 rotations/sec on 100 MHz
) (
    input  logic         clk,
    input  logic         btnC,
    input  logic [N-1:0] sw,
    output logic [N-1:0] led,
    output logic [6:0]   seg,
    output logic [3:0]   an
);
    logic rst_n;
    assign rst_n = ~btnC;            // active-high button -> active-low reset

    logic tick;
    slow_tick #(.DIV(DIV)) u_tick (.clk(clk), .rst_n(rst_n), .tick(tick));

    logic [N-1:0] gnt;
    round_robin_arbiter #(.N(N)) u_arb (
        .clk(clk), .rst_n(rst_n), .en(tick), .req(sw), .gnt(gnt)
    );

    assign led = gnt;

    // one-hot grant -> 4-bit index
    logic [3:0] idx;
    always_comb begin
        idx = 4'd0;
        for (int k = 0; k < N; k++)
            if (gnt[k]) idx = k[3:0];
    end

    // hex digit -> 7-seg pattern (common anode, segments active-low, seg[0]=a .. seg[6]=g)
    logic [6:0] seg_pat;
    always_comb begin
        case (idx)
            4'h0: seg_pat = 7'b1000000;  4'h1: seg_pat = 7'b1111001;
            4'h2: seg_pat = 7'b0100100;  4'h3: seg_pat = 7'b0110000;
            4'h4: seg_pat = 7'b0011001;  4'h5: seg_pat = 7'b0010010;
            4'h6: seg_pat = 7'b0000010;  4'h7: seg_pat = 7'b1111000;
            4'h8: seg_pat = 7'b0000000;  4'h9: seg_pat = 7'b0010000;
            4'hA: seg_pat = 7'b0001000;  4'hB: seg_pat = 7'b0000011;
            4'hC: seg_pat = 7'b1000110;  4'hD: seg_pat = 7'b0100001;
            4'hE: seg_pat = 7'b0000110;  4'hF: seg_pat = 7'b0001110;
        endcase
    end

    assign seg = (|gnt) ? seg_pat : 7'b1111111;  // blank when nobody is granted
    assign an  = 4'b1110;                        // rightmost digit only (active low)
endmodule
