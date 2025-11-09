typedef enum logic [2:0] {
    IDLE_WRITE  = 3'b000,
    WRITE = 3'b001,
    FULL =  3'b010,
    // IDLE_READ =  3'b011,
    READ = 3'b100,
    EMPTY = 3'b101
} state_t;

module multiplier #(
) (
    input  logic                clk,
    input  logic                rst,      

    input  logic                EN_mult, 
    output logic                EN_writeMem,    
    output logic [6-1:0]        writeMem_addr, 

    input  logic [15:0]         mult_input0,
    input  logic [15:0]         mult_input1,
    output logic [32-1:0]       writeMem_val,  

    output logic                RDY_mult,              
     
    input  logic                EN_blockRead,            
    output logic                VALID_memVal,            
    output logic [32-1:0]       memVal_data,             

    output logic                EN_readMem,              
    output logic [6-1:0]        readMem_addr,            
    input  logic [32-1:0]       readMem_val                
);

    state_t state, next_state;

    logic first_write; // flag
    logic first_read; // flag
    logic first_VALID_memVal; // flag

    logic [32-1: 0] product;

    // multiplication logic
    always_comb begin
        product = mult_input0 * mult_input1;
    end

    // writeMem_val
    always_ff @(posedge clk) begin
        writeMem_val = product;
    end

    // state transition/behaviour logic
    always_ff @(posedge clk) begin
        // next_state = state; // default hold

        if (!rst)
            state = IDLE_WRITE;
        else
            // transition to next state
            state = next_state;
        
        unique case (state)

            IDLE_WRITE: begin
                first_write = 1'b0;

                RDY_mult = 1'b1;
                EN_readMem= 1'b0;
                writeMem_addr = 1'b0;

                if (EN_mult == 1'b1) begin
                    next_state = WRITE;
                end
                else begin
                    next_state = IDLE_WRITE;
                end
            end

            WRITE: begin
                EN_writeMem = 1'b1;

                // determine value of RDY_mult
                if (writeMem_addr < 6'd61)
                    RDY_mult = 1'b1;
                else
                    RDY_mult = 1'b0;

                // determine EN_writeMem and next state
                if (EN_mult == 1'b0) begin
                    EN_writeMem = 1'b0;
                    next_state = IDLE_WRITE;
                end
                else begin
                    EN_writeMem = 1'b1;

                    if (writeMem_addr < 6'd62)
                        next_state = WRITE;
                    else
                        next_state = FULL;
                end

                // determine value of writeMem_addr
                writeMem_addr = !first_write ?  1'b0 : writeMem_addr + 1;
                first_write = 1'b1;
            end

            FULL: begin
                // write related signals
                RDY_mult = 1'b0;

                first_read = 1'b0; // flag

                // read related signals
                EN_writeMem = 1'b0;
                EN_readMem = 1'b0;
                readMem_addr = 1'b0;
                VALID_memVal = 1'b0;

                if (EN_mult == 1'b1) begin
                    next_state = FULL;
                end 
                else begin
                    if (EN_blockRead == 1'b1) begin
                        EN_readMem = 1'b1;
                        next_state = READ;
                    end
                    else 
                        next_state = FULL;
                end
            end

            READ: begin
                // set flag
                first_VALID_memVal = 1'b0;
                
                // set states
                if (readMem_addr < 6'd62)
                    next_state = READ;
                else
                    next_state = EMPTY;

                // set value for VALID_memVal
                if (EN_readMem == 1'b1)
                    VALID_memVal = 1'b1;
                else
                    VALID_memVal = 1'b0;

                // determine value of writeMem_addr
                readMem_addr = !first_read ?  1'b0 : readMem_addr + 1;
                first_read = 1'b1;
            end

            EMPTY: begin
                EN_readMem = 1'b0;
                RDY_mult = 1'b1;

                VALID_memVal = !first_VALID_memVal ?  1'b1 : 1'b0;
                first_VALID_memVal = 1'b1;
            end

            default: next_state = IDLE_WRITE;
        endcase
    end

endmodule


