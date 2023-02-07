#########################################################################
# 
# Filename: fib_template.s
#
# Author:
# Date:
#
# Description:
#
# Functions:
#  - fibonacci:
#
#########################################################################

.globl  main

# Constant defines for system calls
.eqv PRINT_INT 1
.eqv PRINT_STR 4
.eqv EXIT_CODE 93

# Global data segment
.data
fib_input:                                     # The location for the input factorial value
    .word 10                                   # Allocates 4 bytes and sets the input to 10 (arbitrary)
    
result_str:                                    # The location for the result string data
    .string "\nFibinnoci Number is "           # Allocates 1 byte per character plus null character

netid_str:                                     # The location for the netid string data
                                               # Change the string below to include your net id
    .string "\nNet ID=nrbenn14"                # Allocates 1 byte per character plus null character

.text

# Main function that calls your fibonacci function
main:

    # Load n into a0 as the argument
    lw a0, fib_input
    
    # Call the fibonacci function
    jal fibonacci
    
    # Save the result into s2
    mv s2, a0 

    # Print the Result string
    la a0,result_str            # Put string pointer in a0
    li a7,PRINT_STR             # System call code for print_str
    ecall                       # Make system call

    # Print the number        
     mv a0, s2
    li a7,PRINT_INT             # System call code for print_int
    ecall                       # Make system call

    # Print the netid string
    la a0,netid_str             # Put string pointer in a0
    li a7,PRINT_STR             # System call code for print_str
    ecall                       # Make system call

    # Exit (93) with code 0
    li a0,0
    li a7,EXIT_CODE
    ecall
    ebreak

fibonacci:

    # This is where you should create your Fibonacci function.
    # The input argument for your Fibonacci arrives in a0. You should 
    # put your result in a0.
    #
    # You should properly manage the stack to save registers that
    # you use.


    addi sp, sp, -12            # Make room on stack
    sw s0, 0(sp)                # Make 3 saved registers
    sw s1, 4(sp)                # Each register is 4 bytes
    sw ra, 8(sp)                # Save return address
    mv s0, a0                   # Move a0 to s0

loop:

    beqz s0 return              # If s0 == 0, go to return
    li t1, 1                    # Set the temp register to 1
    beq s0, t1, return          # Go to return if s0 == 1

    addi a0, s0, -1             # a0 = s0 - 1
    jal fibonacci               # Jump back to fibonacci
    mv s1, a0                   # Move a0 to s1

    addi a0, s0, -2             # a0 = s0 - 2
    jal fibonacci               # Jump back to fibonacci
    add a0, a0, s1              # a0 = a0 + s1

return:

    lw s0, 0(sp)                # Restore saved registers
    lw s1, 4(sp)                # Each register is 4 bytes
    lw ra, 8(sp)                # Same here
    addi sp, sp, 12             # Update stack pointer
    ret                         # Jump to return address
