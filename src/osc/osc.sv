/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains table oscillator
 *
 ***********************************************************************************/

module osc
#(
	int DATA_WIDTH 			= 16, 									// Width sin/cos values
	int TABLE_SZ 			= 5,									// Sin/cos table size (script output \osc\osc_gen.py)

	string INIT_FNAME = "export_osc.csv"							// Sin/cos table file (script output \osc\osc_gen.py)
)(
	input 	logic 											clk,	// clk
	input 	logic											rst_n,	// rst_n

	output 	logic 	signed 	[DATA_WIDTH-1:0] 				cos_o,	// Output value cos(2*pi*f_osc*t)
	output 	logic 	signed 	[DATA_WIDTH-1:0] 				sin_o	// Output value sin(2*pi*f_osc*t)
);

	logic [2 * DATA_WIDTH   - 1 : 0] ram [0 : TABLE_SZ - 1];
	logic [2 * DATA_WIDTH   - 1 : 0] value;
	logic [$clog2(TABLE_SZ) - 1 : 0] ph_cnt;

	initial $readmemh(INIT_FNAME, ram, 0, TABLE_SZ - 1);

	always_ff @(posedge clk)
		if(!rst_n)
			ph_cnt <= '0;
		else
			ph_cnt <= (ph_cnt == TABLE_SZ - 1) ? '0 : ph_cnt + 1'b1;

	always_ff @(posedge clk)
		value <= ram[ph_cnt];
			
	assign	cos_o = $signed(value[DATA_WIDTH-1:0]);
	assign	sin_o = $signed(value[2*DATA_WIDTH-1:DATA_WIDTH]);

endmodule
