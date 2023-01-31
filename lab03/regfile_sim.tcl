#########################################################################
# 
# Filename: regfile_sim.tcl
#
# Author: Nathan Bennion
# Class: ECEN 323, Section 2, Winter Semester 2023
# Date: 31 Jan 2023
#
# Description: Simulates different operands for the regfile module.
#
#
#########################################################################


restart

# Initial run
run 20ns

# Add clock cycles and test run again
add_force clk {0} {1 5} -repeat_every 10
run 20ns

# Read inputs from two registers, prep write to register 2, enable write
add_force readReg1 00001 
add_force readReg2 00010 
add_force writeReg 00010
add_force write 1
run 20ns

# Write in a random hex value
add_force writeData 0ff00ff0 -radix hex
run 20ns

# Reads registers 0 and 2 and tries to write to 0
add_force readReg1 00000 
add_force readReg2 00010 
add_force writeReg 00000
add_force write 1
run 20ns

# A random hex to register 0
add_force writeData 764ba980 -radix hex
run 20ns

# Reads registers 7 and 15 then writes to 7
add_force readReg1 00111 
add_force readReg2 01111 
add_force writeReg 00111
add_force write 1
run 20ns

# Write a hex value to register 7
add_force writeData 87baabff -radix hex
run 20ns

# End of simulation