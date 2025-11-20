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
    (* keep = "true" *) input  logic                    clk,
    (* keep = "true" *) input  logic                    rst,      

    (* keep = "true" *) input  logic                    EN_mult, // high to start multiplication
    (* keep = "true" *) output logic                    EN_writeMem, // high to write to mem   
    (* keep = "true" *) output logic [LOGDEPTH-1:0]     writeMem_addr, // addr to write to

    (* keep = "true" *) input  logic [16-1:0]           mult_input0,
    (* keep = "true" *) input  logic [16-1:0]           mult_input1,
    (* keep = "true" *) output reg  [WIDTH-1:0]          writeMem_val,  // 

    (* keep = "true" *) output logic                    RDY_mult, // ready to multiply             
     
    (* keep = "true" *) input  logic                    EN_blockRead, // high to read from mem block           
    (* keep = "true" *) output logic                    VALID_memVal, // high for valid mem val           
    (* keep = "true" *) output logic [WIDTH-1:0]        memVal_data, // mem data            

    (* keep = "true" *) output logic                    EN_readMem, // high to start reading mem             
    (* keep = "true" *) output logic [LOGDEPTH-1:0]     readMem_addr, // addr to read from           
    (* keep = "true" *) input  logic [WIDTH-1:0]        readMem_val // data read from mem               
);
    // state stuff
    (* keep = "true" *) state_t state;
    (* keep = "true" *) state_t next_state;

    // flags
    (* keep = "true" *) logic first_write = 1'b0; 
    (* keep = "true" *) logic first_read = 1'b0; 
    (* keep = "true" *) logic first_VALID_memVal = 1'b0; 

    (* keep = "true" *) logic [WIDTH-1: 0] product;

    // EN_writeMem = 1'b0;
    // writeMem_addr = 6'b0;
    // writeMem_val = 32'b0;
    // RDY_mult = 1'b0;
    // VALID_memVal = 1'b0;
    // memVal_data = 32'b0;
    // EN_readMem = 1'b0;
    // readMem_addr = 6'b0;

    // multiplication logic
    always_ff @(posedge clk) begin
        writeMem_val <= product; 
    end

    always_comb begin
        product = mult_input0 * mult_input1;
        memVal_data = readMem_val;   
    end

    // state transition/behaviour logic
    always_ff @(posedge clk) begin
        // next_state = state; // default hold

        if (rst) begin
            state = IDLE;
            next_state = IDLE;
            // initialize all i/o
            EN_writeMem = 1'b0;
            writeMem_addr = 6'b0;
            writeMem_val = 16'b0;
            RDY_mult = 1'b0;
            VALID_memVal = 1'b0;
            EN_readMem = 1'b0;
            readMem_addr = 6'b0;
        end
        else
            // transition to next state
            state = next_state;

        // state = next_state;
        
        unique case (state)

            IDLE: begin

                first_write = 1'b0; //set flag
                
                // initialize write signals
                EN_writeMem = 1'b0;
                RDY_mult = 1'b1;
                EN_readMem = 1'b0;
                writeMem_addr = 1'b0;
                EN_writeMem = 1'b0;
                writeMem_val = 32'b0;

                // // initialize write signals
                readMem_addr = 32'b0;
                VALID_memVal = 1'b0; 
                // memVal_data = 32'b0;

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
                EN_readMem = 1'b0;
                writeMem_val = 32'b0;

                // determine value of RDY_mult
                if (writeMem_addr < 6'd61)
                    RDY_mult = 1'b1;
                else
                    RDY_mult = 1'b0;

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

            end

            FULL: begin
                // initialize write signals
                RDY_mult = 1'b0;
                writeMem_addr = 6'b0;
                writeMem_val = 32'b0;

                // initialize read signals
                VALID_memVal = 1'b0;
                EN_writeMem = 1'b0;
                writeMem_addr = 6'b0;
                EN_readMem = 1'b0;
                readMem_addr = 1'b0;

                // set flag
                first_read = 1'b0; 

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

                EN_writeMem = 1'b0;
                writeMem_addr = 6'b0;
                writeMem_val = 32'b0;
                RDY_mult = 1'b0;
                // VALID_memVal = 1'b0;     
                
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
                    // VALID_memVal = 1'b0;     
                end

            end

            default: next_state = IDLE;
        endcase
    end

endmodule
