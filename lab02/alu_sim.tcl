#########################################################################
# 
# Filename: alu_sim
#
# Author: Nathan Bennion
# Class: ECEN 323, Winter Semester 2023
# Date: 24 Jan 2023
#
# Description: Simulates different operands for the ALU module.
#
#
#########################################################################

restart

# Add original operands
add_force op1 f3212f37 -radix hex
add_force op2 621c3ee7 -radix hex
run 20ns

# Each command is simulated for 20ns based on the inputted alu_op signal

# AND Operation
add_force alu_op 0000
run 20ns

# OR Operation
add_force alu_op 0001
run 20ns

# ADD Operation
add_force alu_op 0010
run 20ns

# Default (ADD)
add_force alu_op 0011
run 20ns

# SUBTRACT Operation
add_force alu_op 0110
run 20ns

# LT Operation
add_force alu_op 0111
run 20ns

# SRL Operation
add_force alu_op 1000
run 20ns

# SLL Operation
add_force alu_op 1001
run 20ns

# SRA Operation
add_force alu_op 1010
run 20ns

# XOR Operation
add_force alu_op 1101
run 20ns

# End of Simulation (End of line...?)