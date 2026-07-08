# Verilog vs SystemVerilog — the differences used in this project

SystemVerilog is (mostly) a superset of Verilog. Everything below is the same
logic; only the syntax/convenience differs. This note exists so the SV in the
repo stays relatable to plain Verilog.

## The arbiter module

### SystemVerilog (what's in `rtl/`)
```systemverilog
module fixed_priority_arbiter #(
    parameter int N = 4
) (
    input  logic [N-1:0] req,
    output logic [N-1:0] gnt
);
    logic [N-1:0] higher_pri_reqs;
    assign higher_pri_reqs[0] = 1'b0;
    genvar i;
    generate
        for (i = 1; i < N; i++) begin : gen_cascade
            assign higher_pri_reqs[i] = higher_pri_reqs[i-1] | req[i-1];
        end
    endgenerate
    assign gnt = req & ~higher_pri_reqs;
endmodule
```

### Verilog-2001 equivalent
```verilog
module fixed_priority_arbiter #(
    parameter N = 4
) (
    input  wire [N-1:0] req,
    output wire [N-1:0] gnt
);
    wire [N-1:0] higher_pri_reqs;
    assign higher_pri_reqs[0] = 1'b0;
    genvar i;
    generate
        for (i = 1; i < N; i = i + 1) begin : gen_cascade
            assign higher_pri_reqs[i] = higher_pri_reqs[i-1] | req[i-1];
        end
    endgenerate
    assign gnt = req & ~higher_pri_reqs;
endmodule
```

### What changed
| SystemVerilog        | Verilog-2001          | Note                                             |
|----------------------|-----------------------|--------------------------------------------------|
| `logic`              | `wire` / `reg`        | `logic` = one 4-state type for both              |
| `parameter int N`    | `parameter N`         | typed parameter                                  |
| `i++`                | `i = i + 1`           | increment operator                               |
| `always_comb`        | `always @(*)`         | SV also checks it's truly combinational          |
| `'0`                 | `{N{1'b0}}` / `0`     | width-agnostic fill literal                      |
| `$error`             | `$display("ERROR ")`  | SV severity task, tallied by the simulator       |
| `task automatic`     | `task` (static)       | `automatic` = re-entrant local storage           |

`generate` / `genvar` exist in both — no change there.

## Testbench differences (same checks, older syntax in Verilog)
- Signals driven in `initial` are `reg` in Verilog (`logic` in SV).
- The check task uses old-style port declarations:
  ```verilog
  task check;
      input [N-1:0] r;
      input [N-1:0] g;
      begin
          if ((g & (g - 1'b1)) !== 0)
              $display("ERROR [t=%0t] more than one grant! req=%b gnt=%b", $time, r, g);
          if ((g & ~r) !== 0)
              $display("ERROR [t=%0t] illegal grant! req=%b gnt=%b", $time, r, g);
      end
  endtask
  ```
- Verilog has no `$error`; use `$display("ERROR ...")`.
