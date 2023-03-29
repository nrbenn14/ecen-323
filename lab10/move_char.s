####################################################################################
#
# move_char.s
#
# This program is written using the primitive instruction set
# for the forwarding RISC-V processor. This program will draw a
# characters on the screen (see code for details).
#
# This program does not use the data segment.
#
# Memory Organization:
#   0x0000-0x1fff : text
#   0x2000-0x3fff : data
#   0x7f00-0x7fff : I/O
#   0x8000- : VGA
#
# Registers:
# x3(gp):   I/O base address
# x4(tp):   VGA Base address
# x8(s0):   Memory pointer to location to display character
# x9(s1):   Current column index
# x18(s2):  Current row index
#
# ##################################################################################
.globl  main

.data
    .word 0

.text


# I/O address offset constants
    .eqv LED_OFFSET 0x0
    .eqv SWITCH_OFFSET 0x4
    .eqv SEVENSEG_OFFSET 0x18
    .eqv BUTTON_OFFSET 0x24
    .eqv CHAR_COLOR_OFFSET 0x34

# I/O mask constants
    .eqv BUTTON_C_MASK 0x01
    .eqv BUTTON_L_MASK 0x02
    .eqv BUTTON_D_MASK 0x04
    .eqv BUTTON_R_MASK 0x08
    .eqv BUTTON_U_MASK 0x10

# ASCI SPACE
    .eqv SPACE_CHAR 0x20
    .eqv HASH_CHAR 0x23
    .eqv LAST_COLUMN 10                 # 79 - last two columns don't show on screen
    .eqv LAST_ROW 10                    # 31 - last two rows down't show on screen
    .eqv ADDRESSES_PER_ROW 512
    .eqv NEG_ADDRESSES_PER_ROW -512
    .eqv N_CHAR 0x4e
    .eqv R_CHAR 0x52
    .eqv B_CHAR 0x42
    .eqv E_CHAR 0x45
    .eqv ONE_CHAR 0x31
    .eqv FOUR_CHAR 0x34
    .eqv SMILE_CHAR 0x01

main:
    # Prepare I/O base address
    addi gp, x0, 0x7f
    # Shift left 8 (0x7f00)
    slli gp, gp, 8
    # 0x7f00 should be in gp

    # init the LED display value
    addi s3, x0, 0

    # Prepare VGA base address
    addi tp, x0, 0x40
    # Shift left 9 (0x8000)
    slli tp, tp, 9
    # 0x8000 should be in tp

CLEAR_VGA:

    # Set the background color and put it in t2
    addi t2, x0, 0x8
    # Shift 4
    slli t2, t2, 8
    # Fill in the rest
    addi t2, t2, 0x97
    # Shift it to the background color section
    slli t2, t2, 9
    # Set the foreground color in t2
    addi t2, t2, 0xf8
    # Shift by 4
    slli t2, t2, 4

    sw t2, CHAR_COLOR_OFFSET(gp)  # Write the new color values

    # Clear the s3 value for the counter
    addi s3, x0, 0

    # Write a space to all locations in VGA memory
    addi t0, x0, SPACE_CHAR       # ASCII character for space
    add t1, x0, tp                # Pointer to VGA space that will change
    # Create constant 0x1000
    addi t2, x0, 0x400            # 0x400
    # should get 0x1000
    slli t2, t2, 2

L5:
    sw t0, 0(t1)                # Write 'space' character to pointer in VGA space
    addi t2, t2, -1             # Decrement counter
    beq t2, x0, WRITE_NETID     # Exit loop when done
    addi t1, t1, 4              # Increment memory pointer by 4 to next character address
    beq x0, x0, L5

WRITE_NETID:
    # Initialize the VGA character write constants

    # add it to tp at the very end
    addi t0, x0, 60             # Start at column 60
    slli t0, t0, 2              # multiply by 4 for the s0 pointer location
    li t2, 24                   # Start at row 24
    slli t2, t2, 9              # Multiply by 512 for the s0 location
    add t2, t2, tp              # Add in the tp (base pointer location)
    add s0, t0, t2              # Store the new address location into s0

    # Write a N
    addi t1, x0, N_CHAR                         # Load a N
    sw t1, 0(s0)                                # Write the character to the VGA
    addi s0, s0, 4                              # Increment pointer for next display location
    # Write a R
    addi t1, x0, R_CHAR                         # Load a R
    sw t1, 0(s0)                                # Write the character to the VGA
    addi s0, s0, 4                              # Increment pointer for next display location
    # Write a B
    addi t1, x0, B_CHAR                         # Load a B
    sw t1, 0(s0)                                # Write the character to the VGA
    addi s0, s0, 4                              # Increment pointer for next display location
    # Write a E
    addi t1, x0, E_CHAR                         # Load a E
    sw t1, 0(s0)                                # Write the character to the VGA
    addi s0, s0, 4                              # Increment pointer for next display location
    # Write a N
    addi t1, x0, N_CHAR                         # Load a N
    sw t1, 0(s0)                                # Write the character to the VGA
    # Write a N
    addi t1, x0, N_CHAR                         # Load a N
    sw t1, 0(s0)                                # Write the character to the VGA
    addi s0, s0, 4                              # Increment pointer for next display location
    # Write a 1
    addi t1, x0, ONE_CHAR                       # Load a 1
    sw t1, 0(s0)                                # Write the character to the VGA
    addi s0, s0, 4                              # Increment pointer for the next display location
    # Write a 4
    addi t1, x0, FOUR_CHAR                      # Load a 4
    sw t1, 0(s0)                                # Write tha character to the VGA

    # Go back to the real init function
    beq x0, x0, L6

L6:
    # Done initializing screen
    # Initialize the VGA character write constants
    addi s0, tp, 0              # s0: pointer to VGA locations
    addi s1, x0, 0              # s1: current column
    addi s2, x0, 0              # s2: current row
    
    # Draw the smiley
    addi t1, x0, SMILE_CHAR                     # load the SMILE_CHAR every time
    sw t1, 0(s0)                                # Write the character to the VGA
    
    # Clear Seven segment display and LEDs
    sw x0, SEVENSEG_OFFSET(gp)
    sw x0, LED_OFFSET(gp)

    # Wait until all the buttons are released before proceeding to check for status of buttons
    # (this is a one shot functionality to prevent one button press from causing more than one
    #  response)
BTN_RELEASE:
    lw t0, BUTTON_OFFSET(gp)
    # Keep jumping back until a button is pressed
    beq x0, t0, BTN_PRESS
    beq x0, x0, BTN_RELEASE

BTN_PRESS:
    # Wait for button press
    lw t0, BUTTON_OFFSET(gp)
    # Keep jumping back until a button is pressed
    beq x0, t0, BTN_PRESS

    # See if BUTTON_C is pressed. If so, clear VGA
    addi t1, x0, BUTTON_C_MASK
    beq t0, t1, CLEAR_VGA

UPDATE_DISPLAY_POINTER:
    # Any other button means print the character of the switches on the VGA and move the pointer

    # Update the pointer based on the button
    addi t1, x0, BUTTON_L_MASK
    beq t0, t1, PROCESS_BTNL
    addi t1, x0, BUTTON_R_MASK
    beq t0, t1, PROCESS_BTNR
    addi t1, x0, BUTTON_U_MASK
    beq t0, t1, PROCESS_BTNU
    addi t1, x0, BUTTON_D_MASK
    beq t0, t1, PROCESS_BTND

    # Shouldn't get here
    beq x0, x0, BTN_RELEASE

    # These code segments update the data to print on the SSD as well
    # as determine the new next location for printing characters
PROCESS_BTNR:
    # Erase the character at the current location
    addi t1, x0, SPACE_CHAR                     # load the SPACE_CHAR every time
    sw t1, 0(s0)                                # Write the character to the VGA
    # Move pointer right
    addi t0, x0, LAST_COLUMN
    beq s1, t0, DISPLAY_LOCATION                     # Ignore if on last column
    addi s1, s1, 1                              # Increment column
    addi s0, s0, 4                              # Increment pointer for next display location
    addi s3, s3, 1                              # increment the counter by 1
    beq x0, x0, DISPLAY_LOCATION

PROCESS_BTNL:
    # Erase the character at the current location
    addi t1, x0, SPACE_CHAR                     # load the SPACE_CHAR every time
    sw t1, 0(s0)                                # Write the character to the VGA
    # Move pointer left
    beq s1, x0, DISPLAY_LOCATION                     # Ignore if on first column
    addi s1, s1, -1                             # Decrement column
    addi s0, s0, -4                             # Decrement pointer for next display location
    addi s3, s3, 1                              # increment the counter by 1
    beq x0, x0, DISPLAY_LOCATION

PROCESS_BTNU:
    # Erase the character at the current location
    addi t1, x0, SPACE_CHAR                     # load the SPACE_CHAR every time
    sw t1, 0(s0)                                # Write the character to the VGA
    # Move pointer Up
    beq s2, x0, DISPLAY_LOCATION                     # Ignore if on first row
    addi s2, s2, -1                             # Decrement row
    addi s0, s0, NEG_ADDRESSES_PER_ROW          # Decrement pointer
    addi s3, s3, 1                              # increment the counter by 1
    beq x0, x0, DISPLAY_LOCATION

PROCESS_BTND:
    # Erase the character at the current location
    addi t1, x0, SPACE_CHAR                     # load the SPACE_CHAR every time
    sw t1, 0(s0)                                # Write the character to the VGA
    # Move pointer Down
    addi t0, x0, LAST_ROW
    beq s2, t0, DISPLAY_LOCATION                     # Ignore if on last row
    addi s2, s2, 1                              # Increment row
    addi s0, s0, ADDRESSES_PER_ROW              # Increment pointer
    addi s3, s3, 1                              # increment the counter by 1
    beq x0, x0, DISPLAY_LOCATION

DISPLAY_LOCATION:
    # Display the character at the current location
    addi t1, x0, SMILE_CHAR                     # load the SMILE_CHAR every time
    sw t1, 0(s0)                                # Write the character to the VGA

    # Display counter on LCD
    sw s3, SEVENSEG_OFFSET(gp)
    # Display col,row on LEDs
    add t0, s1, x0                              # Load s1 (column) to t0
    # Shift by 8
    slli t0, t0, 8
    # Or s2 (row)
    or t0, t0, s2
    # Write to LEDs
    sw t0, LED_OFFSET(gp)

    # Go back to button release
    beq x0, x0, BTN_RELEASE