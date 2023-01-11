`timescale 1 ns / 1 ps 

/***************************************************************************
* 
* File: UpDownButtonCount.sv
*
* Author: Nathan Bennion
* Class: ECEN 323, Winter Semester 2023
* Date: 1/10/2023
*
* Module: UpDownButtonCount
*
* Description:
*    This module includes logic to do specific outputs to the LEDs based on
*    the button inputs. An up press will increment by one, a down press will
*    decrement by 1, a left press will decrement by the binary amount based
*    on the switches, and a right press will increment by the switches.
*
****************************************************************************/

module UpDownButtonCount(clk, btnc, btnu, btnd, btnl, btnr, led, sw);

	input wire logic clk, btnc, btnu, btnd, btnl, btnr;
	input wire logic [15:0] sw;
	output logic [15:0] led;
	
	// The internal 16-bit count signal. 
	logic [15:0] count_i;
	// The increment counter output from the one shot module
	logic inc_count_up, inc_count_down, inc_count_left, inc_count_right;
	// reset signal
	logic rst;
	// increment signals (synchronized version of btnu)
	logic btnu_d, btnu_dd;
	logic btnd_d, btnd_dd;
	logic btnl_d, btnl_dd;
	logic btnr_d, btnr_dd;
	
	// outputted incremented signals (to the OneShot module)
	logic inc_up, inc_down, inc_left, inc_right;

	// Assign the 'rst' signal to button c
	assign rst = btnc;

	// The following always block creates a "synchronizer" for the 'btnu' input.
	// A synchronizer synchronizes the asynchronous 'btnu' input to the global
	// clock.
	// This particular synchronizer is just two flip-flop in series: 'btnu_d'
	// is the first flip-flop of the synchronizer and 'btnu_dd' is the second
	// flip-flop of the synchronizer.
	
	always_ff@(posedge clk)
		if (rst) begin
			btnu_d <= 0;
			btnu_dd <= 0;
		end
		else begin
			btnu_d <= btnu;
			btnu_dd <= btnu_d;
		end
	assign inc_up = btnu_dd;
	
	// Symchronizers for each of the other buttons
	
	// btnd input
	always_ff@(posedge clk)
		if (rst) begin
			btnd_d <= 0;
			btnd_dd <= 0;
		end
		else begin
			btnd_d <= btnd;
			btnd_dd <= btnd_d;
		end
	assign inc_down = btnd_dd;
	
	// btnl input
	always_ff@(posedge clk)
		if (rst) begin
			btnl_d <= 0;
			btnl_dd <= 0;
		end
		else begin
			btnl_d <= btnl;
			btnl_dd <= btnl_d;
		end
	assign inc_left = btnl_dd;
	
	// btnr input
	always_ff@(posedge clk)
		if (rst) begin
			btnr_d <= 0;
			btnr_dd <= 0;
		end
		else begin
			btnr_d <= btnr;
			btnr_dd <= btnr_d;
		end
	assign inc_right = btnr_dd;
	
	

	// Instances of the OneShot module for each of the directional buttons
	OneShot osu (.clk(clk), .rst(rst), .in(inc_up), .os(inc_count_up));
	OneShot osd (.clk(clk), .rst(rst), .in(inc_down), .os(inc_count_down));
	OneShot osl (.clk(clk), .rst(rst), .in(inc_left), .os(inc_count_left));
	OneShot osr (.clk(clk), .rst(rst), .in(inc_right), .os(inc_count_right));	
	

	// 16-bit Counter. Increments or decrements based on the button is pressed. 

	always_ff@(posedge clk)
		if (rst)
			count_i <= 0;
			
        // Logic for incrementing
		else if (inc_count_up)
			count_i <= count_i + 1;
			
        // Logic for decrementing
        else if (inc_count_down)
            count_i <= count_i - 1;
            
        // Logic for decrementing based on the switch
        else if (inc_count_left)
            count_i <= count_i - sw;
            
        // Logic for incrementing based on the switch
        else if (inc_count_right)
            count_i <= count_i + sw;
	
	// Assign the 'led' output the value of the internal count_i signal.
	assign led = count_i;

endmodule