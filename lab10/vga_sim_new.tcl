##########################################################################
#
# Filname: vga_sim_new.tcl
# Author: Nathan Bennion
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
add_force sw 0 -radix hex
add_force RsTx 1

# Run the simulator until the screen has been cleared
run 984970 ns
    
# Add your test stimulus here

# Set switches to the ASCII character "!" (0x21)
add_force sw 21 -radix hex

# Press BTNR
add_force btnr 1

# Run until the char appears on screen
run 40 ns

# End of Simulation