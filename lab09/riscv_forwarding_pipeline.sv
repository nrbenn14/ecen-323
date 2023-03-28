`timescale 1ns / 1ps
/***************************************************************************
* 
* File: riscv_forwarding_pipeline.sv
*
* Author: Nathan Bennion
* Class: ECEn 323, Winter Semester 2023, Section 2
* Date: 21 March 2023
*
* Module: riscv_forwarding_pipeline
*
* Description: This module enables and pipelines 5 different instructions 
*               to come through at once through the datapath.
*               Uses five seperate stages to manage each instruction.
*               Includes logic to handle different instruction hazards.
*	
****************************************************************************/


module riscv_forwarding_pipeline #(parameter INITIAL_PC = 32'h00400000)(clk, rst, PC, instruction, ALUResult,
dAddress, dWriteData, dReadData,  MemRead, MemWrite, WriteBackData, iMemRead);


    `include "riscv_alu_constants.sv"
    `include "riscv_datapath_constants.sv"
    
    // Inputs
    input wire logic clk;
    input wire logic rst;
    input wire logic [31:0] instruction;
    input wire logic [31:0] dReadData;
    
    // Outputs
    output logic MemRead;
    output logic MemWrite;
    output logic iMemRead;
    output logic [31:0] PC;
    output logic [31:0] ALUResult;
    output logic [31:0] dAddress;
    output logic [31:0] dWriteData;
    output logic [31:0] WriteBackData;
    
    // IF Stage Signals
    logic [31:0] if_PC;
    
    
    // ID Stage Signals
    logic [31:0] id_PC;
    logic [3:0] id_ALUCtrl;
    logic id_ALUSrc;
    logic id_MemWrite;
    logic id_MemRead;
    logic id_Branch;
    logic id_RegWrite;
    logic id_MemtoReg;
    logic [31:0] id_immediate;
    logic [31:0] id_readData1;
    logic [31:0] id_readData2;
    logic [31:0] id_itype_immediate;
    logic [31:0] id_stype_immediate;
    logic [31:0] id_branch_offset;
    
    // ID Forwarding logic
    logic [4:0] id_reg1, id_reg2;
    logic [4:0] id_writeReg;
    
    // EX Stage Signals
    logic [31:0] ex_PC;
    logic ex_ALUSrc;
    logic ex_MemWrite;
    logic ex_MemRead;
    logic ex_Branch;
    logic ex_RegWrite;
    logic ex_MemtoReg;
    logic [3:0] ex_ALUCtrl;
    logic [31:0] ex_PC_Offset;
    logic [31:0] ex_immediate;
    logic [31:0] ex_readData1;
    logic [31:0] ex_readData2;
    logic ex_ALU_zero;
    logic [31:0] ex_ALU_result;
    logic [31:0] ex_PC_plus_Offset;
    logic [31:0] ex_branch_offset;
    
    // EX Forwarding logic
    logic [4:0] ex_reg1, ex_reg2;
    logic [4:0] ex_writeReg;
    
    
    // MEM Stage Signals
    logic [31:0] mem_PC;
    logic mem_RegWrite;
    logic mem_MemtoReg;
    logic mem_Branch;
    logic mem_MemRead;
    logic mem_MemWrite;
    logic [31:0] mem_PC_plus_Offset;
    logic mem_ALU_zero;
    logic [31:0] mem_ALU_result;
    logic [31:0] mem_writeData;
    logic mem_PCSrc;
    logic [31:0] mem_readData2;
    
    // MEM Forwarding logic
    logic [4:0] mem_writeReg;
    logic branch_mem_taken;
    
    
    // WB Stage Signals
    logic wb_RegWrite;
    logic wb_MemtoReg;
    logic [31:0] wb_writeData;
    logic [31:0] wb_ALU_result;
    
    // WB Forwarding logic
    logic [4:0] wb_writeReg;
    logic branch_wb_taken;
    
    // To Top-Level
    assign PC = if_PC;
    assign ALUResult = ex_ALU_result;
    assign dWriteData = mem_readData2;
    assign MemWrite = mem_MemWrite;
    assign MemRead = mem_MemRead;
    assign dAddress = mem_ALU_result;
    assign WriteBackData = wb_writeData;
    
    // Load_use_hazard detection
    logic load_use_hazard;
    assign load_use_hazard = (ex_MemRead && !mem_PCSrc && 
                             ((ex_writeReg == id_reg1) || (ex_writeReg == id_reg2))) ? 
                             1 : 0;
                             
    // Branch taken signal in MEM stage                         
    assign branch_mem_taken = mem_PCSrc;
    
    // iMemRead signal
    assign iMemRead = !load_use_hazard;
    
//////////////////////////////////////////////////////////////////////
// IF: Instruction Fetch
//////////////////////////////////////////////////////////////////////

    // always_ff block for IF pipelined signals
    always_ff@(posedge clk)
    begin
        if (rst)
        begin
            if_PC <= INITIAL_PC;
        end
        else if (load_use_hazard)
        begin
            //nothing, stall
        end    
        else
        begin
            if (mem_PCSrc)
            begin
                if_PC <= mem_PC_plus_Offset;
            end
            else
            begin
                if_PC <= if_PC + 4;
            end
        end
    end
    
//////////////////////////////////////////////////////////////////////
// ID: Instruction Decode
//////////////////////////////////////////////////////////////////////

    // always_ff block for pipelined ID signals
    always_ff@(posedge clk)
    begin
        if (rst)
        begin
            id_PC <= INITIAL_PC;
        end
        else if (load_use_hazard)
        begin
            //nothing, stall
        end  
        else
        begin
            id_PC <= if_PC;
        end
    end
            
    logic [3:0] func3;
    logic [6:0] opcode;
    logic func7;
    
    assign func3 = instruction[14:12];
    
    assign opcode = instruction[6:0];
           
    assign func7 = instruction[30];
    
    // ALUCtrl determination
    always_comb
        begin
            id_ALUCtrl = ALUOP_ADD;
            if (rst)
                id_ALUCtrl = ALUOP_ADD;
            case(opcode)
                I_TYPE_OP_CODE:
                    if (func3 == FUNCT3_AND)
                        id_ALUCtrl = ALUOP_AND;
                    else if (func3 == FUNCT3_OR)
                        id_ALUCtrl = ALUOP_OR;
                    else if(func3 == FUNCT3_ADD)
                        id_ALUCtrl = ALUOP_ADD;
                    else if (func3 == FUNCT3_XOR)
                        id_ALUCtrl = ALUOP_XOR;
                    else if (func3 == FUNCT3_SLT)
                        id_ALUCtrl = ALUOP_LESS;
                    else if (func3 == FUNCT3_SLL)
                        id_ALUCtrl = ALUOP_SLL;
                    else if ((func3 == FUNCT3_SRL)  && (func7 == 0))
                        id_ALUCtrl = ALUOP_SRL;
                    else if ((func3 == FUNCT3_SRA) && (func7 == 1))
                        id_ALUCtrl = ALUOP_SRA;
                    else
                        id_ALUCtrl = ALUOP_ADD;
                ILOAD_TYPE_OP_CODE:
                    id_ALUCtrl = ALUOP_ADD;
                S_TYPE_OP_CODE:
                    id_ALUCtrl = ALUOP_ADD;
                SB_TYPE_OP_CODE:
                    id_ALUCtrl = ALUOP_SUB;
                R_TYPE_OP_CODE:
                    if (func3 == FUNCT3_AND)
                        id_ALUCtrl = ALUOP_AND;
                    else if (func3 == FUNCT3_OR)
                        id_ALUCtrl = ALUOP_OR;
                    else if((func3 == FUNCT3_ADD) && (func7 == 0))
                        id_ALUCtrl = ALUOP_ADD;
                    else if ((func3 == FUNCT3_SUB) && (func7 == 1))
                        id_ALUCtrl = ALUOP_SUB;
                    else if (func3 == FUNCT3_XOR)
                        id_ALUCtrl = ALUOP_XOR;
                    else if (func3 == FUNCT3_SLT)
                        id_ALUCtrl = ALUOP_LESS;
                    else if (func3 == FUNCT3_SLL)
                        id_ALUCtrl = ALUOP_SLL;
                    else if (func3 == FUNCT3_SRL)
                        id_ALUCtrl = ALUOP_SRL;
                    else if (func3 == FUNCT3_SRA)
                        id_ALUCtrl = ALUOP_SRA;
                    else
                        id_ALUCtrl = ALUOP_ADD;
                default:
                    id_ALUCtrl = ALUOP_ADD;
            endcase
        end
        
    assign id_itype_immediate = {{20{instruction[31]}},instruction[31:20]};
    assign id_stype_immediate = {{20{instruction[31]}},instruction[31:25],
                                instruction[11:7]};
    assign id_branch_offset = {{19{instruction[31]}},instruction[31],instruction[7],
                                instruction[30:25],instruction[11:8],1'b0};
                                
    // id_immediate determination
    always_comb
    begin
        if (rst)
        begin
            id_immediate = 0;
        end
        else
        begin
            case(opcode)
                I_TYPE_OP_CODE:
                    id_immediate = id_itype_immediate;
                ILOAD_TYPE_OP_CODE:
                    id_immediate = id_itype_immediate;
                SB_TYPE_OP_CODE:
                    id_immediate = id_branch_offset;
                S_TYPE_OP_CODE:
                    id_immediate = id_stype_immediate;
                default:
                    id_immediate = 0;
             endcase
        end
    end
    
    // id_Branch signal determination
    always_comb
        begin
            id_Branch = 0;
            if (rst)
                id_Branch = 0;
            else if (opcode == SB_TYPE_OP_CODE)
                id_Branch = 1;
            else
                id_Branch = 0;
        end
        
    // ALUSrc signal determination
    always_comb
        begin
            if (opcode == I_TYPE_OP_CODE || instruction[6:0] == ILOAD_TYPE_OP_CODE || opcode == S_TYPE_OP_CODE)
                begin
                    id_ALUSrc = 1;
                end
            else
                begin
                    id_ALUSrc = 0;
                end
        end
        
    // Determine MemRead_temp signal, tied to MemRead
    always_comb
        begin
            if (rst)
                begin
                    id_MemRead = 0;
                end
            else
            begin
                if (opcode == ILOAD_TYPE_OP_CODE)
                    begin
                        id_MemRead = 1;
                    end
                else
                    begin
                        id_MemRead = 0;
                    end
            end
        end
    
    // Determine MemWrite_temp signalm tied to MemWrite
    always_comb
        begin
            if (rst)
                begin
                    id_MemWrite = 0;
                end
            else
            begin
                if (opcode == S_TYPE_OP_CODE)
                    begin
                        id_MemWrite = 1;
                    end
                else
                    begin
                        id_MemWrite = 0;
                    end
            end
        end
        
    // MemtoReg signal
    always_comb
        begin
            if (rst)
                begin
                    id_MemtoReg = 0;
                end
            else
                begin
                    if (opcode == ILOAD_TYPE_OP_CODE)
                        begin
                            id_MemtoReg = 1;
                        end
                    else
                        begin
                            id_MemtoReg = 0;
                        end
                end
        end
        
    // Determine RegWrite_temp signal, ties to RegWrite
    always_comb
        begin
            if (rst)
                begin
                    id_RegWrite = 0;
                end
            else
                begin
                    case(opcode)
                        SB_TYPE_OP_CODE: id_RegWrite = 0;
                        S_TYPE_OP_CODE: id_RegWrite = 0;
                        default: id_RegWrite = 1;
                    endcase
                end
        end
        
    assign id_reg1 = instruction[19:15];
    assign id_reg2 = instruction[24:20];
    assign id_writeReg = instruction[11:7];
    
    // Regfile instantiation
    regfile myregfile (.clk(clk), .readReg1(id_reg1), .readReg2(id_reg2), 
                   .writeReg(wb_writeReg), .writeData(wb_writeData), .write(wb_RegWrite), 
                   .readData1(ex_readData1), .readData2(id_readData2));
                   
//////////////////////////////////////////////////////////////////////
// EX: Execute
//////////////////////////////////////////////////////////////////////	

    // always_ff block for EX pipelined signals
    always_ff@(posedge clk)
        begin
            if (rst || load_use_hazard || branch_mem_taken || branch_wb_taken)
                begin
                    ex_PC <= INITIAL_PC;
                    ex_ALUCtrl <= ALUOP_ADD;
                    ex_ALUSrc <= 0;
                    ex_MemWrite <= 0;
                    ex_MemRead <= 0;
                    ex_Branch <= 0;
                    ex_RegWrite <= 0;
                    ex_MemtoReg <= 0;
                    ex_immediate <= 0;
                    ex_writeReg <= 0;
                    ex_branch_offset <= 0;
                    ex_reg1 <= 0;
                    ex_reg2 <= 0;
                end
            else
                begin
                    ex_PC <= id_PC;
                    ex_ALUCtrl <= id_ALUCtrl;
                    ex_ALUSrc <= id_ALUSrc;
                    ex_MemWrite <= id_MemWrite;
                    ex_MemRead <= id_MemRead;
                    ex_Branch <= id_Branch;
                    ex_RegWrite <= id_RegWrite;
                    ex_MemtoReg <= id_MemtoReg;
                    ex_immediate <= id_immediate;
                    ex_writeReg <= id_writeReg;
                    ex_branch_offset <= id_branch_offset;
                    ex_reg1 <= id_reg1;
                    ex_reg2 <= id_reg2;
                end
        end
            
            
    logic [31:0] ex_op1, ex_op2;

    // Forwarding unit for ex_op1
    always_comb
        begin
            if (ex_reg1 == 0)
                begin
                    ex_op1 = 0;
                end
            else if ((ex_reg1 == mem_writeReg) && (mem_RegWrite != 0))
                begin
                    ex_op1 = mem_ALU_result;
                end
            else if (ex_reg1 == wb_writeReg)
                begin
                    ex_op1 = wb_writeData;
                end
            else
                begin
                    ex_op1 = ex_readData1;
                end
        end
        
    // Forwarding unit for ex_op2
    always_comb
        begin
            if (ex_ALUSrc)
                begin
                    ex_op2 = ex_immediate;
                end
            else if (ex_reg2 == 0)
                begin
                    ex_op2 = 0;
                end
            else if ((ex_reg2 == mem_writeReg)  && (mem_RegWrite != 0))
                begin
                    ex_op2 = mem_ALU_result;
                end
            else if (ex_reg2 == wb_writeReg)
                begin
                    ex_op2 = wb_writeData;
                end
            else
                begin
                    ex_op2 = ex_readData2;
                end
        end
        

    // ALU instantiation
    alu myALU (.alu_op(ex_ALUCtrl), .op1(ex_op1), .op2(ex_op2), .zero(ex_ALU_zero), .result(ex_ALU_result));
    
    // Determine branch target
    assign ex_PC_plus_Offset = ex_PC + ex_branch_offset;
    
    // sw forwarding
    always_comb
        begin
            if (ex_reg2 == mem_writeReg)
                begin
                    ex_readData2 = mem_ALU_result;
                end
            else if (ex_reg2 == wb_writeReg)
                begin
                    ex_readData2 = wb_writeData;
                end
            else
                begin
                    ex_readData2 = id_readData2;
                end
        end
        
//////////////////////////////////////////////////////////////////////
// MEM: Memory Access
//////////////////////////////////////////////////////////////////////	


    // always_ff block for pipelined MEM signals
    always_ff@(posedge clk)
        begin
            if (rst || branch_mem_taken)
                begin
                    mem_PC <= 0;
                    mem_RegWrite <= 0;
                    mem_MemtoReg <= 0;
                    mem_Branch <= 0;
                    mem_MemRead <= 0;
                    mem_MemWrite <= 0;
                    mem_PC_plus_Offset <= 0;
                    mem_ALU_zero <= 0;
                    mem_ALU_result <= 0;
                    mem_writeReg <= 0;
                    mem_readData2 <= 0;
                end
            else
                begin
                    mem_PC <= ex_PC;
                    mem_RegWrite <= ex_RegWrite;
                    mem_MemtoReg <= ex_MemtoReg;
                    mem_Branch <= ex_Branch;
                    mem_MemRead <= ex_MemRead;
                    mem_MemWrite <= ex_MemWrite;
                    mem_PC_plus_Offset <= ex_PC_plus_Offset;
                    mem_ALU_zero <= ex_ALU_zero;
                    mem_ALU_result <= ex_ALU_result;
                    mem_writeReg <= ex_writeReg;  
                    mem_readData2 <= ex_readData2;     
                end
        end
    
    // mem_PCSrc signal
    assign mem_PCSrc = (mem_Branch && mem_ALU_zero);
    
    
//////////////////////////////////////////////////////////////////////
// WB: Write Back
//////////////////////////////////////////////////////////////////////	

    // always_ff block for pipelined WB signals
    always_ff@(posedge clk)
        begin
            if (rst)
                begin
                    wb_MemtoReg <= 0;
                    wb_RegWrite <= 0;
                    wb_writeReg <= 0;
                    wb_ALU_result <= 0;
                    branch_wb_taken <= 0;
                end
            else
                begin
                    wb_MemtoReg <= mem_MemtoReg;
                    wb_RegWrite <= mem_RegWrite;
                    wb_writeReg <= mem_writeReg;
                    wb_ALU_result <= mem_ALU_result;
                    
                    branch_wb_taken <= branch_mem_taken;
                end
        end
        
    // Determine correct writeback data
    assign wb_writeData = (wb_MemtoReg)?dReadData:wb_ALU_result;
                            
        
                        
                        
endmodule
