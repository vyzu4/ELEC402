`timescale 1ns/1ps
`include "memory_wrapper_2port.sv"
`include "registerArray.sv"
`include "design.sv"
`include "design_no_pipe.sv"

`timescale 1ns/1ps

// Define this macro to use the pipelined version (for 800MHz)
// Comment it out to use the non-pipelined version (for 400MHz)
//`define USE_PIPELINED

module multiplier_module_tb;

    // Clock frequency selection
    parameter CLOCK_FREQ = 400; // Options: 400 or 800 (MHz)
    
    // Calculate clock period based on frequency
    localparam real CLK_PERIOD = (CLOCK_FREQ == 800) ? 1.25 : 2.5; // ns
    
    // Testbench signals
    logic clk;
    logic rst_n;
    logic [15:0] operandA;
    logic [15:0] operandB;
    logic EN_mult;
    logic EN_readMem;
    logic RDY_mult;
    logic RDY_readMem;
    logic [31:0] memVal;
    logic VALID_memVal;
    
    // Test variables
    integer i, j, k;
    integer error_count;
    integer mult_count;
    integer read_count;
    logic [31:0] expected_results[0:511]; // Store expected results for 8 iterations * 64
    integer total_mults;
    
    // DUT instantiation - switched via `define
`ifdef USE_PIPELINED
    multiplier_module dut (              // Pipelined version (for 800MHz)
`else
    multiplier_module_no_pipeline dut (  // Non-pipelined version (for 400MHz)
`endif
        .clk(clk),
        .rst_n(rst_n),
        .operandA(operandA),
        .operandB(operandB),
        .EN_mult(EN_mult),
        .EN_readMem(EN_readMem),
        .RDY_mult(RDY_mult),
        .RDY_readMem(RDY_readMem),
        .memVal(memVal),
        .VALID_memVal(VALID_memVal)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("multiplier_module.vcd");
        $dumpvars(0, multiplier_module_tb);
    end
    
    // Main test sequence
    initial begin
        // Initialize
        $display("================================================");
        $display("Multiplier Module Testbench");
`ifdef USE_PIPELINED
        $display("Version: PIPELINED (for 800MHz)");
`else
        $display("Version: NON-PIPELINED (for 400MHz)");
`endif
        $display("Clock Frequency: %0d MHz", CLOCK_FREQ);
        $display("Clock Period: %0.3f ns", CLK_PERIOD);
        $display("================================================");
        
        error_count = 0;
        total_mults = 0;
        operandA = 16'h0;
        operandB = 16'h0;
        EN_mult = 1'b0;
        EN_readMem = 1'b0;
        
        // Apply reset
        rst_n = 1'b0;
        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);
        
        $display("\n[%0t] Reset complete, starting test...", $time);
        
        // Run 8 iterations of memory fill
        for (i = 0; i < 8; i++) begin
            $display("\n[%0t] ========== Iteration %0d ==========", $time, i+1);
            
            // Fill memory with 64 multiplications
            mult_count = 0;
            @(posedge clk);
            
            while (mult_count < 64) begin
                
                if (RDY_mult) begin
                    EN_mult = 1'b1;
                    // Generate pseudo-random test values
                    operandA = 16'h0100 + (i * 64 + mult_count);
                    operandB = 16'h0200 + (i * 64 + mult_count);
                    
                    // Store expected result
                    expected_results[i * 64 + mult_count] = operandA * operandB;
                    
                    $display("[%0t] Mult %0d: A=0x%h, B=0x%h, Expected=0x%h", 
                             $time, mult_count, operandA, operandB, 
                             expected_results[i * 64 + mult_count]);
                    
                    mult_count++;
                    total_mults++;
                    @(posedge clk);  // Wait one cycle with EN_mult=1
                end else begin
                    EN_mult = 1'b0;
                    $display("[%0t] RDY_mult = 0, waiting...", $time);
                    @(posedge clk);
                end
            end
            
            EN_mult = 1'b0;
            @(posedge clk);
            
            // Wait for pipeline to drain
            // For non-pipelined: no pipeline, so just 1 cycle
            // For pipelined: 2-3 cycles for 2-stage pipeline
            $display("[%0t] All multiplications sent, waiting for any pending writes...", $time);
            repeat(2) @(posedge clk);  // Works for both versions
            
            // Wait for memory to be full
            $display("[%0t] Waiting for memory full (write_count should be 64)...", $time);
            wait(RDY_readMem == 1'b1);
            repeat(2) @(posedge clk);
            $display("[%0t] Memory full, RDY_readMem asserted, write_count=%0d", 
                     $time, dut.write_count);
            
            // Initiate read operation
            @(posedge clk);
            EN_readMem = 1'b1;
            @(posedge clk);
            EN_readMem = 1'b0;
            
            $display("[%0t] Read operation initiated", $time);
            
            // Read and verify all 64 values
            read_count = 0;
            while (read_count < 64) begin
                @(posedge clk);
                
                if (VALID_memVal) begin
                    if (memVal !== expected_results[i * 64 + read_count]) begin
                        $display("[%0t] ERROR! Read %0d: Got=0x%h, Expected=0x%h", 
                                 $time, read_count, memVal, 
                                 expected_results[i * 64 + read_count]);
                        error_count++;
                    end else begin
                        $display("[%0t] Read %0d: PASS (0x%h)", 
                                 $time, read_count, memVal);
                    end
                    read_count++;
                end
            end
            
            $display("[%0t] Iteration %0d complete: %0d reads verified", 
                     $time, i+1, read_count);
            
            // Wait for read to complete and return to IDLE
            repeat(5) @(posedge clk);
        end
        
        // Test completion
        repeat(10) @(posedge clk);
        
        $display("\n================================================");
        $display("TEST SUMMARY");
        $display("================================================");
        $display("Clock Frequency: %0d MHz", CLOCK_FREQ);
        $display("Total Iterations: 8");
        $display("Total Multiplications: %0d", total_mults);
        $display("Total Reads Verified: %0d", total_mults);
        $display("Errors: %0d", error_count);
        
        if (error_count == 0) begin
            $display("\n*** ALL TESTS PASSED ***");
        end else begin
            $display("\n*** TESTS FAILED: %0d errors ***", error_count);
        end
        $display("================================================\n");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 100000); // Adjust timeout as needed
        $display("\n[%0t] ERROR: Testbench timeout!", $time);
        $finish;
    end
    
    // Monitor key signals - DISABLED to reduce clutter
    // Uncomment for detailed monitoring
    // initial begin
    //     $monitor("[%0t] State Monitor: RDY_mult=%b, RDY_readMem=%b, VALID_memVal=%b", 
    //              $time, RDY_mult, RDY_readMem, VALID_memVal);
    // end
    
    // Additional debug signals
    logic [1:0] dut_state;
    logic [6:0] dut_write_count;
    logic dut_mem_full;
    logic dut_write_en;
`ifdef USE_PIPELINED
    logic dut_mult_valid_d2;
    logic dut_mult_valid_d1;
`endif
    logic [6:0] dut_read_count;
    logic dut_read_done;
    
    assign dut_state = dut.current_state;
    assign dut_write_count = dut.write_count;
    assign dut_mem_full = dut.mem_full;
    assign dut_write_en = dut.write_en;
`ifdef USE_PIPELINED
    assign dut_mult_valid_d2 = dut.mult_valid_d2;
    assign dut_mult_valid_d1 = dut.mult_valid_d1;
`endif
    assign dut_read_count = dut.read_count;
    assign dut_read_done = dut.read_done;
    
    // Detailed state transition monitor
    logic [1:0] prev_state;
    always @(posedge clk) begin
        prev_state <= dut_state;
        if (prev_state != dut_state) begin
            $display("[%0t] STATE CHANGE: %0d -> %0d (write_cnt=%0d, read_cnt=%0d, mem_full=%b, read_done=%b)", 
                     $time, prev_state, dut_state, dut_write_count, dut_read_count, dut_mem_full, dut_read_done);
        end
        
        // Debug reading state
        if (dut_state == 2'd3) begin  // READING state
            $display("[%0t] READING: read_count=%0d, aA=%0d, VALID=%b, q=0x%h, read_done=%b", 
                     $time, dut_read_count, dut.aA, VALID_memVal, memVal, dut_read_done);
        end
    end
    
    // Debug monitor for internal state
    always @(posedge clk) begin
        if (EN_mult && RDY_mult) begin
            $display("[%0t] DEBUG: Mult accepted! A=0x%h, B=0x%h, state=%0d", 
                     $time, operandA, operandB, dut_state);
        end
        if (EN_mult && !RDY_mult) begin
            $display("[%0t] DEBUG: EN_mult=1 but RDY_mult=0, state=%0d, write_count=%0d, mem_full=%b", 
                     $time, dut_state, dut_write_count, dut_mem_full);
        end
        if (dut_write_en) begin
            $display("[%0t] DEBUG: WRITE! addr=%0d, data=0x%h, count_will_be=%0d", 
                     $time, dut.aB, dut.d, dut_write_count + 1);
        end
`ifdef USE_PIPELINED
        if (dut_mult_valid_d1) begin
            $display("[%0t] DEBUG: Pipeline stage 1 valid, result=0x%h", 
                     $time, dut.mult_result_d1);
        end
        if (dut_mult_valid_d2) begin
            $display("[%0t] DEBUG: Pipeline stage 2 valid, result=0x%h", 
                     $time, dut.mult_result_d2);
        end
`endif
    end

endmodule
