/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains calculation arctan(im/re) and abs(im+j*im)
 *
 ***********************************************************************************/

module cordic_atan_abs

#(
	int 	ACCURANCY 	= 10, 					// accurancy of input values, artan table, output artan and abs
	int 	STAGES 		= ACCURANCY,
	int     CALC_ABS    = 0,					// do need to calculate the abs(x+iy)
	string 	INIT_FNAME 	= "export_arctan.csv"	// a file containing a table atan(2^-i)
)(
	input 	logic 									clk,
	input 	logic									rst_n,

	input 	logic	signed 	[ACCURANCY - 1 : 0]		re_i, 		// (-1;1)
	input 	logic 	signed	[ACCURANCY - 1 : 0]		im_i, 		// (-1;1)
	
	output 	logic 	signed 	[ACCURANCY - 1 : 0]		atan_o, 	// (-1; 1) `*pi` - 1 sign, oth - fract
	output  logic   signed  [ACCURANCY - 1 : 0]     abs_o 		// sqrt(re_i^2 + im_i^2)
);

	localparam int EXTRA_BITS = ACCURANCY + 2; 					// 2 int bits
	localparam logic signed [EXTRA_BITS - 1 : 0] K_MAX = 'd309;	// if you change ACCURANCY, then change K_MAX (cordic_gen.py)
	localparam int ABS_PROD_SHIFT = 2 + 4; 						// 2 bit - sign, 4 - int

	typedef enum logic [1:0] {	// sin_cos quarter
		AREA_I 		= 2'b00, // re/im
		AREA_II 	= 2'b10,
		AREA_III	= 2'b11,
		AREA_IV 	= 2'b01
	} area_t;

	area_t area_select;

	localparam bit signed [ACCURANCY - 1 : 0] PI_P = (2 ** (ACCURANCY - 1)) - 1; 	// +pi
	localparam bit signed [ACCURANCY - 1 : 0] PI_N = (2 ** (ACCURANCY - 1));		// -pi

	logic [ACCURANCY - 1 : 0] ram_atan [0 : STAGES - 1];

	initial $readmemh(INIT_FNAME, ram_atan, 0, STAGES - 1);

	// pipe
	logic signed [EXTRA_BITS - 1 : 0] x [0 : STAGES - 1];
	logic signed [EXTRA_BITS - 1 : 0] y [0 : STAGES - 1];
	logic signed [ACCURANCY  - 1 : 0] z [0 : STAGES - 1];

	logic signed [EXTRA_BITS - 1 : 0] x_sh [1 : STAGES - 1];
	logic signed [EXTRA_BITS - 1 : 0] y_sh [1 : STAGES - 1];

	logic alpha [1 : STAGES - 1];
	logic [STAGES - 1 : 0] sign_re;
	logic [STAGES - 1 : 0] sign_im;

	logic signed [2 * EXTRA_BITS - 1 : 0] abs_prod_result;

	always_ff @(posedge clk) begin
		if(!rst_n) begin
			x[0] <= '0;
			y[0] <= '0;
		end else begin
			x[0] <= re_i[ACCURANCY - 1] ? -re_i : re_i;
			y[0] <= im_i;
		end
	end

	assign z[0] = '0;

	always_ff @(posedge clk) begin
		if(!rst_n) begin
			sign_re <= '0;
			sign_im <= '0;
		end else begin
			sign_re <= {sign_re[STAGES - 2 : 0], re_i[ACCURANCY - 1]};
			sign_im <= {sign_im[STAGES - 2 : 0], im_i[ACCURANCY - 1]};
		end
	end

	generate
		for (genvar i = 1; i < STAGES; i++) begin

			assign alpha[i] = y[i - 1][EXTRA_BITS - 1];

			assign x_sh[i]  = x[i - 1] >>> (i - 1);
			assign y_sh[i]  = y[i - 1] >>> (i - 1);

			always_ff @(posedge clk)
				x[i] <= alpha[i] ? x[i - 1] - y_sh[i] : x[i - 1] + y_sh[i];

			always_ff @(posedge clk)
				y[i] <= alpha[i] ? y[i - 1] + x_sh[i] : y[i - 1] - x_sh[i];

			always_ff @(posedge clk)
				z[i] <= alpha[i] ? z[i - 1] - ram_atan[i - 1] : z[i - 1] + ram_atan[i - 1];

		end
	endgenerate

	assign area_select = area_t'({sign_re[STAGES - 1], sign_im[STAGES - 1]});

	always_ff @(posedge clk)
		case (area_select)
			AREA_I, AREA_IV: 	atan_o <= z[STAGES - 1][ACCURANCY - 1 : 0];			// arg(z) = arctan(y/x), z E [-pi/2;pi/2]
			AREA_II: 			atan_o <= PI_P - z[STAGES - 1][ACCURANCY - 1 : 0];	// arg(z) = pi - arctan(y/x), z E [pi/2;pi]
			AREA_III: 			atan_o <= PI_N - z[STAGES - 1][ACCURANCY - 1 : 0];	// arg(z) = -pi + arctan(y/x), z E [-pi;-pi/2]
		endcase


	generate
		if(CALC_ABS)
			always_ff @(posedge clk) // kABS * 1/K -> ABS
				abs_prod_result <= x[STAGES - 1] * K_MAX;
		else
			assign abs_prod_result = '0;
	endgenerate
	

	// Drop fractional part
	assign abs_o = abs_prod_result[2 * EXTRA_BITS - ABS_PROD_SHIFT - 1 : 2 * EXTRA_BITS - ACCURANCY - ABS_PROD_SHIFT]; // 2 bit - sign, 4 - int

endmodule