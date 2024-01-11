/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains calculation y/x
 *
 ***********************************************************************************/

module cordic_div

#(
	int 	DWIDTH 	  = 16, // accurancy of input values
	int 	ACCURANCY = 8 	// accurancy of output values
)(
	input 	logic 									clk,
	input 	logic									rst_n,

	input 	logic	signed 	[DWIDTH - 1 : 0]		x_i,	// Divider
	input 	logic 	signed	[DWIDTH - 1 : 0]		y_i,	// Dividend
	
	output 	logic 	signed 	[ACCURANCY - 1 : 0]		res,	// Result y/x

	input	logic									req,	// Divide request
	output 	logic									rdy		// Result ready flag
);

// ==============================================
// ===================== DEFINES
// ==============================================
	logic signed [DWIDTH - 1 : 0] x;
	logic signed [DWIDTH - 1 : 0] y;
	logic signed [DWIDTH - 1 : 0] z;

	logic signed [DWIDTH - 1 : 0] x_sh;
	logic signed [DWIDTH - 1 : 0] z_sh;
	
	logic alpha, sign_x, sign_y;

	logic f;

	logic [$clog2(ACCURANCY):0] cnt;

// ==============================================
// ===================== Calc y/x
// ==============================================
	assign sign_x = x_i[DWIDTH - 1];
	assign sign_y = y_i[DWIDTH - 1];

	assign alpha = y[DWIDTH - 1];
	assign x_sh  = x 							>>> (cnt);
	assign z_sh  = {1'b1, {(DWIDTH-1){1'b0}}} 	>>  (cnt);

	always_ff @(posedge clk)
		if(req && !f) begin
			x <= sign_x ? -x_i : x_i;
			y <= sign_y ? -y_i : y_i;
			z <= '0;
		end else if (f) begin
			x <= x;
			y <= alpha ? y + x_sh : y - x_sh;
			z <= alpha ? z - z_sh : z + z_sh;
		end

// ==============================================
// ===================== Cnt logic
// ==============================================

	always_ff @(posedge clk)
		if(!rst_n)
			cnt <= '0;
		else
			if(rdy)
				cnt <= '0;
			else if (f)
				cnt <= cnt + 1'b1;

	always_ff @(posedge clk)
		if(!rst_n)
			rdy <= '0;
		else
			if(rdy)
				rdy <= '0;
			else if(cnt == ACCURANCY - 1)
				rdy <= '1;

// ==============================================
// ===================== Result
// ==============================================
	
	always_ff @(posedge clk)
		f <= req & ~rdy;

	assign res = z[DWIDTH-1:DWIDTH-ACCURANCY];

endmodule