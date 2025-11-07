typedef enum logic [1:0] {
    IDLE  = 2'b00,
    PREP  = 2'b01,
    WRITE = 2'b10,
    FULL = 2'b11
} state_t;

module fsm #(
) (
    input  logic                clk,
    input  logic                rst,      

    input  logic                EN_mult, 
    output logic                EN_writeMem,    
    output logic [6:0]          writeMem_addr, 

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

    // logic first_writeMem_addr = 1'b0;

    logic [32-1: 0] product;

    always_comb begin
        product = mult_input0 * mult_input1;
    end

    // next state logic
    always_ff @(posedge clk) begin
        next_state = state; // default hold
        
        unique case (state)

            IDLE: begin
                RDY_mult = 1'b1;
                EN_readMem= 1'b0;
                writeMem_addr = 1'b0;

                if (EN_mult == 1'b1) begin
                    EN_writeMem = 1'b1; // needs 1 cycle delay
                    next_state = PREP;
                end
                else begin
                    EN_writeMem = 1'b0;
                    next_state = IDLE;
                end
            end

            PREP: begin
                if (EN_mult == 1'b1) begin
                    // EN_writeMem = 1'b1; // needs 1 cycle delay
                    next_state = WRITE;
                end
                else begin
                    // EN_writeMem = 1'b0;
                    next_state = IDLE;
                end
            end

            WRITE: begin
                EN_writeMem = 1'b1;
                writeMem_addr = writeMem_addr + 1;

                // determine value of RDY_mult
                if (writeMem_addr <= 6'd61)
                    RDY_mult = 1'b1;
                else
                    RDY_mult = 1'b0;

                // determine next state
                if (EN_mult == 1'b0)
                    next_state = IDLE;
                else if (writeMem_addr == 6'd63)
                    next_state = FULL;
                else 
                    next_state = WRITE;
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

    // State register (sync reset)
    always_ff @(posedge clk) begin
        if (!rst)
            state <= IDLE;
        else
            // transition to next state
            state <= next_state;
            // delay reg for multiplication product
            writeMem_val <= product;
    end

endmodule


