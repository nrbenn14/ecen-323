`timescale 1 ns / 1 ps 
`include "riscv_alu_constants.sv"
/***************************************************************************
* 
* File: alu.sv
*
* Author: Nathan Bennion
* Class: ECEN 323, Winter Semester 2023
* Date: 24 Jan 2023
*
* Module: alu
*
* Description: This module takes a 4 bit input and two 32 bit parameters
*    and then does an operation on the parameters based on the input
*	
****************************************************************************/


module alu(op1, op2, alu_op, zero, result);

    input wire logic [31:0] op1, op2;
    input wire logic [3:0] alu_op;
    output logic zero;
    output logic [31:0] result;
    
    assign zero = (result == 0);
    
    // ALU Multiplexer block - picks the operation to preform
    
    always_comb
        case(alu_op)
            ALUOP_AND: result = op1 & op2;
            ALUOP_OR: result = op1 | op2;
            ALUOP_ADD: result = op1 + op2;
            ALUOP_SUB: result = op1 - op2;
            ALUOP_LESS: result = $signed(op1) < $signed(op2);
            ALUOP_SRL: result = op1 >> op2[4:0];
            ALUOP_SLL: result = op1 << op2[4:0];
            ALUOP_SRA: result = $unsigned($signed(op1) >>> op2[4:0]);
            ALUOP_XOR: result = op1 ^ op2; 
            default: result = op1 + op2;
        endcase
    
    


endmodule
