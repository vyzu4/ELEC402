typedef enum logic [1:0] {
    IDLE  = 2'b00,
    WRITE = 2'b01,
    FULL = 2'b10
    // READ = 2'b11
} state_t;

module multiplier #(
) (
    input  logic                clk,
    input  logic                rst,      

    input  logic                EN_mult, 
    output logic                EN_writeMem,    
    output logic [6-1:0]          writeMem_addr, 

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
            state = IDLE;
        else
            // transition to next state
            state = next_state;
        
        unique case (state)

            IDLE: begin
                first_write = 1'b0;

                RDY_mult = 1'b1;
                EN_readMem= 1'b0;
                writeMem_addr = 1'b0;

                if (EN_mult == 1'b1) begin
                    next_state = WRITE;
                end
                else begin
                    next_state = IDLE;
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
                    next_state = IDLE;
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
                RDY_mult = 1'b0;

                if (EN_mult == 1'b1) begin
                    EN_writeMem=1'b0;
                    next_state = FULL;
                end 
                else begin
                    EN_writeMem=1'b0;
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

endmodule


