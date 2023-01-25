`timescale 1 ns / 1 ps 
`include "riscv_alu_constants.sv"
/***************************************************************************
* 
* File: calc.sv
*
* Author: Nathan Bennion
* Class: ECEN 323, Winter Semester 2023
* Date: 24 Jan 2023
*
* Module: calc
*
* Description: Top level module for implementing and utilizing
*    the ALU module.
*	
****************************************************************************/


module calc(clk, btnc, btnl, btnu, btnr, btnd, sw, led);

    input wire logic clk, btnc, btnu, btnd, btnl, btnr;
	input wire logic [15:0] sw;
	output logic [15:0] led;
	
	//Internal signals 
	logic [31:0] accumulator_ext, result, sw_ext;
	logic [15:0] accumulator;
	logic [2:0] alu_buttons;
	logic [3:0] alu_op;
	// Output from the one shot module
	logic btnd_alu;
	// Reset signal
	logic rst, zero;
	// Synchonized bntd
	logic btnd_d, inc1;
	
	assign led = accumulator;
	assign rst = btnu;
	assign alu_buttons = {btnl, btnc, btnr};
	assign accumulator_ext = {{16 {accumulator[15]}}, accumulator};
	assign sw_ext = {{16 {sw[15]}}, sw};
	
	// Synchronize buttons to the clock
    always_ff@(posedge clk) begin
        if (rst) begin
            btnd_d <= 0;
            inc1 <= 0;
        end
        else begin
            btnd_d <= btnd;
            inc1 <= btnd_d;
        end  
    end
    
    // OneShot instance
    OneShot os0 (.clk(clk), .rst(rst), .in(inc1), .os(btnd_alu));
    
    // Sets accumulator to 0 if btnu is pressed.
    // Otherwise, if btnd is pressed sets accumulator to the last
    // 16 bits of the result
    always_ff@(posedge clk)
	   	if(btnu)
	   	   accumulator <= 0;
	   	else if(btnd_alu)
	   	   accumulator <= result[15:0];
	   	   
    // Choose the right ALU input based on button input
	always_comb
        case(alu_buttons)
            3'b000: alu_op = 4'b0010;
            3'b001: alu_op = 4'b0110;
            3'b010: alu_op = 4'b0000;
            3'b011: alu_op = 4'b0001;
            3'b100: alu_op = 4'b1101;
            3'b101: alu_op = 4'b0111;
            3'b110: alu_op = 4'b1001;
            3'b111: alu_op = 4'b1010;
        endcase
    
    // ALU module instance
	alu alu0 (.op1(accumulator_ext), .op2(sw_ext), .alu_op(alu_op), .zero(zero), .result(result));


endmodule
