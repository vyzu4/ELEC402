module fsm_tb;
  // multiplier i/o
    logic                clk;
    logic                rst;      

    logic                EN_mult;
    logic                EN_writeMem; 
    logic [6-1:0]          writeMem_addr;

    logic [15:0]         mult_input0;
    logic [15:0]         mult_input1;
    logic [16-1:0]       writeMem_val;  

    logic                RDY_mult;             
     
    logic                EN_blockRead;            
    logic                VALID_memVal;            
    logic [16-1:0]       memVal_data;             

    logic                EN_readMem;              
    logic [6-1:0]        readMem_addr;            
    logic [16-1:0]       readMem_val; 

  // Instantiate multiplier DUT
  multiplier multiplier_dut (
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
    .readMem_val(readMem_val)
  );

  // Instantiate memory_wrapper_2port DUT
  memory_wrapper_2port mw2p_dut (
    .clkA(clk),
    .clkB(clk),

    .aA(writeMem_addr),
    .aB(readMem_addr),

    .cenA(~EN_writeMem),
    .cenB(~EN_readMem),

    .d(writeMem_val),
    .q(readMem_val)
  );

  // Instantiate registerArray DUT
  registerArray mra_dut (
    .clkA(clk),
    .clkB(clk),

    .aA(writeMem_addr),
    .aB(readMem_addr),

    .cenA(~EN_writeMem),
    .cenB(~EN_readMem),

    .d(writeMem_val),
    .q(readMem_val)
  );

  // Clock generator
  initial clk = 0;
  always #5 clk = ~clk;

  // Stimulus to fsm
  initial begin
    // initialize signals
    rst = 0; EN_mult = 0; EN_blockRead = 0; 

    #10 rst = 1;                // release reset
    #10 EN_mult = 1;            // start writing
    #10 mult_input0 = 1; mult_input1 = 9;
    #10 mult_input0 = 2; mult_input1 = 8;
    #10 mult_input0 = 3; mult_input1 = 7;
    #10 mult_input0 = 4; mult_input1 = 6;
    #10 mult_input0 = 5; mult_input1 = 5;
    #10 mult_input0 = 6; mult_input1 = 4;
    #10 mult_input0 = 7; mult_input1 = 3;
    #10 mult_input0 = 8; mult_input1 = 2;
    #10 mult_input0 = 9; mult_input1 = 1;
    #10 mult_input0 = 11; mult_input1 = 91;
    #10 mult_input0 = 12; mult_input1 = 81;
    #10 mult_input0 = 13; mult_input1 = 71;
    #10 mult_input0 = 14; mult_input1 = 61;
    #10 mult_input0 = 15; mult_input1 = 51;
    #10 mult_input0 = 16; mult_input1 = 41;
    #10 mult_input0 = 17; mult_input1 = 31;
    #10 mult_input0 = 18; mult_input1 = 21;
    #10 mult_input0 = 19; mult_input1 = 11;
    #600 EN_mult = 0; // stop writing
    #10 EN_blockRead = 1;
    #10 readMem_val = 1; EN_blockRead = 0;
    #1000;

    $stop;
  end




  
endmodule


