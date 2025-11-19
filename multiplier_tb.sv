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

  ////////////////////////////
    logic first=1'b0;
    // wire            wire_clkA; // input  
    // wire            wire_clkB; // input  
    // wire [6-1:0]    wire_aA; // input  
    // wire [6-1:0]    wire_aB; // input  
    // wire            wire_cenA; // input  
    // wire            wire_cenB; // input  
    // wire [16-1:0]   wire_d; // input  
    // wire [16-1:0]   wire_q; // output  


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
    output logic [31:0] inputs_vector [0:63],
    output logic [31:0] outputs_vector [0:63]
);
    $display("start");
    for (int i = 0; i < 64; i++) begin
        inputs_vector[i] = i;
        outputs_vector[i] = i*i;
        $display("inputs: %0d", inputs_vector[i]);
        $display("outputs: %0d", outputs_vector[i]);
    end
    $display("stop");
endtask

  // Clock generator
  initial clk = 0;
  // always #1.25 clk = ~clk; // 400 MHz
  always begin
    #0.625 clk = ~clk; // 800 MHz
  end

  always begin
    #0.05;
    if (clk==1) begin
      #0.500;
      mult_input0 = 1; 
      mult_input1 = writeMem_addr; 
    end
  end

  // always begin
  //   // #1.25; 
  //   // assign mult_input0 = 16'd65535; 
  //   // assign mult_input1 = 16'd65535; 

  //   #1.25;
  //   assign mult_input0 = 1; 
  //   assign mult_input1 = writeMem_addr; 
  // end

  // always begin

  //   if (first!=1'b1)begin
  //     #0.625;
  //     first=1'b1;
  //   end
  //   // assign mult_input0 = 16'd65535; 
  //   // assign mult_input1 = 16'd65535; 

  //   #1.25;
  //   // mult_input0 = 1; 
  //   // mult_input1 = writeMem_addr; 
    
  // end

logic [31:0] inputs_vector [0:63];
logic [31:0] outputs_vector [0:63];

  // Stimulus to fsm
  initial begin
    // initialize signals
    #1.25 rst = 1; EN_mult = 0; EN_blockRead = 0; 
    #1.25 rst = 0;

    generate_vectors(inputs_vector, outputs_vector);

    // 
    #5 EN_mult = 1; // enable writing   
    #80; // finish multiplying
    #1.25 EN_mult = 0; // stop writing
    #1.25 EN_blockRead = 1; // enable reading
    #1.25 EN_blockRead = 0;
    #80; // finish reading
    // 
    #5 EN_mult = 1; // enable writing   
    #80; // finish multiplying
    #1.25 EN_mult = 0; // stop writing
    #1.25 EN_blockRead = 1; // enable reading
    #1.25 EN_blockRead = 0;
    #80; // finish reading
    // 
    #5 EN_mult = 1; // enable writing   
    #80; // finish multiplying
    #1.25 EN_mult = 0; // stop writing
    #1.25 EN_blockRead = 1; // enable reading
    #1.25 EN_blockRead = 0;
    #80; // finish reading
    // 
    #5 EN_mult = 1; // enable writing   
    #80; // finish multiplying
    #1.25 EN_mult = 0; // stop writing
    #1.25 EN_blockRead = 1; // enable reading
    #1.25 EN_blockRead = 0;
    #80; // finish reading
    // 
    #5 EN_mult = 1; // enable writing   
    #80; // finish multiplying
    #1.25 EN_mult = 0; // stop writing
    #1.25 EN_blockRead = 1; // enable reading
    #1.25 EN_blockRead = 0;
    #80; // finish reading
    // 
    #5 EN_mult = 1; // enable writing   
    #80; // finish multiplying
    #1.25 EN_mult = 0; // stop writing
    #1.25 EN_blockRead = 1; // enable reading
    #1.25 EN_blockRead = 0;
    #80; // finish reading
    // 
    #5 EN_mult = 1; // enable writing   
    #80; // finish multiplying
    #1.25 EN_mult = 0; // stop writing
    #1.25 EN_blockRead = 1; // enable reading
    #1.25 EN_blockRead = 0;
    #80; // finish reading
    // 
    #5 EN_mult = 1; // enable writing   
    #80; // finish multiplying
    #1.25 EN_mult = 0; // stop writing
    #1.25 EN_blockRead = 1; // enable reading
    #1.25 EN_blockRead = 0;
    #80; // finish reading
    // 
    #5 EN_mult = 1; // enable writing   
    #80; // finish multiplying
    #1.25 EN_mult = 0; // stop writing
    #1.25 EN_blockRead = 1; // enable reading
    #1.25 EN_blockRead = 0;
    #80; // finish reading

    $stop;
  end

endmodule
