`timescale 1ns/1ps
module fsm_tb #(
    parameter WIDTH = 32
);
  // multiplier i/o
    logic                clk; // input
    logic                rst; // input     

    logic                EN_mult; // input
    logic                EN_writeMem; // output
    logic [6-1:0]          writeMem_addr; // output

    logic [15:0]         mult_input0; // input
    logic [15:0]         mult_input1; // input
    logic [WIDTH-1:0]       writeMem_val; // output 

    logic                RDY_mult;             
     
    logic                EN_blockRead; // input           
    logic                VALID_memVal; // output           
    logic [WIDTH-1:0]       memVal_data; // output            

    logic                EN_readMem; // output             
    logic [6-1:0]        readMem_addr; // output           
    logic [WIDTH-1:0]       readMem_val; // input 

  /////////////////////////////////////////

    logic           clkA; // input  
    logic           clkB; // input  
    logic [6-1:0]   aA; // input  
    logic [6-1:0]   aB; // input  
    logic           cenA; // input  
    logic           cenB; // input  
    logic [WIDTH-1:0]   d; // input  
    logic [WIDTH-1:0]   q; // output  

multiplier #(
    .WIDTH(WIDTH)
  ) multiplier_dut (
    .clk(clk),
    .rst(rst),

    .EN_mult(EN_mult),
    .EN_writeMem(EN_writeMem),
    .writeMem_addr(writeMem_addr),

    .mult_input0(mult_input0),
    .mult_input1(mult_input1),
    .writeMem_val(writeMem_val),

    .RDY_mult(RDY_mult),

    .EN_blockRead(EN_blockRead),
    .VALID_memVal(VALID_memVal),
    .memVal_data(memVal_data),

    .EN_readMem(EN_readMem),
    .readMem_addr(readMem_addr),
    .readMem_val(q)
);

  // Instantiate memory_wrapper_2port DUT
  memory_wrapper_2port #(
    .WIDTH(WIDTH)
  ) mw2p_dut (
    .clkA(clk),
    .clkB(clk),

    .aA(readMem_addr),
    .aB(writeMem_addr),

    .cenA(~EN_readMem),
    .cenB(~EN_writeMem),

    .d(writeMem_val),
    .q(q)
  );

task automatic generate_vectors(
    output logic [31:0] vec0 [0:63],
    output logic [31:0] vec1 [0:63],
    output logic [31:0] outputs_vector [0:63]
);
    $display("start");
    for (int i = 0; i < 64; i++) begin
        vec0[i] = $urandom_range(64, 0);
        vec1[i] = $urandom_range(64, 0);
        outputs_vector[i] = vec0[i] * vec1[i];
        $display("inputs: %0d", vec0[i]);
        $display("inputs: %0d", vec0[i]);
        $display("outputs: %0d", outputs_vector[i]);
    end
    $display("stop");
endtask

  // Clock generator
  initial clk = 1;
  // always #1.35 clk = ~clk; // 400 MHz
  always #0.635 clk = ~clk; // 800 MHz

// logic [31:0] vec0 [0:63];
// logic [31:0] vec1 [0:63];
// logic [31:0] mult_output_vector [0:63];

// drive multiplier inputs based on current writeMem_addr
always_ff @(posedge clk) begin
    mult_input0 = $urandom_range(64, 0);  // use address as index
    mult_input1 = $urandom_range(64, 0);
end

  // Stimulus to fsm
  initial begin

    // initialize signals
    #1.25 rst = 1; EN_mult = 0; EN_blockRead = 0; 
    #1.25 rst = 0;

    for (int i = 0; i < 8; i++) begin
      #50;
      #5 EN_mult = 1; // enable writing   
      #200; // finish multiplying
      #2.5 EN_mult = 0; // stop writing
      #2.5 EN_blockRead = 1; // enable reading
      #2.5 EN_blockRead = 0;
      #200; // finish reading
    end

    $stop;
  end

endmodule
