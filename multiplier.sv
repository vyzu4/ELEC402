typedef enum logic [1:0] { 
  S_IDLE, 
  S_WRITE, 
  S_FULL, 
  S_READ 
} state_t;

module multiplier #(
  parameter int DEPTH     = 64,
  parameter int LOGDEPTH  = 6,           // log2(DEPTH) = 6 for 64
  parameter int DATAW     = 32,          // N+1 bits in the figure; use 32 for 16x16 product
  parameter bit SIGNED    = 1'b1,
  parameter int OUT_SHIFT = 0
)(
  input  logic                clk,
  // input  logic                rst_n,

  input  logic                EN_mult,                 // enable to accept new multiplies
  output logic                EN_writeMem,             // write enable (ACTIVE-HIGH)
  output logic [LOGDEPTH-1:0] writeMem_addr,           // write address

  input  logic [15:0]         mult_input0,
  input  logic [15:0]         mult_input1,
  output logic [DATAW-1:0]    writeMem_val,            // write data

  output logic                RDY_mult,                // ready for new inputs

  input  logic                EN_blockRead,            // request to drain after FULL
  output logic                VALID_memVal,            // valid flag for memVal_data
  output logic [DATAW-1:0]    memVal_data,             // streamed data (from memory)

  output logic                EN_readMem,              // read enable (ACTIVE-HIGH)
  output logic [LOGDEPTH-1:0] readMem_addr,            // read address
  input  logic [DATAW-1:0]    readMem_val              // registered read data from memory
);


  //////////////////////////
  // extra signals
  //////////////////////////


state_t state, next_state;
logic first_write = 0'b0;
  ////////////////////////////

  // assign writeMem_val = mult_input0 * mult_input1; //add buffer before outputting, need clk

always_ff @(posedge clk) begin //maybe only on a clk edge TODO: make into always_ff(?) and put in sensitivity list
    // default values
    //next_state = state; //todo: do this ONLY on a clk edge


//    EN_writeMem     = 1'b0;
//    writeMem_addr   = 6'b0;
//    writeMem_val    = 32'b0;
//
//    RDY_mult        = 1'b1;
//
//    EN_readMem      = 1'b0;
//    readMem_addr    = 6'b0;
//
    // VALID_memVal    = 
    // memVal_data     = 


    case (state)
      S_IDLE: begin
        RDY_mult   = 1'b1;
	      EN_readMem= 1'b0;

        if(EN_mult==1'b1) begin
          //todo: 
          next_state = S_WRITE;
        end else begin
          next_state = S_IDLE;
        end
      end

      S_WRITE: begin //todo: CURRENTLY assuming enable bit is HIGH until
        RDY_mult   = 1'b1;
        if (writeMem_addr == 6'd61) begin //may be different value
          next_state = S_FULL;
        end else begin
		    next_state= S_WRITE;
	    end

      writeMem_addr = !first_write ?  0'b0 : writeMem_addr+1;
      first_write=1'b1;
      end

      S_FULL: begin
        RDY_mult = 1'b0;
        if (writeMem_addr!=6'd63) begin
          writeMem_addr = writeMem_addr + 1;
          EN_writeMem=1'b1;// this should STAY on, not turn on
        end else begin
          EN_writeMem=1'b0;
        end
      end

      default: next_state = S_IDLE;
    endcase

  end

endmodule
