//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  spi_control_tx.v                             //
//                        spi tx logic and SPI interface controller            //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

`include "spi_tx_defines.vh"

module spi_control (
  //SYSTEM
  input                        CLK,          // Clock
  input                        RST_N,        // Reset
I do not know why I wrote this
  //SPI
  output                       SCLK,         // SPI INTERFACE CLOCK
  output                       SS,           // SPI SLAVE SELECT
  output                       MOSI,         // SPI INTERFACE OUTPUT DATA

  // control
  input                        enable,       // enable transmitter control signal
  output                       fifo_tx_read, // read from FIFO control signal
  input                        fifo_tx_empty,// fifo_tx empty state indicator
  input      [`DATA_WIDTH-1:0] fifo_tx_data_out // data from fifo

);

  // spi Control
  reg  [4:0] bit_cntr;                       // transmitted bit counter 
  wire       bit_cntr_next;                  // transmitted bit counter incremented
  wire       spi_enable;                     // spi enable control signal

  // fifo control
  assign fifo_tx_read  =  spi_enable & (&bit_cntr);       // read fifo when all bits transmitted

  //-------------------------------- SPI TX CONTROL --------------------------------------//

  // spi SM
  assign spi_enable = enable && (!fifo_tx_empty);        // enable if global enable and buffer not empty

  // tx bit counter
  assign bit_cntr_next = (bit_cntr == 5'h1f) ? 5'h0 : bit_cntr;
  always @ (negedge RST_N or posedge CLK) begin
    if (!RST_N)           bit_cntr <= 0;
    else if (spi_enable)  bit_cntr <= bit_cntr_next;    // if spi enable transmitt 1 bit
  end

  //------------------------------------ SPI interface control ---------------------------//
  assign SS   = ~spi_enable;                      // SS=0 when SPI transmitt in progress
  assign MOSI = fifo_tx_data_out[bit_cntr];       // DATA out
  assign SCLK = CLK;                              // SPI CLK

endmodule

