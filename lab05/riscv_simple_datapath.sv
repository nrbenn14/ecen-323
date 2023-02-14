`timescale 1ns / 1ps
`include "riscv_datapath_constants.sv"
/***************************************************************************
* 
* Filename: riscv_simple_datapath.sv
*
* Author: Nathan Bennion
* Class: ECEn 323, Section 1, Winter 2023
* Date: 14 Feb 2023
*
* Description: Takes inputs from PCSrc, ALUSrc, registers and memory to
*               perform operations used on the RISC-V Processor.
*
****************************************************************************/


module riscv_simple_datapath #(parameter INITIAL_PC = 32'h00400000)(clk, rst, PCSrc, ALUSrc, 
    RegWrite, MemtoReg, loadPC, instruction, dReadData, ALUCtrl, Zero, PC, dAddress, dWriteData, WriteBackData);


    input wire logic clk, rst, PCSrc, ALUSrc, RegWrite, MemtoReg, loadPC;
    input wire logic [31:0] instruction, dReadData;
    input wire logic [3:0] ALUCtrl;
    output logic Zero;
    output logic [31:0] PC, dAddress, dWriteData, WriteBackData;
    
    
    logic [31:0] ReadData1, ReadData2, instruction_ext, ALUresult, op2, s_type_immediate;
    logic [31:0] branch_offset;
    

    assign s_type_immediate = {{20 {instruction[31]}}, instruction[31:25], instruction[11:7]};
    assign instruction_ext = {{20 {instruction[31]}}, instruction[31:20]};
    assign branch_offset = {{19 {instruction[31]}}, instruction[31], instruction[7], 
                            instruction[30:25], instruction[11:8], 1'b0};
                            
    // Checks if ready for a branch, adds offset to PC. Also does the reset case.
    always_ff@(posedge clk) begin
        if(rst)
            PC <= INITIAL_PC;
        if(loadPC & PCSrc & Zero)
             PC <= PC + branch_offset;
        else if(loadPC)
             PC <= PC + 4;
        end
        
    // Regfile instance
    regfile regfile0 (.clk(clk), .readReg1(instruction[19:15]), 
        .readReg2(instruction[24:20]), .writeReg(instruction[11:7]), .writeData(WriteBackData), 
        .write(RegWrite), .readData1(ReadData1), .readData2(ReadData2));
        
    // Checks if instruction type is S-type. Sets ReadData2 to the sign extended immediate if so.    
    always_comb
        if(ALUSrc)
            if(instruction[6:0] == S_TYPE_OP_CODE)
                op2 <= s_type_immediate;    
            else
                op2 <= instruction_ext;
        else   
            op2 <= ReadData2;
            
    // ALU instance
    alu alu0 (.op1(ReadData1), .op2(op2), .alu_op(ALUCtrl), .zero(Zero), .result(ALUresult));

    assign dWriteData = ReadData2;
    assign dAddress = ALUresult;
    
    // Assigns the writebackdata to ALU result or the read data (if memtoreg is high).
    // For data block.
    always_comb
        if(MemtoReg)
            WriteBackData <= dReadData;
        else
            WriteBackData <= ALUresult;
endmodule
