`timescale 1ns/1ps
//======================================================================
// fixed_priority_arbiter_tree.sv
//----------------------------------------------------------------------
// Functionally identical to fixed_priority_arbiter, but the prefix-OR
// ("is anyone higher-priority asking?") is computed with a Kogge-Stone
// PARALLEL PREFIX tree: O(log N) depth instead of the ripple's O(N).
//
// Lower index = higher priority. gnt is one-hot or all-zero.
//======================================================================
module fixed_priority_arbiter_tree #(
    parameter int N = 4
) (
    input  logic [N-1:0] req,
    output logic [N-1:0] gnt
);
    // Number of parallel-prefix levels = ceil(log2 N).
    localparam int LOGN = (N <= 1) ? 1 : $clog2(N);

    // pre[l] = inclusive prefix-OR of req after l combine levels.
    //   pre[0]    = req
    //   pre[LOGN] = OR of req[0..i] at every position i
    logic [N-1:0] pre [LOGN+1];

    assign pre[0] = req;

    genvar l, i;
    generate
        for (l = 0; l < LOGN; l++) begin : g_level
            for (i = 0; i < N; i++) begin : g_bit
                if (i >= (1 << l))
                    // OR in the value 2^l positions below (doubling reach each level)
                    assign pre[l+1][i] = pre[l][i] | pre[l][i - (1 << l)];
                else
                    assign pre[l+1][i] = pre[l][i];   // nothing below to combine yet
            end
        end
    endgenerate

    // higher_pri_reqs[i] = OR of req[0..i-1] = inclusive prefix shifted up by 1,
    // with bit 0 forced to 0 (nothing outranks index 0).
    logic [N-1:0] higher_pri_reqs;
    assign higher_pri_reqs = {pre[LOGN][N-2:0], 1'b0};

    assign gnt = req & ~higher_pri_reqs;
endmodule
