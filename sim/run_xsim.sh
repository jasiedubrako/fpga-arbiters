#!/usr/bin/env bash
#----------------------------------------------------------------------
# Behavioral simulation with Vivado XSim.
# Compiles every module in rtl/ and every testbench in tb/, then runs
# the testbench you name (default: the round-robin testbench).
#
# Requires Vivado's bin/ on your PATH. If you get "command not found",
# add it first, e.g. on Windows Git Bash:
#     export PATH="/c/Xilinx/Vivado/2024.2/bin:$PATH"   # use your version
#
# Run from the sim/ directory:
#     ./run_xsim.sh                          # runs tb_round_robin_arbiter
#     ./run_xsim.sh tb_fixed_priority_arbiter
#----------------------------------------------------------------------
set -e

# On Windows (Git Bash / MSYS) the Vivado tools are .bat files.
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) EXT=".bat" ;;
  *)                    EXT=""     ;;
esac

TOP=${1:-tb_round_robin_arbiter}

xvlog${EXT} -sv ../rtl/*.sv ../tb/*.sv
xelab${EXT} -debug typical "$TOP" -s sim_snapshot
xsim${EXT} sim_snapshot -runall
