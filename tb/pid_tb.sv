/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains PID tb module
 *
 ***********************************************************************************/

`timescale 1ns / 1ps

module pid_tb ();

	localparam int RST_DELAY  	= 15;
	localparam real SYS_CLK 	= 125; 				// Mhz
	localparam real CLK_PERIOD 	= 1000 / (SYS_CLK); // ns

	localparam int PHASE_WIDTH 		= 10;
	localparam int PID_OUT_WIDTH 	= 10;

	bit clk, rst_n;
	bit [PHASE_WIDTH-1:0] phase;

	pid_ctrl #(
		.PHASE_WIDTH(PHASE_WIDTH),
		.PID_OUT_WIDTH(PID_OUT_WIDTH),	// bit-width output pid value

		.K_PROD(10), 
		.K_INT(1),
		.K_DIFF(121),
		.INT_MAX(1)
	) dut (
		.clk(clk),
		.rst_n(rst_n),
		
		.phase_i(phase),

		.pid_o()
	);
	

	
	initial begin
		clk = 0;

		forever begin
			#(CLK_PERIOD);
			clk = ~clk;
		end
	end

	initial begin
		rst_n = '0;
		phase = 0;//(2 ** PHASE_WIDTH)/2 - 1;


		repeat(RST_DELAY) @(posedge clk);
		#2;
		rst_n = '1;


		#100;

		// phase = (2 ** PHASE_WIDTH) - 1;

		repeat(2 ** PHASE_WIDTH-1) begin
			@(posedge clk);
			phase = $urandom_range(0,2**PHASE_WIDTH-1);
		end

		$finish;
	end

endmodule
