## ---------------------------------------------------------------------
## basys3.xdc
## Timing constraint for Phase 3 characterization.
##
## The Basys3 has a 100 MHz oscillator (10 ns period). We declare it here
## so static timing analysis has a clock to measure register-to-register
## paths against. Fmax is then back-calculated from the reported slack.
## ---------------------------------------------------------------------
create_clock -name sys_clk -period 10.000 [get_ports clk]

## Pin assignment (only needed later, when building a real bitstream in
## Phase 4). Left commented so it doesn't interfere with timing analysis.
# set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
