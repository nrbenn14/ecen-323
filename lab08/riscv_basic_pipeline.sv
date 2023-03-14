`timescale 1ns / 1ps
`include "riscv_alu_constants.sv"
`include "riscv_datapath_constants.sv"
/***************************************************************************
* 
* File: riscv_basic_pipeline.sv
*
* Author: Nathan Bennion
* Class: ECEn 323, Winter Semester 2023, Section 2
* Date: 11 March 2023
*
* Module: riscv_basic_pipeline
*
* Description: This module enables and pipelines 5 different instructions 
*               to come through at once through the datapath.
*               Uses five seperate stages to manage each instruction.
*	
****************************************************************************/


module riscv_basic_pipeline #(parameter INITIAL_PC = 32'h00400000)(clk, rst, PC, instruction, ALUResult,
dAddress, dWriteData, dReadData,  MemRead, MemWrite, WriteBackData);

    input wire logic clk, rst;
    input wire logic [31:0] instruction, dReadData;
    output logic MemRead, MemWrite;
    output logic [31:0] PC, ALUResult, dAddress, dWriteData, WriteBackData;
    
    // IF stage signals
    logic [31:0] if_PC, if_instruction;
    
    // ID stage signals
    logic id_ALUSrc, id_MemWrite, id_MemRead, id_Branch, id_MemtoReg, id_RegWrite;
    logic [3:0] id_ALUCtrl;
    logic [2:0] id_funct3;
    logic [4:0] id_writereg;
    logic [6:0] id_opcode, id_funct7;
    logic [31:0] id_PC, id_instruction, id_branch_offset, id_ReadData1, 
                 id_ReadData2, id_s_type_immediate, id_instruction_ext;
    
    // EX stage signals
    logic ex_ALUSrc, ex_MemWrite, ex_MemRead, ex_Branch, ex_Zero, ex_MemtoReg, ex_RegWrite;
    logic [3:0] ex_ALUCtrl;
    logic [6:0] ex_opcode;
    logic [4:0] ex_writereg;
    logic [31:0] ex_PC, ex_branch_offset, ex_ALUresult, ex_ReadData1, 
                 ex_ReadData2, ex_op2, ex_instruction_ext, ex_s_type_immediate;
    
    // MEM stage signals
    logic mem_PCSrc, mem_MemtoReg, mem_RegWrite, mem_MemWrite, mem_MemRead, mem_Zero, mem_Branch;
    logic [4:0] mem_writereg;
    logic [31:0] mem_ALUresult, mem_branch_offset, mem_ReadData2;
    
    // WB stage signals
    logic wb_PCSrc, wb_MemtoReg, wb_RegWrite;
    logic [4:0] wb_writereg;
    logic [31:0] wb_ALUresult, wb_WriteBackData;
    
    
//////////////////////////////////////////////////////////////////////
// IF: Instruction Fetch
//////////////////////////////////////////////////////////////////////	

    // always_ff block for IF pipelined signals
    always_ff@(posedge clk) begin
    
        if (rst) begin
            PC <= INITIAL_PC;
            if_PC <= INITIAL_PC;
            id_instruction <= NOP_CONST;
        end
        
        else begin
            if_PC <= PC;
            id_instruction <= instruction;
            if (!mem_PCSrc)
                PC <= PC + 4;
                
            else
                PC <= ex_PC + ex_branch_offset;
        end
    end
    
//////////////////////////////////////////////////////////////////////
// ID: Instruction Decode
//////////////////////////////////////////////////////////////////////	

    // Register instantiation
    regfile regfile0 (.clk(clk), .readReg1(instruction[19:15]), 
        .readReg2(instruction[24:20]), .writeReg(wb_writereg), .writeData(WriteBackData), 
        .write(wb_RegWrite), .readData1(id_ReadData1), .readData2(id_ReadData2));
        
    // always_ff block for ID pipelined signals
    always_ff@(posedge clk) begin
        if (rst) begin
            id_PC <= INITIAL_PC;
            id_branch_offset <= EMPTY_32;
            id_writereg <= 5'b00000;
        end
        
        else begin
            id_PC <= if_PC;
            id_branch_offset <= {{19 {instruction[31]}}, instruction[31], 
                                instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        end
    end
    
    assign id_opcode = {instruction[6:0]};
    assign id_funct3 = {instruction[14:12]};
    assign id_funct7 = {instruction[31:25]};

    assign id_ALUSrc = ((id_opcode != R_TYPE_OP_CODE) && (id_opcode != SB_TYPE_OP_CODE)) ? 1 : 0;
    assign id_MemWrite = (id_opcode == S_TYPE_OP_CODE) ? 1 : 0;
    assign id_MemRead = (id_opcode == ILOAD_TYPE_OP_CODE) ? 1 : 0;
    assign id_Branch = (id_opcode == SB_TYPE_OP_CODE) ? 1 : 0; 
    assign id_MemtoReg = (id_opcode == ILOAD_TYPE_OP_CODE) ? 1 : 0;
    assign id_RegWrite = ((id_opcode != S_TYPE_OP_CODE) && (id_opcode != SB_TYPE_OP_CODE)) ? 1 : 0;
    
    assign id_s_type_immediate = {{20 {instruction[31]}}, instruction[31:25], instruction[11:7]};
    assign id_instruction_ext = {{20 {instruction[31]}}, instruction[31:20]};
    
    
    // Determine ALUCtrl based on opcode, func3, and func7
        always_comb begin
        if((id_opcode == ILOAD_TYPE_OP_CODE) || (id_opcode == S_TYPE_OP_CODE)) // for load/store, add
            id_ALUCtrl = ALUOP_ADD;
            
        else if(id_opcode == SB_TYPE_OP_CODE)    //for branch, subtract
            id_ALUCtrl = ALUOP_SUB;
            
        else if((id_opcode == R_TYPE_OP_CODE) || (id_opcode == I_TYPE_OP_CODE)) begin
            
            if(id_funct3 == FUNCT3_OR)        // for or/ori
                id_ALUCtrl = ALUOP_OR;
                
            else if(id_funct3 == FUNCT3_SLT) // for slt/slti
                id_ALUCtrl = ALUOP_LESS;
                
            else if(id_funct3 == FUNCT3_XOR) // for xor/xori
                id_ALUCtrl = ALUOP_XOR;
                
            else if(id_funct3 == FUNCT3_AND) // for and/andi
                id_ALUCtrl = ALUOP_AND;  
                              
            else if((id_funct3 == FUNCT3_SUB) && (id_funct7 == FUNCT7_SUB) && (id_opcode == R_TYPE_OP_CODE)) // for sub
                id_ALUCtrl = ALUOP_SUB;
                
            else if((id_funct3 == FUNCT3_ADD) && (id_opcode == I_TYPE_OP_CODE)) // for sub
                id_ALUCtrl = ALUOP_ADD;
                
            else if((id_funct3 == FUNCT3_ADD) && (id_funct7 == FUNCT7_ADD)) // for add/addi
                id_ALUCtrl = ALUOP_ADD;
                
            else if(id_funct3 == FUNCT3_SLL) // for sll/slli
                id_ALUCtrl = ALUOP_SLL;
                
            else if((id_funct3 == FUNCT3_SRL) && (id_funct7 == FUNCT7_SRL)) // for srl/srli
                id_ALUCtrl = ALUOP_SRL;
                
            else if((id_funct3 == FUNCT3_SRA) && (id_funct7 == FUNCT7_SRA)) // for sra/srai
                id_ALUCtrl = ALUOP_SRA;
                
            else
                id_ALUCtrl = ALUOP_ADD;
            end
        else
            id_ALUCtrl = ALUOP_ADD;
    end
    

//////////////////////////////////////////////////////////////////////
// EX: Execute
//////////////////////////////////////////////////////////////////////


    // ALU module instance
    alu alu0 (.op1(id_ReadData1), .op2(ex_op2), .alu_op(ex_ALUCtrl), .zero(ex_Zero), .result(ex_ALUresult));
    
    assign ALUResult = ex_ALUresult;
    
    // always_ff block for EX pipelined signals
    always_ff@(posedge clk) begin
        
        if (rst) begin
            ex_PC <= INITIAL_PC;
            ex_writereg <= 5'b00000;
            ex_MemWrite <= 0;
            ex_MemRead <= 0;
            ex_MemtoReg <= 0;
            ex_RegWrite <= 1;
            ex_Branch <= 0;
            ex_ALUSrc <= 0;
            ex_ALUCtrl <= ALUOP_ADD;
            ex_branch_offset <= EMPTY_32;
            ex_ReadData1 <= EMPTY_32;
            ex_ReadData2 <= EMPTY_32;
            ex_opcode <= 7'b0000000;
            ex_instruction_ext <= EMPTY_32;
            ex_s_type_immediate <= EMPTY_32;
        end
        
        else begin
            ex_PC <= id_PC;
            ex_writereg <= instruction[11:7];
            ex_MemWrite <= id_MemWrite;
            ex_MemRead <= id_MemRead;
            ex_MemtoReg <= id_MemtoReg;
            ex_Branch <= id_Branch;
            ex_ALUSrc <= id_ALUSrc;
            ex_ALUCtrl <= id_ALUCtrl;
            ex_branch_offset <= id_branch_offset;
            ex_ReadData1 <= id_ReadData1;
            ex_ReadData2 <= id_ReadData2;
            ex_opcode <= id_opcode;
            ex_instruction_ext <= id_instruction_ext;
            ex_s_type_immediate <= id_s_type_immediate;
            ex_RegWrite <= id_RegWrite;
            
        end
    end
    
    // Check for S-type instruction, set readData2 to sign extend immediate if so
    always_comb
        if(ex_ALUSrc)
            if(ex_opcode == S_TYPE_OP_CODE) 
                ex_op2 = ex_s_type_immediate;
            
            else
                ex_op2 = ex_instruction_ext;
        else 
            ex_op2 = id_ReadData2;
            
        
//////////////////////////////////////////////////////////////////////
// MEM: Memory
//////////////////////////////////////////////////////////////////////	


    // always_ff block for pipelined MEM signals
    always_ff@(posedge clk) begin
        if (rst) begin
            mem_writereg <= 5'b00000;
            mem_MemRead <= 0;
            mem_MemWrite <= 0;
            mem_RegWrite <= 1;
            mem_PCSrc <= 0;
            mem_Branch <= 0;
            mem_ReadData2 <= EMPTY_32;
            mem_Zero <= 0;
            mem_MemtoReg <= 0;
            mem_ALUresult <= EMPTY_32;
            mem_branch_offset <= EMPTY_32;
        end
        
        else begin
            mem_writereg <= ex_writereg;
            mem_MemRead <= ex_MemRead;
            mem_MemWrite <= ex_MemWrite;
            mem_RegWrite <= ex_RegWrite;
            mem_PCSrc <= (ex_Zero && ex_Branch);
            mem_Branch <= ex_Branch;
            mem_ReadData2 <= ex_ReadData2;
            mem_Zero <= ex_Zero;
            mem_MemtoReg <= ex_MemtoReg;
            mem_ALUresult <= ex_ALUresult;
            mem_branch_offset <= ex_branch_offset;
        end
    end
    
    assign dWriteData = ex_ReadData2;
    assign dAddress = mem_ALUresult;
    assign MemRead = mem_MemRead;
    assign MemWrite = mem_MemWrite; 
    
    
//////////////////////////////////////////////////////////////////////
// WB: Write Back
//////////////////////////////////////////////////////////////////////

    // always_ff block for pipelined WB signals
    always_ff@(posedge clk) begin
         if(rst) begin
             wb_writereg <= 5'b00000;
             wb_WriteBackData <= EMPTY_32;
             wb_MemtoReg <= 0;
             wb_RegWrite <= 1;
         end
         
         else begin
             wb_writereg <= mem_writereg;
             wb_MemtoReg <= mem_MemtoReg;
             wb_RegWrite <= mem_RegWrite;
             wb_ALUresult <= mem_ALUresult;
             wb_WriteBackData <= mem_ALUresult;
         end
    end
    
    assign WriteBackData = wb_MemtoReg ? dReadData : wb_WriteBackData;
    


endmodule
