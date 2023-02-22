`timescale 1ns / 1ps
/***************************************************************************
* 
* File: riscv_multicycle.sv
*
* Author: Nathan Bennion
* Class: ECEN 323, Winter 2023, Section 2
* Date: 20 Feb 2023
*
* Module: riscv_multicycle
*
* Description: Takes all of the instruction inputs and outputs and puts them through a
*   state machine. State machine has 5 states to impliment the 5 states of the RISC-V
*   control path.
*    
*	
****************************************************************************/


module riscv_multicycle#(parameter INITIAL_PC = 32'h00400000)(clk, rst, instruction, dReadData, PC, 
dAddress, dWriteData, MemRead, MemWrite, WriteBackData);

    `include "riscv_datapath_constants.sv"
    `include "riscv_alu_constants.sv"


    input wire logic clk, rst;
    input wire logic [31:0] instruction, dReadData;
    output logic MemRead, MemWrite;
    output logic [31:0] PC, dAddress, dWriteData, WriteBackData;
    
    logic ALUSrc, MemtoReg, RegWrite, loadPC, PCSrc, Zero;
    logic [3:0] ALUCtrl;
    logic [6:0] opcode, funct7;
    logic [2:0] funct3;
    
    
    // Implement datapath module
    riscv_simple_datapath #INITIAL_PC datapath(.clk(clk), .rst(rst), .PCSrc(PCSrc), .ALUSrc(ALUSrc), 
        .RegWrite(RegWrite), .MemtoReg(MemtoReg), .loadPC(loadPC), .instruction(instruction), .dReadData(dReadData), 
        .ALUCtrl(ALUCtrl), .Zero(Zero), .PC(PC), .dAddress(dAddress), .dWriteData(dWriteData), .WriteBackData(WriteBackData));
        
        
    // State machine state declaration
    typedef enum logic[2:0] {IF, ID, EX, MEM, WB, ERR='X} StateType;
    StateType cs, ns;
    
    // Change next state to current state
    always_ff@(posedge clk)
        cs <= ns;
    
    // State machine actual instantiation 
    always_comb begin
           ns = ERR;
           if(rst)
                ns = IF;
           else
           case(cs)
                IF: 
                    ns = ID;
                ID:
                    ns = EX;   
                EX: 
                    ns = MEM;   
                MEM:              
                    ns = WB;   
                WB: 
                    ns = IF; 
                default:
                    ns = IF; 
           endcase
    end
     
    // Divvy up pieces of the instruction
    assign opcode = {instruction[6:0]};
    assign funct3 = {instruction[14:12]};
    assign funct7 = {instruction[31:25]};
    
        
    // Logic to assign signals based on the instruction
    assign ALUSrc = ((opcode != R_TYPE_OP_CODE) && (opcode != SB_TYPE_OP_CODE)) ? 1 : 0;
    assign MemRead = ((opcode == ILOAD_TYPE_OP_CODE) && (cs == MEM)) ? 1 : 0;
    assign MemWrite = ((opcode == S_TYPE_OP_CODE) && (cs == MEM)) ? 1 : 0;
    assign MemtoReg = ((opcode == ILOAD_TYPE_OP_CODE) && (cs == WB)) ? 1 : 0;
    assign RegWrite = ((opcode != S_TYPE_OP_CODE) && (opcode != SB_TYPE_OP_CODE) && (cs == WB)) ? 1 : 0;
    assign loadPC = (cs == WB) ? 1 : 0;
    assign PCSrc = (Zero && (opcode == SB_TYPE_OP_CODE) && (cs == WB)) ? 1 : 0;
    
    // ALUCtrl assignment block
    always_comb begin
        if((opcode == ILOAD_TYPE_OP_CODE) || (opcode == S_TYPE_OP_CODE)) // for load/store, add
            ALUCtrl = ALUOP_ADD;
        else if(opcode == SB_TYPE_OP_CODE)    //for branch, subtract
            ALUCtrl = ALUOP_SUB;
        else if((opcode == R_TYPE_OP_CODE) || (opcode == I_TYPE_OP_CODE)) begin
            if(funct3 == FUNCT3_OR)        // for or/ori
                ALUCtrl = ALUOP_OR;
            else if(funct3 == FUNCT3_SLT) // for slt/slti
                ALUCtrl = ALUOP_LESS;
            else if(funct3 == FUNCT3_XOR) // for xor/xori
                ALUCtrl = ALUOP_XOR;
            else if(funct3 == FUNCT3_AND) // for and/andi
                ALUCtrl = ALUOP_AND;                
            else if((funct3 == FUNCT3_SUB) && (funct7 == FUNCT7_SUB) && (opcode == R_TYPE_OP_CODE)) // for sub
                ALUCtrl = ALUOP_SUB;
            else if((funct3 == FUNCT3_ADD) && (opcode == I_TYPE_OP_CODE)) // for sub
                ALUCtrl = ALUOP_ADD;
            else if((funct3 == FUNCT3_ADD) && (funct7 == FUNCT7_ADD)) // for add/addi
                ALUCtrl = ALUOP_ADD;
            else if(funct3 == FUNCT3_SLL) // for sll/slli
                ALUCtrl = ALUOP_SLL;
            else if((funct3 == FUNCT3_SRL) && (funct7 == FUNCT7_SRL)) // for srl/srli
                ALUCtrl = ALUOP_SRL;
            else if((funct3 == FUNCT3_SRA) && (funct7 == FUNCT7_SRA)) // for sra/srai
                ALUCtrl = ALUOP_SRA;
            else
                ALUCtrl = ALUOP_ADD;
            end
        else
            ALUCtrl = ALUOP_ADD;
    end
     
endmodule
