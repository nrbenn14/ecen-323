#########################################################################
# 
# Filename: regfile_top_sim.tcl
#
# Author: Nathan Bennion
# Class: ECEN 323, Section 2, Winter Semester 2023
# Date: 31 Jan 2023
#
# Description: Simulates different operands for the 
#              top level regfile module.
#
#
#########################################################################


restart

# Initial run
run 50ns

# Add clock cycles and test run again
add_force clk {0} {1 5} -repeat_every 10
run 50ns

# Designate register 1 to be loaded
add_force sw 0000010000000000
add_force btnl 1
add_force btnc 0
run 50ns

# Load 0x1234 to register 1
add_force sw 9234 -radix hex
add_force btnl 0
add_force btnc 1
run 50ns

# Designate register 2 to now be loaded
add_force sw 0000100000000000
add_force btnl 1
add_force btnc 0
run 50ns

# Load 0x3678 to register 2
add_force sw b678 -radix hex
add_force btnl 0
add_force btnc 1
run 50ns

# Designate register 3 to be written to, 1 is the A port address, 2 is the B port
add_force sw 0c41 -radix hex
add_force btnl 1
add_force btnc 0
run 50ns

# Perform an add operation
add_force sw 0002 -radix hex
add_force btnl 0
add_force btnc 1
run 50ns



# End of line