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

    logic signed [15:0] p00, p01, p10, p11;

    logic signed [31:0] intermediate_sum;

    logic signed [31:0] delay = 0;

    always @(posedge clk) begin
        if (EN_mult && RDY_mult) begin
            p00 <= mult_input0[7:0] * mult_input1[7:0];
            p01 <= mult_input0[7:0] * mult_input1[15:8];
            p10 <= mult_input0[15:8] * mult_input1[7:0];
            p11 <= mult_input0[15:8] * mult_input1[15:8];
        end
    end

    always @(posedge clk) begin
        intermediate_sum <= p00 + (p01 << 16) + (p10 << 16) + (p11 << 32);
    end
    
    always @(posedge clk) begin
        product <= intermediate_sum;
    end

    always_ff @(posedge clk) begin
        writeMem_val <= product;
    end

    always_comb begin
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
                    if (delay > 4) 
                        next_state = WRITE;
                end
                else begin
                    next_state = IDLE;
                end

                delay = delay + 1;
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
                delay = 0;              
                
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
