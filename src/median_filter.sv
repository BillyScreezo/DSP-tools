/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains median filter module
 *
 ***********************************************************************************/
 
module median_filter 
    #(
        int                                 FILTER_SIZE = 8,
        int                                 COMP_NUMBER = 4
    )(
       input    logic                       clk,
       
       input    logic                       bit_in,
       output   logic                       bit_out 
    );

// ============================================================================
// =============================== DEFINES  ===================================
// ============================================================================
    
    localparam int SUMM_WIDTH = $clog2(FILTER_SIZE + 1);

    logic [FILTER_SIZE-1:0] filter_sh_rg;

    logic [FILTER_SIZE-1:1] [SUMM_WIDTH-1:0] summ_step;

    logic [SUMM_WIDTH-1:0] summ_of_bits;
    
// ============================================================================
// ================================ SH_RG  ====================================
// ============================================================================
    
    always_ff @(posedge clk)
        filter_sh_rg <= {bit_in, filter_sh_rg[FILTER_SIZE-1:1]};  

// ============================================================================
// ========================== SH_RG_BITS_ADDER  ===============================
// ============================================================================
    
    generate

        genvar i;

        for(i = 1; i < FILTER_SIZE; i++) begin

            if(i == 1)
                assign summ_step[i] = (filter_sh_rg[1] + filter_sh_rg[0]);
            else
                assign summ_step[i] = (summ_step[i-1] + filter_sh_rg[i]);

        end   

    endgenerate
    
    assign summ_of_bits = summ_step[FILTER_SIZE - 1];
    
    assign bit_out = (summ_of_bits >= COMP_NUMBER);
      
endmodule
