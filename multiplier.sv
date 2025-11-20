typedef enum logic [2:0] {
    IDLE  = 3'b000,
    WRITE = 3'b001,
    FULL =  3'b010,
    READ = 3'b011
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
    (* dont_touch = "true" *) output reg [WIDTH-1:0]        writeMem_val,  

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
    (* dont_touch = "true" *) state_t state, next_state;

    // flags
    logic first_write = 1'b0; 
    logic first_read = 1'b0; 
    logic first_VALID_memVal = 1'b0; 

    (* dont_touch = "true" *) reg [WIDTH-1: 0] product;

    logic signed [31:0] intermediate_sum, intermediate_sum_2;









    // Stage 1: Perform 16 smaller 4x4 multiplications (all pipelined)
    logic signed [7:0] p00, p01, p02, p03;
    logic signed [7:0] p10, p11, p12, p13;
    logic signed [7:0] p20, p21, p22, p23;
    logic signed [7:0] p30, p31, p32, p33;

    // logic signed [31:0] intermediate_sum;

    always_ff @(posedge clk) begin
        // a0 = mult_input0[3:0],  a1 = mult_input0[7:4],  a2 = mult_input0[11:8], a3 = mult_input0[15:12]
        // b0 = mult_input1[3:0],  b1 = mult_input1[7:4],  b2 = mult_input1[11:8], b3 = mult_input1[15:12]

        // row 0 (a0 * b?)
        p00 <= mult_input0[ 3: 0] * mult_input1[ 3: 0]; // a0*b0
        p01 <= mult_input0[ 3: 0] * mult_input1[ 7: 4]; // a0*b1
        p02 <= mult_input0[ 3: 0] * mult_input1[11: 8]; // a0*b2
        p03 <= mult_input0[ 3: 0] * mult_input1[15:12]; // a0*b3

        // row 1 (a1 * b?)
        p10 <= mult_input0[ 7: 4] * mult_input1[ 3: 0]; // a1*b0
        p11 <= mult_input0[ 7: 4] * mult_input1[ 7: 4]; // a1*b1
        p12 <= mult_input0[ 7: 4] * mult_input1[11: 8]; // a1*b2
        p13 <= mult_input0[ 7: 4] * mult_input1[15:12]; // a1*b3

        // row 2 (a2 * b?)
        p20 <= mult_input0[11: 8] * mult_input1[ 3: 0]; // a2*b0
        p21 <= mult_input0[11: 8] * mult_input1[ 7: 4]; // a2*b1
        p22 <= mult_input0[11: 8] * mult_input1[11: 8]; // a2*b2
        p23 <= mult_input0[11: 8] * mult_input1[15:12]; // a2*b3

        // row 3 (a3 * b?)
        p30 <= mult_input0[15:12] * mult_input1[ 3: 0]; // a3*b0
        p31 <= mult_input0[15:12] * mult_input1[ 7: 4]; // a3*b1
        p32 <= mult_input0[15:12] * mult_input1[11: 8]; // a3*b2
        p33 <= mult_input0[15:12] * mult_input1[15:12]; // a3*b3
    end

    // Stage 2: Add partial products with appropriate 4-bit shifts
    // logic signed [31:0] intermediate_sum;

    always_ff @(posedge clk) begin
        intermediate_sum <=
            // i,j -> shift = 4*(i+j)
            ($signed(p00) <<< 0)  +  // a0*b0 * 2^0
            ($signed(p01) <<< 4)  +  // a0*b1 * 2^4
            ($signed(p02) <<< 8)  +  // a0*b2 * 2^8
            ($signed(p03) <<< 12) +  // a0*b3 * 2^12

            ($signed(p10) <<< 4)  +  // a1*b0 * 2^4
            ($signed(p11) <<< 8)  +  // a1*b1 * 2^8
            ($signed(p12) <<< 12) +  // a1*b2 * 2^12
            ($signed(p13) <<< 16) +  // a1*b3 * 2^16

            ($signed(p20) <<< 8)  +  // a2*b0 * 2^8
            ($signed(p21) <<< 12) +  // a2*b1 * 2^12
            ($signed(p22) <<< 16) +  // a2*b2 * 2^16
            ($signed(p23) <<< 20) +  // a2*b3 * 2^20

            ($signed(p30) <<< 12) +  // a3*b0 * 2^12
            ($signed(p31) <<< 16) +  // a3*b1 * 2^16
            ($signed(p32) <<< 20) +  // a3*b2 * 2^20
            ($signed(p33) <<< 24);   // a3*b3 * 2^24
    end

    // Stage 3: Register the final output
    always_ff @(posedge clk) begin
        intermediate_sum_2 <= intermediate_sum;
    end

    // Stage 3: Register the final output
    always_ff @(posedge clk) begin
        product <= intermediate_sum_2;
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

                // // initialize write signals
                // readMem_addr = 1'b0;
                VALID_memVal = 1'b0; 

                // determine next state
                if (EN_mult == 1'b1) begin
                    // EN_writeMem = 1'b1;
                    // state = WRITE;
                    next_state = WRITE;
                end
                else begin
                    next_state = IDLE;
                end
            end

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
