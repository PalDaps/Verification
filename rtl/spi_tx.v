//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  spi_tx.v                                     //
//                        top level of RTL example project                     //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

`include "spi_tx_defines.vh"

module spi_tx (

  //SYSTEM
  input                        CLK,          // Clock
  input                        RST_N,        // Reset

  //AHB
  input                        HSEL,         // AHB INTERFACE SELECT DEVICE
  input                        HTRANS,       // AHB INTERFACE TRANSACTION ENABLE
  input  [`AHB_ADDR_WIDTH-1:0] HADDR,        // AHB INTERFACE ADDRESS
  input                        HWRITE,       // AHB INTERFACE WRITE/READ TRANSACTION SELECT
  input                        HREADY,       // AHB INTERFACE MASTER HANDSHAKE
  output                       HREADY_RESP,  // AHB INTERFACE SLAVE HANDSHAKE
  input      [`DATA_WIDTH-1:0] HWDATA,       // AHB INTERFACE WRITE DATA
  output     [`DATA_WIDTH-1:0] HRDATA,       // AHB INTERFACE READ DATA

  //SPI
  output                       SCLK,         // SPI INTERFACE CLOCK
  output                       SS,           // SPI SLAVE SELECT
  output                       MOSI          // SPI INTERFACE OUTPUT DATA
);

  // SPI control
  wire                   enable;             // enable transmitter control signal

  // FIFO TX control 
  wire                   fifo_tx_write;      // write from FIFO control signal
  wire                   fifo_tx_read;       // read from FIFO control signal
  wire                   fifo_tx_empty;      // fifo_tx empty state indicator
  wire                   fifo_tx_full;       // fifo_tx full state indicator
  wire [`DATA_WIDTH-1:0] fifo_tx_data_out;   // data from fifo

  //------------------------------- AHB Control ------------------------------------------//
  ahb_control ahb_cntrl(
    // SYSTEM
    .CLK(CLK),
    .RST_N(RST_N),

    //AHB
    .HSEL(HSEL),
    .HTRANS(HTRANS),
    .HADDR(HADDR),
    .HWRITE(HWRITE),
    .HREADY(HREADY),
    .HREADY_RESP(HREADY_RESP),
    .HWDATA(HWDATA),
    .HRDATA(HRDATA),
  
    //control
    .enable(enable),
    .fifo_tx_empty(fifo_tx_empty),
    .fifo_tx_full(fifo_tx_full),
    .fifo_tx_write(fifo_tx_write)
  );

  //---------------------------------- FIFO TX--------------------------------------------//
  fifo_buffer #(.pointer_width(2)) fifo_tx (
    //SYSTEM
    .CLK(CLK),
    .RST_N(RST_N),

    //control
    .FIFO_WRITE(fifo_tx_write),
    .FIFO_READ(fifo_tx_read),
    /* 
    Mistake 4
    Incorrect buffer dimension. The correct size is shown in the documentation.
    .DATA_IN(HWDATA[30:0]),
    */
    .DATA_IN(HWDATA[31:0]),
    .DATA_OUT(fifo_tx_data_out),
    .EMPTY(fifo_tx_empty),
    .FULL(fifo_tx_full)
  );

  //------------------------------- SPI Control ------------------------------------------//
  /* 
  Сollaboration
  Mistake 3
  Incorrect module name. It was like this:
  sip_control spi_cntrl( 
  */
  spi_control spi_cntrl(
    //SYSTEM
    .CLK(CLK),
    .RST_N(RST_N),

    //SPI
    .SCLK(SCLK),         // SPI INTERFACE CLOCK
    .SS(SS),             // SPI SLAVE SELECT
    .MOSI(MOSI),         // SPI INTERFACE OUTPUT DATA

    // control
    .enable(enable),
    .fifo_tx_read(fifo_tx_read),
    .fifo_tx_empty(fifo_tx_empty),
    .fifo_tx_data_out(fifo_tx_data_out)
  );

  //-------------------------------------RTL TRACER---------------------------------------//
  `ifdef TRACER_ENABLE
  spi_tx_tracer tracer();
  `endif

endmodule

