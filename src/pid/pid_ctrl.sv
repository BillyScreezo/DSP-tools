/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains PID controller module
 *
 ***********************************************************************************/


module pid_ctrl
#(
	int 								PHASE_WIDTH 	= 10, 	// bit-width input phase
	int 								PID_OWIDTH 		= 9, 	// PID_OWIDTH <= 2 * (PHASE_WIDTH + 1) - 1

	bit signed [PHASE_WIDTH-1:0] 		INT_MAX 		= '0,
	bit signed [PHASE_WIDTH-1:0] 		K_PROD 			= '0,
	bit signed [PHASE_WIDTH-1:0] 		K_INT			= '0,
	bit signed [PHASE_WIDTH-1:0]		K_DIFF			= '0
)(
	input 	logic									clk,
	input 	logic									rst_n,
	
	input 	logic			[PHASE_WIDTH-1:0] 		phase_i, 	// [0 : 0.5) - all is fract

	output	logic	signed	[PID_OWIDTH-1:0]		pid_o 		// (-1 : 1) - 1 bit : sign, other : fractional part
);

// ==============================================
// ===================== DEFINES
// ==============================================
// pid error

	localparam bit 	[PHASE_WIDTH - 1 : 0] SET_POINT = (2 ** PHASE_WIDTH)/4 - 1; // set point = 1/4

	logic signed   	[PHASE_WIDTH - 1 : 0] pid_error;	 // 1 - sign, oth - fract
	logic signed   	[PHASE_WIDTH - 0 : 0] pid_error_pre; // 1 - sign, oth - fract 

// prod cell
	logic signed 	[PHASE_WIDTH - 1 : 0] err_prod; // err_prod = pid_error

// int cell
	localparam bit signed [PHASE_WIDTH - 1 : 0] ERR_MAX 	= INT_MAX;
	localparam bit signed [PHASE_WIDTH - 1 : 0] ERR_MIN 	= -ERR_MAX;

	logic signed 	[PHASE_WIDTH - 1 : 0] err_int; // (ERR_MIN ; ERR_MAX)
	logic signed 	[PHASE_WIDTH - 0 : 0] err_int_pre_summ;

// diff cell
	logic signed	[PHASE_WIDTH - 1 : 0] err_diff;

//
	logic signed 	[2 * PHASE_WIDTH - 1 : 0] pid_prod; 	// pid_coeff * err_fun (2 - sign, oth - fract)
	logic signed 	[2 * PHASE_WIDTH - 1 : 0] pid_int; 		// pid_coeff * err_fun (2 - sign, oth - fract)
	logic signed 	[2 * PHASE_WIDTH - 1 : 0] pid_diff; 	// pid_coeff * err_fun (2 - sign, oth - fract)

	logic signed 	[2 * PHASE_WIDTH - 1 : 0] pid_prod_d, pid_summ_int_diff, pid_summ_all; // (2 - sign, oth - fract)

// ==============================================
// ===================== PID ERROR
// ==============================================

	assign pid_error_pre = $signed(SET_POINT - phase_i);

// pid_error
	always_ff @(posedge clk)
		pid_error <= pid_error_pre[PHASE_WIDTH:1]; // (-1/4 ; 1/4)

// ==============================================
// ===================== PROD PART
// ==============================================

// prod of error
	generate
		if(K_INT != 0 || K_DIFF != 0) begin

			always_ff @(posedge clk)
				err_prod <= pid_error;

		end else begin

			assign err_prod = pid_error;

		end
	endgenerate

	// calc multiply
	always_ff @(posedge clk) begin
		pid_prod 	<= $signed(err_prod) * $signed(K_PROD);
		pid_prod_d	<= pid_prod;
	end

// ==============================================
// ===================== INT part
// ==============================================

	generate
		if(K_INT != 0) begin
			
			assign err_int_pre_summ = $signed(err_int) + $signed(pid_error);

			always_ff @(posedge clk)
				if(!rst_n)
					err_int		<= '0;
				else
					if($signed(err_int_pre_summ) > $signed(ERR_MAX))
						err_int	<= ERR_MAX;
					else if($signed(err_int_pre_summ) < $signed(ERR_MIN))
						err_int <= ERR_MIN;
					else
						err_int <= err_int_pre_summ[PHASE_WIDTH:1];

			always_ff @(posedge clk)
				pid_int	<= $signed(err_int)  * $signed(K_INT);

		end else begin
			
			assign err_int = '0;
			assign err_int_pre_summ = '0;
			assign pid_int = '0;

		end
	endgenerate

// ==============================================
// ===================== DIFF PART
// ==============================================

	generate
		if(K_DIFF != 0) begin

			// diff of error
			always_ff @(posedge clk)
				err_diff <= pid_error - err_prod;

			always_ff @(posedge clk)
				pid_diff <= $signed(err_diff) * $signed(K_DIFF);

		end else begin

			assign err_diff = '0;
			assign pid_diff = '0;

		end
	endgenerate

// ==============================================
// ===================== CALC OUTPUT SUMM
// ==============================================

	generate
		if(K_INT != 0 && K_DIFF != 0) begin

			always_ff @(posedge clk) begin
				pid_summ_int_diff 	<= $signed(pid_int) + $signed(pid_diff);				// first edge clk - sum(int, diff)
				pid_summ_all		<= $signed(pid_summ_int_diff) + $signed(pid_prod_d);	// second edge clk - sum(int+diff, prod)
			end

		end else if (K_INT == 0) begin

			always_ff @(posedge clk)
				pid_summ_all <= $signed(pid_diff) + $signed(pid_prod);	// second edge clk - sum(int+diff, prod)

			assign pid_summ_int_diff = '0;

		end else if (K_DIFF == 0) begin

			always_ff @(posedge clk)
				pid_summ_all <= $signed(pid_int) + $signed(pid_prod);	// second edge clk - sum(int+diff, prod)

			assign pid_summ_int_diff = '0;

		end else begin
			
			assign pid_summ_int_diff = '0;
			assign pid_summ_all = pid_prod;

		end
	endgenerate

	assign pid_o = {pid_summ_all[2*PHASE_WIDTH-1], pid_summ_all[2*PHASE_WIDTH-3:2*PHASE_WIDTH-PID_OWIDTH-1]}; // reduce 1 sign bit

 
endmodule