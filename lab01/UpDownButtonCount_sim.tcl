##########################################################################
#
# UpDownButtonCount_sim.tcl
# Author: Nathan
# Class: ECEN 323
# Date: 1/10/2023
#
# This .tcl script will apply the input stimulus to the circuit
# as shown in the waveform in the lab wiki.
#
##########################################################################

# restart the simulation at time 0
restart

# Run circuit with no input stimulus settings
run 20 ns

# Set the clock to oscillate with a period of 10 ns
add_force clk {0} {1 5} -repeat_every 10

# Run the circuit for two clock cycles
run 20 ns

# Issue a reset (btnc) an set inc (btnu) to 0
add_force btnc 1
add_force btnu 0
run 10 ns

# Set reset (btnc) back to 0
add_force btnc 0
run 10 ns

# set inc (btnu)=1 for four clock cycles
add_force btnu 1
run 40 ns

# set inc (btnu)=0 for one clock cycles
add_force btnu 0
run 10 ns

# set inc (btnu)=1 for one clock cycles
add_force btnu 1
run 10 ns

# set inc (btnu)=0 for three clock cycles
add_force btnu 0
run 30 ns

# set inc (btnu)=1 for one clock cycles
add_force btnu 1
run 10 ns

# set inc (btnu)=0 for one clock cycles
add_force btnu 0
run 10 ns

# set inc (btnu)=1 for one clock cycles
add_force btnu 1
run 10 ns

# set inc (btnu)=0 for one clock cycles
add_force btnu 0
run 10 ns

# set decrement (btnd)=1 for two clock cycles
add_force btnd 1
run 20 ns

# set decrement (btnd)=0 for three clock cycles
add_force btnd 0
run 30 ns

# set decrement (btnd)=1 for four clock cycles
add_force btnd 1
run 40 ns

# set decrement (btnd)=0 for one clock cycles
add_force btnd 0
run 10 ns

# set the switches (sw)=4 for two clock cycles
add_force sw 0000000000000100
run 20 ns

# set switch increment (btnr)=1 for three clock cycles
add_force btnr 1
run 30 ns

# set switch increment (btnr)=0 for three clock cycles
add_force btnr 0
run 30 ns

# set the switches (sw)=2 for two clock cycles
add_force sw 0000000000000010
run 20 ns

# set switch decrement (btnl)=1 for three clock cycles
add_force btnl 1
run 30 ns

# set switch decrement (btnl)=0 for three clock cycles
add_force btnl 0
run 30 ns

# Issue a reset (btnc) for one clock cycle
add_force btnc 1
run 10 ns

# Return rst to 0
add_force btnc 0
run 10 ns

# Add additional input stimulus here
