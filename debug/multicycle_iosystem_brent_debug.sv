///////////////////////////////////////////////////////////////////////////////////////////////
// 
// Filename: multicycle_io_system.sv
//
// Author: Mike Wirthlin
// Date: 2/4/2022
//
// Top-level I/O system for multicycle RISC-V processor. 
//
///////////////////////////////////////////////////////////////////////////////////////////////
`default_nettype none
module multicycle_iosystem (clk, btnc, btnd, btnl, btnr, btnu, sw, led,
    an, seg, dp, RsRx, RsTx, vgaBlue, vgaGreen, vgaRed, Hsync, Vsync);

	// Top-level ports
	input logic clk;
	input logic btnc;
	input logic btnd;
	input logic btnl;
	input logic btnr;
	input logic btnu;
	input [15:0]sw;
	output [15:0]led;
	output [3:0]an;
	output [6:0]seg;
    output logic dp;
	output logic RsRx;
	input logic RsTx;
	output [3:0]vgaRed;
	output [3:0]vgaBlue;
	output [3:0]vgaGreen;
	output logic Hsync;
	output logic Vsync;

    // Top-level Parameters
    parameter TEXT_MEMORY_FILENAME = "multicycle_iosystem_text.mem";        // Instruction binary file
    parameter DATA_MEMORY_FILENAME = "";        // Data segment binary file
    parameter USE_DEBOUNCER = 1;
    parameter TIMER_CLOCK_REDUCTION = 1;

    // Local constants
	localparam INPUT_CLOCK_RATE = 100_000_000;
    localparam PROC_CLK_DIVIDE = 3;
    localparam VGA_CLK_DIVIDE = 2;
    localparam INSTRUCTION_BRAMS = 2;
    localparam DATA_BRAMS = 2;
	localparam TEXT_START_ADDRESS = 32'h00000000;
	localparam DATA_START_ADDRESS = 32'h00002000;
	localparam IO_START_ADDRESS = 32'h00007f00;
	localparam VGA_START_ADDRESS = 32'h00008000;
    localparam PROC_CLOCK_RATE = INPUT_CLOCK_RATE / PROC_CLK_DIVIDE;
    localparam DEBOUNCE_DELAY_US = 1;

    
    // Module Signals
    logic clk_proc, clk_vga, rst;
    logic [31:0] PC, instruction, dAddress, dReadData, dWriteData, WriteBackData;
    logic dMemRead, dMemWrite, io_valid_data;
    logic [31:0] io_read_data;

    // Debug stuff
    logic [31:0] ioled, dbgled, pre_instruction, last_instruction;
    logic run_clk, mmcm_rst, sw13_dla;

    always_comb
      unique case (sw[3:0])
          0: dbgled = PC[15:0];
          1: dbgled = PC[31:16];
          2: dbgled = instruction[15:0];
          3: dbgled = instruction[31:16];
          4: dbgled = pre_instruction[15:0];
          5: dbgled = pre_instruction[31:16];
          6: dbgled = last_instruction[15:0];
          7: dbgled = last_instruction[31:16];
          8: dbgled = {15'd0, rst};
          default:  dbgled = 16'hBEEF;
      endcase

    assign led = sw[15]?dbgled:ioled;
    BUFGMUX bufg(.I1(btnc), .I0(run_clk), .S(sw[14]), .O(clk_proc));
    //assign clk_proc = run_clk;

    always_ff @(posedge clk_proc) begin
        if (sw[13])
            rst <= 1;
        else
            rst <= mmcm_rst;
    end


    // Clocking Module: generates clocks and reset
    io_clocks #(.INPUT_CLOCK_RATE(INPUT_CLOCK_RATE), .PROC_CLK_DIVIDE(PROC_CLK_DIVIDE), 
        .VGA_CLK_DIVIDE(VGA_CLK_DIVIDE))
        clocks (.clk_in(clk), .reset_out(mmcm_rst), .clk_proc(run_clk), .clk_vga(clk_vga));

    // Processor (Created in Lab 6)
    logic [31:0] mem_io_read_data; // output of mux between i/o data and dmem data
     // mux between dReadDAta and i/o
    assign mem_io_read_data = io_valid_data ? io_read_data : dReadData;
    riscv_multicycle #(.INITIAL_PC(TEXT_START_ADDRESS)) 
        riscv (.clk(clk_proc), .rst(rst), .PC(PC), .instruction(instruction), 
        .dAddress(dAddress), .dReadData(mem_io_read_data), .dWriteData(dWriteData), 
        .MemRead(dMemRead), .MemWrite(dMemWrite), .WriteBackData(WriteBackData)
	);

    // Memories (instruction and data)
    logic iMemRead = 1;  // Always read instruction memory
    riscv_mem #(.INSTRUCTION_BRAMS(INSTRUCTION_BRAMS),.DATA_BRAMS(DATA_BRAMS),
        .TEXT_MEMORY_FILENAME(TEXT_MEMORY_FILENAME),.DATA_MEMORY_FILENAME(DATA_MEMORY_FILENAME),
        .TEXT_START_ADDRESS(TEXT_START_ADDRESS),.DATA_START_ADDRESS(DATA_START_ADDRESS))
        mem (.clk(clk_proc), .rst(rst), .PC(PC), .iMemRead(iMemRead), .instruction(instruction),
        .dAddress(dAddress), .MemWrite(dMemWrite), .dWriteData(dWriteData), .dReadData(dReadData), .pre_instruction(pre_instruction), .last_instruction(last_instruction));

    // I/O Sub-system
    iosystem #(.INPUT_CLOCK_RATE(PROC_CLOCK_RATE),.VGA_START_ADDRESS(VGA_START_ADDRESS),
        .IO_START_ADDRESS(IO_START_ADDRESS),.USE_DEBOUNCER(USE_DEBOUNCER),.DEBOUNCE_DELAY_US(DEBOUNCE_DELAY_US),
        .TIMER_CLOCK_REDUCTION(TIMER_CLOCK_REDUCTION))
        iosystem (
        // Clock and reset ports
        .clk(clk_proc), .clkvga(clk_vga), .rst(rst), .pc(PC),
        // Processor bus interface
        .address(dAddress), .MemWrite(dMemWrite), .MemRead(dMemRead),
        .io_memory_read(io_read_data), .io_memory_write(dWriteData), .valid_io_read(io_valid_data),
        // Top-level ports
        .btnc(btnc), .btnd(btnd), .btnl(btnl), .btnr(btnr), .btnu(btnu), .sw(sw), 
        .led(ioled), .an(an), .seg(seg), .dp(dp), .RsRx(RsRx), .RsTx(RsTx), .vgaBlue(vgaBlue),
        .vgaGreen(vgaGreen), .vgaRed(vgaRed), .Hsync(Hsync), .Vsync(Vsync));

endmodule
