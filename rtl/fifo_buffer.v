//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  fifo_buffer.v                                //
//                        fifo buffer block for example project                //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

`define FIFO_DATA_WIDTH 32

module fifo_buffer (
  input                        CLK,                 // clock signal
  input                        RST_N,               // reset signal
  input                        FIFO_WRITE,          // write enable (write DATA_IN to FIFO on FIFO_WRITE=1)
  input                        FIFO_READ,           // read enable (read data from FIFO to DATA_OUT on FIFO_READ=1)
  input      [`FIFO_DATA_WIDTH-1:0] DATA_IN,        // input data
//output reg [`FIFO_DATA_WIDTH-1:0] DATA_OUT,       // output data buffered
  output     [`FIFO_DATA_WIDTH-1:0] DATA_OUT,       // output data unbuffered
  output                       EMPTY,               // FIFO empty flag
  output                       FULL                 // FIFO full flag
);

  parameter   [31:0] pointer_width = 2;                   // FIFO pointer width
  localparam  [31:0] fifo_depth    = 2**pointer_width;    // FIFO DEPTH

  reg [`FIFO_DATA_WIDTH-1:0] mem [fifo_depth-1:0];  // FIFO memory

  reg  [pointer_width:0] read_ptr;                  // pointer to last readed position
  reg  [pointer_width:0] wite_ptr;                  // pointer to write position
  wire [pointer_width:0] wite_ptr_p1;               // incremented pointer to last readed position
  wire [pointer_width:0] read_ptr_p1;               // incremented pointer to write position

  // FIFO DATA control
  always @(posedge CLK)
    if (FIFO_WRITE && !FULL) mem[wite_ptr[pointer_width:0]] <= DATA_IN;       // write to FIFO

  /*
  always @(posedge CLK)
    if (FIFO_READ && !EMPTY) DATA_OUT <= mem[read_ptr];                         // read from FIFO (buffered)
  */
  assign DATA_OUT = mem[read_ptr[pointer_width-1:0]];                           // read from FIFO (unbuffered)

  // FIFO pointers control
  assign wite_ptr_p1 = wite_ptr+1;
  always @(posedge CLK or negedge RST_N)
    if (!RST_N)                       wite_ptr <= 0;
    else if (FIFO_WRITE && !FULL)     wite_ptr <= wite_ptr_p1;                  // increment pointer on write FIFO event

  assign read_ptr_p1 = read_ptr+1;
  always @(posedge CLK or negedge RST_N)
    if (!RST_N)                       read_ptr <= 0;
    else if (FIFO_READ && !EMPTY)     read_ptr <= read_ptr_p1;                  // increment pointer on read FIFO event

  // FIFO State flags control
  assign EMPTY  = (wite_ptr == read_ptr) ? 1'b1 : 1'b0;
  assign FULL   = ((wite_ptr[pointer_width-1:0] == read_ptr[pointer_width-1:0]) && (wite_ptr[pointer_width] != read_ptr[pointer_width])) ? 1'b1 : 1'b0;

endmodule