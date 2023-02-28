##########################################################################
#
# Filname: iosystem.tcl
#
# Author: Nathan Bennion
# Class: ECEn 323, Section 2, Winter 2023
# Date: 28 Feb 2023
#
# This .tcl script will apply stimulus to the top-level pins of the FPGA
# 
#
##########################################################################


# Start the simulation over
restart

# Run circuit with no input stimulus settings
run 20 ns

# Set the clock to oscillate with a period of 10 ns
add_force clk {0} {1 5} -repeat_every 10
# Run the circuit for a bit
run 40 ns

# set the top-level inputs
add_force btnc 0
add_force btnl 0
add_force btnr 0
add_force btnu 0
add_force btnd 0
add_force sw 0
add_force RsTx 1
run 7 us

# Add your test stimulus here

# Press BTNR, observe impact on LEDs
add_force btnr 1
run 20 us

add_force btnr 0
run 20 us

# Press BTNL, observe impact on LEDs
add_force btnl 1
run 20 us

add_force btnl 0
run 20 us

#Press BTNU, observe impact on LEDs
add_force btnu 1
run 20 us

add_force btnu 0
run 20 us

#Press BTND, observe impact on LEDs
add_force btnd 1
run 30 us

add_force btnd 0
run 20 us

#Make sure the simulation executes for at least 1 ms to see the timer reach a value of 1 ms
run 1000 us

#Press BTNC and observe the impact on the timer and seven segment display
add_force btnc 1
run 20 us

add_force btnc 0
run 20 us

add_force sw 0000000011111111
run 20 us

add_force sw 1111111100000000
run 20 us


# End of simulation