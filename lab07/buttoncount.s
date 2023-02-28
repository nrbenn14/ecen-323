####################################################################################3#
#
# Filename: buttoncount.s
#
# Author: Nathan Bennion
# Class: ECEn 323, Section 2, Winter 2023
# Date: 28 Feb 2023
#
# Description: Values of switches are displayed on seven-segment display.
#			   Increments LEDs by 1 when BTNU is pressed
#	   		   Decrements LEDs by 1 when BTND is pressed
#			   Clear LEDs when BTNC is pressed
#
# Functions:
#
# This program does not use the data segment.
#
# Memory Organization:
#   0x0000-0x1fff : text
#   0x2000-0x3fff : data
#   0x7f00-0x7fff : I/O
#
# Registers:
#  x3(gp):  I/O base address
#  x8(s0):  Value of buttons
#  x9(s1):  Value of switches
#  x18(s2): Value to write in LEDs
#
####################################################################################3#
.globl  main

.data
	.word 0

.text


# I/O address offset constants
	.eqv LED_OFFSET 0x0
	.eqv SWITCH_OFFSET 0x4
	.eqv SEVENSEG_OFFSET 0x18
	.eqv TIMER 0x30
	.eqv BUTTON_OFFSET 0x24

# I/O mask constants
	.eqv BUTTON_C_MASK 0x01
	.eqv BUTTON_L_MASK 0x02
	.eqv BUTTON_D_MASK 0x04
	.eqv BUTTON_R_MASK 0x08
	.eqv BUTTON_U_MASK 0x10

main:
	# Prepare I/O base address
	addi gp, x0, 0x7f
	# Shift left 8
	slli gp, gp, 8
	# 0x7f00 should be in gp (x3)

	# Set constants
	sw x0, SEVENSEG_OFFSET(gp)          # Clear seven segment display
	sw x0, TIMER(gp)                    # Clear timer to zero

LOOP_START:

	# Load the buttons
	lw s0, BUTTON_OFFSET(gp)
	# Read the switches
	lw s1, SWITCH_OFFSET(gp)
	sw s1, SEVENSEG_OFFSET(gp) 			# Set switches to seven segment

	# Mask the buttons for button C
	andi t0, s0, BUTTON_C_MASK
	# If button is not pressed, skip btnc code
	beq t0, x0, BUTTON_CHECK
	# Button C pressed
	sw x0, LED_OFFSET(gp)				# Reset LEDs if BTNC is pressed
	beq x0, x0, LOOP_START              # Don't process other buttons

BUTTON_CHECK:							# Main label for button checking

BTNU_CHECK:

	andi t0, s0, BUTTON_U_MASK			# Mask for BTNU
	beq t0, t1, BTND_CHECK				# Skip if BTND is not pressed

	add t1, t0, x0						# Update previous button
	beq t0, x0, BTND_CHECK				# Check again

	lw s9, LED_OFFSET(gp)				# Prep the LEDs
	addi s9, s9, 1						# Increment
	sw s9, LED_OFFSET(gp)				# Write to LEDs
	beq x0, x0, LOOP_START				# Restart loop

BTND_CHECK:

	andi t0, s0, BUTTON_D_MASK			# Mask for BTND
	beq t0, t2, LOOP_START				# Skip if button is not pressed
	add t2, t0, x0						# Update mask
	beq t0, x0, LOOP_START				# Check again

	lw s9, LED_OFFSET(gp) 				# Prep the LEDs
	addi s9, s9, -1						# Decrement
	sw s9, LED_OFFSET(gp)				# Write to LEDs
	beq x0, x0, LOOP_START				# Restart loop