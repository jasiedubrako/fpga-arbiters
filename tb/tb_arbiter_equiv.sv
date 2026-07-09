`timescale 1ns/1ps
//======================================================================
// tb_arbiter_equiv.sv
//----------------------------------------------------------------------
// Proves the tree arbiter is functionally IDENTICAL to the ripple one
// before we claim any optimization. Both are driven with the same req,
// and for small N we check EVERY possible input pattern exhaustively.
//======================================================================
module tb_arbiter_equiv;

    localparam int N = 4;   // 2^4 = 16 patterns, fully exhaustive

    logic [N-1:0] req;
    logic [N-1:0] gnt_ripple;
    logic [N-1:0] gnt_tree;

    fixed_priority_arbiter      #(.N(N)) u_ripple (.req(req), .gnt(gnt_ripple));
    fixed_priority_arbiter_tree #(.N(N)) u_tree   (.req(req), .gnt(gnt_tree));

    int errors = 0;

    initial begin
        for (int v = 0; v < (1 << N); v++) begin
            req = v[N-1:0];
            #1;
            if (gnt_ripple !== gnt_tree) begin
                $error("MISMATCH: req=%b  ripple=%b  tree=%b", req, gnt_ripple, gnt_tree);
                errors++;
            end
        end

        if (errors == 0)
            $display("PASS: tree matches ripple on all %0d input patterns.", (1 << N));
        else
            $display("FAIL: %0d mismatch(es).", errors);
        $finish;
    end

endmodule
