`timescale 1ns / 1ps
/***************************************************************************
* 
* Filename: regfile.sv
*
* Author: Nathan Bennion
* Class: ECEn 323, Section 2, Winter Semester 2023
* Date: 31 Jan 2023
*
* Description:  This file provides the instantiation for and read/write 
*               support for our two-ported register file.
*
****************************************************************************/


module regfile(clk, readReg1, readReg2, writeReg, writeData, 
               write, readData1, readData2);
               
    input wire logic clk;
    input wire logic [4:0] readReg1, readReg2, writeReg;
    input wire logic [31:0] writeData;
    input wire logic write;
    
    output logic [31:0] readData1, readData2;

    localparam WIDTH = 8'h20;
    
    // Declare multi-dimensional logic array (32 words, 32 bits each)
    logic [31:0] register[31:0];
    
    // Initialize our register and its words
    integer i;
    initial
        for (i = 0; i < WIDTH; i = i + 1)
            register[i] = 0;
            
            
    // Reads and writes to the desired registers
    always_ff@(posedge clk) begin
        readData1 <= register[readReg1];
        readData2 <= register[readReg2];
        if (write && (writeReg != 0)) begin
          register[writeReg] <= writeData;
          if (readReg1 == writeReg)
              readData1 <= writeData;
          if (readReg2 == writeReg)
              readData2 <= writeData;
       end
     end
     
endmodule
