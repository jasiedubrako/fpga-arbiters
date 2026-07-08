#!/usr/bin/env bash
#----------------------------------------------------------------------
# Behavioral simulation of the fixed-priority arbiter with Vivado XSim.
# Requires Vivado on your PATH (source settings64.sh first).
# Run from the sim/ directory:  ./run_xsim.sh
#----------------------------------------------------------------------
set -e
xvlog -sv ../rtl/fixed_priority_arbiter.sv ../tb/tb_fixed_priority_arbiter.sv
xelab -debug typical tb_fixed_priority_arbiter -s tb_sim
xsim tb_sim -runall
