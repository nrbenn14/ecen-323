#########################################################################
# 
# Filename: calc_sim
#
# Author: Nathan Bennion
# Class: ECEN 323, Winter Semester 2023
# Date: 24 Jan 2023
#
# Description: Simulates different calculations for the calc module.
#
#
#########################################################################


restart

add_force clk {0} {1 5} -repeat_every 10

# Run resets after the clock instance.
run 50ns
add_force btnu 1
run 20ns
add_force btnu 0
run 20ns
add_force btnu 1
run 20ns
add_force btnu 0
run 20ns

# OR - 0x0, 0x1234
add_force sw 1234 -radix hex
run 20ns
add_force btnl 0
add_force btnc 1
add_force btnr 1
run 20ns
add_force btnd 1
run 20ns

add_force btnd 0
run 20ns

# AND - 0x1234, 0x0ff0
add_force sw 0ff0 -radix hex
run 20ns

add_force btnl 0
add_force btnc 1
add_force btnr 0
run 20ns

add_force btnd 1
run 20ns

add_force btnd 0
run 20ns

# ADD - 0x0230, 0x324f
add_force sw 324f -radix hex
run 20ns

add_force btnl 0
add_force btnc 0
add_force btnr 0
run 20ns

add_force btnd 1
run 20ns

add_force btnd 0
run 20ns

# SUB - 0x347f, 0x2d31
add_force sw 2d31 -radix hex
run 20ns

add_force btnl 0
add_force btnc 0
add_force btnr 1
run 20ns

add_force btnd 1
run 20ns

add_force btnd 0
run 20ns

# XOR - 0x001, 0xffff
add_force sw ffff -radix hex
run 20ns

add_force btnl 1
add_force btnc 0
add_force btnr 0
run 20ns

add_force btnd 1
run 20ns

add_force btnd 0
run 20ns

# LT - 0xf8b1, 0x7346
add_force sw 7346 -radix hex
run 20ns

add_force btnl 1
add_force btnc 0
add_force btnr 1
run 20ns

add_force btnd 1
run 20ns

add_force btnd 0
run 20ns

# LT - 0x001, 0xffff
add_force sw ffff -radix hex
run 20ns

add_force btnl 1
add_force btnc 0
add_force btnr 1
run 20ns

add_force btnd 1
run 20ns

add_force btnd 0
run 20ns

# End of simulation (I think I'm going to use "end of line" from now on)
# Kudos if you get the reference