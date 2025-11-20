module multiplier_module_no_pipeline (
    input logic clk,
    input logic rst_n,  // Asynchronous active-low reset
    
    // Multiplier inputs
    input logic [15:0] operandA,
    input logic [15:0] operandB,
    input logic EN_mult,
    
    // Memory read control
    input logic EN_readMem,
    
    // Outputs
    output logic RDY_mult,
    output logic RDY_readMem,
    output logic [31:0] memVal,
    output logic VALID_memVal
);

    // FSM States
    typedef enum logic [1:0] {
        IDLE        = 2'b00,
        MULTIPLYING = 2'b01,
        MEM_FULL    = 2'b10,
        READING     = 2'b11
    } state_t;
    
    state_t current_state, next_state;
    
    // Internal signals
    logic [31:0] mult_result;
    
    // Memory interface signals for 2-port memory
    // Port A: Read port
    logic [5:0] aA;           // Read address
    logic cenA;               // Read chip enable (active low)
    logic [31:0] q;           // Read data output
    
    // Port B: Write port
    logic [5:0] aB;           // Write address
    logic cenB;               // Write chip enable (active low)
    logic [31:0] d;           // Write data input
    
    // Control counters
    logic [6:0] write_count;  // 7 bits to hold 0-64
    logic [6:0] read_count;   // 7 bits to hold 0-65
    logic mem_full;
    logic read_done;
    logic write_en;
    
    // Combinational multiply (no pipeline)
    assign mult_result = operandA * operandB;
    
    // Write enable logic
    assign write_en = EN_mult && RDY_mult && !mem_full;
    
    // Memory write control (Port B - Write)
    assign d = mult_result;
    assign cenB = !write_en;  // Active low, so invert
    
    // Memory full flag
    logic mem_full_flag;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_full_flag <= 1'b0;
        end else begin
            if (current_state == IDLE || current_state == READING) begin
                mem_full_flag <= 1'b0;
            end else if (write_count == 7'd64) begin
                mem_full_flag <= 1'b1;
            end
        end
    end
    
    assign mem_full = mem_full_flag;
    
    // Write counter and address
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_count <= 7'h0;
            aB <= 6'h0;
        end else begin
            if (current_state == READING && read_done) begin
                // Only reset after reading is complete
                write_count <= 7'h0;
                aB <= 6'h0;
            end else if (write_en && write_count < 7'd64) begin
                write_count <= write_count + 1'b1;
                aB <= aB + 1'b1;
            end
        end
    end
    
    // Read counter and address (Port A - Read)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_count <= 7'h0;
            aA <= 6'h0;
            cenA <= 1'b1;  // Disabled by default
        end else begin
            if (current_state == READING) begin
                if (read_count < 7'd65) begin
                    cenA <= 1'b0;  // Enable reading (active low)
                    if (read_count < 7'd64) begin
                        aA <= read_count[5:0];  // Set addresses 0-63
                    end
                    read_count <= read_count + 1'b1;
                end else begin
                    cenA <= 1'b1;  // Disable after done
                end
            end else if (current_state == MEM_FULL) begin
                // Reset for next read cycle
                read_count <= 7'h0;
                aA <= 6'h0;
                cenA <= 1'b1;
            end else begin
                read_count <= 7'h0;
                aA <= 6'h0;
                cenA <= 1'b1;  // Disabled
            end
        end
    end
    
    assign read_done = (read_count >= 7'd65);
    
    // FSM: State register with asynchronous reset
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    // FSM: Next state logic
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (EN_mult && !mem_full)
                    next_state = MULTIPLYING;
            end
            
            MULTIPLYING: begin
                if (mem_full)
                    next_state = MEM_FULL;
                else if (!EN_mult && write_count == 0)
                    next_state = IDLE;
            end
            
            MEM_FULL: begin
                if (EN_readMem)
                    next_state = READING;
            end
            
            READING: begin
                if (read_done)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // FSM: Output logic
    always_comb begin
        // Default values
        RDY_mult = 1'b0;
        RDY_readMem = 1'b0;
        VALID_memVal = 1'b0;
        
        case (current_state)
            IDLE: begin
                RDY_mult = 1'b1;
                RDY_readMem = 1'b0;
            end
            
            MULTIPLYING: begin
                RDY_mult = !mem_full;
                RDY_readMem = 1'b0;
            end
            
            MEM_FULL: begin
                RDY_mult = 1'b0;
                RDY_readMem = 1'b1;
            end
            
            READING: begin
                RDY_mult = 1'b0;
                RDY_readMem = 1'b0;
                VALID_memVal = (read_count >= 7'd1) && (read_count <= 7'd64);
            end
        endcase
    end
    
    // Memory output
    assign memVal = q;
    
    // Instantiate memory unit (2-port memory)
    memory_wrapper_2port #(
        .DEPTH(64),
        .LOGDEPTH(6),
        .WIDTH(32),
        .MEMTYPE(0),
        .TECHNODE(0),
        .COL_MUX(1)
    ) mem_inst (
        // Port A: Read
        .clkA(clk),
        .aA(aA),
        .cenA(cenA),
        .q(q),
        // Port B: Write
        .clkB(clk),
        .aB(aB),
        .cenB(cenB),
        .d(d)
    );

endmodule
