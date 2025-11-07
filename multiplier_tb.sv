module fsm_tb;
  logic                 clk;
  logic                 rst;

  logic                 EN_mult;

  logic [15:0]          mult_input0;
  logic [15:0]          mult_input1;

  logic                 EN_blockRead;

  logic [32-1:0]        readMem_val;

  // Instantiate DUT
  fsm dut (
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

  // Clock generator
  initial clk = 0;
  always #5 clk = ~clk;

  // Stimulus
  initial begin
    rst = 0; EN_mult = 0; 
    #10 rst = 1;                // release reset
    #10 EN_mult = 1;            // start writing
    #10 mult_input0 = 1; mult_input1 = 1;
    #10 mult_input0 = 2; mult_input1 = 2;
    #10 mult_input0 = 3; mult_input1 = 3;
    #600; EN_mult = 0; 
    #50;
    $stop;
  end
endmodule


