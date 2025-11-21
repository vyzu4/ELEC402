typedef enum logic [2:0] {
    IDLE  = 3'b000,
    WRITE = 3'b001,
    FULL =  3'b010,
    READ = 3'b011,
    DELAY = 3'b100
} state_t;

module multiplier #(    
    parameter LOGDEPTH = 6,
    parameter WIDTH = 32
) (
    input  logic                    clk, //
    input  logic                    rst,      

    input  logic                    EN_mult, // high to start multiplication
    output logic                    EN_writeMem, // high to write to mem   
    output logic [LOGDEPTH-1:0]     writeMem_addr, // addr to write to

    input  logic [16-1:0]           mult_input0,
    input  logic [16-1:0]           mult_input1,
    output reg [WIDTH-1:0]        writeMem_val,  

    output logic                    RDY_mult, // ready to multiply             
     
    input  logic                    EN_blockRead, // high to read from mem block           
    output logic                    VALID_memVal, // high for valid mem val           
    output logic [WIDTH-1:0]        memVal_data, // mem data            

    output logic                    EN_readMem, // high to start reading mem             
    output logic [LOGDEPTH-1:0]     readMem_addr, // addr to read from           
    input  logic [WIDTH-1:0]        readMem_val // data read from mem               
);

    // Stage 1: Perform 4 smaller 16x16 multiplications
    // logic signed [15:0] p00, p01, p10, p11;

    // state stuff
    state_t state, next_state;

    // flags
    logic first_write = 1'b0; 
    logic first_read = 1'b0; 
    logic first_VALID_memVal = 1'b0; 

    logic [3:0] delay = 4'b0; 

    reg [WIDTH-1: 0] product;

    // =========================================================================
    // Stage M0: register inputs (so later stages see aligned values)
    // =========================================================================
    logic [15:0] a_s0, b_s0;
    logic [15:0] a_s1, b_s1;  // forwarded to second multiplier stage

    always_ff @(posedge clk) begin
        a_s0 <= mult_input0;
        b_s0 <= mult_input1;
    end

    // =========================================================================
    // Stage M1: first half of partial products (rows 0 and 1)
    // =========================================================================
    logic [7:0] p00_s1, p01_s1, p02_s1, p03_s1;
    logic [7:0] p10_s1, p11_s1, p12_s1, p13_s1;

    always_ff @(posedge clk) begin
        // keep inputs aligned for next stage
        a_s1 <= a_s0;
        b_s1 <= b_s0;

        // a0 = a_s0[3:0],  a1 = a_s0[7:4]
        // b0 = b_s0[3:0],  b1 = b_s0[7:4], etc.

        // row 0 (a0 * b?)
        p00_s1 <= a_s0[ 3: 0] * b_s0[ 3: 0]; // a0*b0
        p01_s1 <= a_s0[ 3: 0] * b_s0[ 7: 4]; // a0*b1
        p02_s1 <= a_s0[ 3: 0] * b_s0[11: 8]; // a0*b2
        p03_s1 <= a_s0[ 3: 0] * b_s0[15:12]; // a0*b3

        // row 1 (a1 * b?)
        p10_s1 <= a_s0[ 7: 4] * b_s0[ 3: 0]; // a1*b0
        p11_s1 <= a_s0[ 7: 4] * b_s0[ 7: 4]; // a1*b1
        p12_s1 <= a_s0[ 7: 4] * b_s0[11: 8]; // a1*b2
        p13_s1 <= a_s0[ 7: 4] * b_s0[15:12]; // a1*b3
    end

    // =========================================================================
    // Stage M2: second half of partial products (rows 2 and 3),
    //           and align first-half partials into this stage
    // =========================================================================
    logic [7:0] p00, p01, p02, p03;
    logic [7:0] p10, p11, p12, p13;
    logic [7:0] p20, p21, p22, p23;
    logic [7:0] p30, p31, p32, p33;

    always_ff @(posedge clk) begin
        // forward first-half partials so all 16 are aligned in this stage
        p00 <= p00_s1;
        p01 <= p01_s1;
        p02 <= p02_s1;
        p03 <= p03_s1;

        p10 <= p10_s1;
        p11 <= p11_s1;
        p12 <= p12_s1;
        p13 <= p13_s1;

        // a2 = a_s1[11:8], a3 = a_s1[15:12]
        // b0..b3 from b_s1

        // row 2 (a2 * b?)
        p20 <= a_s1[11: 8] * b_s1[ 3: 0]; // a2*b0
        p21 <= a_s1[11: 8] * b_s1[ 7: 4]; // a2*b1
        p22 <= a_s1[11: 8] * b_s1[11: 8]; // a2*b2
        p23 <= a_s1[11: 8] * b_s1[15:12]; // a2*b3

        // row 3 (a3 * b?)
        p30 <= a_s1[15:12] * b_s1[ 3: 0]; // a3*b0
        p31 <= a_s1[15:12] * b_s1[ 7: 4]; // a3*b1
        p32 <= a_s1[15:12] * b_s1[11: 8]; // a3*b2
        p33 <= a_s1[15:12] * b_s1[15:12]; // a3*b3
    end

    // =========================================================================
    // Combinational: shift partial products + explicit adder tree (no loops)
    // =========================================================================

    // Shifted partial products (32-bit)
    logic [31:0] spp0,  spp1,  spp2,  spp3;
    logic [31:0] spp4,  spp5,  spp6,  spp7;
    logic [31:0] spp8,  spp9,  spp10, spp11;
    logic [31:0] spp12, spp13, spp14, spp15;

    // Tree levels
    logic [31:0] lvl1_0, lvl1_1, lvl1_2, lvl1_3;
    logic [31:0] lvl1_4, lvl1_5, lvl1_6, lvl1_7;

    logic [31:0] lvl2_0, lvl2_1, lvl2_2, lvl2_3;
    logic [31:0] lvl3_0, lvl3_1;
    logic [31:0] sum_comb;

    always_ff @(posedge clk) begin
        // shift amount = 4 * (i + j) for p_ij

        // row 0
        spp0  <= p00 << 0;   // a0*b0 * 2^0
        spp1  <= p01 << 4;   // a0*b1 * 2^4
        spp2  <= p02 << 8;   // a0*b2 * 2^8
        spp3  <= p03 << 12;  // a0*b3 * 2^12

        // row 1
        spp4  <= p10 << 4;   // a1*b0 * 2^4
        spp5  <= p11 << 8;   // a1*b1 * 2^8
        spp6  <= p12 << 12;  // a1*b2 * 2^12
        spp7  <= p13 << 16;  // a1*b3 * 2^16

        // row 2
        spp8  <= p20 << 8;   // a2*b0 * 2^8
        spp9  <= p21 << 12;  // a2*b1 * 2^12
        spp10 <= p22 << 16;  // a2*b2 * 2^16
        spp11 <= p23 << 20;  // a2*b3 * 2^20

        // row 3
        spp12 <= p30 << 12;  // a3*b0 * 2^12
        spp13 <= p31 << 16;  // a3*b1 * 2^16
        spp14 <= p32 << 20;  // a3*b2 * 2^20
        spp15 <= p33 << 24;  // a3*b3 * 2^24

        // // -------- explicit binary adder tree, no loops ----------

        // // Level 1: 16 -> 8
        // lvl1_0 = spp0  + spp1;
        // lvl1_1 = spp2  + spp3;
        // lvl1_2 = spp4  + spp5;
        // lvl1_3 = spp6  + spp7;
        // lvl1_4 = spp8  + spp9;
        // lvl1_5 = spp10 + spp11;
        // lvl1_6 = spp12 + spp13;
        // lvl1_7 = spp14 + spp15;

        // // Level 2: 8 -> 4
        // lvl2_0 = lvl1_0 + lvl1_1;
        // lvl2_1 = lvl1_2 + lvl1_3;
        // lvl2_2 = lvl1_4 + lvl1_5;
        // lvl2_3 = lvl1_6 + lvl1_7;

        // // Level 3: 4 -> 2
        // lvl3_0 = lvl2_0 + lvl2_1;
        // lvl3_1 = lvl2_2 + lvl2_3;

        // // Level 4: 2 -> 1
        // sum_comb = lvl3_0 + lvl3_1;
    end
    always_ff @(posedge clk) begin
        // shift amount = 4 * (i + j) for p_ij

        // // row 0
        // spp0  = p00 << 0;   // a0*b0 * 2^0
        // spp1  = p01 << 4;   // a0*b1 * 2^4
        // spp2  = p02 << 8;   // a0*b2 * 2^8
        // spp3  = p03 << 12;  // a0*b3 * 2^12

        // // row 1
        // spp4  = p10 << 4;   // a1*b0 * 2^4
        // spp5  = p11 << 8;   // a1*b1 * 2^8
        // spp6  = p12 << 12;  // a1*b2 * 2^12
        // spp7  = p13 << 16;  // a1*b3 * 2^16

        // // row 2
        // spp8  = p20 << 8;   // a2*b0 * 2^8
        // spp9  = p21 << 12;  // a2*b1 * 2^12
        // spp10 = p22 << 16;  // a2*b2 * 2^16
        // spp11 = p23 << 20;  // a2*b3 * 2^20

        // // row 3
        // spp12 = p30 << 12;  // a3*b0 * 2^12
        // spp13 = p31 << 16;  // a3*b1 * 2^16
        // spp14 = p32 << 20;  // a3*b2 * 2^20
        // spp15 = p33 << 24;  // a3*b3 * 2^24

        // -------- explicit binary adder tree, no loops ----------

        // Level 1: 16 -> 8
        lvl1_0 <= spp0  + spp1;
        lvl1_1 <= spp2  + spp3;
        lvl1_2 <= spp4  + spp5;
        lvl1_3 <= spp6  + spp7;
        lvl1_4 <= spp8  + spp9;
        lvl1_5 <= spp10 + spp11;
        lvl1_6 <= spp12 + spp13;
        lvl1_7 <= spp14 + spp15;

        // Level 2: 8 -> 4
        lvl2_0 <= lvl1_0 + lvl1_1;
        lvl2_1 <= lvl1_2 + lvl1_3;
        lvl2_2 <= lvl1_4 + lvl1_5;
        lvl2_3 <= lvl1_6 + lvl1_7;

        // Level 3: 4 -> 2
        lvl3_0 <= lvl2_0 + lvl2_1;
        lvl3_1 <= lvl2_2 + lvl2_3;

        // Level 4: 2 -> 1
        sum_comb <= lvl3_0 + lvl3_1;
    end

    // =========================================================================
    // Output register
    // =========================================================================
    always_ff @(posedge clk) begin
        product <= sum_comb;
    end
    
    // multiplication logic
    always_ff @(posedge clk) begin
        writeMem_val <= product;
    end

    always_comb begin
        // product = mult_input0 * mult_input1;
        memVal_data = readMem_val;   
    end

    // state transition/behaviour logic
    always_ff @(posedge clk) begin
        // next_state = state; // default hold

        if (rst) begin
            state = IDLE;
            next_state = IDLE;
            // // initialize all i/o
            // EN_writeMem = 1'b0;
            // writeMem_addr = 6'b0;
            // writeMem_val = 16'b0;
            // RDY_mult = 1'b0;
            // VALID_memVal = 1'b0;
            // EN_readMem = 1'b0;
            // readMem_addr = 6'b0;
        end
        else
            // transition to next state
            state = next_state;

        // state = next_state;
        
        unique case (state)

            IDLE: begin
                first_write = 1'b0; //set flag
                
                // initialize write signals
                RDY_mult = 1'b1;
                EN_readMem = 1'b0;
                writeMem_addr = 1'b0;
                EN_writeMem = 1'b0;

                delay = 4'b0;

                // // initialize write signals
                // readMem_addr = 1'b0;
                VALID_memVal = 1'b0; 

                // determine next state
                if (EN_mult == 1'b1) begin
                    // EN_writeMem = 1'b1;
                    // state = WRITE;
                    next_state = WRITE;
                    // next_state = DELAY;
                end
                else begin
                    next_state = IDLE;
                end
            end

            // DELAY: begin
            //     if (delay > 4)
            //         next_state = WRITE;
            //     else
            //         next_state = DELAY;
                    
            //     delay = delay + 1;
            // end

            WRITE: begin
                // initialize write signals
                EN_writeMem = 1'b1;

                // initialize write signals
                readMem_addr = 1'b0;
                VALID_memVal = 1'b0; 

                // determine value of RDY_mult
                if (writeMem_addr < 6'd61)
                    RDY_mult = 1'b1;
                else
                    RDY_mult = 1'b0;

                // // determine EN_writeMem and next state
                // if (EN_mult == 1'b0) begin
                //     EN_writeMem = 1'b0;
                //     next_state = IDLE;
                // end
                // else begin
                //     EN_writeMem = 1'b1;

                //     if (writeMem_addr < 6'd62)
                //         next_state = WRITE;
                //     else
                //         next_state = FULL;
                // end

                if (writeMem_addr <= 6'd62) begin
                    next_state = WRITE;

                    // determine value of writeMem_addr
                    writeMem_addr = !first_write ?  6'b0 : writeMem_addr + 1;
                    first_write = 1'b1;
                end
                else begin
                    next_state = FULL;
                    EN_writeMem = 1'b0;
                    writeMem_addr = 6'b0;
                end


                // // determine value of writeMem_addr
                // writeMem_addr = !first_write ?  1'b0 : writeMem_addr + 1;
                // first_write = 1'b1;

                // writeMem_addr = writeMem_addr + 1;
            end

            FULL: begin
                // initialize write signals
                RDY_mult = 1'b0;

                // initialize read signals
                EN_writeMem = 1'b0;
                writeMem_addr = 6'b0;
                EN_readMem = 1'b0;
                readMem_addr = 1'b0;

                // set flag
                first_read = 1'b0; 

                // // determine next state
                // if (EN_mult == 1'b1) begin
                //     next_state = FULL;
                // end 
                // else begin
                //     if (EN_blockRead == 1'b1) begin
                //         state = READ;
                //         next_state = READ;
                //         EN_readMem = 1'b1;
                //         readMem_addr = 6'b0;
                //     end
                //     else 
                //         next_state = FULL;
                // end

                if (EN_blockRead == 1'b1) begin
                    // state = READ;
                    next_state = READ;
                    EN_readMem = 1'b1;
                    readMem_addr = 6'b0;
                end
                else 
                    next_state = FULL;

            end

            READ: begin
                // // set flag
                // first_VALID_memVal = 1'b0;

                // VALID_memVal = 1'b1;
                // memVal_data <= readMem_val;                
                
                // determine next state
                if (readMem_addr < 6'd63) begin
                    next_state = READ;
                    EN_readMem = 1'b1;
                    readMem_addr = readMem_addr + 1;
                    // readMem_addr = !first_read ?  6'b0 : readMem_addr + 1;
                    // VALID_memVal = !first_read ?  1'b0 : 1'b1;
                    VALID_memVal = 1'b1;
                    first_read = 1'b1;
                end
                else begin
                    next_state = IDLE;
                    RDY_mult = 1'b1;
                    EN_readMem = 1'b0;
                end

                // // determine value for VALID_memVal
                // if (EN_readMem == 1'b0)
                //     VALID_memVal = 1'b0;
                // else
                //     VALID_memVal = 1'b1;

                // determine value of writeMem_addr

                // readMem_addr = !first_read ?  1'b0 : readMem_addr + 1;
                // first_read = 1'b1;

            end

            default: next_state = IDLE;
        endcase
    end

endmodule
