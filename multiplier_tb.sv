module fsm_tb;
  // multiplier i/o
    logic                clk; // input
    logic                rst; // input     

    logic                EN_mult; // input
    logic                EN_writeMem; // output
    logic [6-1:0]          writeMem_addr; // output

    logic [15:0]         mult_input0; // input
    logic [15:0]         mult_input1; // input
    logic [16-1:0]       writeMem_val; // output 

    logic                RDY_mult;             
     
    logic                EN_blockRead; // input           
    logic                VALID_memVal; // output           
    logic [16-1:0]       memVal_data; // output            

    logic                EN_readMem; // output             
    logic [6-1:0]        readMem_addr; // output           
    logic [16-1:0]       readMem_val; // input 

    /////////////////////////////////////////

    logic           clkA; // input  
    logic           clkB; // input  
    logic [6-1:0]   aA; // input  
    logic [6-1:0]   aB; // input  
    logic           cenA; // input  
    logic           cenB; // input  
    logic [16-1:0]   d; // input  
    logic [16-1:0]   q; // output  



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
    .readMem_val(q)
  );

  // Instantiate memory_wrapper_2port DUT
  memory_wrapper_2port mw2p_dut (
    .clkA(clk),
    .clkB(clk),

    .aA(readMem_addr),
    .aB(writeMem_addr),

    .cenA(~EN_readMem),
    .cenB(~EN_writeMem),

    .d(writeMem_val),
    .q(q)
  );

  // Instantiate registerArray DUT
  registerArray mra_dut (
    .clkA(clk),
    .clkB(clk),

    .aA(readMem_addr),
    .aB(writeMem_addr),

    .cenA(~EN_readMem),
    .cenB(~EN_writeMem),

    .d(writeMem_val),
    .q(q)
  );


  // Clock generator
  initial clk = 0;
  always #5 clk = ~clk;

  // Stimulus to fsm
  initial begin
    // initialize signals
    rst = 0; EN_mult = 0; EN_blockRead = 0; 

    #10 rst = 1;                
    #10 EN_mult = 1;            
    #10 mult_input0 = 16'd1; mult_input1 = 16'd9;
    #10 mult_input0 = 16'd2; mult_input1 = 16'd8;
    #10 mult_input0 = 16'd3; mult_input1 = 16'd7;
    #10 mult_input0 = 16'd4; mult_input1 = 16'd6;
    #10 mult_input0 = 16'd5; mult_input1 = 16'd5;
    #10 mult_input0 = 16'd6; mult_input1 = 16'd4;
    #10 mult_input0 = 16'd7; mult_input1 = 16'd3;
    #10 mult_input0 = 16'd8; mult_input1 = 16'd2;
    #10 mult_input0 = 16'd9; mult_input1 = 16'd1;
    #10 mult_input0 = 16'd1; mult_input1 = 16'd9;
    #10 mult_input0 = 16'd2; mult_input1 = 16'd8;
    #10 mult_input0 = 16'd3; mult_input1 = 16'd7;
    #10 mult_input0 = 16'd4; mult_input1 = 16'd6;
    #10 mult_input0 = 16'd5; mult_input1 = 16'd5;
    #10 mult_input0 = 16'd6; mult_input1 = 16'd4;
    #10 mult_input0 = 16'd7; mult_input1 = 16'd3;
    #10 mult_input0 = 16'd8; mult_input1 = 16'd2;
    #10 mult_input0 = 16'd9; mult_input1 = 16'd1;
    #10 mult_input0 = 16'd1; mult_input1 = 16'd9;
    #10 mult_input0 = 16'd2; mult_input1 = 16'd8;
    #10 mult_input0 = 16'd3; mult_input1 = 16'd7;
    #10 mult_input0 = 16'd4; mult_input1 = 16'd6;
    #10 mult_input0 = 16'd5; mult_input1 = 16'd5;
    #10 mult_input0 = 16'd6; mult_input1 = 16'd4;
    #10 mult_input0 = 16'd7; mult_input1 = 16'd3;
    #10 mult_input0 = 16'd8; mult_input1 = 16'd2;
    #10 mult_input0 = 16'd9; mult_input1 = 16'd1;
    #10 mult_input0 = 16'd1; mult_input1 = 16'd9;
    #10 mult_input0 = 16'd2; mult_input1 = 16'd8;
    #10 mult_input0 = 16'd3; mult_input1 = 16'd7;
    #10 mult_input0 = 16'd4; mult_input1 = 16'd6;
    #10 mult_input0 = 16'd5; mult_input1 = 16'd5;
    #10 mult_input0 = 16'd6; mult_input1 = 16'd4;
    #10 mult_input0 = 16'd7; mult_input1 = 16'd3;
    #10 mult_input0 = 16'd8; mult_input1 = 16'd2;
    #10 mult_input0 = 16'd9; mult_input1 = 16'd1;
    #10 mult_input0 = 16'd1; mult_input1 = 16'd9;
    #10 mult_input0 = 16'd2; mult_input1 = 16'd8;
    #10 mult_input0 = 16'd3; mult_input1 = 16'd7;
    #10 mult_input0 = 16'd4; mult_input1 = 16'd6;
    #10 mult_input0 = 16'd5; mult_input1 = 16'd5;
    #10 mult_input0 = 16'd6; mult_input1 = 16'd4;
    #10 mult_input0 = 16'd7; mult_input1 = 16'd3;
    #10 mult_input0 = 16'd8; mult_input1 = 16'd2;
    #10 mult_input0 = 16'd9; mult_input1 = 16'd1;
    #10 mult_input0 = 16'd1; mult_input1 = 16'd9;
    #10 mult_input0 = 16'd2; mult_input1 = 16'd8;
    #10 mult_input0 = 16'd3; mult_input1 = 16'd7;
    #10 mult_input0 = 16'd4; mult_input1 = 16'd6;
    #10 mult_input0 = 16'd5; mult_input1 = 16'd5;
    #10 mult_input0 = 16'd6; mult_input1 = 16'd4;
    #10 mult_input0 = 16'd7; mult_input1 = 16'd3;
    #10 mult_input0 = 16'd8; mult_input1 = 16'd2;
    #10 mult_input0 = 16'd9; mult_input1 = 16'd1;
    #10 mult_input0 = 16'd1; mult_input1 = 16'd9;
    #10 mult_input0 = 16'd2; mult_input1 = 16'd8;
    #10 mult_input0 = 16'd3; mult_input1 = 16'd7;
    #10 mult_input0 = 16'd4; mult_input1 = 16'd6;
    #10 mult_input0 = 16'd5; mult_input1 = 16'd5;
    #10 mult_input0 = 16'd6; mult_input1 = 16'd4;
    #10 mult_input0 = 16'd7; mult_input1 = 16'd3;
    #10 mult_input0 = 16'd8; mult_input1 = 16'd2;
    #10 mult_input0 = 16'd9; mult_input1 = 16'd1;
    #10 mult_input0 = 16'd1; mult_input1 = 16'd9;
    #10 mult_input0 = 16'd2; mult_input1 = 16'd8;
    #10 mult_input0 = 16'd3; mult_input1 = 16'd7;
    #10 mult_input0 = 16'd4; mult_input1 = 16'd6;
    #10 mult_input0 = 16'd5; mult_input1 = 16'd5;
    #10 mult_input0 = 16'd6; mult_input1 = 16'd4;
    #10 mult_input0 = 16'd7; mult_input1 = 16'd3;
    #10 mult_input0 = 16'd8; mult_input1 = 16'd2;
    #10 mult_input0 = 16'd9; mult_input1 = 16'd1;
    #100;
    #10 EN_mult = 0; // stop writing
    #10 EN_blockRead = 1;

    #700 EN_mult = 1;
    #700;

    $stop;
  end

endmodule


// module fsm_tb;
//   localparam DEPTH=64, LOGD=6, W=16;

//   logic clk;
//   logic [LOGD-1:0] aA, aB;
//   logic cenA, cenB;             // ACTIVE-LOW enables
//   logic [W-1:0] d;
//   wire  [W-1:0] q;

//   // DUT: tie both ports to same clock for a simple demo
//   registerArray #(.DEPTH(DEPTH), .LOGDEPTH(LOGD), .WORDWIDTH(W)) dut (
//     .clkA(clk), .aA(aA), .cenA(cenA), .q(q),
//     .clkB(clk), .aB(aB), .cenB(cenB), .d(d)
//   );

//   // simple 50% duty clock
//   initial clk = 0;
//   always #5 clk = ~clk;

//   initial begin
//     // defaults
//     cenA = 0; cenB = 0; aA = '0; aB = '0; d = '0;

//     // ---- WRITE phase (addr=3, data=16'hBEEF) ----
//     @(negedge clk);              // set up before posedge
//       aB   = 6'd3;
//       d    = 16'hBEEF;
//       cenB = 0;                  // enable write (active-low)
//     @(posedge clk);              // write occurs here
//     @(negedge clk);
//       cenB = 0;                  // disable write

//     // ---- READ phase (same addr=3) ----
//     @(negedge clk);
//       aA   = 6'd3;
//       cenA = 0;                  // enable read (active-low)
//     @(posedge clk);              // rowBuffer <= mem[3] here; q updates
//     #1 $display("q = 0x%h (expect 0xBEEF)", q);

//     $finish;
//   end
// endmodule
