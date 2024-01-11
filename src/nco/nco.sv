/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains numerically controlled oscillator (NCO) with adjustable carrier frequency
 *
 ***********************************************************************************/

module nco 
#(
	int DATA_WIDTH 			= 16, // width sin/cos values
	int PHASE_WIDTH 		= 12, // width phase accum, 12 bit : 1 bram (4kB) block (two 16-bit word in cell) + 2 bit quarter sin/cos
	int DELTA_PHASE_WIDTH 	= 10, // width delta phase error

	real F_OSC 				= 40, 	// nco frequency, MHz
	real SYS_CLK 			= 125, 	// system frequency, MHz

	string INIT_FNAME = "export_nco_sin.csv"
)(
	input 	logic 											clk,
	input 	logic											rst_n,

	input 	logic	signed	[DELTA_PHASE_WIDTH-1:0] 		delta_phase_i,  // (-1 : 1) - 1 bit : sign, DELTA_PHASE_WIDTH - 1 : fractional part

	output 	logic 	signed 	[DATA_WIDTH-1:0] 				cos_o,
	output 	logic 	signed 	[DATA_WIDTH-1:0] 				sin_o
);

	localparam int TABLE_DIV = 4; // Table in range [0 ; pi/2], 4 times less than [0 ; 2pi]

	localparam bit [DELTA_PHASE_WIDTH - 1 : 0] MAX_ABS_DELTA_PHASE = ((2 ** DELTA_PHASE_WIDTH)/2) - 1;							// one DELTA_PHASE_WIDTH width
	localparam bit [DELTA_PHASE_WIDTH - 1 : 0] PHASE_COEFF = int'($ceil((F_OSC / SYS_CLK) * 2 ** (DELTA_PHASE_WIDTH - 1))); 	// phase coeff << DELTA_PHASE_WIDTH - 1

	typedef enum logic [$clog2(TABLE_DIV) - 1 : 0] {// sin_cos quarter
		AREA_I 		= 2'h0,
		AREA_II 	= 2'h1,
		AREA_III	= 2'h2,
		AREA_IV 	= 2'h3
	} area_t;

	area_t area_select;

	logic [2 * DATA_WIDTH  - 1 : 0] ram_sin [0 : ((2 ** PHASE_WIDTH) / TABLE_DIV) - 1];

	logic [    DELTA_PHASE_WIDTH - 1 : 0] one_minus_dphi;	// 1 - delta_phi
	logic [2 * DELTA_PHASE_WIDTH - 1 : 0] phase_mult;		// PHASE_COEFF * (1 - delta_phi)

	logic [PHASE_WIDTH - 1 : 0] phase_acc_summ;				// accum additional 
	logic [PHASE_WIDTH - 1 : 0] phase_accum;				// accum phase

	logic [2 * DATA_WIDTH - 1 : 0] sin_value;
	logic [	   DATA_WIDTH - 1 : 0] sin_def, sin_rev; 		// sin default, sin reverse select

	initial $readmemh(INIT_FNAME, ram_sin, 0, ((2 ** PHASE_WIDTH) / TABLE_DIV) - 1);

	// calculate one_minus_dphi
	always_ff @(posedge clk)
		one_minus_dphi <= $signed(MAX_ABS_DELTA_PHASE) - $signed(delta_phase_i);

	// calculate PHASE_COEFF * (1 - delta_phi)
	always_ff @(posedge clk)
		phase_mult 	<= PHASE_COEFF * one_minus_dphi;

	assign phase_acc_summ = phase_mult[2 * DELTA_PHASE_WIDTH - 3 : 2 * DELTA_PHASE_WIDTH - PHASE_WIDTH - 2]; // ignore 2 int bits


	always_ff @(posedge clk)
		if(~rst_n)
			phase_accum <= '0;
		else
			phase_accum <= phase_accum + phase_acc_summ;

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

endmodule
