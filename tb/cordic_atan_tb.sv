/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains cordic tb module
 *
 ***********************************************************************************/

`timescale 1ns / 1ps

module cordic_atan_tb ();

	localparam int RST_DELAY  	= 15;
	localparam real SYS_CLK 	= 125; 				// Mhz
	localparam real CLK_PERIOD 	= 1000 / (SYS_CLK); // ns

	bit clk, rst_n;

	localparam int INPUT_ACC = 10;

	logic signed [INPUT_ACC - 1 : 0] re_i, im_i; // (-1;1)

	cordic_wp #(
		.INPUT_ACC(INPUT_ACC),
		.OUTPUT_ACC(10)
	) DUT (
		.clk(clk),
		.rst_n(rst_n),

		.re_i(re_i), // (-1;1)
		.im_i(im_i), // (-1;1)


		.atan_norm_o() // (-pi; pi) - 1 sign, 2 - int, oth - fract
	);

	integer data_file, fscanf_ret;

	initial begin
		data_file = $fopen("cordic\\export_test_vect.csv", "r");
		if (data_file == 0) begin
			$display("Signal file not found\n");
			$finish;
		end
		
		repeat(RST_DELAY-1) @(posedge clk);
		while (!$feof(data_file)) begin
			@(posedge clk)
				fscanf_ret = $fscanf(data_file, "%d;%d\n", re_i, im_i);
		end
	
		$fclose(data_file);
		
		$finish;
	end
	
	initial begin
		clk = 0;

		forever begin
			#(CLK_PERIOD);
			clk = ~clk;
		end
	end

	initial begin
		rst_n = '0;

		repeat(RST_DELAY) @(posedge clk);
		#2;
		rst_n = '1;
		
	end

endmodule
