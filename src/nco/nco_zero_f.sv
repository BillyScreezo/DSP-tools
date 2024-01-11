/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains numerically controlled oscillator (NCO) with zero carrier frequency
 *
 ***********************************************************************************/

module nco_zero_f
#(
	int DATA_WIDTH 			= 16, // width sin/cos values
	int PHASE_WIDTH 		= 12, // width phase accum, 12 bit : 1 bram (4kB) block (two 16-bit word in cell) + 2 bit quarter sin/cos
	int DELTA_PHASE_WIDTH 	= 10, // width delta phase error

	string INIT_FNAME = "export_nco_sin.csv"
)(
	input 	logic 											clk,
	input 	logic											rst_n,

	input 	logic	signed	[DELTA_PHASE_WIDTH-1:0] 		delta_phase_i,  // (-1 : 1) - 1 bit : sign, DELTA_PHASE_WIDTH - 1 : fractional part

	output 	logic 	signed 	[DATA_WIDTH-1:0] 				cos_o,
	output 	logic 	signed 	[DATA_WIDTH-1:0] 				sin_o
);

	localparam int TABLE_DIV = 4; // Table in range [0 ; pi/2], 4 times less than [0 ; 2pi]

	localparam bit signed [PHASE_WIDTH - 0 : 0] MAX_PHASE = ((2 ** PHASE_WIDTH)/2) - 1;
	localparam bit signed [PHASE_WIDTH - 0 : 0] MIN_PHASE = ((2 ** PHASE_WIDTH)) + ((2 ** PHASE_WIDTH)/2);

	localparam bit signed [PHASE_WIDTH - 1 : 0] MAX_PHASE_ACC = ((2 ** PHASE_WIDTH)/2) - 1;
	localparam bit signed [PHASE_WIDTH - 1 : 0] MIN_PHASE_ACC = ((2 ** PHASE_WIDTH)/2) - 0;

	typedef enum logic [$clog2(TABLE_DIV) - 1 : 0] {	// sin_cos quarter
		AREA_I 		= 2'h0,
		AREA_II 	= 2'h1,
		AREA_III	= 2'h2,
		AREA_IV 	= 2'h3
	} area_t;

	area_t area_select;

	logic [2 * DATA_WIDTH  - 1 : 0] ram_sin [0 : ((2 ** PHASE_WIDTH) / TABLE_DIV) - 1];

	logic signed [   PHASE_WIDTH - 1 : 0] phase_add;				// accum phase

	logic signed [   PHASE_WIDTH - 1 : 0] phase_accum;				// accum phase
	logic signed [   PHASE_WIDTH - 0 : 0] phase_accum_pre;			// accum phase


	logic [2 * DATA_WIDTH - 1 : 0] sin_value;
	logic [	   DATA_WIDTH - 1 : 0] sin_def, sin_rev; 				// sin default, sin reverse select

	initial $readmemh(INIT_FNAME, ram_sin, 0, ((2 ** PHASE_WIDTH) / TABLE_DIV) - 1);

	assign phase_add = delta_phase_i[DELTA_PHASE_WIDTH-1:DELTA_PHASE_WIDTH-PHASE_WIDTH];
	assign phase_accum_pre = $signed(phase_accum) - $signed(phase_add);

	always_ff @(posedge clk)
		if(~rst_n)
			phase_accum <= '0;
		else
			phase_accum <= {phase_accum_pre[PHASE_WIDTH], phase_accum_pre[PHASE_WIDTH-2:0]};	// drop int bit

	always_ff @(posedge clk)
		area_select <= area_t'(phase_accum[PHASE_WIDTH - 1 : PHASE_WIDTH - $clog2(TABLE_DIV)]);

	always_ff @(posedge clk)
		sin_value <= ram_sin[phase_accum[PHASE_WIDTH - $clog2(TABLE_DIV) - 1 : 0]];

	assign sin_rev = sin_value[DATA_WIDTH - 1 : 0];
	assign sin_def = sin_value[2 * DATA_WIDTH - 1 : DATA_WIDTH];

	// sin table select
	always_ff @(posedge clk)
		unique case(area_select)
			AREA_I: 	sin_o <= -	sin_def;
			AREA_II:	sin_o <= -	sin_rev;
			AREA_III:	sin_o <=  	sin_def;
			AREA_IV:	sin_o <=    sin_rev;
		endcase

	// cos table select
	always_ff @(posedge clk)
		unique case(area_select)
			AREA_I: 	cos_o <= 	sin_rev;
			AREA_II:	cos_o <= -	sin_def;
			AREA_III:	cos_o <= - 	sin_rev;
			AREA_IV:	cos_o <= 	sin_def;
		endcase

endmodule : nco_zero_f
